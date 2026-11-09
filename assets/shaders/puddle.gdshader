// v0.5: лужа после дождя — неровный край (шум), почти зеркальная тёмная вода, рябь от капель во время дождя.
shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_back, shadows_disabled;

uniform float wet = 1.0;
uniform float rain = 0.0;
uniform float seed = 0.0;
uniform sampler2D noise_tex : filter_linear_mipmap, repeat_enable;

varying vec3 wp;

void vertex() {
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

vec2 h22(vec2 p) {
	vec3 a = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973));
	a += dot(a, a.yzx + 33.33);
	return fract((a.xx + a.yz) * a.zy);
}

// рябь: кольца от капель в ячейках
vec2 ripples(vec2 p, float t) {
	vec2 g = vec2(0.0);
	for (int l = 0; l < 2; l++) {
		vec2 pp = p * (l == 0 ? 2.2 : 3.4) + float(l) * 17.0;
		vec2 c = floor(pp);
		for (int j = -1; j <= 1; j++) {
			for (int i = -1; i <= 1; i++) {
				vec2 cc = c + vec2(float(i), float(j));
				vec2 h = h22(cc + seed);
				vec2 o = cc + 0.5 + (h - 0.5) * 0.7;
				float ph = fract(t * (0.9 + h.x * 0.6) + h.y);
				vec2 dv = pp - o;
				float dist = length(dv);
				float rr = ph * 0.9;
				float w = sin((dist - rr) * 28.0) * smoothstep(0.12, 0.0, abs(dist - rr)) * (1.0 - ph) * (1.0 - ph);
				g += normalize(dv + 1e-4) * w;
			}
		}
	}
	return g * 0.35;
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float n = texture(noise_tex, wp.xz * 0.11 + seed).r;
	float n2 = texture(noise_tex, wp.xz * 0.37 + seed * 1.7).g;
	float r = length(p) + (n - 0.5) * 0.9 + (n2 - 0.5) * 0.35;
	float water = 1.0 - smoothstep(0.48, 0.62, r);
	float damp = 1.0 - smoothstep(0.58, 0.98, r);
	vec2 rg = vec2(0.0);
	if (rain > 0.01) {
		rg = ripples(wp.xz, TIME) * rain;
	}
	NORMAL_MAP = normalize(vec3(rg * water, 1.0)) * 0.5 + 0.5;
	NORMAL_MAP_DEPTH = 1.0;
	ALBEDO = vec3(0.025, 0.027, 0.03);
	ROUGHNESS = mix(0.32, 0.03, water);
	METALLIC = 0.0;
	SPECULAR = 0.75;
	ALPHA = clamp(water * 0.86 + (damp - water) * 0.38, 0.0, 1.0) * wet;
}
