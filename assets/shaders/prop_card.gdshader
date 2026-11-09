// v0.5: плоская вырезка объекта по референсу (кронштейн фонаря): фото с маской, двусторонняя
shader_type spatial;
render_mode cull_disabled;

uniform sampler2D tex : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
uniform float rough = 0.5;
uniform float spec = 0.4;
uniform float wet = 0.0;

void fragment() {
	vec4 c = texture(tex, UV);
	if (c.a < 0.5) {
		discard;
	}
	ALBEDO = c.rgb;
	ROUGHNESS = mix(rough, rough * 0.4, wet);
	SPECULAR = spec;
}
