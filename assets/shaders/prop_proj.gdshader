// v0.5: объект по референсу — проекция фото видов (спереди/сзади/слева/справа/сверху/снизу)
// на визуальную оболочку. Позиция в объекте: перед = +Z, право = +X. Альфа атласа: 1 - маска свечения.
shader_type spatial;
render_mode cull_back;

uniform sampler2D atlas : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
uniform vec4 pxu; uniform vec4 pxv;
uniform vec4 nxu; uniform vec4 nxv;
uniform vec4 pyu; uniform vec4 pyv;
uniform vec4 nyu; uniform vec4 nyv;
uniform vec4 pzu; uniform vec4 pzv;
uniform vec4 nzu; uniform vec4 nzv;
uniform float has_ny = 0.0;
uniform vec3 under_col : source_color = vec3(0.05);
uniform float sharp = 5.0;
uniform float rough = 0.75;
uniform float spec = 0.35;
uniform float bright = 0.86;
// верх уже освещён на фото — приглушаем, чтобы солнце сверху не выжигало
uniform float top_k = 0.78;
uniform float wet = 0.0;
uniform float soak = 0.25;
uniform float glow = 0.0;
uniform vec3 glow_col : source_color = vec3(1.0, 0.86, 0.62);

varying vec3 op;
varying vec3 on;

void vertex() {
	op = VERTEX;
	on = NORMAL;
}

vec2 mp(vec4 u, vec4 v) {
	return vec2(dot(u.xyz, op) + u.w, dot(v.xyz, op) + v.w);
}

void fragment() {
	vec3 n = normalize(on);
	vec3 w = pow(abs(n), vec3(sharp));
	bool nob = n.y < 0.0 && has_ny < 0.5;
	if (nob) {
		w.y *= 0.12;
	}
	float s = w.x + w.y + w.z + 1e-5;
	vec2 ux = n.x > 0.0 ? mp(pxu, pxv) : mp(nxu, nxv);
	vec2 uy = n.y > 0.0 ? mp(pyu, pyv) : mp(nyu, nyv);
	vec2 uz = n.z > 0.0 ? mp(pzu, pzv) : mp(nzu, nzv);
	vec4 cx = texture(atlas, ux);
	vec4 cy = texture(atlas, uy);
	if (nob) {
		cy = vec4(under_col, 1.0);
	}
	vec4 cz = texture(atlas, uz);
	vec4 c = (cx * w.x + cy * w.y + cz * w.z) / s;
	vec3 col = c.rgb * bright * mix(1.0, top_k, smoothstep(0.3, 0.9, n.y));
	if (nob) {
		col = mix(col, under_col, smoothstep(0.55, 0.95, -n.y));
	}
	float up = clamp(n.y + 0.25, 0.0, 1.0);
	ALBEDO = col * (1.0 - soak * wet);
	ROUGHNESS = mix(rough, rough * 0.3, wet * up);
	SPECULAR = mix(spec, 0.6, wet * up);
	METALLIC = 0.0;
	EMISSION = glow_col * smoothstep(0.15, 0.85, 1.0 - c.a) * glow * (0.6 + 0.6 * dot(c.rgb, vec3(0.33)));
}
