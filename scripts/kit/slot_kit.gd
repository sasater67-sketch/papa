extends RefCounted
# SlotKit — детализированные игровые автоматы на MeshKit: кабинеты со скруглёнными гранями, вращающиеся
# барабаны (шейдер с инерцией, отскоком и смазом), видеоэкраны покера, арки-топперы с артом, бегущие
# огни, кнопки на наклонной панели, рычаг, лоток с монетами, купюроприёмник, табуреты-«токарки».
# Банк автоматов (вся ячейка) собирается в один кэшированный ArrayMesh.

const MK := preload("res://scripts/kit/mesh_kit.gd")
const KL := preload("res://scripts/kit/kit_lib.gd")

static var _m := {}

const STYLE := {
	"fruit": {"body": Color("b01c28"), "seat": Color("8a1a2a"), "strip": "fruit", "art": "fruit", "b0": Color(1.0, 0.82, 0.3), "b1": Color(1.0, 0.3, 0.2)},
	"classic": {"body": Color("c8601a"), "seat": Color("2a2a6a"), "strip": "classic", "art": "classic", "b0": Color(1.0, 1.0, 0.92), "b1": Color(0.3, 0.5, 1.0)},
	"vpoker": {"body": Color("17388f"), "seat": Color("1a2a6a"), "strip": "cards", "art": "vpoker", "screen": true, "b0": Color(0.45, 0.75, 1.0), "b1": Color(1, 1, 1)},
	"gold": {"body": Color("b8861e"), "metal": 0.75, "seat": Color("5a3a0a"), "strip": "gold", "art": "gold", "b0": Color(1.0, 0.8, 0.32), "b1": Color(1.0, 0.95, 0.75)},
	"mega": {"body": Color("4a1a7a"), "seat": Color("c89a2a"), "strip": "mega", "art": "mega", "b0": Color(1.0, 0.85, 0.3), "b1": Color(0.8, 0.45, 1.0)},
	"diamond": {"body": Color("1a5a7a"), "metal": 0.5, "seat": Color("2a6a8a"), "strip": "diamond", "art": "diamond", "b0": Color(0.55, 0.92, 1.0), "b1": Color(1, 1, 1)},
}

const REEL_SH := """
shader_type spatial;
uniform sampler2D strip : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float nsym = 10.0;
uniform float glow = 0.6;
varying flat float v_reel;
varying flat float v_seed;
varying flat float v_nr;
float h1(float n) { return fract(sin(n * 12.9898 + 0.731) * 43758.5453); }
float stop_sym(float cyc, float reel, float seed) {
	float win = step(h1(seed * 3.7 + cyc * 1.31), 0.17);
	float base = floor(h1(seed + cyc * 7.17) * nsym);
	float own = floor(h1(seed + cyc * 7.17 + reel * 3.3 + 0.5) * nsym);
	return mix(own, base, win);
}
void vertex() {
	v_reel = floor(COLOR.r * 8.0 + 0.5);
	v_nr = floor(COLOR.b * 8.0 + 0.5);
	vec3 o = MODEL_MATRIX[3].xyz;
	v_seed = COLOR.g * 17.0 + o.x * 0.37 + o.z * 1.13 + o.y * 0.11;
}
void fragment() {
	float reel = v_reel;
	float period = 7.0 + h1(v_seed) * 6.0;
	float tt = TIME + h1(v_seed + 0.77) * 50.0;
	float cyc = floor(tt / period);
	float ph = tt - cyc * period;
	float ts = 1.25 + reel * 0.42;
	float s0 = stop_sym(cyc - 1.0, reel, v_seed);
	float s1 = stop_sym(cyc, reel, v_seed);
	float dist = (2.0 + reel) * nsym + mod(s1 - s0 + nsym, nsym);
	float x = clamp(ph / ts, 0.0, 1.0);
	float e = 1.0 - pow(1.0 - x, 2.6);
	float pos = s0 + dist * e;
	float bt = ph - ts;
	pos -= 0.14 * sin(clamp(bt / 0.24, 0.0, 1.0) * PI) * step(0.0, bt);
	float speed = dist * 2.6 * pow(1.0 - x, 1.6) / ts * step(ph, ts);
	float v = UV.y - (pos + 0.5) / nsym;
	float blur = clamp(speed * 0.0035, 0.0, 0.08);
	vec3 c = vec3(0.0);
	for (int i = 0; i < 6; i++) {
		c += texture(strip, vec2(UV.x, v + blur * (float(i) / 5.0 - 0.5))).rgb;
	}
	c /= 6.0;
	float win = step(h1(v_seed * 3.7 + cyc * 1.31), 0.17);
	float last = 1.25 + (v_nr - 1.0) * 0.42;
	float flash = win * step(last + 0.3, ph) * step(ph, last + 2.6) * (0.5 + 0.5 * sin(TIME * 16.0));
	float shade = pow(max(cos(UV.y * 6.2831853), 0.0), 1.5);
	ALBEDO = c * 0.75;
	ROUGHNESS = 0.4;
	SPECULAR = 0.3;
	EMISSION = c * (glow * shade + flash * 1.4) + vec3(1.0, 0.8, 0.3) * flash * 0.25;
}
"""

const GLOW_SH := """
shader_type spatial;
uniform float energy = 3.2;
uniform float speed = 1.0;
void fragment() {
	vec3 c = COLOR.rgb;
	float a = COLOR.a;
	float k = 1.0;
	if (a < 0.985) {
		if (a < 0.5) {
			float f = fract(a * 2.0 * 3.0 - TIME * speed * 0.9);
			k = 0.12 + 0.88 * smoothstep(0.45, 0.0, abs(f - 0.5) - 0.05);
		} else {
			float ph = (a - 0.5) * 2.0;
			k = 0.25 + 0.75 * step(0.5, fract(TIME * speed * 0.7 + ph));
		}
	}
	ALBEDO = c * 0.2;
	ROUGHNESS = 0.25;
	EMISSION = c * energy * k;
}
"""

const SCREEN_SH := """
shader_type spatial;
uniform sampler2D cards : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
varying flat float v_seed;
float h1(float n) { return fract(sin(n * 12.9898 + 0.731) * 43758.5453); }
void vertex() {
	vec3 o = MODEL_MATRIX[3].xyz;
	v_seed = COLOR.g * 17.0 + o.x * 0.37 + o.z * 1.13;
}
void fragment() {
	vec2 uv = UV;
	vec3 c = mix(vec3(0.03, 0.08, 0.32), vec3(0.01, 0.03, 0.14), uv.y);
	float period = 6.0 + h1(v_seed) * 4.0;
	float tt = TIME + h1(v_seed + 0.3) * 40.0;
	float cyc = floor(tt / period);
	float ph = tt - cyc * period;
	// таблица выплат: строки «текста»
	if (uv.y > 0.05 && uv.y < 0.27 && uv.x > 0.06 && uv.x < 0.94) {
		float row = floor((uv.y - 0.05) / 0.044);
		float ry = fract((uv.y - 0.05) / 0.044);
		float cell = floor(uv.x * 46.0);
		float on = step(0.25, ry) * step(ry, 0.75) * step(0.3, h1(cell * 1.7 + row * 9.1)) * step(0.5, fract(uv.x * 46.0) + 0.3);
		float right = step(0.62, uv.x);
		vec3 tc = mix(vec3(1.0, 0.85, 0.2), vec3(1.0), right);
		float hl = step(abs(row - mod(cyc, 5.0)), 0.1) * step(1.2, ph);
		c = mix(c, tc * (1.0 + hl), on * 0.9);
		c += vec3(0.5, 0.1, 0.0) * hl * 0.3;
	}
	float col = floor((uv.x - 0.06) / 0.18);
	float lx = (uv.x - 0.06 - col * 0.18) / 0.16;
	if (col >= 0.0 && col < 5.0 && lx <= 1.0) {
		float ly = (uv.y - 0.33) / 0.42;
		float held = step(h1(v_seed + cyc * 2.1 + col), 0.4);
		float ft = clamp((ph - 0.3 - col * 0.12) / 0.28, 0.0, 1.0) * (1.0 - held);
		float sx = abs(cos(ft * PI));
		float shown = cyc - 1.0 + step(0.5, ft) + held;
		float idx = floor(h1(v_seed + shown * 5.31 + col * 1.7) * 10.0);
		float cx = (lx - 0.5) / max(sx, 0.02) + 0.5;
		if (ly >= 0.0 && ly <= 1.0 && cx >= 0.0 && cx <= 1.0) {
			vec4 t = texture(cards, vec2(0.168 + cx * 0.664, (idx + 0.04 + ly * 0.92) / 10.0));
			c = mix(c, t.rgb, 1.0);
		}
		if (uv.y > 0.79 && uv.y < 0.85 && lx > 0.1 && lx < 0.9) {
			c = mix(c, vec3(1.0, 0.9, 0.2) * 1.4, held * step(1.0, ph));
		}
	}
	if (uv.y > 0.89 && uv.y < 0.95 && uv.x > 0.08 && uv.x < 0.92) {
		float seg = step(0.35, fract(uv.x * 30.0)) * step(0.4, h1(floor(uv.x * 30.0) + floor(cyc)));
		c = mix(c, vec3(1.0, 0.15, 0.1) * 1.3, seg);
	}
	ALBEDO = c * 0.2;
	ROUGHNESS = 0.15;
	SPECULAR = 0.6;
	EMISSION = c * 1.15;
}
"""


# ------------------------------------------------------------------ материалы

static func _shader(key: String, code: String) -> Shader:
	if _m.has(key):
		return _m[key]
	var s := Shader.new()
	s.code = code
	_m[key] = s
	return s


static func _tex(name: String) -> Texture2D:
	var p := "res://assets/hd/%s.png" % name
	if ResourceLoader.exists(p):
		return load(p)
	return null


static func m_reel(strip: String) -> Material:
	var key := "reel_" + strip
	if _m.has(key):
		return _m[key]
	var m := ShaderMaterial.new()
	m.shader = _shader("reel_sh", REEL_SH)
	m.set_shader_parameter("strip", _tex("slot_strip_" + strip))
	_m[key] = m
	return m


static func m_glow() -> Material:
	if _m.has("glow"):
		return _m["glow"]
	var m := ShaderMaterial.new()
	m.shader = _shader("glow_sh", GLOW_SH)
	_m["glow"] = m
	return m


static func m_screen() -> Material:
	if _m.has("screen"):
		return _m["screen"]
	var m := ShaderMaterial.new()
	m.shader = _shader("screen_sh", SCREEN_SH)
	m.set_shader_parameter("cards", _tex("slot_strip_cards"))
	_m["screen"] = m
	return m


static func m_art(art: String) -> Material:
	var key := "art_" + art
	if _m.has(key):
		return _m[key]
	var m := StandardMaterial3D.new()
	var t := _tex("slot_art_" + art)
	m.albedo_texture = t
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	m.emission_enabled = true
	m.emission_texture = t
	m.emission = Color.WHITE
	m.emission_operator = BaseMaterial3D.EMISSION_OP_MULTIPLY
	m.emission_energy_multiplier = 0.85
	m.roughness = 0.22
	m.metallic_specular = 0.7
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	m.alpha_scissor_threshold = 0.5
	if t == null:
		m.albedo_color = Color(0.9, 0.3, 0.3)
	_m[key] = m
	return m


static func m_glass() -> Material:
	if _m.has("glass"):
		return _m["glass"]
	var m := StandardMaterial3D.new()
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(0.75, 0.85, 1.0, 0.1)
	m.roughness = 0.03
	m.metallic_specular = 1.0
	m.cull_mode = BaseMaterial3D.CULL_BACK
	_m["glass"] = m
	return m


static func m_body(st: Dictionary) -> Material:
	return Assets.pbr(st.body, 0.26, float(st.get("metal", 0.3)), {"clearcoat": 0.9})


static func m_gloss_black() -> Material:
	return Assets.pbr(Color(0.025, 0.025, 0.03), 0.16, 0.2, {"clearcoat": 1.0})


static func m_seat(c: Color) -> Material:
	return Assets.kit_mat("leather", {"tint": c.lightened(0.15), "uv": Vector2(2, 2)})


# ------------------------------------------------------------------ банк автоматов
# units: [[x, big(bool)], ...]; z — центр корпуса по глубине; табурет — на z + 0.75

static func bank(model: Node3D, lb, style: String, units: Array, z: float) -> void:
	var key := "slotbank_%s_%s_%.2f" % [style, str(units), z]
	var mesh := KL.cached(key, func(k): _build_bank(k, style, units, z))
	var mi := KL.inst(model, mesh, Transform3D.IDENTITY, true)
	mi.name = "SlotBank"
	for u: Array in units:
		var x := float(u[0])
		var big := bool(u[1])
		var W := 1.5 if big else 0.8
		var H := 2.95 if big else 2.1
		lb.add_collider(Vector3(x, H * 0.5, z - 0.01), Vector3(W, H, 0.66))
		lb.add_cyl_collider(Vector3(x, 0.37, z + 0.75), 0.2, 0.74)


static func _build_bank(k, style: String, units: Array, z: float) -> void:
	var st: Dictionary = STYLE[style]
	for i in units.size():
		var u: Array = units[i]
		var big := bool(u[1])
		var o := {"W": 0.78, "yd": 0.84, "yu0": 0.97, "yu1": 1.62, "rr": 0.12, "ry": 1.27, "nr": 3, "th": 0.36}
		if big:
			o = {"W": 1.46, "yd": 0.84, "yu0": 0.97, "yu1": 2.3, "rr": 0.19, "ry": 1.42, "nr": 5, "th": 0.6, "big": true}
		_machine(k, st, Vector3(float(u[0]), 0, z), i, o)
		_stool(k, Vector3(float(u[0]), 0, z + 0.75), st.seat)


static func _T(p: Vector3) -> Transform3D:
	return Transform3D(Basis(), p)


static func _machine(k, st: Dictionary, base: Vector3, mi: int, o: Dictionary) -> void:
	var W: float = o.W
	var hw := W * 0.5
	var yd: float = o.yd
	var yu0: float = o.yu0
	var yu1: float = o.yu1
	var rr: float = o.rr
	var ry: float = o.ry
	var nr: int = o.nr
	var th: float = o.th
	var big: bool = o.get("big", false)
	var zb := -0.31
	var zf := 0.27
	var zu := 0.22
	var body := m_body(st)
	var dark := KL.m_dark()
	var gloss := m_gloss_black()
	var chrome := KL.m_chrome()
	var glow := m_glow()
	var art := m_art(str(st.art))
	var b0: Color = st.b0
	var b1: Color = st.b1
	var is_screen: bool = st.get("screen", false)
	# --- цоколь
	k.box(dark, _T(base + Vector3(0, 0.05, -0.01)), Vector3(W + 0.03, 0.1, 0.64), 0.015)
	k.box(chrome, _T(base + Vector3(0, 0.094, 0.312)), Vector3(W + 0.03, 0.014, 0.012), 0.005)
	# --- нижний корпус
	k.box(body, _T(base + Vector3(0, (0.1 + yd) * 0.5, (zb + zf) * 0.5)), Vector3(W, yd - 0.1, zf - zb), 0.03)
	for sx: float in [-1.0, 1.0]:
		k.box(gloss, _T(base + Vector3(sx * (hw + 0.002), (0.2 + yd) * 0.5, -0.03)), Vector3(0.008, yd - 0.26, 0.44), 0.003)
		k.box(gloss, _T(base + Vector3(sx * (hw + 0.002), (yu0 + yu1) * 0.5, -0.06)), Vector3(0.008, yu1 - yu0 - 0.14, 0.36), 0.003)
	# --- панель с артом (belly glass) в хромированной рамке
	var bw := W - 0.22
	var bh := minf(0.4, (yd - 0.3) * 0.75)
	var bc := base + Vector3(-0.04 if not big else 0.0, 0.3 + bh * 0.5 + 0.06, zf + 0.004)
	k.panel(art, _T(bc), bw, bh, Color.WHITE, Rect2(0, 0.5, 1, 0.5))
	var fr := 0.022
	k.box(chrome, _T(bc + Vector3(0, bh * 0.5 + fr * 0.5, 0.003)), Vector3(bw + fr * 2.0, fr, 0.014), 0.006)
	k.box(chrome, _T(bc + Vector3(0, -bh * 0.5 - fr * 0.5, 0.003)), Vector3(bw + fr * 2.0, fr, 0.014), 0.006)
	k.box(chrome, _T(bc + Vector3(-bw * 0.5 - fr * 0.5, 0, 0.003)), Vector3(fr, bh, 0.014), 0.006)
	k.box(chrome, _T(bc + Vector3(bw * 0.5 + fr * 0.5, 0, 0.003)), Vector3(fr, bh, 0.014), 0.006)
	# --- купюроприёмник
	if not big:
		var ba := base + Vector3(hw - 0.075, bc.y - base.y + 0.06, zf + 0.022)
		k.box(gloss, _T(ba), Vector3(0.085, 0.15, 0.045), 0.01)
		k.box(glow, _T(ba + Vector3(0, 0.035, 0.024)), Vector3(0.056, 0.008, 0.004), 0.0, {"col": Color(0.2, 1.0, 0.4, 0.75)})
		k.box(chrome, _T(ba + Vector3(0, -0.035, 0.024)), Vector3(0.06, 0.02, 0.006), 0.003)
	# --- лоток для монет
	var tw := minf(0.46, W - 0.2)
	k.box_mm(chrome, base + Vector3(-tw * 0.5, 0.14, zf - 0.01), base + Vector3(tw * 0.5, 0.24, zf + 0.1), 0.012)
	k.box(gloss, _T(base + Vector3(0, 0.241, zf + 0.045)), Vector3(tw - 0.04, 0.004, 0.08), 0.0)
	var cg := KL.m_gold()
	for c in 4:
		var cx := -tw * 0.3 + float(c) * tw * 0.19
		k.cyl(cg, MK.TR(base + Vector3(cx, 0.248, zf + 0.04 + float(c % 2) * 0.02), Vector3(0.25 * float(c % 3 - 1), float(c), 0.0)), 0.022, 0.006, 14, {"bevel": 0.002})
	# --- наклонная кнопочная панель
	var dz0 := zf - 0.02
	var dz1 := zf + 0.17
	var dk := Transform3D(Basis(Vector3(0, 0, 1), Vector3(1, 0, 0), Vector3(0, 1, 0)), base)
	k.extrude(gloss, dk, PackedVector2Array([Vector2(dz0, yd), Vector2(dz1, yd), Vector2(dz1, yd + 0.045), Vector2(dz0, yd + 0.13)]), -hw - 0.005, hw + 0.005, {"bottom": true})
	k.tube(chrome, base + Vector3(-hw - 0.005, yd + 0.045, dz1), base + Vector3(hw + 0.005, yd + 0.045, dz1), 0.009, 8)
	k.tube(chrome, base + Vector3(-hw - 0.005, yd + 0.003, dz1), base + Vector3(hw + 0.005, yd + 0.003, dz1), 0.006, 8)
	var ang := atan2(dz1 - dz0, 0.085)
	var nb := 6 if not big else 8
	var bcols := [Color(1, 0.85, 0.2), Color(1, 1, 1), Color(0.3, 1, 0.4), Color(0.3, 0.6, 1), Color(1, 1, 1), Color(1, 0.55, 0.15), Color(1, 1, 1), Color(0.3, 1, 0.4)]
	for bi in nb:
		var bx := -hw + 0.09 + float(bi) * (W - 0.18) / float(nb - 1)
		var s := 0.42
		var bp := base + Vector3(bx, yd + 0.045 + 0.085 * s, dz1 - (dz1 - dz0) * s)
		var bxf := Transform3D(Basis(Vector3.RIGHT, ang), bp)
		var last := bi == nb - 1
		var r := 0.042 if last else 0.026
		k.cyl(chrome, bxf * _T(Vector3(0, 0.005, 0)), r + 0.006, 0.01, 16, {"bevel": 0.003})
		var bcol: Color = bcols[bi]
		var bc2: Color = Color(1.0, 0.15, 0.1, 0.8) if last else Color(bcol.r, bcol.g, bcol.b, 1.0)
		k.cyl(glow, bxf * _T(Vector3(0, 0.016, 0)), r, 0.016, 16, {"bevel": 0.005, "col": bc2})
	# --- верхний корпус
	k.box(body, _T(base + Vector3(0, (yu0 + yu1) * 0.5, (zb + zu) * 0.5)), Vector3(W, yu1 - yu0, zu - zb), 0.03)
	k.box(chrome, _T(base + Vector3(0, yu0 + 0.004, zu - 0.01)), Vector3(W + 0.004, 0.012, 0.03), 0.004)
	# --- окно барабанов / экран
	var ww := W - 0.16
	var wtop := ry + rr + 0.05
	var wbot := ry - rr - 0.05
	var zh := 0.3
	k.box_mm(gloss, base + Vector3(-hw + 0.04, wbot, zu - 0.05), base + Vector3(hw - 0.04, wtop, zh), 0.014, {"skip": ["pz"]})
	var hy := rr * 0.84
	if is_screen:
		var sw := W - 0.14
		var sh := (wtop - wbot) - 0.03
		k.box_mm(gloss, base + Vector3(-hw + 0.04, wbot, zh - 0.02), base + Vector3(hw - 0.04, wtop, zh), 0.01)
		k.panel(m_screen(), _T(base + Vector3(0, ry, zh + 0.002)), sw - 0.04, sh - 0.03, Color(0, float(mi) / 8.0, 0, 1))
		k.box(chrome, _T(base + Vector3(0, wtop + 0.006, zh - 0.005)), Vector3(sw + 0.01, 0.012, 0.02), 0.005)
		k.box(chrome, _T(base + Vector3(0, wbot - 0.006, zh - 0.005)), Vector3(sw + 0.01, 0.012, 0.02), 0.005)
	else:
		k.panel(dark, _T(base + Vector3(0, ry, zu + 0.004)), ww, wtop - wbot)
		var rw := ww / float(nr)
		var reel_m := m_reel(str(st.strip))
		var cz := zh - 0.012 - rr
		for r in nr:
			var rx := -ww * 0.5 + rw * (float(r) + 0.5)
			_reel(k, reel_m, base + Vector3(rx, ry, cz), rr, rw - 0.016, r, mi, nr)
			if r > 0:
				k.box(dark, _T(base + Vector3(-ww * 0.5 + rw * float(r), ry, cz + rr * 0.5)), Vector3(0.014, rr * 2.2, rr * 1.1), 0.004)
		# хромированный безель
		var bt := (wtop - wbot) * 0.5 - hy
		k.box(chrome, _T(base + Vector3(0, wtop - bt * 0.5, zh + 0.008)), Vector3(W - 0.08, bt, 0.018), 0.007)
		k.box(chrome, _T(base + Vector3(0, wbot + bt * 0.5, zh + 0.008)), Vector3(W - 0.08, bt, 0.018), 0.007)
		k.box(chrome, _T(base + Vector3(-hw + 0.06, ry, zh + 0.008)), Vector3(0.04, hy * 2.0, 0.018), 0.007)
		k.box(chrome, _T(base + Vector3(hw - 0.06, ry, zh + 0.008)), Vector3(0.04, hy * 2.0, 0.018), 0.007)
		# линия выплаты и стрелки
		k.box(glow, _T(base + Vector3(0, ry, zh - 0.006)), Vector3(ww - 0.02, 0.005, 0.002), 0.0, {"col": Color(1.0, 0.1, 0.1, 1.0)})
		for sx: float in [-1.0, 1.0]:
			k.extrude(glow, Transform3D(Basis(Vector3(1, 0, 0), Vector3(0, 0, -1), Vector3(0, 1, 0)), base + Vector3(sx * (hw - 0.06), ry, zh + 0.017)),
				PackedVector2Array([Vector2(-0.016 * sx, -0.018), Vector2(0.012 * sx, 0.0), Vector2(-0.016 * sx, 0.018)]), -0.003, 0.003, {"bottom": true, "col": Color(1, 0.2, 0.1, 0.8)})
		k.panel(m_glass(), _T(base + Vector3(0, ry, zh + 0.02)), W - 0.08, wtop - wbot)
	# --- LED-табло кредитов
	var ly := wtop + 0.06
	if ly + 0.04 < yu1 - 0.02:
		k.box(gloss, _T(base + Vector3(0, ly, zu + 0.012)), Vector3(W - 0.24, 0.07, 0.024), 0.008)
		var nd := 8 if not big else 12
		for d in nd:
			var dx := -(W - 0.32) * 0.5 + (W - 0.32) * (float(d) + 0.5) / float(nd)
			k.box(glow, _T(base + Vector3(dx, ly, zu + 0.025)), Vector3((W - 0.32) / float(nd) * 0.7, 0.04, 0.003), 0.0, {"col": Color(1.0, 0.18, 0.08, 0.5 + 0.49 * float((d * 7) % nd) / float(nd))})
	if big:
		# большое табло джекпота над барабанами
		var jy := (ly + 0.05 + yu1 - 0.04) * 0.5
		var jh := (yu1 - 0.04) - (ly + 0.06)
		k.panel(art, _T(base + Vector3(0, jy, zu + 0.004)), W - 0.2, jh, Color.WHITE, Rect2(0, 0.5, 1, 0.5))
		k.box(chrome, _T(base + Vector3(0, jy + jh * 0.5 + 0.01, zu + 0.006)), Vector3(W - 0.16, 0.02, 0.016), 0.006)
		k.box(chrome, _T(base + Vector3(0, jy - jh * 0.5 - 0.01, zu + 0.006)), Vector3(W - 0.16, 0.02, 0.016), 0.006)
		for sx: float in [-1.0, 1.0]:
			k.cyl(KL.m_gold(), _T(base + Vector3(sx * (hw + 0.05), (yu1 + th) * 0.5, 0.15)), 0.05, yu1 + th - 0.12, 20, {"bevel": 0.02})
			for q in 14:
				k.sphere(glow, _T(base + Vector3(sx * (hw + 0.05), 0.3 + float(q) * (yu1 + th - 0.5) / 13.0, 0.205)), 0.02, 8, 5, {"col": Color(b0.r, b0.g, b0.b, float(q) / 14.0 * 0.49)})
	# --- топпер-арка с артом
	var arch := PackedVector2Array()
	arch.append(Vector2(-hw, yu1))
	arch.append(Vector2(hw, yu1))
	var na := 20
	for i in na + 1:
		var a := PI * float(i) / float(na)
		arch.append(Vector2(hw * cos(a), yu1 + th * 0.5 + th * 0.5 * sin(a)))
	var tz0 := -0.27
	var tz1 := 0.23
	k.extrude(body, Transform3D(Basis(Vector3(1, 0, 0), Vector3(0, 0, -1), Vector3(0, 1, 0)), base), arch, -tz1, -tz0, {"bottom": true})
	k.panel(art, _T(base + Vector3(0, yu1 + th * 0.5, tz1 + 0.003)), W, th, Color.WHITE, Rect2(0, 0, 1, 0.5))
	# хромированный кант по арке
	var rim: Array = []
	for i in na + 1:
		var a := PI * float(i) / float(na)
		rim.append(base + Vector3((hw + 0.004) * cos(a), yu1 + th * 0.5 + (th * 0.5 + 0.004) * sin(a), tz1 + 0.002))
	k.pipe(chrome, rim, 0.009, 8, {"joints": false})
	k.tube(chrome, base + Vector3(-hw - 0.004, yu1, tz1 + 0.002), base + Vector3(-hw - 0.004, yu1 + th * 0.5, tz1 + 0.002), 0.009, 8)
	k.tube(chrome, base + Vector3(hw + 0.004, yu1, tz1 + 0.002), base + Vector3(hw + 0.004, yu1 + th * 0.5, tz1 + 0.002), 0.009, 8)
	# лампочки по контуру арки (бегущие огни)
	var nbul := 24 if not big else 34
	var pts: Array = []
	var ins := 0.03 if not big else 0.045
	for i in nbul:
		var t := float(i) / float(nbul - 1)
		var a2 := PI * t
		pts.append(base + Vector3((hw - ins) * cos(a2), yu1 + th * 0.5 + (th * 0.5 - ins) * sin(a2), tz1 + 0.012))
	for i in pts.size():
		var bc3: Color = b0 if i % 2 == 0 else b1
		k.sphere(glow, _T(pts[i]), 0.013 if not big else 0.018, 8, 5, {"col": Color(bc3.r, bc3.g, bc3.b, float(i) / float(pts.size()) * 0.49)})
	# --- вертикальные световые полосы по фронтальным рёбрам
	for sx: float in [-1.0, 1.0]:
		var n1 := 9
		for q in n1:
			var yy := 0.2 + (yd - 0.28) * float(q) / float(n1 - 1)
			k.box(glow, _T(base + Vector3(sx * (hw + 0.003), yy, zf - 0.012)), Vector3(0.014, 0.05, 0.022), 0.004, {"col": Color(b1.r, b1.g, b1.b, float(q) / float(n1) * 0.49)})
		var n2 := 7 if not big else 13
		for q in n2:
			var yy2 := yu0 + 0.06 + (yu1 - yu0 - 0.12) * float(q) / float(n2 - 1)
			k.box(glow, _T(base + Vector3(sx * (hw + 0.003), yy2, zu - 0.012)), Vector3(0.014, 0.05, 0.022), 0.004, {"col": Color(b0.r, b0.g, b0.b, float(n2 - q) / float(n2) * 0.49)})
	# --- рычаг справа
	if not big:
		var lp := base + Vector3(hw + 0.03, ry - 0.08, -0.02)
		k.box(chrome, _T(lp), Vector3(0.06, 0.16, 0.16), 0.025)
		k.cyl(chrome, MK.TR(lp + Vector3(0.035, 0, 0), Vector3(0, 0, PI * 0.5)), 0.035, 0.02, 16, {"bevel": 0.006})
		var top := lp + Vector3(0.07, 0.34, 0.1)
		k.tube(chrome, lp + Vector3(0.05, 0, 0), top, 0.011, 10, {"caps": true})
		k.sphere(Assets.pbr(Color(0.85, 0.05, 0.05), 0.15, 0.1, {"clearcoat": 1.0}), _T(top + Vector3(0, 0.03, 0.01)), 0.045, 16, 10)
	# --- сигнальная «свеча» сверху
	var cy := yu1 + th + 0.02
	k.cyl(chrome, _T(base + Vector3(0, cy, -0.02)), 0.04, 0.04, 16, {"bevel": 0.008})
	k.cyl(glow, _T(base + Vector3(0, cy + 0.07, -0.02)), 0.03, 0.1, 16, {"col": Color(1.0, 0.25, 0.15, 0.5 + 0.49 * float(mi % 4) / 4.0)})
	k.cyl(glow, _T(base + Vector3(0, cy + 0.15, -0.02)), 0.03, 0.06, 16, {"col": Color(1.0, 1.0, 0.95, 1.0)})
	k.sphere(chrome, _T(base + Vector3(0, cy + 0.18, -0.02)), 0.032, 14, 6, {"from": 0.5})


static func _reel(k, m: Material, c: Vector3, rr: float, w: float, ridx: int, mi: int, nr: int) -> void:
	var seg := 16
	var amax := 1.3
	var col := Color(float(ridx) / 8.0, float(mi) / 8.0, float(nr) / 8.0, 1.0)
	for s in seg:
		var a0 := -amax + 2.0 * amax * float(s) / float(seg)
		var a1 := -amax + 2.0 * amax * float(s + 1) / float(seg)
		var p0 := Vector3(0, -sin(a0) * rr, cos(a0) * rr)
		var p1 := Vector3(0, -sin(a1) * rr, cos(a1) * rr)
		var n0 := p0 / rr
		var n1 := p1 / rr
		var A := c + Vector3(-w * 0.5, 0, 0) + p0
		var B := c + Vector3(w * 0.5, 0, 0) + p0
		var C := c + Vector3(w * 0.5, 0, 0) + p1
		var D := c + Vector3(-w * 0.5, 0, 0) + p1
		k.quad_n(m, A, B, C, D, n0, n0, n1, n1, Vector2(0, a0 / TAU), Vector2(1, a0 / TAU), Vector2(1, a1 / TAU), Vector2(0, a1 / TAU), col)


# табурет: диск-основание, хромированная стойка, кольцо для ног, мягкое сиденье
static func _stool(k, p: Vector3, c: Color) -> void:
	var chrome := KL.m_chrome()
	k.lathe(chrome, _T(p), PackedVector2Array([Vector2(0, 0.0), Vector2(0.19, 0.0), Vector2(0.205, 0.008), Vector2(0.2, 0.022), Vector2(0.12, 0.04), Vector2(0.04, 0.055), Vector2(0, 0.06)]), 24)
	k.cyl(chrome, _T(p + Vector3(0, 0.34, 0)), 0.03, 0.58, 14, {"caps": false})
	k.torus(chrome, _T(p + Vector3(0, 0.3, 0)), 0.16, 0.011, 24, 6)
	for q in 3:
		var a := TAU * float(q) / 3.0
		k.tube(chrome, p + Vector3(0, 0.3, 0), p + Vector3(cos(a) * 0.16, 0.3, sin(a) * 0.16), 0.008, 6)
	k.lathe(KL.m_dark(), _T(p), PackedVector2Array([Vector2(0.06, 0.6), Vector2(0.14, 0.615), Vector2(0.15, 0.63), Vector2(0, 0.63)]), 18)
	k.lathe(m_seat(c), _T(p), PackedVector2Array([Vector2(0, 0.63), Vector2(0.17, 0.632), Vector2(0.2, 0.648), Vector2(0.212, 0.675), Vector2(0.205, 0.705), Vector2(0.18, 0.725), Vector2(0.1, 0.735), Vector2(0, 0.738)]), 28)
