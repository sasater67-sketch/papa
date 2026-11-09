extends RefCounted
# Библиотека детализированных пропсов на MeshKit: машины, фонари, скамейки, урны, клумбы, остановка,
# статуя, ящики, грузовик, светофор. Меши кэшируются (ArrayMesh) и инстансятся.

const MK := preload("res://scripts/kit/mesh_kit.gd")

const RPR := preload("res://scripts/kit/ref_props.gd")
static var _cache := {}
static var _tl_mats := {}


static func cached(key: String, builder: Callable) -> ArrayMesh:
	if _cache.has(key):
		return _cache[key]
	var tmp := Node3D.new()
	var k = MK.new(tmp, key, false)
	builder.call(k)
	var am: ArrayMesh = k.commit_mesh()
	tmp.free()
	_cache[key] = am
	return am


static func inst(parent: Node3D, mesh: Mesh, xf: Transform3D, shadows: bool = true) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.transform = xf
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadows else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi


static func put(parent: Node3D, key: String, builder: Callable, xf: Transform3D, shadows: bool = true) -> MeshInstance3D:
	return inst(parent, cached(key, builder), xf, shadows)


# ------------------------------------------------------------------ материалы

static func m_paint(c: Color) -> StandardMaterial3D:
	return Assets.pbr(c, 0.32, 0.35, {"clearcoat": 0.7})


static func m_chrome() -> StandardMaterial3D:
	return Assets.pbr(Color(0.86, 0.87, 0.9), 0.12, 1.0)


static func m_steel() -> StandardMaterial3D:
	return Assets.pbr(Color(0.42, 0.44, 0.47), 0.45, 0.85)


static func m_dark() -> StandardMaterial3D:
	return Assets.pbr(Color(0.07, 0.07, 0.08), 0.55, 0.2)


static func m_rubber() -> StandardMaterial3D:
	return Assets.pbr(Color(0.05, 0.05, 0.05), 0.9)


static func m_glass_car() -> StandardMaterial3D:
	return Assets.pbr(Color(0.06, 0.08, 0.11), 0.04, 0.7)


static func m_emit(c: Color, e: float = 2.5, id: String = "") -> StandardMaterial3D:
	var o := {"tint": c, "emit": e, "emit_color": c}
	if id != "":
		o["id"] = id
	return Assets.mat("", o)


static func m_gold() -> StandardMaterial3D:
	return Assets.pbr(Color(1.0, 0.78, 0.34), 0.22, 1.0)


static func m_wood() -> StandardMaterial3D:
	return Assets.kit_mat("wood_mid", {"rough": 0.7})


static func m_concrete() -> StandardMaterial3D:
	return Assets.kit_mat("concrete", {"tint": Color(0.78, 0.77, 0.75)})


# ------------------------------------------------------------------ машины (вперёд = +X)

const CAR_KINDS := ["sedan", "sedan", "hatch", "taxi", "van", "sedan", "police", "hatch"]
const CAR_COLORS := [Color("b8202a"), Color("e8e8ea"), Color("1a1c22"), Color("2a5ab8"), Color("7a7e86"), Color("2a7a4a"), Color("d8b040"), Color("5a2a7a")]


static func car_len(kind: String) -> float:
	return {"van": 5.0, "hatch": 3.9}.get(kind, 4.5)


static func car_mesh(kind: String, paint: Color) -> ArrayMesh:
	if kind == "taxi":
		paint = Color("f2c218")
	elif kind == "police":
		paint = Color("eef0f4")
	return cached("car_%s_%s" % [kind, paint.to_html(false)], func(k): _car(k, kind, paint))


static func _car(k, kind: String, paint: Color) -> void:
	var pm := m_paint(paint)
	var gl := m_glass_car()
	var rb := m_rubber()
	var ch := m_chrome()
	var dk := m_dark()
	var head := m_emit(Color(1.0, 0.96, 0.86), 3.0)
	var tail := m_emit(Color(1.0, 0.08, 0.05), 2.4)
	var L := car_len(kind)
	var hl := L * 0.5
	if kind == "van":
		k.box(pm, MK.T(Vector3(-0.35, 1.25, 0)), Vector3(L - 0.7, 1.75, 1.9), 0.16, {"seg": 2})
		k.box(pm, MK.T(Vector3(hl - 0.62, 0.78, 0)), Vector3(1.24, 0.82, 1.9), 0.22, {"seg": 3})
		k.box(gl, MK.TR(Vector3(hl - 0.98, 1.5, 0), Vector3(0, 0, -0.5)), Vector3(0.06, 0.8, 1.72), 0.03)
		for s: float in [-1.0, 1.0]:
			k.box(gl, MK.T(Vector3(hl - 1.6, 1.55, s * 0.95)), Vector3(0.9, 0.55, 0.04), 0.02)
		k.box(m_paint(Color(0.85, 0.85, 0.86)), MK.T(Vector3(-0.5, 1.3, 0.955)), Vector3(2.6, 0.7, 0.02), 0.0)
	else:
		var low_h := 0.62
		k.box(pm, MK.T(Vector3(0, 0.66, 0)), Vector3(L, low_h, 1.82), 0.24, {"seg": 3})
		var cab_l := 2.3 if kind != "hatch" else 2.2
		var cab_x := -0.25 if kind != "hatch" else -0.45
		k.box(gl, MK.T(Vector3(cab_x, 1.15, 0)), Vector3(cab_l, 0.52, 1.64), 0.22, {"seg": 3})
		k.box(pm, MK.T(Vector3(cab_x - 0.08, 1.4, 0)), Vector3(cab_l - 0.45, 0.08, 1.6), 0.04)
		for s: float in [-1.0, 1.0]:
			k.box(pm, MK.T(Vector3(cab_x, 1.15, s * 0.8)), Vector3(0.08, 0.5, 0.06), 0.02)
		if kind == "hatch":
			k.box(pm, MK.T(Vector3(-hl + 0.3, 1.05, 0)), Vector3(0.5, 0.42, 1.7), 0.18)
	# колёса
	var wx := hl - 0.95
	for x: float in [wx, -wx]:
		for s: float in [-1.0, 1.0]:
			var xf := Transform3D(Basis(Vector3.RIGHT, PI / 2.0), Vector3(x, 0.36, s * 0.8))
			k.cyl(rb, xf, 0.36, 0.26, 20, {"bevel": 0.07})
			k.cyl(ch, Transform3D(Basis(Vector3.RIGHT, PI / 2.0), Vector3(x, 0.36, s * 0.935)), 0.21, 0.03, 16)
			k.cyl(dk, Transform3D(Basis(Vector3.RIGHT, PI / 2.0), Vector3(x, 0.36, s * 0.955)), 0.07, 0.02, 10)
	# фары, фонари, бамперы, решётка, зеркала
	for s: float in [-1.0, 1.0]:
		k.box(head, MK.T(Vector3(hl - 0.04, 0.78, s * 0.62)), Vector3(0.08, 0.15, 0.36), 0.035)
		k.box(tail, MK.T(Vector3(-hl + 0.03, 0.82 if kind != "van" else 1.2, s * 0.68)), Vector3(0.06, 0.13 if kind != "van" else 0.4, 0.3), 0.03)
		k.box(pm, MK.T(Vector3(hl - 1.45 if kind != "van" else hl - 1.0, 1.08, s * 0.98)), Vector3(0.16, 0.1, 0.16), 0.04)
	k.box(dk, MK.T(Vector3(hl - 0.02, 0.44, 0)), Vector3(0.22, 0.2, 1.86), 0.08)
	k.box(dk, MK.T(Vector3(-hl + 0.02, 0.44, 0)), Vector3(0.22, 0.2, 1.86), 0.08)
	k.box(ch, MK.T(Vector3(hl + 0.01, 0.64, 0)), Vector3(0.04, 0.16, 0.74), 0.02)
	k.box(dk, MK.T(Vector3(-hl + 0.02, 0.6, 0)), Vector3(0.03, 0.14, 0.5), 0.0)
	if kind == "taxi":
		k.box(m_emit(Color(1.0, 0.85, 0.3), 1.8), MK.T(Vector3(-0.3, 1.52, 0)), Vector3(0.36, 0.16, 0.7), 0.05)
		for i in 10:
			var cc := Color(0.05, 0.05, 0.05) if i % 2 == 0 else Color(0.95, 0.95, 0.95)
			for s: float in [-1.0, 1.0]:
				k.box(Assets.pbr(cc, 0.5), MK.T(Vector3(-1.2 + i * 0.26, 0.86, s * 0.915)), Vector3(0.26, 0.1, 0.01), 0.0)
	elif kind == "police":
		k.box(dk, MK.T(Vector3(-0.3, 1.5, 0)), Vector3(0.3, 0.1, 1.2), 0.03)
		k.box(m_emit(Color(0.15, 0.35, 1.0), 2.5), MK.T(Vector3(-0.3, 1.58, 0.33)), Vector3(0.26, 0.1, 0.5), 0.04)
		k.box(m_emit(Color(1.0, 0.1, 0.1), 2.5), MK.T(Vector3(-0.3, 1.58, -0.33)), Vector3(0.26, 0.1, 0.5), 0.04)
		for s: float in [-1.0, 1.0]:
			k.box(Assets.pbr(Color("1a3a9a"), 0.4), MK.T(Vector3(0, 0.74, s * 0.915)), Vector3(L - 0.6, 0.16, 0.01), 0.0)


# ------------------------------------------------------------------ уличная мебель

static func lamp_post(parent: Node3D, pos: Vector3, yaw: float, h: float = 6.0) -> Vector3:
	# v0.5: чугунный фонарь с плафоном по референсу (кронштейн — в сторону дороги)
	if RPR.has("lamp"):
		RPR.put(parent, "lamp", MK.T(pos, yaw))
		return pos + Vector3(0, float(RPR.data("lamp").get("head", 3.8)), 0)
	put(parent, "lamp_%d" % int(h * 10), func(k): _lamp(k, h), MK.T(pos, yaw))
	return pos + Basis(Vector3.UP, yaw) * Vector3(1.15, h - 0.22, 0)


static func _lamp(k, h: float) -> void:
	var m := Assets.pbr(Color(0.12, 0.13, 0.15), 0.4, 0.8)
	k.lathe(m, MK.T(Vector3.ZERO), PackedVector2Array([Vector2(0, 0), Vector2(0.24, 0), Vector2(0.24, 0.1), Vector2(0.17, 0.2), Vector2(0.13, 0.55), Vector2(0.09, 0.7), Vector2(0, 0.7)]), 16)
	k.cyl(m, MK.T(Vector3(0, h * 0.5 + 0.3, 0)), 0.075, h - 0.6, 14, {"r_top": 0.055, "caps": false})
	k.pipe(m, [Vector3(0, h - 0.35, 0), Vector3(0.12, h - 0.1, 0), Vector3(0.5, h - 0.02, 0), Vector3(1.0, h - 0.05, 0)], 0.045, 10)
	k.box(m, MK.T(Vector3(1.15, h - 0.12, 0)), Vector3(0.62, 0.14, 0.32), 0.05)
	k.box(m_emit(Color(1.0, 0.82, 0.55), 4.0), MK.T(Vector3(1.15, h - 0.2, 0)), Vector3(0.5, 0.03, 0.24), 0.01)
	k.sphere(m, MK.T(Vector3(0, h - 0.3, 0)), 0.09, 12, 8)


static func bench(parent: Node3D, pos: Vector3, yaw: float) -> void:
	if RPR.has("bench"):
		RPR.put(parent, "bench", MK.T(pos, yaw), 1.9 / RPR.size("bench").x)
		return
	put(parent, "bench", func(k): _bench(k), MK.T(pos, yaw))


static func _bench(k) -> void:
	var w := m_wood()
	var iron := Assets.pbr(Color(0.1, 0.1, 0.11), 0.5, 0.7)
	for i in 4:
		k.box(w, MK.T(Vector3(0, 0.45, -0.18 + i * 0.12)), Vector3(1.9, 0.04, 0.1), 0.015)
	for i in 3:
		k.box(w, MK.TR(Vector3(0, 0.62 + i * 0.13, -0.27 - i * 0.025), Vector3(-0.2, 0, 0)), Vector3(1.9, 0.1, 0.035), 0.015)
	for x: float in [-0.82, 0.82]:
		k.extrude(iron, MK.T(Vector3(x, 0, 0)), PackedVector2Array([Vector2(-0.03, -0.25), Vector2(0.03, -0.25), Vector2(0.03, 0.25), Vector2(-0.03, 0.25)]), 0.0, 0.03)
		k.box(iron, MK.T(Vector3(x, 0.22, 0.18)), Vector3(0.05, 0.44, 0.05), 0.01)
		k.box(iron, MK.T(Vector3(x, 0.22, -0.18)), Vector3(0.05, 0.44, 0.05), 0.01)
		k.box(iron, MK.T(Vector3(x, 0.42, 0)), Vector3(0.05, 0.05, 0.46), 0.01)
		k.box(iron, MK.TR(Vector3(x, 0.68, -0.28), Vector3(-0.2, 0, 0)), Vector3(0.05, 0.5, 0.05), 0.01)
		k.box(iron, MK.T(Vector3(x, 0.62, 0.02)), Vector3(0.06, 0.04, 0.42), 0.015)
		k.box(iron, MK.T(Vector3(x, 0.54, 0.2)), Vector3(0.05, 0.16, 0.05), 0.01)


static func trash_bin(parent: Node3D, pos: Vector3, yaw: float = 0.0) -> void:
	# v0.5: зелёный мусорный контейнер по референсу (уменьшенный — уличный)
	if RPR.has("container"):
		RPR.put(parent, "container", MK.T(pos, yaw), 0.66)
		return
	put(parent, "bin", func(k): _bin(k), MK.T(pos, 0.0))


# большой контейнер (служебный двор)
static func container(parent: Node3D, pos: Vector3, yaw: float = 0.0) -> void:
	if RPR.has("container"):
		RPR.put(parent, "container", MK.T(pos, yaw), 1.0)
	else:
		put(parent, "bin", func(k): _bin(k), MK.T(pos, 0.0))


static func _bin(k) -> void:
	var m := Assets.pbr(Color(0.16, 0.3, 0.2), 0.45, 0.6)
	var ch := m_steel()
	k.lathe(m, MK.T(Vector3.ZERO), PackedVector2Array([Vector2(0, 0.02), Vector2(0.22, 0.02), Vector2(0.27, 0.12), Vector2(0.28, 0.8), Vector2(0.25, 0.8), Vector2(0.25, 0.3), Vector2(0, 0.3)]), 20)
	k.torus(ch, MK.T(Vector3(0, 0.82, 0)), 0.27, 0.025, 20, 6)
	k.torus(ch, MK.T(Vector3(0, 0.45, 0)), 0.285, 0.015, 20, 6)
	k.lathe(ch, MK.T(Vector3(0, 0.86, 0)), PackedVector2Array([Vector2(0.27, 0), Vector2(0.22, 0.12), Vector2(0.08, 0.16), Vector2(0, 0.16)]), 20)


static func planter(parent: Node3D, pos: Vector3, yaw: float, w: float = 2.4, d: float = 1.0) -> void:
	put(parent, "planter_%d_%d" % [int(w * 10), int(d * 10)], func(k): _planter(k, w, d), MK.T(pos, yaw))


static func _planter(k, w: float, d: float) -> void:
	k.box(m_concrete(), MK.T(Vector3(0, 0.3, 0)), Vector3(w, 0.6, d), 0.06, {"seg": 2})
	k.box(Assets.kit_mat("soil"), MK.T(Vector3(0, 0.59, 0)), Vector3(w - 0.16, 0.04, d - 0.16), 0.0)
	var leaf := Assets.pbr(Color(0.16, 0.36, 0.14), 0.8)
	var leaf2 := Assets.pbr(Color(0.22, 0.46, 0.16), 0.8)
	var n := int(w / 0.5)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(w * 100 + d * 7)
	for i in n:
		var x := -w * 0.5 + 0.35 + (w - 0.7) * float(i) / maxf(1.0, float(n - 1))
		var r := rng.randf_range(0.22, 0.34)
		k.sphere(leaf if i % 2 == 0 else leaf2, MK.T(Vector3(x, 0.62 + r * 0.6, rng.randf_range(-0.15, 0.15) * d)), r, 10, 7)
		if rng.randf() < 0.6:
			var fc: Color = [Color(1.0, 0.3, 0.35), Color(1.0, 0.85, 0.2), Color(0.85, 0.4, 1.0), Color(1, 1, 1)][rng.randi_range(0, 3)]
			for j in 4:
				k.sphere(Assets.pbr(fc, 0.6), MK.T(Vector3(x + rng.randf_range(-0.2, 0.2), 0.75 + r + rng.randf_range(-0.1, 0.05), rng.randf_range(-0.2, 0.2) * d)), 0.05, 6, 4)


static func bollard(parent: Node3D, pos: Vector3) -> void:
	put(parent, "bollard", func(k): _b_bollard(k), MK.T(pos))


static func _b_bollard(k) -> void:
	var m := Assets.pbr(Color(0.15, 0.15, 0.17), 0.4, 0.7)
	k.lathe(m, MK.T(Vector3.ZERO), PackedVector2Array([Vector2(0, 0), Vector2(0.12, 0), Vector2(0.11, 0.8), Vector2(0.08, 0.9), Vector2(0, 0.92)]), 14)
	k.torus(m_emit(Color(1.0, 0.8, 0.5), 2.0), MK.T(Vector3(0, 0.78, 0)), 0.112, 0.012, 14, 4)


static func hydrant(parent: Node3D, pos: Vector3) -> void:
	put(parent, "hydrant", func(k): _b_hydrant(k), MK.T(pos))


static func _b_hydrant(k) -> void:
	var m := Assets.pbr(Color(0.75, 0.08, 0.06), 0.4, 0.3)
	k.lathe(m, MK.T(Vector3.ZERO), PackedVector2Array([Vector2(0, 0), Vector2(0.16, 0), Vector2(0.16, 0.06), Vector2(0.11, 0.08), Vector2(0.11, 0.6), Vector2(0.14, 0.62), Vector2(0.12, 0.7), Vector2(0.06, 0.78), Vector2(0, 0.8)]), 14)
	for s: float in [-1.0, 1.0]:
		k.cyl(m, Transform3D(Basis(Vector3.FORWARD, PI / 2.0), Vector3(s * 0.15, 0.45, 0)), 0.045, 0.1, 10)
	k.cyl(m_chrome(), Transform3D(Basis(), Vector3(0, 0.81, 0)), 0.03, 0.04, 8)


# светофор: лампы с общими материалами (переключаются все разом)
static func tl_mat(id: String) -> StandardMaterial3D:
	if not _tl_mats.has(id):
		var c: Color = {"r": Color(1.0, 0.12, 0.08), "y": Color(1.0, 0.7, 0.1), "g": Color(0.2, 1.0, 0.45)}[id]
		var m := StandardMaterial3D.new()
		m.albedo_color = c * 0.3
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = 0.0
		m.roughness = 0.3
		_tl_mats[id] = m
	return _tl_mats[id]


static func set_lights(cars_go: bool, yellow: bool) -> void:
	tl_mat("r").emission_energy_multiplier = 0.0 if (cars_go or yellow) else 4.0
	tl_mat("g").emission_energy_multiplier = 4.0 if cars_go and not yellow else 0.0
	tl_mat("y").emission_energy_multiplier = 4.0 if yellow else 0.0


static func traffic_light(parent: Node3D, pos: Vector3, yaw: float) -> void:
	put(parent, "tlight", func(k): _b_traffic_light(k), MK.T(pos, yaw))


static func _b_traffic_light(k) -> void:
	var m := Assets.pbr(Color(0.1, 0.1, 0.11), 0.45, 0.7)
	k.lathe(m, MK.T(Vector3.ZERO), PackedVector2Array([Vector2(0, 0), Vector2(0.18, 0), Vector2(0.14, 0.12), Vector2(0, 0.12)]), 14)
	k.cyl(m, MK.T(Vector3(0, 2.0, 0)), 0.06, 4.0, 12, {"caps": false})
	k.box(m, MK.T(Vector3(0, 3.7, 0.12)), Vector3(0.34, 1.05, 0.26), 0.06, {"seg": 2})
	var ids := ["r", "y", "g"]
	for i in 3:
		k.cyl(tl_mat(ids[i]), Transform3D(Basis(Vector3.RIGHT, PI / 2.0), Vector3(0, 4.03 - i * 0.32, 0.26)), 0.1, 0.03, 14)
		k.box(m, MK.T(Vector3(0, 4.13 - i * 0.32, 0.31)), Vector3(0.26, 0.03, 0.12), 0.01)


# ------------------------------------------------------------------ остановка, статуя, ящики, грузовик

static func bus_stop(parent: Node3D, pos: Vector3, yaw: float) -> void:
	put(parent, "busstop", func(k): _b_bus_stop(k), MK.T(pos, yaw))


static func _b_bus_stop(k) -> void:
	var fr := Assets.pbr(Color(0.2, 0.22, 0.26), 0.35, 0.85)
	var gl := Assets.pbr(Color(0.7, 0.85, 1.0, 0.25), 0.05, 0.0, {"blend": true})
	for x: float in [-1.9, 1.9]:
		for z: float in [-0.6, 0.6]:
			k.box(fr, MK.T(Vector3(x, 1.25, z)), Vector3(0.08, 2.5, 0.08), 0.02)
	k.box(fr, MK.T(Vector3(0, 2.55, 0)), Vector3(4.2, 0.12, 1.6), 0.05)
	k.box(Assets.pbr(Color(0.85, 0.2, 0.2), 0.4), MK.T(Vector3(0, 2.66, 0)), Vector3(4.0, 0.1, 1.4), 0.04)
	k.box(gl, MK.T(Vector3(0, 1.35, -0.6)), Vector3(3.7, 2.0, 0.02), 0.0)
	k.box(gl, MK.T(Vector3(-1.9, 1.35, 0)), Vector3(0.02, 2.0, 1.1), 0.0)
	k.box(fr, MK.T(Vector3(1.9, 1.3, 0)), Vector3(0.14, 2.1, 1.2), 0.03)
	k.box(Assets.kit_mat("poster_jackpot", {"emit": 0.9, "emit_color": Color(1, 1, 1)}), MK.T(Vector3(1.98, 1.3, 0)), Vector3(0.02, 1.8, 1.0), 0.0)
	for i in 3:
		k.box(m_wood(), MK.T(Vector3(0, 0.48, -0.42 + i * 0.13)), Vector3(3.0, 0.04, 0.11), 0.015)
	for x: float in [-1.3, 1.3]:
		k.box(fr, MK.T(Vector3(x, 0.24, -0.3)), Vector3(0.05, 0.48, 0.3), 0.01)


static func statue(parent: Node3D, pos: Vector3, yaw: float) -> void:
	# v0.5: золотой автомат-статуя по референсу на мраморном постаменте
	if RPR.has("statue"):
		put(parent, "statue_base", func(k): _b_statue_base(k), MK.T(pos, yaw))
		RPR.put(parent, "statue", MK.T(pos + Vector3(0, 1.62, 0), yaw), 2.5 / RPR.size("statue").y)
		return
	put(parent, "statue", func(k): _b_statue(k), MK.T(pos, yaw))


static func _b_statue_base(k) -> void:
	var mb := Assets.kit_mat("marble_white", {"rough": 0.25})
	k.lathe(mb, MK.T(Vector3.ZERO), PackedVector2Array([Vector2(0, 0), Vector2(1.5, 0), Vector2(1.5, 0.25), Vector2(1.3, 0.3), Vector2(1.15, 0.45),
		Vector2(1.0, 0.5), Vector2(1.0, 1.4), Vector2(1.15, 1.5), Vector2(1.2, 1.62), Vector2(0, 1.62)]), 32, {"hard": 0.5})
	k.torus(m_gold(), MK.T(Vector3(0, 1.66, 0)), 1.18, 0.04, 32, 8)


static func _b_statue(k) -> void:
	var mb := Assets.kit_mat("marble_white", {"rough": 0.25})
	var g := m_gold()
	k.lathe(mb, MK.T(Vector3.ZERO), PackedVector2Array([Vector2(0, 0), Vector2(1.5, 0), Vector2(1.5, 0.25), Vector2(1.3, 0.3), Vector2(1.15, 0.45),
		Vector2(1.0, 0.5), Vector2(1.0, 1.4), Vector2(1.15, 1.5), Vector2(1.2, 1.62), Vector2(0, 1.62)]), 32, {"hard": 0.5})
	k.box(g, MK.T(Vector3(0, 2.55, 0)), Vector3(1.3, 1.8, 0.9), 0.14, {"seg": 3})
	k.box(g, MK.T(Vector3(0, 3.6, -0.05)), Vector3(1.4, 0.36, 1.0), 0.16, {"seg": 3})
	k.box(Assets.pbr(Color(0.05, 0.04, 0.03), 0.3, 0.5), MK.T(Vector3(0, 2.8, 0.43)), Vector3(1.0, 0.5, 0.06), 0.04)
	for i in 3:
		k.cyl(g, Transform3D(Basis(Vector3.FORWARD, PI / 2.0), Vector3(-0.3 + i * 0.3, 2.8, 0.36)), 0.2, 0.26, 18, {"bevel": 0.03})
	k.box(g, MK.T(Vector3(0, 2.3, 0.5)), Vector3(1.1, 0.12, 0.25), 0.05)
	k.cyl(g, MK.T(Vector3(0.78, 2.6, 0)), 0.09, 0.3, 14, {"bevel": 0.03})
	k.tube(g, Vector3(0.84, 2.6, 0), Vector3(0.95, 3.5, 0.0), 0.04, 10)
	k.sphere(Assets.pbr(Color(0.85, 0.08, 0.08), 0.2, 0.3, {"clearcoat": 1.0}), MK.T(Vector3(0.96, 3.58, 0)), 0.13, 14, 10)
	k.torus(g, MK.T(Vector3(0, 1.66, 0)), 0.75, 0.05, 28, 8)


static func crate(parent: Node3D, xf: Transform3D, s: float = 0.7) -> MeshInstance3D:
	# v0.5: картонная коробка «ОСТОРОЖНО! ХРУПКОЕ!» по референсу; s — ширина
	if RPR.has("box"):
		return RPR.put(parent, "box", xf, s / RPR.size("box").x)
	return put(parent, "crate_%d" % int(s * 100), func(k): _b_crate(k, s), xf)


# высота коробки шириной s
static func crate_h(s: float) -> float:
	if RPR.has("box"):
		var b := RPR.size("box")
		return b.y * s / b.x
	return s


static func _b_crate(k, s: float) -> void:
	var w := Assets.kit_mat("wood_crate", {"tint": Color(0.92, 0.82, 0.62)})
	var fr := Assets.kit_mat("wood_mid", {"tint": Color(0.75, 0.6, 0.4)})
	k.box(w, MK.T(Vector3(0, s * 0.5, 0)), Vector3(s, s, s) * 0.96, 0.01)
	var e := s * 0.5
	for a in 3:
		for sx: float in [-1.0, 1.0]:
			for sy: float in [-1.0, 1.0]:
				var c := Vector3.ZERO
				var sz := Vector3.ONE * 0.07
				if a == 0:
					c = Vector3(0, e + sx * (e - 0.035), sy * (e - 0.035))
					sz.x = s
				elif a == 1:
					c = Vector3(sx * (e - 0.035), e, sy * (e - 0.035))
					sz.y = s
				else:
					c = Vector3(sx * (e - 0.035), e + sy * (e - 0.035), 0)
					sz.z = s
				k.box(fr, MK.T(c), sz, 0.01)


static func pallet(parent: Node3D, xf: Transform3D) -> void:
	if RPR.has("pallet"):
		RPR.put(parent, "pallet", xf)
		return
	put(parent, "pallet", func(k): _b_pallet(k), xf)


static func pallet_h() -> float:
	return RPR.size("pallet").y if RPR.has("pallet") else 0.14


static func _b_pallet(k) -> void:
	var w := Assets.kit_mat("wood_light", {"tint": Color(0.85, 0.75, 0.55)})
	for i in 5:
		k.box(w, MK.T(Vector3(-0.48 + i * 0.24, 0.13, 0)), Vector3(0.14, 0.025, 1.2), 0.005)
	for z: float in [-0.5, 0.0, 0.5]:
		k.box(w, MK.T(Vector3(0, 0.06, z)), Vector3(1.2, 0.1, 0.12), 0.01)


static func truck(parent: Node3D, xf: Transform3D, title: String = "ДОСТАВКА") -> void:
	put(parent, "truck", func(k): _b_truck(k), xf)
	var lb := Label3D.new()
	lb.text = title
	lb.font = Assets.font_title
	lb.font_size = 96
	lb.pixel_size = 0.01
	lb.modulate = Color(0.15, 0.3, 0.75)
	lb.outline_size = 0
	lb.transform = xf * Transform3D(Basis(), Vector3(-1.0, 2.1, 1.23))
	parent.add_child(lb)
	var lb2 := lb.duplicate() as Label3D
	lb2.transform = xf * Transform3D(Basis(Vector3.UP, PI), Vector3(-1.0, 2.1, -1.23))
	parent.add_child(lb2)


static func _b_truck(k) -> void:
	var pm := m_paint(Color("e8e6e0"))
	var cab := m_paint(Color("2a5ab8"))
	k.box(cab, MK.T(Vector3(3.1, 1.45, 0)), Vector3(1.9, 2.3, 2.3), 0.22, {"seg": 3})
	k.box(m_glass_car(), MK.T(Vector3(4.04, 1.95, 0)), Vector3(0.06, 0.9, 2.0), 0.03)
	for s: float in [-1.0, 1.0]:
		k.box(m_glass_car(), MK.T(Vector3(3.2, 1.95, s * 1.15)), Vector3(1.0, 0.7, 0.04), 0.02)
		k.box(m_emit(Color(1.0, 0.95, 0.85), 2.5), MK.T(Vector3(4.05, 0.85, s * 0.85)), Vector3(0.06, 0.2, 0.3), 0.03)
	k.box(pm, MK.T(Vector3(-1.0, 1.95, 0)), Vector3(6.2, 2.9, 2.44), 0.08)
	k.box(m_dark(), MK.T(Vector3(0.6, 0.55, 0)), Vector3(8.6, 0.3, 1.6), 0.03)
	k.box(m_dark(), MK.T(Vector3(4.1, 0.6, 0)), Vector3(0.3, 0.3, 2.3), 0.08)
	for x: float in [3.0, -1.6, -2.8]:
		for s: float in [-1.0, 1.0]:
			k.cyl(m_rubber(), Transform3D(Basis(Vector3.RIGHT, PI / 2.0), Vector3(x, 0.5, s * 1.0)), 0.5, 0.38, 20, {"bevel": 0.08})
			k.cyl(m_steel(), Transform3D(Basis(Vector3.RIGHT, PI / 2.0), Vector3(x, 0.5, s * 1.2)), 0.28, 0.03, 14)
	for s: float in [-1.0, 1.0]:
		k.box(m_emit(Color(1.0, 0.1, 0.05), 2.0), MK.T(Vector3(-4.12, 0.75, s * 1.0)), Vector3(0.04, 0.15, 0.25), 0.02)
