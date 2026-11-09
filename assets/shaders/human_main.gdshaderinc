void vertex() {
	rp = vec3(UV.x, UV.y, UV2.x);
	pid = UV2.y;
	mk = COLOR;
}

void fragment() {
	float pw = max(length(fwidth(rp)), 0.00025);
	vec3 col;
	float rough;
	float spec;
	float metal = 0.0;
	if (pid > 7.5 && pid < 8.5) {
		// рваная кромка чёлки и кончиков прядей
		float e = mk.r * 0.04;
		if (e < 0.03) {
			vec3 d = rp - vec3(0.0, 1.585, -0.005);
			float ph = atan(d.x, d.z);
			float amp = rp.y < 1.56 ? 0.024 : 0.011;
			float jag = amp * (0.15 + 0.6 * vnoise(vec2(ph * 46.0, 1.7)) + 0.4 * vnoise(vec2(ph * 150.0, 5.3)));
			if (e < jag) discard;
		}
		hair_paint(rp, col, rough, spec);
	} else if (pid > 8.5) {
		// юбка: цвет низа (или платья), складки, подол; у горничной — белый фартук спереди
		vec3 c = (bot_kind == 4 || top_kind == 13) ? top_col : bot_col;
		if (top_kind == 10) c = vec3(0.06, 0.06, 0.07);
		float a = atan(rp.x, rp.z + 0.01);
		c *= 0.9 + 0.12 * (0.5 + 0.5 * cos(a * 22.0)) ;
		c = mix(c, c * 0.75, band(rp.y, 0.46, 0.475, pw));
		if (top_kind == 10) {
			float ap = aa(0.75 - abs(a), pw * 6.0) * step(0.47 + 0.006 * sin(a * 40.0), rp.y);
			c = mix(c, vec3(0.96, 0.95, 0.93), ap);
		}
		col = c * (0.95 + 0.05 * vnoise(vec2(a * 60.0, rp.y * 200.0)));
		rough = 0.82;
		spec = 0.3;
	} else {
		body_paint(rp, mk, pw, col, rough, spec, metal);
		if (mk.a > 0.5 && mk.r < 0.5) {
			face_paint(rp, pw, col, rough, spec);
		}
	}
	ALBEDO = col;
	ROUGHNESS = rough;
	SPECULAR = spec;
	METALLIC = metal;
}
