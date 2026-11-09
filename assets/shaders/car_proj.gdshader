// v0.5: кузов машины по референсу — проекция фото пяти видов (бок справа/слева, сверху, спереди, сзади)
// на лофт-силуэт. Координаты — позиция в объекте (вперёд +X, вправо +Z). Альфа атласа: 1 - маска фонарей.
shader_type spatial;
render_mode cull_back;

uniform sampler2D atlas : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
uniform vec4 m_sr;
uniform vec4 m_sl;
uniform vec4 m_top;
uniform vec4 m_front;
uniform vec4 m_rear;
uniform float lights = 0.0;
uniform float front_pow = 6.0;
uniform float wet = 0.0;

varying vec3 op;
varying vec3 on;

void vertex() {
	op = VERTEX;
	on = NORMAL;
}

vec4 smp(vec4 m, float a, float b) {
	return texture(atlas, vec2(m.x * a + m.y, m.z * b + m.w));
}

void fragment() {
	vec3 n = normalize(on);
	vec3 w = pow(abs(n), vec3(6.0));
	float ws = w.z;
	float wt = n.y > 0.0 ? w.y : 0.0;
	float wf = n.x > 0.0 ? pow(n.x, front_pow) : 0.0;
	float wr = n.x < 0.0 ? w.x : 0.0;
	float s = ws + wt + wf + wr + 1e-5;
	vec4 c = vec4(0.0);
	if (ws > 0.03 * s) c += ws * (n.z > 0.0 ? smp(m_sr, op.x, op.y) : smp(m_sl, op.x, op.y));
	if (wt > 0.03 * s) c += wt * smp(m_top, op.x, op.z);
	if (wf > 0.03 * s) c += wf * smp(m_front, op.z, op.y);
	if (wr > 0.03 * s) c += wr * smp(m_rear, op.z, op.y);
	c /= s;
	float under = clamp(-n.y * 1.6 - 0.25, 0.0, 1.0);
	vec3 col = mix(c.rgb * 0.92, vec3(0.025), under);
	float lum = dot(col, vec3(0.3, 0.59, 0.11));
	float rough = mix(0.2, 0.34, smoothstep(0.02, 0.2, lum));
	rough = mix(rough, rough * 0.45, wet * clamp(n.y + 0.3, 0.0, 1.0));
	ALBEDO = col * (1.0 - 0.12 * wet);
	ROUGHNESS = rough;
	SPECULAR = 0.4;
	METALLIC = 0.0;
	float em = (1.0 - c.a) * lights;
	EMISSION = c.rgb * em * 5.0;
}
