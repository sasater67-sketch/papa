shader_type canvas_item;
// Пост-обработка в духе «Project Zomboid от первого лица»: приглушённые, чуть выцветшие цвета,
// холодные тени и тёплые света (сплит-тонирование), виньетка, зерно плёнки, лёгкая хроматическая аберрация.
// Применяется к SubViewportContainer, в котором рисуется 3D-мир (TEXTURE — картинка мира).

uniform float amount : hint_range(0.0, 1.0) = 1.0;
uniform float saturation : hint_range(0.0, 2.0) = 0.62;
uniform float contrast : hint_range(0.5, 2.0) = 1.14;
uniform float brightness : hint_range(0.3, 1.6) = 1.0;
uniform vec3 shadow_tint = vec3(0.88, 0.97, 1.02);
uniform vec3 high_tint = vec3(1.08, 1.0, 0.82);
uniform float lift : hint_range(0.0, 0.2) = 0.035;
uniform float vignette : hint_range(0.0, 1.0) = 0.58;
uniform float grain : hint_range(0.0, 0.4) = 0.055;
uniform float grain_px = 1.0;
uniform float aberration : hint_range(0.0, 0.02) = 0.0018;
uniform float flash = 0.0;      // >0 — вспышка в белое, <0 — уход в чёрное (для катсцен)
uniform float bw = 0.0;         // 1 — чёрно-белое (флешбэки)

float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

void fragment() {
	vec2 uv = UV;
	vec2 d = uv - vec2(0.5);
	vec3 col = texture(TEXTURE, uv).rgb;
	if (aberration > 0.0) {
		vec2 off = d * aberration;
		col.r = texture(TEXTURE, uv + off).r;
		col.b = texture(TEXTURE, uv - off).b;
	}
	vec3 src = col;
	float l = dot(col, vec3(0.299, 0.587, 0.114));
	vec3 g = mix(vec3(l), col, saturation * (1.0 - bw));
	g = (g - 0.5) * contrast + 0.5;
	g *= brightness;
	vec3 tint = mix(shadow_tint, high_tint, smoothstep(0.05, 0.75, l));
	g *= mix(tint, vec3(1.0), bw * 0.6);
	g = lift + g * (1.0 - lift);
	float r = length(d * vec2(1.0, 0.78));
	g *= 1.0 - vignette * smoothstep(0.26, 0.8, r);
	float n = hash12(floor(FRAGCOORD.xy / grain_px) + vec2(fract(TIME * 3.7) * 613.0, fract(TIME * 1.9) * 197.0)) - 0.5;
	g += n * grain * (1.15 - l);
	col = mix(src, g, amount);
	col = mix(col, vec3(1.0), clamp(flash, 0.0, 1.0));
	col = mix(col, vec3(0.0), clamp(-flash, 0.0, 1.0));
	COLOR = vec4(clamp(col, 0.0, 1.0), 1.0);
}
