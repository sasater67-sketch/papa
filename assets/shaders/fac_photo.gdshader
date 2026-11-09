// v0.5: фасад здания по референсу — фото вида спереди с вырезкой фона (альфа),
// ночью светятся вывески и витрины (прямоугольники gr[i], сила gk[i]).
shader_type spatial;
render_mode cull_back;

uniform sampler2D tex : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
uniform vec4 gr[6];
uniform float gk[6];
uniform int ng = 0;
uniform float glow = 0.0;
uniform float wet = 0.0;
uniform float rough = 0.8;

void fragment() {
	vec4 c = texture(tex, UV);
	ALPHA = c.a;
	ALPHA_SCISSOR_THRESHOLD = 0.5;
	float e = 0.0;
	for (int i = 0; i < ng; i++) {
		vec4 r = gr[i];
		if (UV.x > r.x && UV.x < r.z && UV.y > r.y && UV.y < r.w) {
			e = max(e, gk[i]);
		}
	}
	float wl = wet * smoothstep(0.75, 1.0, UV.y);
	ALBEDO = c.rgb * (1.0 - 0.18 * wl);
	ROUGHNESS = mix(rough, 0.3, wl);
	SPECULAR = 0.35;
	EMISSION = c.rgb * c.rgb * e * glow * 2.2;
}
