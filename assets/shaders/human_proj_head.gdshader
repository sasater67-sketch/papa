shader_type spatial;
render_mode cull_disabled;
// Фото-человек: волосы и головные уборы — аффинная проекция видов головы (rp или вершины в позе покоя)
uniform sampler2D atlas : source_color, filter_linear_mipmap, repeat_disable;
uniform vec4 hf = vec4(0.0);
uniform vec4 hb = vec4(0.0);
uniform vec4 hs = vec4(0.0);
uniform bool use_vertex = false;
uniform float side_w = 1.0;
uniform float bright = 1.06;
uniform float wet = 0.0;
varying vec3 rp;
varying vec3 nm;

void vertex() {
	rp = use_vertex ? VERTEX : vec3(UV.x, UV.y, UV2.x);
	nm = NORMAL;
}

void fragment() {
	vec3 n = normalize(nm);
	vec2 uf = vec2(clamp(hf.x * rp.x + hf.y, 0.001, 0.332), hf.z * rp.y + hf.w);
	vec2 ub = vec2(clamp(hb.x * rp.x + hb.y, 0.334, 0.666), hb.z * rp.y + hb.w);
	vec2 us = vec2(clamp(hs.x * rp.z + hs.y, 0.668, 0.999), hs.z * rp.y + hs.w);
	float wf = pow(max(n.z, 0.0), 3.0);
	float wb = pow(max(-n.z, 0.0), 3.0);
	float ws = pow(abs(n.x), 3.0) * side_w;
	float wt = pow(abs(n.y), 3.0);
	wf += wt * step(0.0, rp.z + 0.01);
	wb += wt * step(rp.z + 0.01, 0.0);
	vec4 cf = texture(atlas, uf);
	vec4 cb = texture(atlas, ub);
	vec4 cs = texture(atlas, us);
	wf *= 0.04 + cf.a;
	wb *= 0.04 + cb.a;
	ws *= 0.04 + cs.a;
	float W = wf + wb + ws + 1e-4;
	vec3 col = (cf.rgb * wf + cb.rgb * wb + cs.rgb * ws) / W;
	ALBEDO = col * bright;
	ROUGHNESS = mix(0.75, 0.4, wet);
	SPECULAR = 0.3;
}
