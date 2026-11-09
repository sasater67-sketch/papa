extends RefCounted
# TableKit — детализированные игровые столы на MeshKit: сукно с HD-разметкой, мягкий кожаный бортик
# (протяжка профиля), деревянный фартук, токарные опоры, лоток дилера с фишками, ставки, карты, шуз.
# Стол целиком (вместе с табуретами) собирается в один кэшированный ArrayMesh.

const MK := preload("res://scripts/kit/mesh_kit.gd")
const KL := preload("res://scripts/kit/kit_lib.gd")
const SK := preload("res://scripts/kit/slot_kit.gd")

static var _m := {}

const CHIP_COLS := [Color("c8202a"), Color("1f4fc8"), Color("1f9a4a"), Color("1a1a1e"), Color("7a2ab8"), Color("e8c040"), Color("e8e8e8"), Color("e86a1a")]

const KINDS := {
	"bj": {"shape": "d", "w": 2.6, "d": 1.3, "felt": "bj_hd", "rail": Color("3a1a10"), "wood": "wood_dark", "seat": Color("6a1a2a"), "shoe": true, "rack": true},
	"vip": {"shape": "d", "w": 2.8, "d": 1.4, "felt": "vip_hd", "rail": Color("141414"), "wood": "wood_dark", "seat": Color("1a1a1a"), "shoe": true, "rack": true, "gold": true},
	"bacc": {"shape": "d", "w": 2.8, "d": 1.4, "felt": "bacc_hd", "rail": Color("141418"), "wood": "wood_dark", "seat": Color("1a2a4a"), "shoe": true, "rack": true, "gold": true},
	"roul": {"shape": "rect", "w": 3.0, "d": 1.4, "felt": "roul_hd", "rail": Color("3a1a0a"), "wood": "wood_dark", "seat": Color("6a1a2a"), "shoe": false, "rack": false, "chips_only": true},
	"craps": {"shape": "rect", "w": 3.2, "d": 1.5, "felt": "", "rail": Color("2a1a10"), "wood": "wood_red", "seat": Color("6a1a2a"), "shoe": false, "rack": false, "chips_only": true, "tub": true},
	"poker": {"shape": "oval", "w": 3.0, "d": 1.4, "felt": "poker_hd", "rail": Color("2a1a12"), "wood": "wood_dark", "seat": Color("3a2a1a"), "shoe": false, "rack": true, "community": true},
}


static func _tex(name: String) -> Texture2D:
	var p := "res://assets/hd/%s.png" % name
	return load(p) if ResourceLoader.exists(p) else null


static func m_felt(name: String) -> Material:
	var key := "felt_" + name
	if _m.has(key):
		return _m[key]
	var m := StandardMaterial3D.new()
	var t := _tex("felt_" + name)
	if t:
		m.albedo_texture = t
	else:
		m.albedo_color = Color(0.1, 0.45, 0.25)
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	m.roughness = 0.97
	m.metallic_specular = 0.2
	var nt := _tex("felt_green_n") if Assets.hd_enabled else null
	if nt:
		m.normal_enabled = true
		m.normal_texture = nt
		m.normal_scale = 0.6
		m.uv1_scale = Vector3(1, 1, 1)
		m.detail_enabled = false
	_m[key] = m
	return m


static func m_cards() -> Material:
	if _m.has("cards"):
		return _m["cards"]
	var m := StandardMaterial3D.new()
	m.albedo_texture = _tex("slot_strip_cards")
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	m.roughness = 0.45
	_m["cards"] = m
	return m


static func m_chip(c: Color) -> Material:
	return Assets.pbr(c, 0.42, 0.0, {"clearcoat": 0.3})


# контур стола в плоскости (x, z): "d" — полумесяц (прямой край дилера), "oval" — стадион
static func outline(shape: String, w: float, d: float, n: int = 64) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n:
		var t := TAU * float(i) / float(n)
		var c := cos(t)
		var s := sin(t)
		if shape == "oval":
			var r := d * 0.5
			var hx := w * 0.5 - r
			var x := hx * signf(c) + r * c
			if absf(c) < 0.0001:
				x = 0.0
			pts.append(Vector2(clampf(x, -w * 0.5, w * 0.5), r * s))
		else:
			var front := s > 0.0 and shape == "d"
			var px := 2.6 if front else 9.0
			var pz := 2.2 if front else 9.0
			var x2 := w * 0.5 * signf(c) * pow(absf(c), 2.0 / px)
			var z2 := d * 0.5 * signf(s) * pow(absf(s), 2.0 / pz)
			pts.append(Vector2(x2, z2))
	return pts


static func edge_z(shape: String, w: float, d: float, x: float) -> float:
	var best := -1e9
	var o := outline(shape, w, d, 128)
	for p in o:
		if p.y > 0.0 and absf(p.x - x) < w / 60.0:
			best = maxf(best, p.y)
	return best if best > -1e8 else d * 0.5


# стол; возвращает позиции мест (локально в model)
static func card_table(model: Node3D, lb, kind: String, pos: Vector3, nseats: int, seed_v: int) -> Array:
	var kd: Dictionary = KINDS[kind]
	var w: float = kd.w
	var d: float = kd.d
	var seats: Array = []
	var sp := w / float(nseats) * 0.96
	for i in nseats:
		var sx := (float(i) - (nseats - 1) * 0.5) * sp
		var ez := edge_z(str(kd.shape), w, d, sx)
		seats.append(pos + Vector3(sx, 0, ez + 0.52))
	var key := "table_%s_%d_%d" % [kind, nseats, seed_v % 7]
	var local_seats: Array = []
	for s: Vector3 in seats:
		local_seats.append(s - pos)
	var mesh := KL.cached(key, func(k): _build(k, kd, local_seats, seed_v % 7))
	var mi := KL.inst(model, mesh, Transform3D(Basis(), pos), true)
	mi.name = "Table"
	lb.add_collider(pos + Vector3(0, 0.45, 0), Vector3(w + 0.12, 0.9, d + 0.12))
	for s: Vector3 in seats:
		lb.add_cyl_collider(s + Vector3(0, 0.37, 0), 0.2, 0.74)
	return seats


static func _build(k, kd: Dictionary, seats: Array, sv: int) -> void:
	var w: float = kd.w
	var d: float = kd.d
	var shape: String = kd.shape
	var ty := 0.85
	var rng := RandomNumberGenerator.new()
	rng.seed = 1000 + sv
	var o := outline(shape, w, d, 72)
	var path: Array = []
	for p in o:
		path.append(Vector3(p.x, ty, p.y))
	var leather := Assets.kit_mat("leather", {"tint": kd.rail, "uv": Vector2(3, 3)})
	var wood := Assets.kit_mat(str(kd.wood), {})
	var gold := KL.m_gold()
	var dark := KL.m_dark()
	var chrome := KL.m_chrome()
	# сукно
	k.flat_poly(m_felt(str(kd.felt)), Transform3D.IDENTITY, o, ty, Rect2(-w * 0.5, -d * 0.5, w, d))
	# корпус столешницы
	k.extrude(wood, Transform3D.IDENTITY, o, ty - 0.16, ty - 0.005, {"caps": false})
	k.flat_poly(dark, Transform3D(Basis(Vector3.RIGHT, PI), Vector3(0, 0, 0)), _mirror_z(o), -(ty - 0.16), Rect2(-w * 0.5, -d * 0.5, w, d))
	# мягкий бортик (кожа) и деревянный фартук
	var rail := PackedVector2Array()
	var R := 0.062
	var steps := 12
	for i in steps + 1:
		var a := -1.1 + (PI + 0.35 + 1.1) * float(i) / float(steps)
		rail.append(Vector2(0.045 + R * cos(a), 0.02 + R * sin(a)))
	k.sweep(leather, path, rail, true, {"uvk": 2.0, "hard": 0.0})
	k.sweep(wood, path, PackedVector2Array([Vector2(0.0, -0.17), Vector2(0.06, -0.155), Vector2(0.078, -0.12), Vector2(0.08, -0.06), Vector2(0.074, -0.036)]), true, {"hard": 0.5})
	if kd.get("gold", false):
		k.sweep(gold, path, PackedVector2Array([Vector2(0.079, -0.064), Vector2(0.085, -0.056), Vector2(0.085, -0.044), Vector2(0.079, -0.036)]), true)
	# опоры
	for sx: float in [-w * 0.27, w * 0.27]:
		k.lathe(wood, MK.T(Vector3(sx, 0, -0.05)), PackedVector2Array([Vector2(0, 0), Vector2(0.3, 0), Vector2(0.31, 0.015), Vector2(0.28, 0.04), Vector2(0.14, 0.1), Vector2(0.085, 0.2), Vector2(0.075, 0.6), Vector2(0.16, 0.65), Vector2(0.17, 0.69), Vector2(0, 0.69)]), 28)
		k.torus(gold, MK.T(Vector3(sx, 0.21, -0.05)), 0.085, 0.012, 24, 6)
		k.torus(gold, MK.T(Vector3(sx, 0.03, -0.05)), 0.3, 0.01, 32, 6)
	# лоток дилера с фишками
	if kd.get("rack", false):
		var rz := -d * 0.5 + 0.13
		k.box_mm(wood, Vector3(-0.44, ty - 0.01, rz - 0.085), Vector3(0.44, ty + 0.03, rz + 0.085), 0.012)
		k.box_mm(dark, Vector3(-0.41, ty + 0.0305, rz - 0.065), Vector3(0.41, ty + 0.031, rz + 0.065), 0.0)
		for c in 9:
			var cx := -0.36 + float(c) * 0.09
			var ccol: Color = CHIP_COLS[c % CHIP_COLS.size()]
			_chips(k, m_chip(ccol), Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(cx, ty + 0.05, rz - 0.06)), 0.02, 0.0034, 34)
		k.box(chrome, MK.T(Vector3(0, ty + 0.033, rz + 0.088)), Vector3(0.9, 0.012, 0.012), 0.004)
	# шуз и сброс
	if kd.get("shoe", false):
		var shoe := Transform3D(Basis(Vector3(0, 0, 1), Vector3(1, 0, 0), Vector3(0, 1, 0)), Vector3(w * 0.5 - 0.42, ty, -d * 0.5 + 0.2))
		k.extrude(KL.m_dark(), shoe, PackedVector2Array([Vector2(-0.16, 0.0), Vector2(0.16, 0.0), Vector2(0.16, 0.07), Vector2(-0.1, 0.12), Vector2(-0.16, 0.12)]), -0.075, 0.075, {"bottom": true})
		k.box(Assets.pbr(Color(0.95, 0.95, 0.92), 0.6), Transform3D(Basis(Vector3.RIGHT, -0.2), Vector3(w * 0.5 - 0.42, ty + 0.105, -d * 0.5 + 0.17)), Vector3(0.12, 0.03, 0.24), 0.004)
		k.box(m_glass_t(), MK.T(Vector3(-w * 0.5 + 0.42, ty + 0.06, -d * 0.5 + 0.2)), Vector3(0.13, 0.12, 0.18), 0.006)
		k.box(Assets.pbr(Color(0.95, 0.95, 0.92), 0.6), MK.T(Vector3(-w * 0.5 + 0.42, ty + 0.025, -d * 0.5 + 0.2)), Vector3(0.1, 0.05, 0.15), 0.003)
	# карты и ставки на местах игроков
	var cm := m_cards()
	for i in seats.size():
		var s: Vector3 = seats[i]
		var bz := s.z - 0.52 - 0.3
		if rng.randf() < 0.75 and not kd.get("chips_only", false):
			for c2 in 2:
				var idx := rng.randi_range(0, 9)
				var cxf := Transform3D(Basis(Vector3.UP, rng.randf_range(-0.25, 0.25)) * Basis(Vector3.RIGHT, -PI * 0.5), Vector3(s.x - 0.03 + c2 * 0.045, ty + 0.002 + c2 * 0.0008, bz - 0.12 + c2 * 0.01))
				k.panel(cm, cxf, 0.063, 0.088, Color.WHITE, Rect2(0.168, (float(idx) + 0.04) / 10.0, 0.664, 0.092))
		var nst := rng.randi_range(1, 3)
		for q in nst:
			var ccol2: Color = CHIP_COLS[rng.randi_range(0, CHIP_COLS.size() - 1)]
			_chips(k, m_chip(ccol2), MK.T(Vector3(s.x + (q - 1) * 0.045, ty, bz + 0.05 + rng.randf_range(-0.01, 0.01))), 0.02, 0.0034, rng.randi_range(2, 9))
	# карты дилера / общие карты
	var ncards := 0 if kd.get("chips_only", false) else (5 if kd.get("community", false) else 2)
	for c3 in ncards:
		var idx2 := rng.randi_range(0, 9)
		var cz := 0.0 if kd.get("community", false) else -d * 0.5 + 0.34
		var cxf2 := Transform3D(Basis(Vector3.RIGHT, -PI * 0.5), Vector3((float(c3) - (ncards - 1) * 0.5) * 0.075, ty + 0.002, cz + (0.12 if kd.get("community", false) else 0.0)))
		k.panel(cm, cxf2, 0.063, 0.088, Color.WHITE, Rect2(0.168, (float(idx2) + 0.04) / 10.0, 0.664, 0.092))
	# табуреты
	for s2: Vector3 in seats:
		SK._stool(k, s2, kd.seat)


static func _mirror_z(o: PackedVector2Array) -> PackedVector2Array:
	var r := PackedVector2Array()
	for p in o:
		r.append(Vector2(p.x, -p.y))
	return r


static func m_glass_t() -> Material:
	if _m.has("glass"):
		return _m["glass"]
	var m := StandardMaterial3D.new()
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(0.8, 0.9, 1.0, 0.18)
	m.roughness = 0.05
	m.metallic_specular = 1.0
	_m["glass"] = m
	return m


# стопка фишек с бороздками (ось — локальная Y трансформа)
static func _chips(k, m: Material, xf: Transform3D, r: float, h: float, n: int) -> void:
	var prof := PackedVector2Array()
	prof.append(Vector2(0, 0))
	for c in n:
		var y0 := float(c) * h
		prof.append(Vector2(r - 0.0012, y0))
		prof.append(Vector2(r, y0 + h * 0.2))
		prof.append(Vector2(r, y0 + h * 0.8))
	prof.append(Vector2(r - 0.0012, float(n) * h))
	prof.append(Vector2(0, float(n) * h))
	k.lathe(m, xf, prof, 14, {"hard": 0.95})


# ------------------------------------------------------------------ рулетка
# pos — точка как у старого roulette_table (стол со сдвигом +0.3 по x, колесо слева)
static func roulette(model: Node3D, lb, pos: Vector3, seed_v: int, sc: float = 1.0) -> Array:
	var kd: Dictionary = KINDS["roul"]
	var fc := pos + Vector3(0.3, 0, 0)
	var seats: Array = []
	for i in 4:
		seats.append(Vector3((-0.7 + i * 0.7 + 0.3) + pos.x, 0, pos.z + 1.22))
	var local_seats: Array = []
	for s3: Vector3 in seats:
		local_seats.append(s3 - fc)
	var mesh := KL.cached("roul_table_%d" % (seed_v % 5), func(k): _build_roul(k, kd, local_seats, seed_v % 5))
	KL.inst(model, mesh, Transform3D(Basis(), fc), true).name = "Roulette"
	lb.add_collider(fc + Vector3(0, 0.45, 0), Vector3(3.12, 0.9, 1.52))
	lb.add_cyl_collider(fc + Vector3(-2.15, 0.5, 0), 0.64, 1.0)
	for s4: Vector3 in seats:
		lb.add_cyl_collider(s4 + Vector3(0, 0.37, 0), 0.2, 0.74)
	var wheel := Node3D.new()
	wheel.set_script(preload("res://scripts/kit/roulette_wheel.gd"))
	wheel.name = "RouletteWheel"
	model.add_child(wheel)
	wheel.position = fc + Vector3(-2.15, 0.985, 0)
	wheel.set("auto", true)
	KL.inst(wheel, KL.cached("roul_rotor", _rotor), Transform3D.IDENTITY, false)
	var out: Array = []
	for s5: Vector3 in seats:
		out.append(s5 * sc)
	return out


static func _build_roul(k, kd: Dictionary, seats: Array, sv: int) -> void:
	_build(k, kd, seats, sv)
	_roul_cabinet(k, Vector3(-2.15, 0, 0))


static func m_roul_face() -> Material:
	if _m.has("roul_face"):
		return _m["roul_face"]
	var m := StandardMaterial3D.new()
	m.albedo_texture = _tex("roul_face_hd")
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	m.roughness = 0.3
	m.metallic_specular = 0.6
	m.clearcoat_enabled = true
	m.clearcoat = 0.6
	m.clearcoat_roughness = 0.1
	_m["roul_face"] = m
	return m


static func _roul_cabinet(k, c: Vector3) -> void:
	var wood := Assets.kit_mat("wood_dark", {})
	var polish := Assets.pbr(Color(0.32, 0.12, 0.05), 0.18, 0.0, {"clearcoat": 1.0})
	var chrome := KL.m_chrome()
	var gold := KL.m_gold()
	k.lathe(wood, MK.T(c), PackedVector2Array([Vector2(0, 0), Vector2(0.48, 0), Vector2(0.5, 0.015), Vector2(0.49, 0.04), Vector2(0.42, 0.09),
		Vector2(0.4, 0.6), Vector2(0.5, 0.7), Vector2(0.62, 0.8), Vector2(0.645, 0.86), Vector2(0.65, 0.96)]), 40)
	k.lathe(polish, MK.T(c), PackedVector2Array([Vector2(0.65, 0.96), Vector2(0.645, 1.0), Vector2(0.628, 1.03), Vector2(0.6, 1.036), Vector2(0.59, 1.02),
		Vector2(0.585, 0.995), Vector2(0.55, 0.978), Vector2(0.0, 0.976)]), 48, {"hard": 0.6})
	k.torus(gold, MK.T(c + Vector3(0, 0.86, 0)), 0.645, 0.012, 48, 6)
	k.torus(gold, MK.T(c + Vector3(0, 0.6, 0)), 0.405, 0.01, 32, 6)
	for q in 8:
		var a := TAU * (float(q) + 0.5) / 8.0
		var p := c + Vector3(sin(a) * 0.575, 0.99, -cos(a) * 0.575)
		k.box(chrome, Transform3D(Basis(Vector3.UP, PI - a) * Basis(Vector3.RIGHT, 0.3), p), Vector3(0.022, 0.012, 0.04 if q % 2 == 0 else 0.026), 0.004)


static func _rotor(k) -> void:
	var face := m_roul_face()
	var chrome := KL.m_chrome()
	var gold := KL.m_gold()
	var R := 0.54
	var prof := PackedVector2Array([Vector2(R, 0.0), Vector2(0.5, -0.004), Vector2(0.465, -0.008), Vector2(0.4, -0.026), Vector2(0.392, -0.004),
		Vector2(0.38, 0.008), Vector2(0.25, 0.04), Vector2(0.13, 0.068), Vector2(0.05, 0.074), Vector2(0.0, 0.075)])
	_disc_lathe(k, face, prof, 74, R)
	# лады между ячейками
	for i in 37:
		var a := TAU * (float(i) + 0.5) / 37.0
		var rr := 0.432
		k.box(chrome, Transform3D(Basis(Vector3.UP, PI - a), Vector3(sin(a) * rr, -0.008, -cos(a) * rr)), Vector3(0.005, 0.022, 0.07), 0.002)
	# турель
	k.lathe(chrome, MK.T(Vector3.ZERO), PackedVector2Array([Vector2(0, 0.07), Vector2(0.05, 0.07), Vector2(0.046, 0.085), Vector2(0.022, 0.11),
		Vector2(0.014, 0.2), Vector2(0.03, 0.212), Vector2(0.03, 0.224), Vector2(0, 0.236)]), 24)
	for q in 4:
		var a2 := TAU * float(q) / 4.0
		var tip := Vector3(cos(a2) * 0.095, 0.19, sin(a2) * 0.095)
		k.tube(chrome, Vector3(0, 0.19, 0), tip, 0.007, 8)
		k.sphere(gold, MK.T(tip), 0.016, 12, 6)


# токарное тело с плоской проекцией UV сверху (для лицевых сторон колёс)
static func _disc_lathe(k, m: Material, prof: PackedVector2Array, sides: int, R: float) -> void:
	var n := prof.size()
	for s in sides:
		var a0 := TAU * float(s) / float(sides)
		var a1 := TAU * float(s + 1) / float(sides)
		for i in n - 1:
			var pa := prof[i]
			var pb := prof[i + 1]
			var d := pb - pa
			var nn := Vector2(-d.y, d.x).normalized()
			if nn.y < 0.0:
				nn = -nn
			var A := Vector3(sin(a0) * pa.x, pa.y, -cos(a0) * pa.x)
			var B := Vector3(sin(a1) * pa.x, pa.y, -cos(a1) * pa.x)
			var C := Vector3(sin(a1) * pb.x, pb.y, -cos(a1) * pb.x)
			var D := Vector3(sin(a0) * pb.x, pb.y, -cos(a0) * pb.x)
			var nA := Vector3(sin(a0) * nn.x, nn.y, -cos(a0) * nn.x).normalized()
			var nB := Vector3(sin(a1) * nn.x, nn.y, -cos(a1) * nn.x).normalized()
			var uA := Vector2(0.5 + 0.5 * A.x / R, 0.5 + 0.5 * A.z / R)
			var uB := Vector2(0.5 + 0.5 * B.x / R, 0.5 + 0.5 * B.z / R)
			var uC := Vector2(0.5 + 0.5 * C.x / R, 0.5 + 0.5 * C.z / R)
			var uD := Vector2(0.5 + 0.5 * D.x / R, 0.5 + 0.5 * D.z / R)
			if pb.x < 0.0001:
				k.tri(m, A, B, C, nA, nB, nB, uA, uB, uC)
			else:
				k.quad_n(m, A, B, C, D, nA, nB, nB, nA, uA, uB, uC, uD)


# ------------------------------------------------------------------ колесо удачи
static func m_wheel_face() -> Material:
	if _m.has("wheel_face"):
		return _m["wheel_face"]
	var m := StandardMaterial3D.new()
	m.albedo_texture = _tex("wheel_face_hd")
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	m.roughness = 0.35
	m.emission_enabled = true
	m.emission_texture = m.albedo_texture
	m.emission = Color.WHITE
	m.emission_operator = BaseMaterial3D.EMISSION_OP_MULTIPLY
	m.emission_energy_multiplier = 0.4
	m.clearcoat_enabled = true
	m.clearcoat = 0.8
	_m["wheel_face"] = m
	return m


static func fortune_wheel(model: Node3D, lb, pos: Vector3, radius: float) -> Node3D:
	var hub := pos + Vector3(0, radius + 0.7, 0)
	KL.inst(model, KL.cached("fwheel_stand_%.2f" % radius, func(k): _wheel_stand(k, radius)), Transform3D(Basis(), pos), true).name = "WheelStand"
	lb.add_collider(pos + Vector3(0, radius + 0.4, -0.2), Vector3(radius * 2.2, radius * 2 + 0.8, 1.2))
	var wheel := Node3D.new()
	wheel.set_script(preload("res://scripts/kit/fortune_wheel.gd"))
	wheel.name = "FortuneWheel"
	model.add_child(wheel)
	wheel.position = hub
	wheel.set("auto", true)
	KL.inst(wheel, KL.cached("fwheel_face_%.2f" % radius, func(k): _wheel_face(k, radius)), Transform3D.IDENTITY, false)
	var ptr := KL.inst(model, KL.cached("fwheel_ptr", _wheel_ptr), Transform3D(Basis(), hub + Vector3(0, radius + 0.1, 0.12)), false)
	ptr.rotation.z = PI
	wheel.set("pointer", ptr)
	return wheel


# ряд табуретов (кэшированный меш) + коллизии
static func stools(model: Node3D, lb, pts: Array, c: Color) -> void:
	var key := "stools_%s_%s" % [str(pts), c.to_html()]
	KL.inst(model, KL.cached(key, func(k): _stools(k, pts, c)), Transform3D.IDENTITY, true)
	for p: Vector3 in pts:
		lb.add_cyl_collider(p + Vector3(0, 0.37, 0), 0.2, 0.74)


static func _stools(k, pts: Array, c: Color) -> void:
	for p: Vector3 in pts:
		SK._stool(k, p, c)


static func _wheel_face(k, R: float) -> void:
	# диск лицом к +Z: проекция UV спереди
	var face := m_wheel_face()
	var n := 96
	var c0 := Vector3(0, 0, 0.03)
	for s in n:
		var a0 := TAU * float(s) / float(n)
		var a1 := TAU * float(s + 1) / float(n)
		var A := c0 + Vector3(sin(a0) * R, cos(a0) * R, 0)
		var B := c0 + Vector3(sin(a1) * R, cos(a1) * R, 0)
		var nz := Vector3(0, 0, 1)
		k.tri(face, c0, A, B, nz, nz, nz, Vector2(0.5, 0.5), Vector2(0.5 + 0.5 * sin(a0), 0.5 - 0.5 * cos(a0)), Vector2(0.5 + 0.5 * sin(a1), 0.5 - 0.5 * cos(a1)))
	var gold := KL.m_gold()
	var chrome := KL.m_chrome()
	var back := Assets.pbr(Color(0.12, 0.06, 0.18), 0.4, 0.3)
	k.cyl(back, MK.TR(Vector3(0, 0, -0.01), Vector3(PI * 0.5, 0, 0)), R + 0.01, 0.08, 64, {"bevel": 0.01})
	k.torus(gold, MK.TR(Vector3(0, 0, 0.03), Vector3(PI * 0.5, 0, 0)), R + 0.02, 0.035, 64, 10)
	var nseg := 51
	for i in nseg:
		var a := TAU * (float(i) + 0.5) / float(nseg)
		var pp := Vector3(sin(a) * (R - 0.035), cos(a) * (R - 0.035), 0.06)
		k.cyl(chrome, MK.TR(pp, Vector3(PI * 0.5, 0, 0)), 0.011, 0.06, 8, {"bevel": 0.003})
	k.lathe(gold, MK.TR(Vector3(0, 0, 0.03), Vector3(PI * 0.5, 0, 0)), PackedVector2Array([Vector2(R * 0.2, 0), Vector2(R * 0.19, 0.03), Vector2(R * 0.12, 0.06), Vector2(R * 0.05, 0.08), Vector2(0, 0.085)]), 32)


static func _wheel_ptr(k) -> void:
	var gold := KL.m_gold()
	var red := Assets.pbr(Color(0.85, 0.08, 0.06), 0.2, 0.1, {"clearcoat": 1.0})
	var xf := Transform3D(Basis(Vector3(1, 0, 0), Vector3(0, 0, -1), Vector3(0, 1, 0)), Vector3.ZERO)
	# остриём вверх: FortuneWheel поворачивает указатель на PI вокруг Z
	k.extrude(gold, xf, PackedVector2Array([Vector2(-0.16, -0.12), Vector2(0.16, -0.12), Vector2(0.0, 0.22)]), -0.04, 0.04, {"bottom": true})
	k.extrude(red, xf, PackedVector2Array([Vector2(-0.1, -0.09), Vector2(0.1, -0.09), Vector2(0.0, 0.14)]), -0.05, 0.05, {"bottom": true})
	k.cyl(gold, MK.TR(Vector3(0, -0.1, 0), Vector3(PI * 0.5, 0, 0)), 0.05, 0.14, 20, {"bevel": 0.01})


static func _wheel_stand(k, R: float) -> void:
	var gold := KL.m_gold()
	var marble := Assets.kit_mat("marble_black", {})
	var dark := KL.m_dark()
	var glow := SK.m_glow()
	var hy := R + 0.7
	k.box(marble, MK.T(Vector3(0, 0.25, -0.2)), Vector3(R * 1.6, 0.5, 1.2), 0.05)
	k.box(gold, MK.T(Vector3(0, 0.515, -0.2)), Vector3(R * 1.6 + 0.06, 0.03, 1.26), 0.012)
	for sx: float in [-1.0, 1.0]:
		k.extrude(gold, Transform3D(Basis(Vector3(1, 0, 0), Vector3(0, 0, -1), Vector3(0, 1, 0)), Vector3(0, 0, -0.25)),
			PackedVector2Array([Vector2(sx * R * 0.55, 0.5), Vector2(sx * R * 0.4, 0.5), Vector2(sx * 0.05, hy), Vector2(sx * 0.12, hy)]), -0.04, 0.04, {"bottom": true})
	k.cyl(dark, MK.TR(Vector3(0, hy, -0.2), Vector3(PI * 0.5, 0, 0)), 0.12, 0.2, 24, {"bevel": 0.02})
	# внешнее кольцо с бегущими огнями
	k.torus(gold, MK.TR(Vector3(0, hy, -0.02), Vector3(PI * 0.5, 0, 0)), R + 0.13, 0.03, 72, 8)
	var nb := 32
	for i in nb:
		var a := TAU * float(i) / float(nb)
		var c := Color(1.0, 0.85, 0.35) if i % 2 == 0 else Color(1.0, 0.35, 0.25)
		k.sphere(glow, MK.T(Vector3(sin(a) * (R + 0.13), hy + cos(a) * (R + 0.13), 0.02)), 0.032, 10, 6, {"col": Color(c.r, c.g, c.b, float(i) / float(nb) * 0.49)})


# ------------------------------------------------------------------ крэпс
# скруглённый прямоугольник в плоскости (x, z)
static func _rr(w: float, d: float, r: float, n: int = 10) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var cs := [Vector2(w * 0.5 - r, d * 0.5 - r), Vector2(-w * 0.5 + r, d * 0.5 - r), Vector2(-w * 0.5 + r, -d * 0.5 + r), Vector2(w * 0.5 - r, -d * 0.5 + r)]
	for q in 4:
		var c: Vector2 = cs[q]
		for i in n + 1:
			var a := PI * 0.5 * float(q) + PI * 0.5 * float(i) / float(n)
			pts.append(c + Vector2(cos(a), sin(a)) * r)
	return pts


static func m_craps_wall() -> Material:
	if _m.has("craps_wall"):
		return _m["craps_wall"]
	var m := StandardMaterial3D.new()
	var t := _tex("craps_wall_hd")
	if t:
		m.albedo_texture = t
	m.albedo_color = Color(0.85, 0.85, 0.9)
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	m.roughness = 0.75
	_m["craps_wall"] = m
	return m


# стол-«ванна» для крэпса; pos — центр стола; возвращает места игроков (локально в model)
static func craps(model: Node3D, lb, pos: Vector3, seed_v: int) -> Array:
	var seats: Array = []
	for i in 4:
		seats.append(pos + Vector3(-1.2 + i * 0.8, 0, 0.75 + 0.6))
	var local: Array = []
	for s: Vector3 in seats:
		local.append(s - pos)
	var mesh := KL.cached("craps_%d" % (seed_v % 5), func(k): _build_craps(k, local, seed_v % 5))
	KL.inst(model, mesh, Transform3D(Basis(), pos), true).name = "Craps"
	lb.add_collider(pos + Vector3(0, 0.5, 0), Vector3(3.22, 1.0, 1.52))
	for s2: Vector3 in seats:
		lb.add_cyl_collider(s2 + Vector3(0, 0.37, 0), 0.2, 0.74)
	var dice := Node3D.new()
	dice.set_script(preload("res://scripts/kit/craps_dice.gd"))
	dice.name = "CrapsDice"
	model.add_child(dice)
	dice.position = pos + Vector3(0, 0.74, 0)
	return seats


static func _build_craps(k, seats: Array, sv: int) -> void:
	var w := 3.2
	var d := 1.5
	var fy := 0.74
	var ty := 0.98
	var rng := RandomNumberGenerator.new()
	rng.seed = 2000 + sv
	var O := _rr(w, d, 0.36)
	var I := _rr(w - 0.4, d - 0.4, 0.16)
	var wood := Assets.kit_mat("wood_red", {})
	var dark := KL.m_dark()
	var gold := KL.m_gold()
	var leather := Assets.kit_mat("leather", {"tint": Color("2a1a10"), "uv": Vector2(3, 3)})
	# сукно на дне ванны
	k.flat_poly(m_felt("craps_hd"), Transform3D.IDENTITY, I, fy, Rect2(-(w - 0.4) * 0.5, -(d - 0.4) * 0.5, w - 0.4, d - 0.4))
	# внутренняя стенка с резиновыми «пирамидками» (нормали внутрь)
	var ip: Array = []
	for p in I:
		ip.append(Vector3(p.x, fy, p.y))
	k.sweep(m_craps_wall(), ip, PackedVector2Array([Vector2(0, ty - fy - 0.02), Vector2(0, 0)]), true, {"uvk": 5.0, "hard": 0.0})
	var op: Array = []
	for p2 in O:
		op.append(Vector3(p2.x, ty, p2.y))
	# деревянный желоб для фишек
	k.sweep(wood, op, PackedVector2Array([Vector2(-0.118, 0.02), Vector2(-0.13, 0.012), Vector2(-0.132, -0.012), Vector2(-0.168, -0.012),
		Vector2(-0.17, 0.012), Vector2(-0.185, 0.02), Vector2(-0.2, 0.012), Vector2(-0.2, -0.02)]), true, {"hard": 0.3})
	# мягкий подлокотник
	var arm := PackedVector2Array()
	for i in 13:
		var a := PI * float(i) / 12.0
		arm.append(Vector2(-0.06 + cos(a) * 0.058, 0.02 + sin(a) * 0.045))
	k.sweep(leather, op, arm, true, {"uvk": 2.0, "hard": 0.0})
	# наружная деревянная обшивка ванны + золотой молдинг
	k.sweep(wood, op, PackedVector2Array([Vector2(-0.12, -0.25), Vector2(-0.01, -0.24), Vector2(0.004, -0.2), Vector2(0.004, 0.0), Vector2(-0.002, 0.02)]), true, {"hard": 0.5})
	var bead := PackedVector2Array()
	for i in 9:
		var a2 := -PI * 0.5 + PI * float(i) / 8.0
		bead.append(Vector2(0.004 + cos(a2) * 0.011, -0.1 + sin(a2) * 0.011))
	k.sweep(gold, op, bead, true, {"hard": 0.0})
	# днище ванны и тумба
	var U := _rr(w - 0.2, d - 0.2, 0.26)
	k.flat_poly(dark, Transform3D(Basis(Vector3.RIGHT, PI), Vector3.ZERO), _mirror_z(U), -(ty - 0.25), Rect2(-w * 0.5, -d * 0.5, w, d))
	k.extrude(wood, Transform3D.IDENTITY, _rr(w - 0.9, d - 0.6, 0.2), 0.08, ty - 0.25, {"caps": false})
	k.extrude(dark, Transform3D.IDENTITY, _rr(w - 0.8, d - 0.5, 0.22), 0.0, 0.08, {"caps": true})
	k.sweep(gold, _path3(_rr(w - 0.9, d - 0.6, 0.2), 0.1), PackedVector2Array([Vector2(0.0, -0.01), Vector2(0.012, 0.0), Vector2(0.0, 0.01)]), true, {"hard": 0.0})
	# фишки в желобе у мест и ставки на «линии прохода»
	for s: Vector3 in seats:
		var gz := d * 0.5 - 0.15
		for q in rng.randi_range(2, 4):
			var cc: Color = CHIP_COLS[rng.randi_range(0, CHIP_COLS.size() - 1)]
			var n := rng.randi_range(6, 16)
			_chips(k, m_chip(cc), Transform3D(Basis(Vector3(0, 0, 1), -PI * 0.5), Vector3(s.x - 0.16 + q * 0.09, ty - 0.012 + 0.02, gz)), 0.02, 0.0034, n)
		for q2 in rng.randi_range(1, 2):
			var cc2: Color = CHIP_COLS[rng.randi_range(0, CHIP_COLS.size() - 1)]
			_chips(k, m_chip(cc2), MK.T(Vector3(s.x + (q2 - 0.5) * 0.05, fy, 0.38 + rng.randf_range(-0.02, 0.02))), 0.02, 0.0034, rng.randi_range(2, 7))
	# ставки на номерах (сторона дилеров)
	for q3 in 5:
		var cc3: Color = CHIP_COLS[rng.randi_range(0, CHIP_COLS.size() - 1)]
		var sx := (1.0 if q3 % 2 == 0 else -1.0) * rng.randf_range(0.45, 1.25)
		_chips(k, m_chip(cc3), MK.T(Vector3(sx, fy, -0.44 + rng.randf_range(-0.02, 0.02))), 0.02, 0.0034, rng.randi_range(2, 6))
	# шайба ВКЛ на «шестёрке»
	k.cyl(Assets.pbr(Color(0.95, 0.95, 0.92), 0.35), MK.T(Vector3(0.36 + 2.5 * 0.162, fy + 0.007, -0.44)), 0.042, 0.014, 24, {"bevel": 0.004})
	k.cyl(dark, MK.T(Vector3(0.36 + 2.5 * 0.162, fy + 0.0145, -0.44)), 0.03, 0.002, 24)
	# клюшка крупье на дальнем борту
	var wd2 := Assets.pbr(Color(0.55, 0.32, 0.14), 0.4)
	k.tube(wd2, Vector3(-1.0, ty + 0.075, -d * 0.5 + 0.08), Vector3(0.55, ty + 0.075, -d * 0.5 + 0.1), 0.007, 8)
	k.tube(wd2, Vector3(0.55, ty + 0.075, -d * 0.5 + 0.1), Vector3(0.6, ty + 0.075, -d * 0.5 + 0.16), 0.007, 8)
	# табуреты
	for s3: Vector3 in seats:
		SK._stool(k, s3, Color("6a1a2a"))


static func _path3(o: PackedVector2Array, y: float) -> Array:
	var r: Array = []
	for p in o:
		r.append(Vector3(p.x, y, p.y))
	return r


# ------------------------------------------------------------------ плинко
const PLINKO_ROWS := 12
const PLINKO_DX := 0.13
const PLINKO_Y0 := 2.85
const PLINKO_DY := 0.14
const PLINKO_Z := -0.235

static func m_plinko_board() -> Material:
	if _m.has("plinko_board"):
		return _m["plinko_board"]
	var m := StandardMaterial3D.new()
	var t := _tex("plinko_board_hd")
	if t:
		m.albedo_texture = t
		m.emission_enabled = true
		m.emission_texture = t
		m.emission = Color.WHITE
		m.emission_operator = BaseMaterial3D.EMISSION_OP_MULTIPLY
		m.emission_energy_multiplier = 0.55
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	m.roughness = 0.4
	_m["plinko_board"] = m
	return m


static func plinko(model: Node3D, lb, pos: Vector3) -> Node3D:
	KL.inst(model, KL.cached("plinko_v3", _build_plinko), Transform3D(Basis(), pos), true).name = "Plinko"
	lb.add_collider(pos + Vector3(0, 1.65, -0.02), Vector3(2.04, 3.3, 0.76))
	var an := Node3D.new()
	an.set_script(preload("res://scripts/kit/plinko_balls.gd"))
	an.name = "PlinkoBalls"
	model.add_child(an)
	an.position = pos
	return an


static func _build_plinko(k) -> void:
	var purple := Assets.pbr(Color(0.2, 0.05, 0.4), 0.22, 0.15, {"clearcoat": 1.0})
	var gold := KL.m_gold()
	var chrome := KL.m_chrome()
	var dark := KL.m_dark()
	var glow := SK.m_glow()
	var gb := SK.m_gloss_black()
	# тумба
	k.box_mm(purple, Vector3(-1.0, 0.0, -0.38), Vector3(1.0, 0.92, 0.36), 0.03)
	k.box_mm(chrome, Vector3(-0.985, 0.0, 0.28), Vector3(0.985, 0.09, 0.37), 0.012)
	k.box_mm(gold, Vector3(-1.01, 0.9, -0.39), Vector3(1.01, 0.935, 0.375), 0.01)
	# пульт: наклонная дека с кнопками
	var deck := Transform3D(Basis(Vector3.RIGHT, -0.32), Vector3(0, 0.99, 0.2))
	k.box(gb, deck, Vector3(1.9, 0.05, 0.36), 0.012)
	var cols := [Color(1.0, 0.25, 0.3), Color(1.0, 0.8, 0.2), Color(0.3, 1.0, 0.45)]
	for i in 3:
		var bx := -0.5 + float(i) * 0.5
		var bxf := deck * Transform3D(Basis(), Vector3(bx, 0.026, 0.0))
		k.lathe(chrome, bxf, PackedVector2Array([Vector2(0, 0), Vector2(0.075, 0), Vector2(0.078, 0.012), Vector2(0, 0.012)]), 24)
		var c: Color = cols[i]
		k.lathe(glow, bxf * Transform3D(Basis(), Vector3(0, 0.012, 0)), PackedVector2Array([Vector2(0.06, 0), Vector2(0.058, 0.018), Vector2(0.04, 0.03), Vector2(0, 0.034)]), 20, {"col": Color(c.r, c.g, c.b, 0.5 + 0.16 * float(i))})
	# щель для купюр и монетоприёмник
	k.box_mm(chrome, Vector3(0.72, 0.6, 0.355), Vector3(0.9, 0.78, 0.385), 0.006)
	k.box_mm(dark, Vector3(0.75, 0.68, 0.383), Vector3(0.87, 0.695, 0.388), 0.0)
	# боковые башни с бегущими огнями
	for sx: float in [-1.0, 1.0]:
		var x0 := 0.88 * sx
		var x1 := 1.0 * sx
		k.box_mm(purple, Vector3(minf(x0, x1), 0.92, -0.37), Vector3(maxf(x0, x1), 3.22, -0.12), 0.02)
		for j in 16:
			var yy := 1.05 + float(j) * 0.135
			var cc := Color(1.0, 0.75, 0.25) if j % 2 == 0 else Color(0.85, 0.35, 1.0)
			k.sphere(glow, MK.T(Vector3(0.94 * sx, yy, -0.11)), 0.022, 10, 6, {"col": Color(cc.r, cc.g, cc.b, fmod(float(j) / 16.0 * 0.49 + (0.0 if sx < 0 else 0.25), 0.49))})
	# задник и рамка
	k.panel(m_plinko_board(), Transform3D(Basis(), Vector3(0, 2.05, -0.262)), 1.76, 2.1)
	k.box_mm(dark, Vector3(-0.9, 0.95, -0.37), Vector3(0.9, 3.15, -0.265), 0.0)
	k.box_mm(gold, Vector3(-0.9, 3.08, -0.3), Vector3(0.9, 3.15, -0.17), 0.015)
	k.box_mm(gold, Vector3(-0.9, 0.93, -0.3), Vector3(0.9, 0.99, -0.17), 0.015)
	for sx2: float in [-1.0, 1.0]:
		k.box_mm(gold, Vector3(minf(0.85 * sx2, 0.9 * sx2), 0.93, -0.3), Vector3(maxf(0.85 * sx2, 0.9 * sx2), 3.15, -0.17), 0.012)
	# колышки
	for r in PLINKO_ROWS:
		for i in r + 3:
			var x := (float(i) - float(r + 2) * 0.5) * PLINKO_DX
			var y := PLINKO_Y0 - float(r) * PLINKO_DY
			k.cyl(chrome, MK.TR(Vector3(x, y, PLINKO_Z), Vector3(PI * 0.5, 0, 0)), 0.011, 0.054, 8, {"bevel": 0.003})
	# лунки: перегородки и подсветка множителей
	var mcol := [Color(1.0, 0.16, 0.28), Color(1.0, 0.43, 0.16), Color(1.0, 0.75, 0.16), Color(1.0, 0.9, 0.28), Color(0.55, 1.0, 0.35), Color(0.28, 0.86, 1.0), Color(0.35, 0.55, 1.0)]
	for i2 in 14:
		var xd := (float(i2) - 6.5) * PLINKO_DX
		k.box_mm(chrome, Vector3(xd - 0.006, 0.99, -0.262), Vector3(xd + 0.006, 1.2, -0.19), 0.003)
	for j2 in 13:
		var xb := (float(j2) - 6.0) * PLINKO_DX
		var mc: Color = mcol[6 - mini(absi(j2 - 6), 6)]
		k.box_mm(glow, Vector3(xb - 0.05, 0.995, -0.25), Vector3(xb + 0.05, 1.015, -0.2), 0.004, {"col": Color(mc.r, mc.g, mc.b, 0.5 + 0.48 * fmod(float(j2) * 0.37, 1.0))})
	# стекло
	k.panel(SK.m_glass(), Transform3D(Basis(), Vector3(0, 2.05, -0.18)), 1.7, 2.1)
	# воронка и запас шаров
	k.lathe(chrome, MK.T(Vector3(0, 2.98, PLINKO_Z)), PackedVector2Array([Vector2(0.02, 0.0), Vector2(0.03, 0.0), Vector2(0.034, 0.05), Vector2(0.08, 0.12), Vector2(0.086, 0.13), Vector2(0.075, 0.13), Vector2(0.026, 0.06), Vector2(0.018, 0.0)]), 20)
	# арка-топпер
	var arch := PackedVector2Array()
	for i3 in 25:
		var a := PI * float(i3) / 24.0
		arch.append(Vector2(cos(a) * 1.02, 3.2 + sin(a) * 0.5))
	var xz := Transform3D(Basis(Vector3(1, 0, 0), Vector3(0, 0, -1), Vector3(0, 1, 0)), Vector3(0, 0, -0.25))
	k.extrude(purple, xz, arch, -0.12, 0.12, {"bottom": true})
	var rim := PackedVector2Array()
	for i4 in 25:
		var a4 := PI * float(i4) / 24.0
		rim.append(Vector2(cos(a4) * 1.07, 3.18 + sin(a4) * 0.55))
	k.extrude(gold, xz * Transform3D(Basis(), Vector3(0, 0.0, 0)), rim, -0.1, 0.1, {"bottom": true})
	for i5 in 21:
		var a5 := PI * (0.04 + 0.92 * float(i5) / 20.0)
		var cb := Color(1.0, 0.85, 0.3) if i5 % 2 == 0 else Color(1.0, 0.3, 0.6)
		k.sphere(glow, MK.T(Vector3(cos(a5) * 0.96, 3.2 + sin(a5) * 0.44, -0.11)), 0.026, 10, 6, {"col": Color(cb.r, cb.g, cb.b, float(i5) / 21.0 * 0.49)})
