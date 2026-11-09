shader_type canvas_item;
// Строки развёртки и бегущая полоса «экрана Пип-боя» поверх окна мини-игры (очень слабые).
uniform float strength = 0.07;
uniform float roll_speed = 0.09;
uniform vec4 tint : source_color = vec4(1.0, 0.71, 0.26, 1.0);

void fragment() {
	float line = step(1.0, mod(FRAGCOORD.y, 3.0));
	float y = fract(UV.y - TIME * roll_speed);
	float band = smoothstep(0.0, 0.05, y) * (1.0 - smoothstep(0.05, 0.12, y));
	COLOR = vec4(tint.rgb * band * 0.5, strength * (1.0 - line) + band * 0.035);
}
