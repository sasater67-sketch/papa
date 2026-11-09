shader_type canvas_item;
// Иконка в монохроме «янтарного» экрана: яркость → оттенок янтаря.
uniform vec4 tint : source_color = vec4(1.0, 0.714, 0.259, 1.0);
void fragment() {
	vec4 c = texture(TEXTURE, UV) * COLOR;
	float l = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	COLOR = vec4(tint.rgb * (0.35 + 0.9 * l), c.a);
}
