// Персонаж: процедурная «роспись» модели тела (кожа, одежда, обувь, лицо с мимикой, волосы).
// Координаты раскраски — позиция вершины в позе покоя (UV = x,y; UV2.x = z), поэтому рисунок
// не «плывёт» при анимации и морфах. UV2.y — тип меша: 0..4 тело, 8 волосы, 9 юбка.
// COLOR вершин тела: r — рука, g — нога, b — запечённая AO, a — голова.

varying vec3 rp;
varying vec4 mk;
varying float pid;

uniform vec3 skin_col : source_color = vec3(0.93, 0.76, 0.62);
uniform vec3 hair_col : source_color = vec3(0.22, 0.13, 0.07);
uniform vec3 eye_col : source_color = vec3(0.28, 0.42, 0.22);
uniform vec3 lip_col : source_color = vec3(0.72, 0.40, 0.38);
uniform vec3 top_col : source_color = vec3(0.2, 0.45, 0.85);
uniform vec3 top_col2 : source_color = vec3(0.95, 0.94, 0.9);
uniform vec3 shirt_col : source_color = vec3(0.95, 0.94, 0.9);
uniform vec3 bot_col : source_color = vec3(0.16, 0.18, 0.26);
uniform vec3 shoe_col : source_color = vec3(0.12, 0.09, 0.07);
uniform vec3 sole_col : source_color = vec3(0.9, 0.88, 0.84);
uniform vec3 tie_col : source_color = vec3(0.75, 0.1, 0.15);
uniform vec3 belt_col : source_color = vec3(0.17, 0.11, 0.07);
// 0 нет, 1 футболка, 2 лонгслив, 3 майка, 4 худи, 5 гавайка, 6 футболка с логотипом, 7 жилет, 8 смокинг,
// 9 костюм, 10 горничная, 11 повар, 12 фартук, 13 платье, 14 поло, 15 свитер, 16 блузка, 17 клетка, 18 полоска
uniform int top_kind = 1;
uniform int bot_kind = 0;      // 0 брюки, 1 джинсы, 2 шорты, 3 юбка, 4 платье (низ = верх)
uniform int shoe_kind = 0;     // 0 кеды, 1 туфли, 2 ботинки, 3 туфли-лодочки
uniform int tie_kind = 0;      // 0 нет, 1 бабочка, 2 галстук
uniform int beard = 0;         // 0 нет, 1 усы, 2 борода, 3 щетина
uniform int scalp = 1;         // 0 лысый, 1 короткая линия роста волос, 2 длинная
uniform float makeup = 0.0;
uniform float slim = 0.0;
uniform float male = 0.0;
uniform float tights = 0.0;
// мимика
uniform float eye_l = 1.0;
uniform float eye_r = 1.0;
uniform float happy_eyes = 0.0;
uniform float mouth_curve = 0.35;
uniform float mouth_open = 0.0;
uniform float teeth = 0.0;
uniform float brow_up = 0.0;
uniform float brow_angry = 0.0;
uniform float brow_sad = 0.0;
uniform float tears = 0.0;
uniform float blush = 0.0;
uniform vec2 gaze = vec2(0.0);

float hash21(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash21(i);
	float b = hash21(i + vec2(1.0, 0.0));
	float c = hash21(i + vec2(0.0, 1.0));
	float d = hash21(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// сглаженная маска по знаковому расстоянию (d > 0 — внутри), pw — размер пикселя в метрах
float aa(float d, float pw) {
	return clamp(d / pw + 0.5, 0.0, 1.0);
}

float band(float v, float a, float b, float pw) {
	return aa(v - a, pw) * aa(b - v, pw);
}

float lerp_tab8(float a, float k0, float k1, float k2, float k3, float k4, float k5, float k6, float k7,
		float v0, float v1, float v2, float v3, float v4, float v5, float v6, float v7) {
	if (a < k1) return mix(v0, v1, clamp((a - k0) / (k1 - k0), 0.0, 1.0));
	if (a < k2) return mix(v1, v2, (a - k1) / (k2 - k1));
	if (a < k3) return mix(v2, v3, (a - k2) / (k3 - k2));
	if (a < k4) return mix(v3, v4, (a - k3) / (k4 - k3));
	if (a < k5) return mix(v4, v5, (a - k4) / (k5 - k4));
	if (a < k6) return mix(v5, v6, (a - k5) / (k6 - k5));
	return mix(v6, v7, clamp((a - k6) / (k7 - k6), 0.0, 1.0));
}

// линия роста волос (высота) по азимуту вокруг головы (0 — лицо)
float hairline_y(float ph, int st) {
	float a = abs(ph);
	if (st == 2) {
		return lerp_tab8(a, 0.0, 0.5, 0.95, 1.35, 1.75, 2.3, 2.8, 3.1416, 1.640, 1.636, 1.618, 1.54, 1.50, 1.48, 1.472, 1.47);
	}
	return lerp_tab8(a, 0.0, 0.5, 0.95, 1.30, 1.62, 2.0, 2.5, 3.1416, 1.642, 1.638, 1.620, 1.588, 1.585, 1.535, 1.50, 1.49);
}

// узор ткани: координаты на «развёртке» части тела
vec2 cloth_uv(vec3 p, float arm, float leg) {
	if (arm > 0.5) {
		float a = atan(p.y - 1.33, p.z + 0.065);
		return vec2(abs(p.x) * sign(p.x + 1e-5), a * 0.05);
	}
	if (leg > 0.5) {
		float cx = sign(p.x) * 0.115;
		float a = atan(p.x - cx, p.z + 0.03);
		return vec2(a * 0.07 + sign(p.x) * 0.5, p.y);
	}
	float a = atan(p.x, p.z + 0.02);
	return vec2(a * 0.19, p.y);
}

vec3 flowers(vec2 q, vec3 base, vec3 c2) {
	vec2 g = q / 0.055;
	vec2 cell = floor(g);
	vec3 col = base;
	for (int j = -1; j <= 1; j++) {
		for (int i = -1; i <= 1; i++) {
			vec2 cc = cell + vec2(float(i), float(j));
			float h = hash21(cc);
			vec2 ctr = cc + vec2(0.25 + 0.5 * hash21(cc + 7.1), 0.25 + 0.5 * hash21(cc + 3.7));
			vec2 d = g - ctr;
			float r = length(d);
			float ang = atan(d.y, d.x) + h * 6.283;
			// лист
			vec2 ld = d - vec2(cos(h * 9.0), sin(h * 9.0)) * 0.42;
			float leaf = 1.0 - smoothstep(0.17, 0.2, length(ld * vec2(1.0, 2.2)));
			col = mix(col, vec3(0.16, 0.42, 0.22) * (0.8 + 0.4 * h), leaf * 0.85);
			float petal = 0.30 * (0.62 + 0.38 * cos(5.0 * ang));
			float fl = 1.0 - smoothstep(petal - 0.02, petal + 0.01, r);
			vec3 pc = mix(c2, vec3(1.0, 0.55, 0.35), step(0.6, h));
			col = mix(col, pc, fl);
			col = mix(col, vec3(1.0, 0.85, 0.3), 1.0 - smoothstep(0.05, 0.07, r));
		}
	}
	return col;
}

// фишка-логотип (казино) на груди
vec3 chip_logo(vec2 d, vec3 col, vec3 c2, float pw) {
	float r = length(d);
	float ang = atan(d.y, d.x);
	float ring = band(r, 0.026, 0.040, pw);
	float notch = step(0.5, fract(ang / 6.2832 * 8.0));
	col = mix(col, mix(c2, vec3(0.95), notch), ring);
	col = mix(col, c2, band(r, 0.0, 0.026, pw));
	// звезда
	float k = abs(fract(ang / 6.2832 * 5.0 + 0.25) - 0.5) * 2.0;
	float star = 0.017 * (0.45 + 0.55 * k);
	col = mix(col, vec3(1.0, 0.86, 0.3), aa(star - r, pw));
	col = mix(col, c2 * 0.6, band(r, 0.0395, 0.042, pw));
	return col;
}

void body_paint(vec3 p, vec4 m, float pw, out vec3 col, out float rough, out float spec, out float metal) {
	float x = p.x;
	float ax = abs(x);
	float y = p.y;
	float z = p.z;
	float s = x >= 0.0 ? 1.0 : -1.0;
	float arm = m.r;
	float leg = m.g;
	float ao = m.b;
	float headm = m.a;
	bool is_arm = arm > 0.5;
	bool is_leg = leg > 0.5;
	bool is_head = headm > 0.5 && !is_arm;
	bool is_torso = !is_arm && !is_leg && !is_head;
	rough = 0.68;
	spec = 0.3;
	metal = 0.0;
	// ---------- кожа (альбедо реальной кожи темнее «рисованных» цветов палитры)
	vec3 skin = skin_col * 0.8 * (0.97 + 0.06 * vnoise(p.xy * 180.0 + p.z * 40.0));
	// ладони и стопы светлее, колени/локти чуть розовее
	skin = mix(skin, skin * vec3(1.03, 0.94, 0.92), 0.5 * exp(-pow((y - 0.46) / 0.04, 2.0)) * leg);
	col = skin;
	// ногти
	if (is_arm && ax > 0.808 && y > 1.326) {
		vec3 nail = mix(skin * vec3(1.08, 1.0, 1.0) + 0.05, vec3(0.75, 0.08, 0.16), step(0.5, makeup));
		col = mix(col, nail, 0.8);
		rough = 0.3;
	}
	// ---------- низ: брюки / шорты / юбка (на бёдрах — под юбкой) / колготки
	float pants_top = 0.905;
	float waist = band(y, -1.0, pants_top, pw) * (is_head ? 0.0 : 1.0) * (is_arm ? 0.0 : 1.0);
	float bot_lo = 0.098;
	if (bot_kind == 2) bot_lo = 0.53;
	if (bot_kind >= 3) bot_lo = 0.46;
	vec3 bcol = bot_kind == 4 ? top_col : bot_col;
	if (top_kind == 10) bcol = vec3(0.06, 0.06, 0.07);
	float cover_b = waist * aa(y - bot_lo, pw);
	if (cover_b > 0.0) {
		vec3 c = bcol;
		vec2 cu = cloth_uv(p, arm, leg);
		if (bot_kind == 1) {
			// джинсы: диагональная саржа, потёртости, строчка, карманы
			float tw = sin((cu.x * 1.0 + y) * 1400.0) * 0.5 + 0.5;
			c *= 0.9 + 0.14 * tw;
			c = mix(c, c * 1.35 + 0.05, 0.35 * smoothstep(0.55, 0.9, vnoise(vec2(cu.x * 30.0, y * 12.0))) * leg);
			vec3 st = vec3(0.85, 0.55, 0.2);
			if (z > 0.02 && !is_leg) {
				// передние карманы — дуга
				float pc = length(vec2(ax - 0.19, (y - 0.93) * 1.1)) - 0.075;
				c = mix(c, st, band(pc, -0.0012, 0.0, pw) * step(y, 0.905));
				c = mix(c, c * 0.6, band(pc, 0.0, 0.0012, pw) * step(y, 0.905));
				// гульфик
				c = mix(c, st, band(x, 0.012, 0.0135, pw) * band(y, 0.78, 0.9, pw));
			}
			if (z < -0.1 && ax > 0.035 && ax < 0.135) {
				float bp = band(y, 0.765, 0.865, pw) * band(ax, 0.04, 0.13, pw);
				float bl = 1.0 - band(y, 0.769, 0.861, pw) * band(ax, 0.044, 0.126, pw);
				c = mix(c, st, bp * bl);
			}
			rough = 0.9;
		} else if (bot_kind == 3 || bot_kind == 4) {
			rough = 0.8;
		} else {
			c *= 0.95 + 0.08 * vnoise(vec2(cu.x * 260.0, y * 260.0));
			// стрелки / шов
			if (z > 0.02 && !is_leg) c = mix(c, c * 0.7, band(x, -0.0008, 0.0008, pw) * band(y, 0.76, 0.9, pw));
			rough = 0.82;
		}
		// подгиб на шортах
		if (bot_kind == 2) c = mix(c, c * 0.8, band(y, bot_lo, bot_lo + 0.018, pw));
		col = mix(col, c, cover_b);
		spec = 0.3;
	}
	// колготки (горничная) / чулки
	float tg = tights > 0.0 ? tights : (top_kind == 10 ? 0.85 : 0.0);
	if (tg > 0.0 && is_leg && y < bot_lo && y > 0.09) {
		col = mix(col, vec3(0.05, 0.05, 0.06) + col * 0.15, tg * 0.8);
		rough = 0.45;
	}
	// ремень
	bool tucked = top_kind == 2 || top_kind == 14 || top_kind == 16 || top_kind == 17 || top_kind == 0;
	if (tucked && bot_kind < 3 && !is_arm && !is_head) {
		float bm = band(y, 0.873, 0.903, pw);
		if (bm > 0.0) {
			vec3 bc = belt_col;
			float bk = band(ax, 0.0, 0.017, pw) * step(0.06, z);
			bc = mix(bc, vec3(0.85, 0.7, 0.35), bk * (1.0 - band(ax, 0.0, 0.011, pw) * band(y, 0.879, 0.897, pw)));
			col = mix(col, bc, bm);
			rough = mix(rough, 0.35, bm);
			metal = bk * bm * 0.8;
		}
	}
	// ---------- обувь
	float shoe_h = shoe_kind == 2 ? 0.2 : (shoe_kind == 3 ? 0.075 : 0.102);
	if (is_leg && y < shoe_h + 0.01) {
		float sm = aa(shoe_h - y, pw);
		vec3 sc = shoe_col;
		float r2 = 0.35;
		if (shoe_kind == 0) {
			// кеды: белая подошва, носок, полоска
			float sole = aa(0.03 - y, pw);
			sc = mix(sc, sole_col, sole);
			sc = mix(sc, sole_col, aa(z - 0.075, pw) * aa(0.05 - y, pw));
			float stripe = band(y - (z + 0.06) * 0.35, 0.045, 0.056, pw) * step(-0.08, z) * step(z, 0.06);
			sc = mix(sc, mix(sole_col, sc * 0.5, 0.3), stripe);
			r2 = 0.75;
			// носки для шорт / юбок
			if (bot_kind >= 2 && y > shoe_h - 0.002) sc = vec3(0.93);
		} else if (shoe_kind == 3) {
			r2 = 0.25;
			sc = mix(sc, sc * 0.4, aa(0.012 - y, pw));
		} else {
			sc = mix(sc, sc * 0.35 + 0.02, aa(0.016 - y, pw));
			if (shoe_kind == 2) sc = mix(sc, sc * 0.75, band(y, 0.17, 0.2, pw));
			r2 = shoe_kind == 1 ? 0.22 : 0.55;
		}
		col = mix(col, sc, sm);
		rough = mix(rough, r2, sm);
		spec = mix(spec, 0.6, sm);
	}
	if (bot_kind >= 2 && shoe_kind == 0 && is_leg && y >= 0.102 && y < 0.145) {
		col = mix(col, vec3(0.93, 0.93, 0.9), band(y, 0.1, 0.142, pw));
		rough = 0.9;
	}
	// ---------- верх
	if (top_kind > 0 && !is_head && !is_leg) {
		float hem = 0.865;
		float sleeve = 0.335;
		float nl_f = 1.412;      // вырез спереди
		float nl_b = 1.445;      // сзади
		float v_d = 0.0;         // глубина V-выреза
		float v_w = 0.06;
		vec3 c = top_col;
		float r3 = 0.85;
		if (top_kind == 2 || top_kind == 15 || top_kind == 17 || top_kind == 4 || top_kind == 11) sleeve = 0.64;
		if (top_kind == 3 || top_kind == 13) sleeve = 0.0;
		if (top_kind == 16) { sleeve = 0.5; v_d = 0.07; v_w = 0.07; }
		if (top_kind == 5) { v_d = 0.075; v_w = 0.065; }
		if (top_kind == 14) { v_d = 0.035; v_w = 0.025; }
		if (top_kind == 7 || top_kind == 8 || top_kind == 9) { sleeve = 0.64; nl_f = 1.45; nl_b = 1.47; }
		if (top_kind == 11) { nl_f = 1.455; nl_b = 1.47; hem = 0.78; }
		if (top_kind == 8 || top_kind == 9) hem = 0.79;
		if (top_kind == 10) { sleeve = 0.29; hem = 0.0; }
		if (top_kind == 12) { sleeve = 0.47; hem = 0.905; }
		if (top_kind == 2 || top_kind == 14 || top_kind == 16 || top_kind == 17) hem = 0.905;
		if (top_kind == 4) hem = 0.84;
		if (top_kind == 13) hem = 0.0;
		float front = smoothstep(-0.03, 0.03, z);
		float nl = mix(nl_b, nl_f, front);
		nl -= v_d * clamp(1.0 - ax / v_w, 0.0, 1.0) * front;
		nl += 0.4 * smoothstep(0.07, 0.105, ax);
		float cov = 0.0;
		if (is_arm) {
			cov = aa(sleeve - ax, pw);
		} else {
			cov = aa(nl - y, pw) * aa(y - hem, pw);
			if (top_kind == 3 || top_kind == 13 || top_kind == 10 && false) {
				// майка / платье на бретелях: открытые плечи
				float strap = band(ax, 0.07, 0.115, pw);
				float body = aa(mix(1.30, 1.255, front) - y + 0.02 * (1.0 - smoothstep(0.0, 0.14, ax)) * front, pw);
				cov = max(body, strap * aa(1.5 - y, pw)) * aa(y - hem, pw);
				if (ax > 0.17 && y > 1.2) cov *= aa(1.245 - y, pw);
			}
		}
		if (cov > 0.0) {
			vec2 cu = cloth_uv(p, arm, leg);
			c *= 0.96 + 0.06 * vnoise(cu * vec2(320.0, 320.0));
			if (top_kind == 18) c = mix(c, top_col2, step(0.5, fract(y / 0.034)));
			if (top_kind == 17) {
				float gx = step(0.5, fract(cu.x / 0.05)); float gy = step(0.5, fract(cu.y / 0.05));
				c = mix(c, c * 0.55, 0.5 * gx + 0.5 * gy);
				c = mix(c, top_col2, 0.5 * step(0.84, fract(cu.x / 0.05 + 0.1)) + 0.5 * step(0.84, fract(cu.y / 0.05 + 0.1)));
			}
			if (top_kind == 5) c = flowers(cu, c, top_col2);
			if (top_kind == 15) {
				c *= 0.92 + 0.1 * (sin(cu.x * 900.0) * 0.5 + 0.5);
				if (is_arm) c = mix(c, c * 0.85, band(ax, 0.6, 0.64, pw));
				else c = mix(c, c * 0.85, band(y, hem, hem + 0.035, pw));
			}
			// подгиб рукава и низа
			if (is_arm && sleeve < 0.6 && sleeve > 0.1) c = mix(c, c * 0.82, band(ax, sleeve - 0.012, sleeve, pw));
			if (!is_arm && hem > 0.1) c = mix(c, c * 0.84, band(y, hem, hem + 0.01, pw));
			// вырез — окантовка
			if (!is_arm) c = mix(c, c * 0.8, band(y, nl - 0.008, nl, pw));
			// плечевой шов
			if (sleeve > 0.1) c = mix(c, c * 0.85, band(ax, 0.212, 0.216, pw) * (is_arm ? 1.0 : 0.0));
			// ----- фасоны
			if (top_kind == 6 && !is_arm && z > 0.04) c = chip_logo(vec2(x, y - 1.245), c, top_col2, pw);
			if (top_kind == 5 || top_kind == 14) {
				// воротник и пуговицы
				if (!is_arm && z > 0.0) {
					float cl = band(y, nl, nl + 0.03, pw) * aa(0.09 - ax, pw);
					c = mix(c, top_col2 * 0.95, cl * (top_kind == 14 ? 1.0 : 0.6));
					float bx = band(x, -0.0016, 0.0016, pw);
					float by = 1.0 - smoothstep(0.0, 0.0035, abs(fract((y - 0.9) / 0.07) - 0.5) * 0.07);
					c = mix(c, vec3(0.95, 0.93, 0.88), aa(0.0032 - length(vec2(x - 0.004, (fract((y - 0.9) / 0.07) - 0.5) * 0.07)), pw) * step(y, nl - 0.004));
				}
			}
			if (top_kind == 4) {
				// худи: капюшон, шнурки, карман-кенгуру, резинки
				if (!is_arm) {
					float hood = aa(-0.02 - z, pw) * band(y, 1.30, 1.50, pw) * aa(0.115 - ax, pw);
					c = mix(c, c * 0.78, hood);
					c = mix(c, c * 0.6, hood * band(y, 1.30, 1.31, pw));
					if (z > 0.0) {
						float cord = band(ax, 0.02, 0.0235, pw) * band(y, 1.27, 1.41, pw);
						c = mix(c, top_col2, cord);
						c = mix(c, top_col2 * 0.5, band(ax, 0.019, 0.0245, pw) * band(y, 1.262, 1.275, pw));
						float pw2 = 0.125 - (y - 0.915) * 0.35;
						float pk = band(y, 0.915, 1.06, pw) * aa(pw2 - ax, pw);
						c = mix(c, c * 0.92, pk);
						c = mix(c, c * 0.62, pk * (1.0 - band(y, 0.92, 1.055, pw) * aa(pw2 - 0.004 - ax, pw)));
					}
					c = mix(c, c * 0.8 * (0.9 + 0.2 * step(0.5, fract(x * 300.0))), band(y, hem, 0.885, pw));
				} else {
					c = mix(c, c * 0.8 * (0.9 + 0.2 * step(0.5, fract(p.z * 300.0))), band(ax, 0.6, 0.64, pw));
				}
			}
			if (top_kind == 7 || top_kind == 8 || top_kind == 9 || top_kind == 11) {
				// рубашка + жилет/пиджак/китель
				vec3 shirt = shirt_col * (0.97 + 0.04 * vnoise(cu * 300.0));
				float vy0 = top_kind == 7 ? 1.2 : 1.17;
				float vw = 0.075 * clamp((y - vy0) / (1.43 - vy0), 0.0, 1.0);
				bool in_v = !is_arm && z > 0.0 && y > vy0 && ax < vw;
				vec3 jc = c;
				if (top_kind == 11) {
					jc = shirt_col;
					// двубортный китель: две колонки пуговиц, стойка-воротник
					float b1 = aa(0.0045 - length(vec2(ax - 0.052, (fract((y - 0.97) / 0.085) - 0.5) * 0.085)), pw) * band(y, 0.92, 1.36, pw) * step(0.0, z);
					jc = mix(jc, vec3(0.78, 0.77, 0.74), b1);
					jc = mix(jc, jc * 0.8, band(x, 0.074, 0.077, pw) * step(0.0, z) * band(y, 0.8, 1.41, pw));
					jc = mix(jc, jc * 0.85, band(y, 1.405, 1.41, pw));
					jc = mix(jc, jc * 0.6, band(ax, 0.0, 0.004, pw) * band(y, 1.41, 1.46, pw) * step(0.0, z));
					if (is_arm) jc = mix(jc, jc * 0.88, band(ax, 0.58, 0.64, pw));
					c = jc;
				} else if (in_v) {
					c = shirt;
					// пуговицы-запонки
					c = mix(c, vec3(0.1), aa(0.0022 - length(vec2(x, (fract((y - 1.2) / 0.05) - 0.5) * 0.05)), pw));
				} else {
					// лацканы
					if (top_kind != 7 && !is_arm && z > 0.0) {
						float lap = band(ax, vw, vw + 0.03 * clamp((y - 1.05) / 0.12, 0.0, 1.0), pw) * band(y, 1.05, 1.44, pw);
						jc = mix(jc, top_kind == 8 ? vec3(0.02) : jc * 0.85, lap);
						if (top_kind == 8) r3 = mix(r3, 0.2, lap);
						jc = mix(jc, jc * 0.55, band(ax, vw - 0.001, vw + 0.001, pw) * band(y, vy0, 1.44, pw));
						// полы пиджака расходятся ниже пуговицы
						float open_w = 0.13 * clamp((1.02 - y) / 0.23, 0.0, 1.0);
						if (y < 1.02 && ax < open_w) jc = y > 0.905 ? shirt : bot_col;
						jc = mix(jc, jc * 0.6, band(ax, open_w - 0.0012, open_w + 0.0006, pw) * step(y, 1.02) * step(0.0, open_w - 0.001));
						// пуговица
						jc = mix(jc, vec3(0.08), aa(0.005 - length(vec2(x, y - 1.035)), pw));
						if (top_kind == 9) jc = mix(jc, vec3(0.08), aa(0.005 - length(vec2(x, y - 0.95)), pw) * step(0.13 * clamp((1.02 - 0.95) / 0.23, 0.0, 1.0), 0.0));
						// карманы
						jc = mix(jc, jc * 0.6, band(y, 0.905, 0.909, pw) * band(ax, 0.1, 0.17, pw));
						if (top_kind == 9) {
							jc = mix(jc, jc * 0.6, band(y, 1.255, 1.258, pw) * band(x, 0.085, 0.135, pw));
							jc = mix(jc, shirt_col, band(y, 1.258, 1.272, pw) * band(x, 0.095, 0.12, pw));
						}
					}
					if (top_kind == 7) {
						// жилет: без рукавов, острые полы
						if (is_arm) jc = shirt;
						else {
							jc = mix(jc, jc * 0.6, band(ax, vw - 0.001, vw + 0.001, pw) * band(y, vy0, 1.44, pw) * step(0.0, z));
							for (int k = 0; k < 4; k++) {
								float by = 1.17 - float(k) * 0.075;
								jc = mix(jc, vec3(0.85, 0.75, 0.4), aa(0.0042 - length(vec2(x - 0.004, y - by)), pw) * step(0.0, z));
							}
							float tip = 0.855 - 0.03 * clamp(1.0 - ax / 0.12, 0.0, 1.0) * step(0.0, z);
							if (y < tip + 0.02) jc = y > 0.905 ? shirt : bot_col;
							if (ax > 0.17 && y > 1.2 && !is_torso) jc = shirt;
							r3 = 0.6;
						}
					}
					if (is_arm && top_kind != 7) {
						// манжета рубашки
						jc = mix(jc, shirt, band(ax, 0.625, 0.645, pw));
					}
					c = jc;
				}
			}
			if (top_kind == 10) {
				// горничная: белый воротник, фартук-нагрудник, бретели, манжеты
				vec3 wh = vec3(0.96, 0.95, 0.93);
				if (is_arm) c = mix(c, wh, band(ax, 0.27, 0.29, pw));
				else {
					float coll = band(y, 1.39, 1.43, pw) * step(0.0, z) * aa(0.075 - ax, pw);
					c = mix(c, wh, coll);
					float bib = band(y, 1.0, 1.245 + 0.004 * sin(x * 260.0), pw) * aa(0.078 - ax, pw) * step(0.02, z);
					c = mix(c, wh, bib);
					float strap = band(ax, 0.062, 0.078, pw) * aa(y - 1.24, pw) * step(-0.2, z);
					c = mix(c, wh, strap * (z > 0.0 ? 1.0 : 0.0));
					float strapb = band(abs(ax - 0.07 + (1.4 - y) * 0.25), 0.0, 0.009, pw) * band(y, 1.0, 1.42, pw) * step(z, 0.0);
					c = mix(c, wh, strapb);
					c = mix(c, wh, band(y, 0.985, 1.01, pw));
				}
			}
			if (top_kind == 12) {
				// фартук бармена
				float aw = mix(0.2, 0.105, smoothstep(1.02, 1.16, y));
				float ap = aa(aw - ax, pw) * band(y, 0.0, 1.30, pw) * step(0.005, z);
				vec3 apc = top_col2 * (0.95 + 0.06 * vnoise(cu * 250.0));
				c = mix(c, apc, ap);
				float neck_s = band(ax, 0.055, 0.07, pw) * aa(y - 1.29, pw);
				c = mix(c, apc, neck_s);
				c = mix(c, apc * 0.8, band(y, 1.0, 1.02, pw) * (1.0 - ap));
				if (is_arm) c = mix(c, c * 0.8, band(ax, 0.43, 0.47, pw));
				if (ap > 0.5) r3 = 0.7;
			}
			if (top_kind == 16 && !is_arm) {
				c = mix(c, c * 0.8, band(y, nl - 0.004, nl + 0.002, pw));
			}
			// галстук / бабочка
			if (!is_arm && z > 0.0) {
				if (tie_kind == 1) {
					vec2 d = vec2(x, y - 1.418);
					float wing = aa(0.034 - abs(d.x), pw) * aa(0.004 + abs(d.x) * 0.38 - abs(d.y), pw);
					c = mix(c, tie_col, wing);
					c = mix(c, tie_col * 0.7, aa(0.0055 - abs(d.x), pw) * aa(0.006 - abs(d.y), pw));
				} else if (tie_kind == 2) {
					float tw = mix(0.011, 0.024, clamp((1.40 - y) / 0.25, 0.0, 1.0));
					float tip = 1.13 + ax * 0.9;
					float tie = aa(tw - ax, pw) * band(y, tip, 1.43, pw);
					vec3 tc = tie_col * (0.9 + 0.2 * step(0.5, fract((x + y) * 45.0)));
					c = mix(c, tc, tie);
					c = mix(c, tie_col * 0.6, aa(0.012 - ax, pw) * band(y, 1.405, 1.43, pw));
					r3 = mix(r3, 0.4, tie);
				}
			}
			col = mix(col, c, cov);
			rough = mix(rough, r3, cov);
			spec = mix(spec, 0.3, cov);
		}
	}
	// ---------- AO (складки) — мягче на худом теле
	float ao_k = mix(0.65, 0.35, slim);
	col *= mix(1.0, ao, ao_k);
	// тёплый «подповерхностный» оттенок в складках кожи
	col = mix(col * vec3(1.0, 0.86, 0.8), col, mix(1.0, ao, 0.5));
}

void face_paint(vec3 p, float pw, inout vec3 col, inout float rough, inout float spec) {
	float x = p.x;
	float ax = abs(x);
	float y = p.y;
	float z = p.z;
	vec3 skin = col;
	vec3 hc = hair_col;
	// --- волосы на коже головы (под мешем причёски) и щетина/борода
	vec3 d = p - vec3(0.0, 1.585, -0.005);
	float ph = atan(d.x, d.z);
	if (scalp > 0) {
		float hl = hairline_y(ph, scalp);
		float hm = aa(y - hl + 0.006, pw);
		col = mix(col, hc * (0.8 + 0.25 * vnoise(vec2(ph * 40.0, y * 90.0))), hm);
		rough = mix(rough, 0.55, hm);
	} else if (male > 0.5) {
		float hl = hairline_y(ph, 1);
		col = mix(col, mix(col, hc, 0.12), aa(y - hl, pw));
	}
	float front = smoothstep(0.035, 0.07, z);
	if (front <= 0.0 && beard == 0) return;
	vec2 q = vec2(x, y);
	// --- борода / усы / щетина
	if (beard > 0) {
		float mu = x / 0.03;
		float must = aa(1.0 - abs(mu), pw * 40.0) * band(y, 1.5185 + 0.002 * mu * mu, 1.531 - 0.004 * mu * mu, pw) * front;
		float bd = 0.0;
		if (beard >= 2) {
			float top = 1.556 - 0.55 * max(0.0, 0.078 - ax);
			bd = aa(top - y, pw) * aa(y - 1.43, pw) * smoothstep(-0.035, -0.005, z);
			// не на губах
			bd *= 1.0 - aa(0.026 - ax, pw) * band(y, 1.502, 1.519, pw);
		}
		float n = vnoise(q * 900.0);
		if (beard == 1) col = mix(col, hc * (0.75 + 0.4 * n), must);
		if (beard == 2) {
			col = mix(col, hc * (0.75 + 0.4 * n), max(bd, must) * 0.97);
			rough = mix(rough, 0.8, bd);
		}
		if (beard == 3) col = mix(col, mix(col, hc * 0.6, 0.45), max(bd, must * 0.0) * step(0.45, n) * 0.6 + bd * 0.12);
	}
	if (front <= 0.0) return;
	// --- румянец
	for (int k = 0; k < 2; k++) {
		float sx = k == 0 ? -1.0 : 1.0;
		float bl = exp(-dot(q - vec2(0.047 * sx, 1.553), q - vec2(0.047 * sx, 1.553)) / (0.017 * 0.017));
		col = mix(col, vec3(0.92, 0.42, 0.42), bl * (0.12 + 0.25 * blush + 0.1 * makeup) * front);
	}
	// --- ноздри
	for (int k = 0; k < 2; k++) {
		float sx = k == 0 ? -1.0 : 1.0;
		vec2 nd = (q - vec2(0.0088 * sx, 1.5435)) / vec2(0.0033, 0.0019);
		col = mix(col, col * vec3(0.62, 0.52, 0.52), aa(1.0 - length(nd), pw / 0.0025) * 0.6 * front);
	}
	// --- глаза
	for (int k = 0; k < 2; k++) {
		float sx = k == 0 ? -1.0 : 1.0;
		float op = k == 0 ? eye_r : eye_l;
		vec2 c = vec2(0.031 * sx, 1.592);
		float u = (x - c.x) / 0.0158 * sx;   // −1 — внутренний угол, +1 — внешний
		float w = max(1.0 - u * u, 0.0);
		float tilt = 0.0018 * u;
		float yu = c.y + tilt + (0.0088 * op - 0.0012) * pow(w, 0.7);
		float yl = c.y + tilt - 0.0052 * pow(w, 0.85);
		float inside = aa(1.0 - abs(u), pw / 0.0158) * aa(yu - y, pw) * aa(y - yl, pw);
		// веко и тень глазницы
		float lid = exp(-pow((y - (yu + 0.0045)) / 0.004, 2.0)) * aa(1.15 - abs(u), pw / 0.0158);
		col = mix(col, col * vec3(0.86, 0.8, 0.8), lid * 0.5 * front);
		if (makeup > 0.0) col = mix(col, mix(col, vec3(0.45, 0.32, 0.5), 0.5), lid * makeup * 0.7 * front);
		if (happy_eyes > 0.5) {
			// закрытые улыбающиеся глаза ^^
			float arc = c.y - 0.002 + 0.0055 * w;
			col = mix(col, vec3(0.12, 0.07, 0.06), aa(1.0 - abs(u), pw / 0.0158) * aa(0.0012 - abs(y - arc), pw) * front);
			continue;
		}
		if (inside > 0.0) {
			vec3 e = vec3(0.95, 0.93, 0.9);
			e = mix(e, vec3(0.85, 0.7, 0.68), 0.6 * smoothstep(0.6, 1.0, abs(u)));
			vec2 ic = c + vec2(gaze.x * 0.0045 * sx * sx, gaze.y * 0.003);
			float ri = 0.0066;
			float r = length(q - ic);
			vec3 iris = eye_col * (0.75 + 0.35 * vnoise(vec2(atan(q.y - ic.y, q.x - ic.x) * 6.0, r * 900.0)));
			iris = mix(iris, eye_col * 0.4, smoothstep(ri * 0.7, ri, r));
			e = mix(e, iris, aa(ri - r, pw));
			e = mix(e, vec3(0.02), aa(0.0027 - r, pw));
			// блик
			e = mix(e, vec3(1.0), aa(0.0012 - length(q - ic - vec2(-0.0021, 0.0023)), pw));
			// тень верхнего века на глазном яблоке
			e *= 1.0 - 0.35 * smoothstep(-0.004, 0.0, y - yu);
			col = mix(col, e, inside * front);
			rough = mix(rough, 0.12, inside);
			spec = mix(spec, 0.7, inside);
		}
		// ресницы / линия века
		float lt = 0.0011 + 0.0011 * makeup + 0.0006 * (1.0 - male);
		float lash = aa(1.04 - abs(u), pw / 0.0158) * aa(lt - abs(y - yu - lt * 0.4), pw);
		if (makeup > 0.0 && u > 0.7) {
			// «стрелка»
			float wy = yu + (u - 0.7) * 0.004;
			lash = max(lash, aa(1.22 - u, pw / 0.0158) * aa(0.0011 - abs(y - wy), pw) * makeup);
		}
		col = mix(col, vec3(0.08, 0.05, 0.04), lash * front);
		col = mix(col, col * 0.7, aa(1.0 - abs(u), pw / 0.0158) * aa(0.0005 - abs(y - yl), pw) * 0.6 * front * step(0.25, op));
		// --- брови
		vec2 bc = vec2(0.034 * sx, 1.6125 + brow_up * 0.004);
		float ub = (x - bc.x) / 0.0195 * sx;
		float yb = bc.y + 0.0028 * (1.0 - ub * ub) - brow_angry * 0.0045 * (1.0 - ub) * 0.5 + brow_sad * 0.0045 * (1.0 - ub) * 0.5;
		float th = (0.0019 + 0.0013 * male) * (1.0 - 0.4 * max(ub, 0.0)) * (1.0 + 0.3 * max(-ub, 0.0));
		float brow = aa(1.0 - abs(ub), pw / 0.0195) * aa(th - abs(y - yb), pw);
		col = mix(col, mix(hc, vec3(0.08, 0.05, 0.03), 0.35) * (0.8 + 0.3 * vnoise(q * 1200.0)), brow * 0.92 * front);
		// --- слёзы
		if (tears > 0.0) {
			float tx = c.x + sx * (0.006 + 0.0015 * sin(y * 500.0));
			float tr = aa(0.0017 - abs(x - tx), pw) * band(y, 1.49 + (1.0 - tears) * 0.08, 1.586, pw);
			col = mix(col, vec3(0.7, 0.85, 1.0), tr * 0.65 * front);
			rough = mix(rough, 0.05, tr);
			spec = mix(spec, 1.0, tr);
		}
	}
	// --- рот
	float mw = 0.0215 * (1.0 + 0.18 * mouth_open + 0.12 * max(mouth_curve, 0.0));
	float mu = x / mw;
	float wm = max(1.0 - mu * mu, 0.0);
	float yc = 1.513 + mouth_curve * 0.0058 * mu * mu - mouth_curve * 0.0014;
	float g = mouth_open * 0.0095 * sqrt(wm);
	float upl = 0.0040 * sqrt(wm) * (1.0 - 0.28 * exp(-pow(mu * 7.0, 2.0)));
	float lol = 0.0052 * sqrt(wm);
	float inm = aa(1.0 - abs(mu), pw / mw);
	float up_l = inm * band(y, yc + g * 0.5, yc + g * 0.5 + upl, pw);
	float lo_l = inm * band(y, yc - g * 0.5 - lol, yc - g * 0.5, pw);
	vec3 lc = mix(lip_col, vec3(0.72, 0.08, 0.17), makeup * 0.9);
	col = mix(col, lc * 0.92, up_l * front);
	col = mix(col, lc * (1.0 + 0.08 * smoothstep(0.0, lol, (yc - g * 0.5) - y)), lo_l * front);
	rough = mix(rough, 0.35 - 0.15 * makeup, max(up_l, lo_l));
	// блик на нижней губе
	col = mix(col, col + 0.12, inm * aa(0.0009 - abs(y - (yc - g * 0.5 - lol * 0.45)), pw) * aa(0.4 - abs(mu), pw / mw) * front);
	float gap = inm * band(y, yc - g * 0.5, yc + g * 0.5, pw);
	if (g > 0.0002) {
		vec3 mi = vec3(0.28, 0.07, 0.07);
		mi = mix(mi, vec3(0.75, 0.3, 0.32), smoothstep(0.0, g, (yc - g * 0.5 + g * 0.35) - y) * 0.5);
		float th = teeth > 0.0 ? 1.0 : 0.0;
		float tt = band(y, yc + g * 0.5 - mix(0.0032, g * 0.9, teeth), yc + g * 0.5, pw) * th;
		mi = mix(mi, vec3(0.96, 0.95, 0.9), tt);
		col = mix(col, mi, gap * front);
	}
	// линия смыкания губ
	col = mix(col, lc * 0.35, inm * aa(0.0007 - abs(y - yc), pw) * front * (1.0 - step(0.0004, g)));
	// уголки рта
	for (int k = 0; k < 2; k++) {
		float sx = k == 0 ? -1.0 : 1.0;
		vec2 cc = vec2(mw * sx * 1.02, yc + mouth_curve * 0.0044);
		col = mix(col, col * 0.75, aa(0.0013 - length(q - cc), pw) * front * 0.7);
	}
}

void hair_paint(vec3 p, out vec3 col, out float rough, out float spec) {
	vec3 d = p - vec3(0.0, 1.585, -0.005);
	float ph = atan(d.x, d.z);
	float th = acos(clamp(d.y / max(length(d), 1e-4), -1.0, 1.0));
	float strand;
	if (p.y < 1.5 && length(d.xz) > 0.07) strand = vnoise(vec2(ph * 70.0, p.y * 8.0)) * 0.6 + vnoise(vec2(ph * 190.0, p.y * 20.0)) * 0.4;
	else strand = vnoise(vec2(ph * 60.0 * sin(th + 0.3), th * 9.0)) * 0.6 + vnoise(vec2(ph * 170.0 * sin(th + 0.3), th * 22.0)) * 0.4;
	col = hair_col * (0.62 + 0.55 * strand);
	rough = 0.42;
	spec = 0.45;
}
