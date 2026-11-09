// v0.5: небо «Атмосфера» — градиент по времени суток, солнце, луна, звёзды, облака-спрайты по референсу
// (атлас wx_clouds), сплошная/рваная облачность (бесшовный шум), вспышки и молнии грозы.
shader_type sky;

uniform vec3 top_col : source_color = vec3(0.012, 0.016, 0.045);
uniform vec3 hor_col : source_color = vec3(0.16, 0.11, 0.13);
uniform vec3 gnd_col : source_color = vec3(0.05, 0.045, 0.05);
uniform vec3 sun_dir = vec3(0.0, 0.5, -0.8);
uniform vec3 sun_col : source_color = vec3(1.0, 0.9, 0.7);
uniform float sun_vis = 1.0;
uniform float sunset = 0.0;
uniform vec3 moon_dir = vec3(0.3, 0.6, 0.7);
uniform float moon_vis = 0.0;
uniform float stars = 0.0;
uniform sampler2D clouds_tex : source_color, filter_linear_mipmap, repeat_disable;
uniform sampler2D noise_tex : filter_linear_mipmap, repeat_enable;
uniform sampler2D bolt_tex : filter_linear_mipmap, repeat_disable;
uniform vec4 cl_pos[24];
uniform vec4 cl_uv[24];
uniform vec4 cl_m[24];
uniform int cl_n = 0;
uniform float cl_rot = 0.0;
uniform vec3 cl_lit : source_color = vec3(1.0);
uniform vec3 cl_dark : source_color = vec3(0.55);
uniform float cover = 0.0;
uniform float cover_dark = 0.0;
uniform vec2 wind = vec2(0.0);
uniform float haze = 0.0;
uniform float flash = 0.0;
uniform vec3 bolt_dir = vec3(0.0, 0.2, -1.0);
uniform float bolt = 0.0;

float hash13(vec3 p3) {
	p3 = fract(p3 * 0.1031);
	p3 += dot(p3, p3.zyx + 31.32);
	return fract((p3.x + p3.y) * p3.z);
}

vec3 star_f(vec3 d) {
	vec3 p = d * 260.0;
	vec3 c = floor(p);
	float h = hash13(c);
	if (h < 0.986) {
		return vec3(0.0);
	}
	vec3 f = fract(p) - 0.5;
	float b = smoothstep(0.3, 0.0, length(f)) * (h - 0.986) / 0.014;
	float tw = 0.6 + 0.4 * fract(h * 911.0);
	return mix(vec3(1.0, 0.85, 0.7), vec3(0.75, 0.85, 1.0), fract(h * 37.0)) * b * tw * 2.2;
}

void sky() {
	vec3 d = normalize(EYEDIR);
	float y = d.y;
	vec3 col;
	if (y >= 0.0) {
		col = mix(hor_col, top_col, pow(clamp(y, 0.0, 1.0), 0.45));
	} else {
		col = mix(hor_col, gnd_col, clamp(-y * 5.0, 0.0, 1.0));
	}
	// закатное зарево со стороны солнца
	vec2 sh = normalize(sun_dir.xz + vec2(1e-4));
	float az = max(dot(normalize(d.xz + vec2(1e-4)), sh), 0.0);
	float lowk = pow(1.0 - clamp(abs(y), 0.0, 1.0), 6.0);
	col += sun_col * pow(az, 3.0) * lowk * sunset * 0.9;
	// солнце
	float sd = dot(d, normalize(sun_dir));
	col += sun_col * sun_vis * (pow(max(sd, 0.0), 12.0) * 0.35 + pow(max(sd, 0.0), 220.0) * 1.5);
	col += sun_col * sun_vis * smoothstep(0.99955, 0.9997, sd) * 14.0;
	// луна
	float md = dot(d, normalize(moon_dir));
	if (moon_vis > 0.0) {
		float disc = smoothstep(0.99935, 0.9995, md);
		float mar = texture(noise_tex, d.xz * 9.0).g;
		col += vec3(0.85, 0.88, 0.95) * disc * moon_vis * (1.4 - mar * 0.6);
		col += vec3(0.25, 0.3, 0.45) * pow(max(md, 0.0), 60.0) * moon_vis * 0.5;
	}
	// звёзды
	if (stars > 0.0 && y > 0.0 && !AT_CUBEMAP_PASS) {
		col += star_f(d) * stars * smoothstep(0.0, 0.2, y);
	}
	// сплошная / рваная облачность
	float ca = 0.0;
	if (cover > 0.001 && y > -0.05) {
		float yy = max(y, 0.0);
		vec2 uvp = d.xz / (yy + 0.1) * 0.06 + wind;
		vec2 n1 = texture(noise_tex, uvp).rg;
		vec2 n2 = texture(noise_tex, uvp * 3.3 + wind * 2.1).rg;
		float dens = n1.r * 0.8 + n2.g * 0.45 - 0.1;
		float th = mix(0.95, -0.2, cover);
		ca = smoothstep(th, th + 0.22, dens) * smoothstep(-0.04, 0.06, y);
		float shade = clamp((n2.g - 0.25) * 1.4 + (dens - th) * 0.6, 0.0, 1.0);
		vec3 oc = mix(cl_dark, cl_lit, shade) * (1.0 - cover_dark * (0.45 + 0.4 * (1.0 - n1.r)));
		oc += sun_col * sun_vis * pow(max(sd, 0.0), 8.0) * 0.4 * (1.0 - shade);
		col = mix(col, oc, ca);
	}
	// молния (за облаками-спрайтами)
	if (bolt > 0.0) {
		vec3 bc = normalize(bolt_dir);
		float db = dot(d, bc);
		if (db > 0.85) {
			vec3 br = normalize(vec3(-bc.z, 0.0, bc.x));
			vec3 bu = cross(br, bc);
			vec2 q = vec2(dot(d, br), dot(d, bu)) / db;
			vec2 st = vec2(q.x / 0.1 + 0.5, 0.5 - q.y / 0.4);
			if (st.x > 0.0 && st.x < 1.0 && st.y > 0.0 && st.y < 1.0) {
				float b = textureLod(bolt_tex, st, 0.0).r;
				col += vec3(0.8, 0.86, 1.0) * b * bolt * 5.0;
			}
		}
	}
	// облака-спрайты (фото по референсу)
	float pa = max(length(fwidth(d)), 1e-5);
	vec4 acc = vec4(0.0);
	for (int i = 0; i < cl_n; i++) {
		vec4 P = cl_pos[i];
		vec4 M = cl_m[i];
		if (M.x <= 0.001) {
			continue;
		}
		float a0 = P.x + cl_rot * M.z;
		float ce = cos(P.y);
		vec3 c = vec3(sin(a0) * ce, sin(P.y), -cos(a0) * ce);
		float dc = dot(d, c);
		if (dc < 0.6) {
			continue;
		}
		vec3 r = vec3(cos(a0), 0.0, sin(a0));
		vec3 u = cross(r, c);
		vec2 q = vec2(dot(d, r), dot(d, u)) / dc;
		vec2 st = q / P.zw * 0.5 + 0.5;
		if (st.x <= 0.0 || st.x >= 1.0 || st.y <= 0.0 || st.y >= 1.0) {
			continue;
		}
		vec4 R = cl_uv[i];
		if (M.w > 0.5) {
			st.x = 1.0 - st.x;
		}
		vec2 uv = vec2(mix(R.x, R.z, st.x), mix(R.w, R.y, st.y));
		float tpp = pa * (R.z - R.x) * 2048.0 / (2.0 * P.z);
		vec4 t = textureLod(clouds_tex, uv, log2(max(tpp, 1.0)));
		float a = t.a * M.x;
		vec3 cc = mix(cl_dark, cl_lit, clamp((t.r - 0.35) * 1.6 * M.y, 0.0, 1.2));
		cc += sun_col * sun_vis * pow(max(sd, 0.0), 6.0) * (1.0 - t.a * 0.7) * 0.8;
		acc.rgb += (1.0 - acc.a) * cc * a;
		acc.a += (1.0 - acc.a) * a;
		if (acc.a > 0.98) {
			break;
		}
	}
	col = col * (1.0 - acc.a) + acc.rgb;
	// дымка у горизонта
	col = mix(col, hor_col, haze * (1.0 - smoothstep(-0.02, 0.3, y)));
	// вспышка грозы
	col += flash * vec3(0.55, 0.6, 0.75) * (0.35 + 0.65 * max(ca, acc.a)) * smoothstep(-0.2, 0.3, y);
	COLOR = col;
}
