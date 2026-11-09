shader_type spatial;
// Оконное стекло под дождём: бегущие струйки и круглые капли (кат-сцены).
// Все размеры — в метрах стекла (qsize), поэтому капли не «раздуваются»
// на больших или близких к камере стёклах.
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never;

uniform vec4 tint : source_color = vec4(0.2, 0.26, 0.36, 0.28);
uniform vec2 qsize = vec2(1.0, 1.0);
uniform float speed = 0.22;
uniform float drop_size = 1.0;
uniform float fade = 1.0;
uniform float drops = 1.0;

float h1(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

void fragment() {
	vec2 p = vec2(UV.x * qsize.x, (1.0 - UV.y) * qsize.y) / drop_size;   // y — вверх
	float d = 0.0;
	float hi = 0.0;
	// струйки: голова ползёт вниз, хвост — над ней
	for (int L = 0; L < 2; L++) {
		float cw = L == 0 ? 0.05 : 0.085;
		float col = floor(p.x / cw);
		float r = h1(vec2(col, float(L) * 7.0 + 1.0));
		float r2 = h1(vec2(col * 1.7, 3.0 + float(L)));
		float per = 0.45 + r * 0.6;
		float q = fract((p.y + TIME * speed * (0.5 + r)) / per + r2 * 5.0);
		float head = smoothstep(0.0, 0.012, q) * (1.0 - smoothstep(0.02, 0.045, q));
		float trail = (1.0 - smoothstep(0.0, 0.55, q)) * 0.32 * step(0.008, q);
		float xo = (r - 0.5) * 0.45 + sin(p.y * 22.0 + r * 6.0) * 0.06;
		float dx = abs(fract(p.x / cw) - 0.5 - xo);
		float xw = 1.0 - smoothstep(0.05, 0.11 - float(L) * 0.02, dx);
		float hw = 1.0 - smoothstep(0.08, 0.16, dx);
		float on = step(0.5, r2);
		d += trail * xw * on;
		hi += head * hw * on;
	}
	// неподвижные круглые капли: светлый блик сверху, тёмный край снизу
	float cs = 0.018;
	vec2 cell = floor(p / cs);
	vec2 f = fract(p / cs) - 0.5;
	float hc = h1(cell);
	float alive = step(0.93, h1(cell + floor(TIME * 0.12 + hc * 3.0) * 13.1));
	vec2 off = (vec2(h1(cell + 3.3), h1(cell + 7.7)) - 0.5) * 0.4;
	float rad = 0.16 + hc * 0.2;
	float dist = length(f - off);
	float drop = (1.0 - smoothstep(rad * 0.75, rad, dist)) * alive * drops;
	float glint = (1.0 - smoothstep(0.0, rad * 0.45, length(f - off - vec2(-0.05, 0.06)))) * alive * drops;
	float rim = smoothstep(rad * 0.45, rad * 0.95, dist) * drop;
	vec3 bright = vec3(0.8, 0.86, 0.96);
	vec3 c = mix(tint.rgb, bright, clamp(d * 0.85 + hi * 0.9 + drop * 0.25 + glint * 0.7, 0.0, 1.0));
	c = mix(c, tint.rgb * 0.5, rim * 0.5);
	ALBEDO = c;
	ALPHA = clamp(tint.a + d * 0.3 + hi * 0.45 + drop * 0.16 + glint * 0.35, 0.0, 0.92) * fade;
}
