extends RefCounted
# DecorKit — детальный декор казино на MeshKit: токарные формы, каннелюры, листва с двусторонним
# материалом, стекло, лёд, анимированные рыбки и пузырьки. Каждый предмет — один кэшированный меш.

const MK := preload("res://scripts/kit/mesh_kit.gd")
const KL := preload("res://scripts/kit/kit_lib.gd")
const SK := preload("res://scripts/kit/slot_kit.gd")
const TK := preload("res://scripts/kit/table_kit.gd")


static func m_leaf(c: Color) -> Material:
	return Assets.pbr(c, 0.55, 0.0, {"double": true})


static func m_ice() -> Material:
	return Assets.pbr(Color(0.78, 0.93, 1.0, 0.58), 0.04, 0.0, {"blend": true, "emit": 0.45, "emit_color": Color(0.45, 0.78, 1.0), "clearcoat": 1.0, "rim": 0.7})


static func m_gem() -> Material:
	return Assets.pbr(Color(0.8, 0.96, 1.0, 0.62), 0.02, 0.0, {"blend": true, "emit": 1.1, "emit_color": Color(0.5, 0.9, 1.0), "clearcoat": 1.0, "rim": 1.0})


static func _by(t: Vector3) -> Basis:
	# базис с осью Y вдоль t
	var y := t.normalized()
	var x := Vector3.RIGHT if absf(y.dot(Vector3.RIGHT)) < 0.9 else Vector3.FORWARD
	var z := x.cross(y).normalized()
	x = y.cross(z).normalized()
	return Basis(x, y, z)


static func _leaf(k, m: Material, c: Vector3, dir: Vector3, up: Vector3, L: float, W: float, col: Color) -> void:
	var dn := dir.normalized()
	var side := dn.cross(up).normalized() * W * 0.5
	var lift := up.normalized() * L * 0.06
	var a := c
	var b := c + dn * L * 0.42 + side + lift
	var e := c + dn * L
	var d := c + dn * L * 0.42 - side + lift
	var n := side.cross(dn).normalized()
	if n.dot(up) < 0.0:
		n = -n
	k.quad_n(m, a, b, e, d, n, n, n, n, Vector2(0, 0.5), Vector2(0.5, 0), Vector2(1, 0.5), Vector2(0.5, 1), col)


# ------------------------------------------------------------------ точка входа
static func build(p, did: String, seed_v: int) -> bool:
	var parent: Node3D = p.root
	var lb = p.lb
	match did:
		"ficus":
			KL.inst(parent, KL.cached("dk_ficus_%d" % (seed_v % 3), func(k): _ficus(k, seed_v % 3)), Transform3D.IDENTITY, true)
			lb.add_cyl_collider(Vector3(0, 0.5, 0), 0.32, 1.0)
		"lamp":
			KL.inst(parent, KL.cached("dk_lamp", _lamp), Transform3D.IDENTITY, true)
			lb.add_cyl_collider(Vector3(0, 0.9, 0), 0.2, 1.8)
			p.light(Vector3(0, 1.6, 0), Color("ffd8a0"), 0.6, 4.0)
		"palm":
			KL.inst(parent, KL.cached("dk_palm_%d" % (seed_v % 3), func(k): _palm(k, seed_v % 3)), Transform3D.IDENTITY, true)
			lb.add_cyl_collider(Vector3(0, 0.5, 0), 0.52, 1.0)
		"column":
			KL.inst(parent, KL.cached("dk_column", func(k): _column(k, 5.0)), Transform3D.IDENTITY, true)
			lb.add_cyl_collider(Vector3(0, 2.5, 0), 0.5, 5.0)
		"aqua":
			KL.inst(parent, KL.cached("dk_aqua", _aqua), Transform3D.IDENTITY, true)
			lb.add_collider(Vector3(0, 0.95, 0), Vector3(1.66, 1.9, 0.76))
			var fish := Node3D.new()
			fish.set_script(preload("res://scripts/kit/aqua_fish.gd"))
			fish.name = "Fish"
			parent.add_child(fish)
			p.light(Vector3(0, 1.5, 0.6), Color("5ab0ff"), 0.5, 3.0)
		"statue":
			KL.inst(parent, KL.cached("dk_statue", _statue), Transform3D.IDENTITY, true)
			lb.add_collider(Vector3(0, 0.5, 0), Vector3(1.0, 1.0, 1.0))
			p.label(Vector3(0, 0.48, 0.44), "ФОРТУНА", 16, Color(0.3, 0.22, 0.05), 0.0, {"px": 0.006, "outline": 0})
			p.light(Vector3(0, 2.9, 0.8), Color("ffe0a0"), 0.7, 4.0)
		"fount":
			KL.inst(parent, KL.cached("dk_fount", _fount), Transform3D.IDENTITY, true)
			lb.add_cyl_collider(Vector3(0, 0.4, 0), 0.92, 0.8)
			_fount_fx(p)
		"goldv":
			KL.inst(parent, KL.cached("dk_goldv", _goldv), Transform3D.IDENTITY, true)
			lb.add_collider(Vector3(0, 0.9, 0), Vector3(1.32, 1.8, 0.82))
			p.light(Vector3(0, 2.1, 0.3), Color("ffd890"), 0.8, 3.0)
		"ice":
			KL.inst(parent, KL.cached("dk_ice", _ice), Transform3D.IDENTITY, true)
			lb.add_cyl_collider(Vector3(0, 0.5, 0), 0.62, 1.0)
			p.light(Vector3(0, 0.9, 0.7), Color("8ad0ff"), 0.7, 3.0)
		"diam":
			KL.inst(parent, KL.cached("dk_diam", _diam), Transform3D.IDENTITY, true)
			lb.add_cyl_collider(Vector3(0, 0.5, 0), 0.72, 1.0)
			var gem := KL.inst(parent, KL.cached("dk_gem", _gem), Transform3D(Basis(), Vector3(0, 1.72, 0)), false)
			gem.set_meta("spin", 0.8)
			p.light(Vector3(0, 2.7, 0), Color("7ad8ff"), 1.0, 5.0)
		_:
			return false
	return true


# ------------------------------------------------------------------ фикус
static func _ficus(k, sv: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 300 + sv
	var pot := Assets.pbr(Color(0.93, 0.92, 0.9), 0.2, 0.0, {"clearcoat": 0.8})
	var gold := KL.m_gold()
	var bark := Assets.pbr(Color(0.36, 0.25, 0.16), 0.8)
	k.lathe(pot, MK.T(Vector3.ZERO), PackedVector2Array([Vector2(0, 0), Vector2(0.2, 0), Vector2(0.21, 0.02), Vector2(0.24, 0.1), Vector2(0.29, 0.38),
		Vector2(0.31, 0.46), Vector2(0.3, 0.5), Vector2(0.27, 0.5), Vector2(0.27, 0.46)]), 28)
	k.torus(gold, MK.T(Vector3(0, 0.4, 0)), 0.296, 0.008, 28, 5)
	k.torus(gold, MK.T(Vector3(0, 0.06, 0)), 0.225, 0.006, 24, 5)
	k.cyl(Assets.kit_mat("soil", {}), MK.T(Vector3(0, 0.455, 0)), 0.27, 0.01, 20)
	var trunk := [Vector3(0, 0.44, 0), Vector3(0.03, 0.75, 0.01), Vector3(-0.02, 1.05, 0.02), Vector3(0.01, 1.32, 0.0)]
	k.pipe(bark, trunk, 0.024, 8)
	var tips: Array = []
	for b in 6:
		var a := TAU * float(b) / 6.0 + rng.randf() * 0.5
		var from: Vector3 = (trunk[2] as Vector3).lerp(trunk[3], rng.randf())
		var tip := from + Vector3(cos(a) * 0.32, rng.randf_range(0.12, 0.3), sin(a) * 0.32)
		k.tube(bark, from, tip, 0.012, 6)
		tips.append(tip)
	tips.append(trunk[3])
	var greens := [Color(0.16, 0.42, 0.14), Color(0.22, 0.5, 0.18), Color(0.12, 0.34, 0.12), Color(0.28, 0.56, 0.2)]
	var lm := m_leaf(Color.WHITE)
	for t: Vector3 in tips:
		for q in 16:
			var c := t + Vector3(rng.randf_range(-0.16, 0.16), rng.randf_range(-0.12, 0.14), rng.randf_range(-0.16, 0.16))
			var dir := (c - t + Vector3(rng.randf_range(-0.3, 0.3), -0.1, rng.randf_range(-0.3, 0.3))).normalized()
			if dir.length() < 0.1:
				dir = Vector3.RIGHT
			var col: Color = greens[rng.randi_range(0, greens.size() - 1)]
			_leaf(k, lm, c, dir, Vector3.UP, rng.randf_range(0.09, 0.13), rng.randf_range(0.045, 0.06), col)


# ------------------------------------------------------------------ торшер
static func _lamp(k) -> void:
	var brass := Assets.kit_mat("brass", {})
	k.lathe(brass, MK.T(Vector3.ZERO), PackedVector2Array([Vector2(0, 0), Vector2(0.2, 0), Vector2(0.21, 0.015), Vector2(0.19, 0.04), Vector2(0.09, 0.07),
		Vector2(0.05, 0.1), Vector2(0.03, 0.13), Vector2(0, 0.13)]), 32)
	k.cyl(brass, MK.T(Vector3(0, 0.86, 0)), 0.014, 1.5, 12)
	for y: float in [0.45, 1.1, 1.52]:
		k.torus(brass, MK.T(Vector3(0, y, 0)), 0.02, 0.008, 12, 6)
	k.lathe(brass, MK.T(Vector3(0, 1.5, 0)), PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.03, 0.0), Vector2(0.035, 0.05), Vector2(0.02, 0.08), Vector2(0, 0.08)]), 16)
	var shade := Assets.kit_mat("fabric_white", {"emit": 0.9, "emit_color": Color("ffd8a0"), "double": true})
	k.lathe(shade, MK.T(Vector3.ZERO), PackedVector2Array([Vector2(0.27, 1.47), Vector2(0.255, 1.6), Vector2(0.21, 1.74), Vector2(0.17, 1.83)]), 36)
	k.torus(brass, MK.T(Vector3(0, 1.47, 0)), 0.27, 0.006, 36, 4)
	k.torus(brass, MK.T(Vector3(0, 1.83, 0)), 0.17, 0.005, 30, 4)
	k.sphere(SK.m_glow(), MK.T(Vector3(0, 1.62, 0)), 0.055, 12, 6, {"col": Color(1.0, 0.85, 0.6, 1.0)})
	k.sphere(brass, MK.T(Vector3(0, 1.88, 0)), 0.022, 10, 5)


# ------------------------------------------------------------------ пальма
static func _palm(k, sv: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 500 + sv
	var marble := Assets.kit_mat("marble_white", {})
	var gold := KL.m_gold()
	var bark := Assets.pbr(Color(0.5, 0.38, 0.26), 0.85)
	var ring := Assets.pbr(Color(0.38, 0.28, 0.18), 0.9)
	k.lathe(marble, MK.T(Vector3.ZERO), PackedVector2Array([Vector2(0, 0), Vector2(0.42, 0), Vector2(0.44, 0.04), Vector2(0.4, 0.08), Vector2(0.48, 0.55),
		Vector2(0.53, 0.6), Vector2(0.52, 0.65), Vector2(0.46, 0.65), Vector2(0.46, 0.6)]), 32)
	k.torus(gold, MK.T(Vector3(0, 0.56, 0)), 0.5, 0.01, 32, 5)
	k.cyl(Assets.kit_mat("soil", {}), MK.T(Vector3(0, 0.6, 0)), 0.46, 0.01, 24)
	var lean := Vector3(rng.randf_range(-1, 1), 0, rng.randf_range(-1, 1)).normalized() * 0.18
	var pts: Array = []
	for i in 8:
		var s := float(i) / 7.0
		pts.append(Vector3(0, 0.6 + s * 2.4, 0) + lean * s * s)
	k.pipe(bark, pts, 0.1, 12)
	for i2 in 14:
		var s2 := float(i2) / 14.0
		var idx := mini(int(s2 * 7.0), 6)
		var a: Vector3 = pts[idx]
		var b: Vector3 = pts[idx + 1]
		var c := a.lerp(b, s2 * 7.0 - float(idx))
		k.torus(ring, Transform3D(_by(b - a), c), 0.104 - s2 * 0.02, 0.014, 12, 4)
	var top: Vector3 = pts[7]
	var lm := m_leaf(Color.WHITE)
	var greens := [Color(0.18, 0.46, 0.16), Color(0.24, 0.54, 0.2), Color(0.14, 0.38, 0.14)]
	var rib := Assets.pbr(Color(0.3, 0.42, 0.16), 0.7)
	for f in 9:
		var a2 := TAU * float(f) / 9.0 + rng.randf() * 0.3
		var hd := Vector3(cos(a2), 0, sin(a2))
		var lift := rng.randf_range(0.25, 0.5)
		var L := rng.randf_range(1.3, 1.6)
		var rp: Array = []
		for j in 9:
			var s3 := float(j) / 8.0
			rp.append(top + hd * (L * s3) + Vector3.UP * (lift * s3 - (lift + 0.75) * s3 * s3))
		k.pipe(rib, rp, 0.012, 5)
		var side := hd.cross(Vector3.UP).normalized()
		for j2 in range(1, 9):
			var s4 := float(j2) / 8.0
			var c2: Vector3 = rp[j2]
			var ll := 0.38 * (1.0 - 0.55 * s4)
			var col: Color = greens[(f + j2) % greens.size()]
			for sg: float in [-1.0, 1.0]:
				var dir := (side * sg * 0.8 + hd * 0.35 + Vector3.DOWN * (0.25 + 0.4 * s4)).normalized()
				_leaf(k, lm, c2, dir, Vector3.UP, ll, 0.075, col)
	for q in 3:
		var aq := TAU * float(q) / 3.0
		k.sphere(Assets.pbr(Color(0.32, 0.2, 0.1), 0.6), MK.T(top + Vector3(cos(aq) * 0.09, -0.06, sin(aq) * 0.09)), 0.06, 10, 6)


# ------------------------------------------------------------------ колонна с каннелюрами
static func _column(k, h: float) -> void:
	var marble := Assets.kit_mat("marble_white", {})
	var gold := KL.m_gold()
	var r := 0.36
	k.box_mm(marble, Vector3(-0.55, 0, -0.55), Vector3(0.55, 0.18, 0.55), 0.02)
	k.lathe(marble, MK.T(Vector3.ZERO), PackedVector2Array([Vector2(0.5, 0.18), Vector2(0.5, 0.22), Vector2(0.46, 0.26), Vector2(0.47, 0.3), Vector2(0.42, 0.33), Vector2(0.4, 0.38), Vector2(r, 0.4)]), 40)
	k.torus(gold, MK.T(Vector3(0, 0.3, 0)), 0.47, 0.012, 40, 5)
	var poly := PackedVector2Array()
	for f in 24:
		for j in 4:
			var a := TAU * (float(f) + float(j) / 4.0) / 24.0
			var rr := r if j == 0 else r * (0.965 - 0.025 * sin(PI * float(j) / 4.0))
			poly.append(Vector2(cos(a) * rr, sin(a) * rr))
	k.extrude(marble, Transform3D.IDENTITY, poly, 0.4, h - 0.55, {"caps": false})
	k.lathe(marble, MK.T(Vector3.ZERO), PackedVector2Array([Vector2(r, h - 0.55), Vector2(0.39, h - 0.52), Vector2(0.37, h - 0.47), Vector2(0.41, h - 0.4),
		Vector2(0.48, h - 0.3), Vector2(0.55, h - 0.24), Vector2(0.56, h - 0.2)]), 40)
	k.torus(gold, MK.T(Vector3(0, h - 0.5, 0)), 0.39, 0.014, 40, 5)
	k.torus(gold, MK.T(Vector3(0, h - 0.3, 0)), 0.485, 0.01, 40, 5)
	k.box_mm(marble, Vector3(-0.6, h - 0.2, -0.6), Vector3(0.6, h, 0.6), 0.02)
	k.box_mm(gold, Vector3(-0.61, h - 0.13, -0.61), Vector3(0.61, h - 0.1, 0.61), 0.008)


# ------------------------------------------------------------------ аквариум
static func _aqua(k) -> void:
	var wood := Assets.kit_mat("wood_dark", {})
	var wood2 := Assets.kit_mat("wood_red", {})
	var chrome := KL.m_chrome()
	var dark := KL.m_dark()
	var brass := Assets.kit_mat("brass", {})
	k.box_mm(wood, Vector3(-0.82, 0, -0.37), Vector3(0.82, 0.8, 0.37), 0.02)
	for sx: float in [-1.0, 1.0]:
		var x0 := 0.04 * sx
		var x1 := 0.78 * sx
		k.box_mm(wood2, Vector3(minf(x0, x1), 0.08, 0.365), Vector3(maxf(x0, x1), 0.72, 0.385), 0.01)
		k.sphere(brass, MK.T(Vector3(0.1 * sx, 0.42, 0.395)), 0.018, 10, 5)
	k.box_mm(dark, Vector3(-0.8, 0.8, -0.35), Vector3(0.8, 0.83, 0.35), 0.0)
	# каркас аквариума
	var y0 := 0.8
	var y1 := 1.8
	for e in [[Vector3(-0.8, y0, -0.35), Vector3(-0.78, y1, -0.33)], [Vector3(0.78, y0, -0.35), Vector3(0.8, y1, -0.33)],
			[Vector3(-0.8, y0, 0.33), Vector3(-0.78, y1, 0.35)], [Vector3(0.78, y0, 0.33), Vector3(0.8, y1, 0.35)],
			[Vector3(-0.8, y1 - 0.02, -0.35), Vector3(0.8, y1, -0.33)], [Vector3(-0.8, y1 - 0.02, 0.33), Vector3(0.8, y1, 0.35)],
			[Vector3(-0.8, y0, 0.33), Vector3(0.8, y0 + 0.04, 0.35)], [Vector3(-0.8, y0, -0.35), Vector3(0.8, y0 + 0.04, -0.33)]]:
		k.box_mm(chrome, e[0], e[1], 0.004)
	# дно: песок, камни, сундук с золотом, водоросли
	var sand := Assets.pbr(Color(0.86, 0.76, 0.55), 0.95)
	k.box_mm(sand, Vector3(-0.78, 0.83, -0.33), Vector3(0.78, 0.88, 0.33), 0.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	for q in 9:
		var c := Vector3(rng.randf_range(-0.7, 0.7), 0.88, rng.randf_range(-0.28, 0.25))
		var sc := Vector3(rng.randf_range(0.6, 1.4), rng.randf_range(0.3, 0.7), rng.randf_range(0.6, 1.2))
		var col := Color(0.5, 0.5, 0.52) if q % 3 else Color(0.62, 0.45, 0.35)
		k.sphere(Assets.pbr(col, 0.8), Transform3D(Basis().scaled(sc), c), rng.randf_range(0.03, 0.07), 7, 4)
	var chest := Vector3(0.42, 0.88, -0.12)
	k.box_mm(Assets.pbr(Color(0.4, 0.24, 0.1), 0.7), chest + Vector3(-0.12, 0, -0.08), chest + Vector3(0.12, 0.11, 0.08), 0.01)
	k.box(Assets.pbr(Color(0.4, 0.24, 0.1), 0.7), Transform3D(Basis(Vector3.RIGHT, -0.9), chest + Vector3(0, 0.15, -0.1)), Vector3(0.24, 0.02, 0.16), 0.006)
	for c3 in 7:
		k.cyl(KL.m_gold(), MK.T(chest + Vector3(rng.randf_range(-0.09, 0.09), 0.115 + rng.randf() * 0.02, rng.randf_range(-0.05, 0.05))), 0.018, 0.005, 12)
	for c4 in 6:
		k.cyl(KL.m_gold(), MK.T(chest + Vector3(0.16 + rng.randf_range(-0.03, 0.06), 0.003 + c4 * 0.0055, 0.06)), 0.018, 0.005, 12)
	var weed := [Color(0.1, 0.5, 0.2), Color(0.2, 0.6, 0.15), Color(0.5, 0.15, 0.3)]
	for w in 7:
		var bx := rng.randf_range(-0.72, 0.2)
		var bz := rng.randf_range(-0.28, 0.1)
		var hh := rng.randf_range(0.35, 0.75)
		var pts: Array = []
		for j in 7:
			var s := float(j) / 6.0
			pts.append(Vector3(bx + sin(s * 5.0 + w) * 0.03, 0.88 + s * hh, bz + cos(s * 4.0 + w) * 0.02))
		k.pipe(Assets.pbr(weed[w % weed.size()], 0.6), pts, 0.012, 5)
	# вода и стекло
	k.box_mm(Assets.pbr(Color(0.45, 0.75, 1.0, 0.22), 0.05, 0.0, {"blend": true, "emit": 0.25, "emit_color": Color(0.2, 0.55, 1.0)}), Vector3(-0.78, 0.84, -0.33), Vector3(0.78, 1.72, 0.33), 0.0)
	k.panel(TK.m_glass_t(), Transform3D(Basis(), Vector3(0, 1.3, 0.345)), 1.58, 0.96)
	# крышка с подсветкой
	k.box_mm(Assets.pbr(Color(0.06, 0.06, 0.07), 0.3, 0.2), Vector3(-0.84, 1.8, -0.38), Vector3(0.84, 1.93, 0.38), 0.015)
	k.box_mm(SK.m_glow(), Vector3(-0.76, 1.785, -0.3), Vector3(0.76, 1.8, 0.3), 0.0, {"col": Color(0.5, 0.8, 1.0, 1.0)})


# ------------------------------------------------------------------ статуя Фортуны
static func _statue(k) -> void:
	var marble := Assets.kit_mat("marble_white", {})
	var gold := Assets.pbr(Color(1.0, 0.78, 0.32), 0.22, 1.0, {"clearcoat": 0.6})
	k.box_mm(marble, Vector3(-0.5, 0, -0.5), Vector3(0.5, 0.12, 0.5), 0.02)
	k.box_mm(marble, Vector3(-0.42, 0.12, -0.42), Vector3(0.42, 0.9, 0.42), 0.015)
	k.box_mm(marble, Vector3(-0.48, 0.9, -0.48), Vector3(0.48, 1.0, 0.48), 0.02)
	k.box_mm(KL.m_gold(), Vector3(-0.26, 0.4, 0.42), Vector3(0.26, 0.56, 0.432), 0.005)
	# фигура
	k.lathe(gold, MK.T(Vector3.ZERO), PackedVector2Array([Vector2(0, 1.0), Vector2(0.3, 1.0), Vector2(0.31, 1.03), Vector2(0.27, 1.12), Vector2(0.22, 1.4),
		Vector2(0.17, 1.65), Vector2(0.14, 1.82), Vector2(0.15, 1.92), Vector2(0.16, 2.02), Vector2(0.13, 2.12), Vector2(0.07, 2.18), Vector2(0.045, 2.22), Vector2(0.04, 2.27), Vector2(0, 2.27)]), 28)
	# складки одеяния
	for f in 10:
		var a := TAU * float(f) / 10.0
		k.tube(gold, Vector3(cos(a) * 0.285, 1.03, sin(a) * 0.285), Vector3(cos(a) * 0.15, 1.78, sin(a) * 0.15), 0.018, 6)
	k.sphere(gold, MK.T(Vector3(0, 2.36, 0)), 0.1, 18, 10)
	k.sphere(gold, MK.T(Vector3(0, 2.41, -0.07)), 0.055, 12, 6)
	k.torus(Assets.pbr(Color(0.85, 0.1, 0.1), 0.4), Transform3D(Basis(Vector3.RIGHT, 0.12), Vector3(0, 2.38, 0.0)), 0.098, 0.014, 20, 5)
	# правая рука с колесом удачи
	var sh_r := Vector3(0.14, 2.12, 0.0)
	var el_r := Vector3(0.28, 2.24, 0.06)
	var ha_r := Vector3(0.33, 2.44, 0.06)
	k.pipe(gold, [sh_r, el_r, ha_r], 0.032, 8)
	var wc := ha_r + Vector3(0.0, 0.18, 0.0)
	var wb := Basis(Vector3.RIGHT, PI * 0.5)
	k.torus(gold, Transform3D(wb, wc), 0.17, 0.014, 32, 6)
	for s in 8:
		var a2 := TAU * float(s) / 8.0
		k.tube(gold, wc, wc + Vector3(cos(a2) * 0.17, sin(a2) * 0.17, 0), 0.007, 5)
		k.sphere(gold, MK.T(wc + Vector3(cos(a2) * 0.19, sin(a2) * 0.19, 0)), 0.016, 8, 4)
	k.sphere(gold, MK.T(wc), 0.028, 10, 5)
	# левая рука с рогом изобилия
	var sh_l := Vector3(-0.14, 2.12, 0.0)
	var el_l := Vector3(-0.27, 1.96, 0.08)
	var ha_l := Vector3(-0.29, 1.8, 0.15)
	k.pipe(gold, [sh_l, el_l, ha_l], 0.03, 8)
	var horn := [ha_l + Vector3(0.05, -0.08, -0.06), ha_l + Vector3(0.0, 0.0, 0.0), ha_l + Vector3(-0.08, 0.1, 0.06), ha_l + Vector3(-0.12, 0.24, 0.12)]
	for i in 3:
		var a3: Vector3 = horn[i]
		var b3: Vector3 = horn[i + 1]
		var r0 := 0.02 + float(i) * 0.03
		k.cyl(gold, Transform3D(_by(b3 - a3), (a3 + b3) * 0.5), r0, a3.distance_to(b3), 14, {"r_top": r0 + 0.03, "caps": false})
	var mouth: Vector3 = horn[3]
	for c in 6:
		k.cyl(KL.m_gold(), Transform3D(Basis(Vector3.RIGHT, 0.5 + c * 0.3), mouth + Vector3(0.03 * cos(c * 1.3), 0.02 + 0.01 * c, 0.03 * sin(c * 1.3))), 0.022, 0.006, 12)


# ------------------------------------------------------------------ фонтан
static func _fount(k) -> void:
	var marble := Assets.kit_mat("marble_white", {})
	var gold := KL.m_gold()
	var water := Assets.pbr(Color(0.55, 0.8, 1.0, 0.7), 0.03, 0.0, {"blend": true, "emit": 0.5, "emit_color": Color(0.35, 0.65, 1.0), "clearcoat": 1.0})
	k.lathe(marble, MK.T(Vector3.ZERO), PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.9, 0.0), Vector2(0.92, 0.04), Vector2(0.88, 0.08), Vector2(0.86, 0.5),
		Vector2(0.92, 0.56), Vector2(0.94, 0.62), Vector2(0.9, 0.66), Vector2(0.8, 0.66), Vector2(0.78, 0.6), Vector2(0.76, 0.3), Vector2(0.0, 0.3)]), 48)
	k.torus(gold, MK.T(Vector3(0, 0.56, 0)), 0.925, 0.01, 48, 5)
	k.cyl(water, MK.T(Vector3(0, 0.52, 0)), 0.78, 0.01, 48)
	# стойка и чаши
	k.lathe(marble, MK.T(Vector3.ZERO), PackedVector2Array([Vector2(0.22, 0.3), Vector2(0.2, 0.4), Vector2(0.12, 0.5), Vector2(0.1, 0.9), Vector2(0.14, 0.98),
		Vector2(0.09, 1.04), Vector2(0.08, 1.5), Vector2(0.11, 1.56), Vector2(0.06, 1.62), Vector2(0.05, 1.95)]), 28)
	k.lathe(marble, MK.T(Vector3.ZERO), PackedVector2Array([Vector2(0.1, 0.98), Vector2(0.3, 1.0), Vector2(0.5, 1.06), Vector2(0.55, 1.12), Vector2(0.52, 1.14),
		Vector2(0.46, 1.1), Vector2(0.1, 1.06)]), 40)
	k.cyl(water, MK.T(Vector3(0, 1.1, 0)), 0.47, 0.01, 40)
	k.lathe(marble, MK.T(Vector3.ZERO), PackedVector2Array([Vector2(0.08, 1.56), Vector2(0.2, 1.58), Vector2(0.3, 1.63), Vector2(0.33, 1.68), Vector2(0.3, 1.7),
		Vector2(0.26, 1.66), Vector2(0.08, 1.62)]), 32)
	k.cyl(water, MK.T(Vector3(0, 1.65, 0)), 0.26, 0.01, 32)
	# золотой кубик на вершине
	var die := Transform3D(Basis(Vector3.UP, 0.6) * Basis(Vector3(1, 0, 1).normalized(), 0.62), Vector3(0, 2.1, 0))
	k.box(gold, die, Vector3(0.24, 0.24, 0.24), 0.035)
	for f in [[Vector3.UP, 1], [Vector3.BACK, 2], [Vector3.RIGHT, 3]]:
		var n: Vector3 = f[0]
		var cnt: int = f[1]
		var u := Vector3.RIGHT if n != Vector3.RIGHT else Vector3.BACK
		var v := n.cross(u)
		var spots: Array = {1: [[0, 0]], 2: [[-1, -1], [1, 1]], 3: [[-1, -1], [0, 0], [1, 1]]}[cnt]
		for sp in spots:
			var pc := n * 0.12 + u * float(sp[0]) * 0.06 + v * float(sp[1]) * 0.06
			k.sphere(KL.m_dark(), die * Transform3D(Basis(), pc), 0.022, 8, 4)
	# монетки на дне
	var rng := RandomNumberGenerator.new()
	rng.seed = 9
	for c in 18:
		var a := rng.randf() * TAU
		var rr := rng.randf_range(0.3, 0.72)
		k.cyl(gold, Transform3D(Basis(Vector3(rng.randf(), 0, rng.randf()).normalized() if rng.randf() < 0.5 else Vector3.UP, rng.randf_range(0.0, 0.4)), Vector3(cos(a) * rr, 0.31, sin(a) * rr)), 0.02, 0.005, 10)


static func _fount_fx(p) -> void:
	var ps := CPUParticles3D.new()
	var pm := SphereMesh.new()
	pm.radius = 0.025
	pm.height = 0.05
	pm.radial_segments = 6
	pm.rings = 3
	ps.mesh = pm
	ps.material_override = Assets.cmat(Color(0.7, 0.9, 1.0), {"emit": 1.0, "emit_color": Color(0.6, 0.85, 1.0), "unshaded": true})
	ps.amount = 70
	ps.lifetime = 1.1
	ps.direction = Vector3(0, 1, 0)
	ps.spread = 30.0
	ps.initial_velocity_min = 1.6
	ps.initial_velocity_max = 2.2
	ps.gravity = Vector3(0, -6.5, 0)
	ps.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	ps.emission_sphere_radius = 0.05
	p.nodes.add_child(ps)
	ps.position = Vector3(0, 1.95, 0)
	p.light(Vector3(0, 1.2, 0), Color("5ab0ff"), 1.0, 6.0)


# ------------------------------------------------------------------ золотая витрина
static func _goldv(k) -> void:
	var wood := Assets.kit_mat("wood_dark", {})
	var gold := Assets.pbr(Color(1.0, 0.8, 0.35), 0.18, 1.0, {"clearcoat": 0.5})
	var chrome := KL.m_chrome()
	var velvet := Assets.pbr(Color(0.45, 0.04, 0.08), 0.9)
	k.box_mm(wood, Vector3(-0.65, 0, -0.4), Vector3(0.65, 0.9, 0.4), 0.02)
	k.box_mm(KL.m_gold(), Vector3(-0.66, 0.86, -0.41), Vector3(0.66, 0.9, 0.41), 0.008)
	k.box_mm(velvet, Vector3(-0.6, 0.9, -0.35), Vector3(0.6, 0.93, 0.35), 0.01)
	# пирамида слитков
	var rows := [5, 4, 3, 2]
	for L in rows.size():
		var n: int = rows[L]
		for i in n:
			var x := (float(i) - float(n - 1) * 0.5) * 0.17
			var y := 0.93 + 0.035 + float(L) * 0.062
			var z := -0.05 if L % 2 == 0 else 0.0
			k.extrude(gold, Transform3D(Basis(Vector3(1, 0, 0), Vector3(0, 0, -1), Vector3(0, 1, 0)), Vector3(0, y - 0.03, z)),
				PackedVector2Array([Vector2(x - 0.075, 0.0), Vector2(x + 0.075, 0.0), Vector2(x + 0.06, 0.058), Vector2(x - 0.06, 0.058)]), -0.045, 0.045, {"bottom": true})
	# столбики монет
	for q in 4:
		var cx := -0.48 + float(q % 2) * 0.96
		var cz := -0.22 + float(q / 2) * 0.44
		for c in 6 + q * 2:
			k.cyl(gold, MK.T(Vector3(cx, 0.935 + float(c) * 0.0062, cz)), 0.04, 0.006, 16, {"bevel": 0.001})
	# стеклянный колпак
	var y0 := 0.93
	var y1 := 1.75
	for e in [[Vector3(-0.62, y0, -0.37), Vector3(-0.6, y1, -0.35)], [Vector3(0.6, y0, -0.37), Vector3(0.62, y1, -0.35)],
			[Vector3(-0.62, y0, 0.35), Vector3(-0.6, y1, 0.37)], [Vector3(0.6, y0, 0.35), Vector3(0.62, y1, 0.37)],
			[Vector3(-0.62, y1, -0.37), Vector3(0.62, y1 + 0.03, 0.37)]]:
		k.box_mm(chrome, e[0], e[1], 0.004)
	var g := TK.m_glass_t()
	k.panel(g, Transform3D(Basis(), Vector3(0, (y0 + y1) * 0.5, 0.36)), 1.2, y1 - y0)
	k.panel(g, Transform3D(Basis(Vector3.UP, PI), Vector3(0, (y0 + y1) * 0.5, -0.36)), 1.2, y1 - y0)
	k.panel(g, Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(0.61, (y0 + y1) * 0.5, 0)), 0.72, y1 - y0)
	k.panel(g, Transform3D(Basis(Vector3.UP, -PI * 0.5), Vector3(-0.61, (y0 + y1) * 0.5, 0)), 0.72, y1 - y0)


# ------------------------------------------------------------------ ледяной лебедь
static func _ice(k) -> void:
	var marble := Assets.kit_mat("marble_white", {})
	var chrome := KL.m_chrome()
	var ice := m_ice()
	k.lathe(marble, MK.T(Vector3.ZERO), PackedVector2Array([Vector2(0, 0), Vector2(0.6, 0), Vector2(0.62, 0.04), Vector2(0.56, 0.1), Vector2(0.52, 0.5),
		Vector2(0.58, 0.55), Vector2(0.6, 0.6), Vector2(0, 0.6)]), 36)
	k.lathe(chrome, MK.T(Vector3.ZERO), PackedVector2Array([Vector2(0, 0.6), Vector2(0.5, 0.6), Vector2(0.53, 0.64), Vector2(0.51, 0.65), Vector2(0.47, 0.62), Vector2(0, 0.615)]), 36)
	k.sphere(ice, Transform3D(Basis().scaled(Vector3(1.0, 0.58, 0.62)), Vector3(-0.04, 0.88, 0)), 0.36, 20, 12)
	k.pipe(ice, [Vector3(0.22, 0.95, 0), Vector3(0.31, 1.2, 0), Vector3(0.24, 1.45, 0), Vector3(0.27, 1.64, 0), Vector3(0.38, 1.7, 0)], 0.05, 10)
	k.sphere(ice, MK.T(Vector3(0.38, 1.69, 0)), 0.07, 14, 8)
	k.cyl(ice, Transform3D(Basis(Vector3(0, 0, 1), -PI * 0.5), Vector3(0.48, 1.67, 0)), 0.026, 0.11, 10, {"r_top": 0.003})
	var xz := Basis(Vector3(1, 0, 0), Vector3(0, 0, -1), Vector3(0, 1, 0))
	for sz: float in [-1.0, 1.0]:
		var wb := Basis(Vector3.RIGHT, -0.32 * sz) * xz
		k.extrude(ice, Transform3D(wb, Vector3(0, 0, 0.2 * sz)), PackedVector2Array([Vector2(-0.42, 0.95), Vector2(0.14, 0.92), Vector2(0.06, 1.12),
			Vector2(-0.12, 1.32), Vector2(-0.3, 1.38), Vector2(-0.5, 1.22)]), -0.025, 0.025, {"bottom": true})
	k.extrude(ice, Transform3D(xz, Vector3.ZERO), PackedVector2Array([Vector2(-0.36, 0.86), Vector2(-0.52, 0.98), Vector2(-0.5, 1.06), Vector2(-0.34, 0.96)]), -0.06, 0.06, {"bottom": true})


# ------------------------------------------------------------------ гигантский бриллиант
static func _diam(k) -> void:
	var marble := Assets.kit_mat("marble_black", {})
	var gold := KL.m_gold()
	var brass := Assets.kit_mat("brass", {})
	k.lathe(marble, MK.T(Vector3.ZERO), PackedVector2Array([Vector2(0, 0), Vector2(0.7, 0), Vector2(0.72, 0.04), Vector2(0.66, 0.1), Vector2(0.55, 0.16),
		Vector2(0.5, 0.85), Vector2(0.56, 0.9), Vector2(0.62, 0.96), Vector2(0.62, 1.0), Vector2(0, 1.0)]), 40)
	k.torus(gold, MK.T(Vector3(0, 0.16, 0)), 0.55, 0.012, 40, 5)
	k.torus(gold, MK.T(Vector3(0, 0.9, 0)), 0.56, 0.012, 40, 5)
	k.lathe(KL.m_chrome(), MK.T(Vector3.ZERO), PackedVector2Array([Vector2(0.0, 1.0), Vector2(0.16, 1.0), Vector2(0.12, 1.08), Vector2(0.0, 1.1)]), 24)
	# стойки с бархатным канатом
	var posts: Array = []
	for q in 4:
		var a := TAU * (float(q) + 0.5) / 4.0
		posts.append(Vector3(cos(a) * 0.92, 0, sin(a) * 0.92))
	for pp: Vector3 in posts:
		k.lathe(brass, MK.T(pp), PackedVector2Array([Vector2(0, 0), Vector2(0.13, 0), Vector2(0.14, 0.02), Vector2(0.11, 0.04), Vector2(0.03, 0.07),
			Vector2(0.02, 0.1), Vector2(0.02, 0.9), Vector2(0.034, 0.93), Vector2(0.042, 0.97), Vector2(0.03, 1.0), Vector2(0, 1.01)]), 18)
	var rope := Assets.pbr(Color(0.6, 0.04, 0.1), 0.85)
	for q2 in 4:
		var A: Vector3 = posts[q2] + Vector3(0, 0.92, 0)
		var B: Vector3 = posts[(q2 + 1) % 4] + Vector3(0, 0.92, 0)
		if q2 == 1:
			continue
		var pts: Array = []
		for j in 9:
			var s := float(j) / 8.0
			pts.append(A.lerp(B, s) + Vector3(0, -0.16 * 4.0 * s * (1.0 - s), 0))
		k.pipe(rope, pts, 0.018, 8)


static func _gem(k) -> void:
	# огранка «кругляш»: павильон, рундист, корона и площадка; 8 граней — видны фасеты
	k.lathe(m_gem(), MK.T(Vector3.ZERO), PackedVector2Array([Vector2(0, -0.42), Vector2(0.38, 0.0), Vector2(0.38, 0.03), Vector2(0.27, 0.16), Vector2(0.17, 0.2), Vector2(0, 0.2)]), 8, {"hard": 0.0})
