shader_type spatial;
render_mode cull_back;
// Фото-человек: проекция трёх видов референса (спереди / сзади / сбоку), UV посчитаны офлайн на вершину
uniform sampler2D atlas : source_color, filter_linear_mipmap, repeat_disable;
uniform float bright = 1.06;
uniform float wet = 0.0;
varying vec2 uvf;
varying vec2 uvb;
varying vec2 uvs;
varying vec3 nm;

void vertex() {
	uvf = UV;
	uvb = UV2;
	uvs = CUSTOM0.xy;
	nm = NORMAL;
}

void fragment() {
	vec3 n = normalize(nm);
	float wf = pow(max(n.z, 0.0), 3.0);
	float wb = pow(max(-n.z, 0.0), 3.0);
	float ws = pow(abs(n.x), 3.0);
	float wt = pow(abs(n.y), 3.0);
	wf += wt * step(0.0, n.z);
	wb += wt * step(n.z, 0.0);
	vec4 cf = texture(atlas, uvf);
	vec4 cb = texture(atlas, uvb);
	vec4 cs = texture(atlas, uvs);
	wf *= 0.04 + cf.a;
	wb *= 0.04 + cb.a;
	ws *= 0.04 + cs.a;
	float W = wf + wb + ws + 1e-4;
	vec3 col = (cf.rgb * wf + cb.rgb * wb + cs.rgb * ws) / W;
	ALBEDO = col * bright;
	ROUGHNESS = mix(0.8, 0.4, wet);
	SPECULAR = 0.32;
}
