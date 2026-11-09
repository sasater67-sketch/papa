extends "res://scripts/kit/props.gd"



const WheelFace := preload("res://scripts/kit/wheel_face.gd")
const RouletteWheel := preload("res://scripts/kit/roulette_wheel.gd")
const FortuneWheel := preload("res://scripts/kit/fortune_wheel.gd")

var wheels := {}
var screens := {}
var jackpot_labels: Array = []
var water_mats: Array = []


func slot_machine(pos: Vector3, yaw: float, front: String, marquee: String, title: String, side: Color, stool_col: Color = Color("8a1a2a")) -> void:
	var q = P(pos, yaw)
	q.box(Vector3(0, 0.82, 0), Vector3(0.78, 1.64, 0.62), front, {"uv": "front", "side_tint": side, "mat": {"emit": 0.35}})
	q.box(Vector3(0, 1.8, -0.04), Vector3(0.82, 0.32, 0.52), marquee, {"uv": "fit", "mat": {"emit": 1.4, "unshaded": true}})
	q.box(Vector3(0, 0.9, 0.36), Vector3(0.74, 0.07, 0.14), "plastic_black")
	q.box(Vector3(0, 0.03, 0), Vector3(0.84, 0.06, 0.68), "chrome")
	q.box(Vector3(0.43, 1.25, 0.05), Vector3(0.06, 0.06, 0.06), "chrome")
	q.box(Vector3(0.43, 1.0, 0.05), Vector3(0.03, 0.5, 0.03), "chrome")
	q.box(Vector3(0.43, 1.28, 0.05), Vector3(0.1, 0.1, 0.1), "plastic_red", {"mat": {"emit": 0.4, "emit_color": Color(1, 0.2, 0.2)}})
	q.solid(Vector3(0, 1.0, 0), Vector3(0.8, 2.0, 0.64))
	stool(q.p(Vector3(0, 0, 0.75)), stool_col, 0.7)
	if title != "":
		label(q.p(Vector3(0, 2.08, 0.0)), title, 16, Color(1.6, 1.5, 1.2), yaw, {"px": 0.0075, "outline": 4})


func mega_slot(pos: Vector3, yaw: float) -> void:
	var q = P(pos, yaw)
	q.box(Vector3(0, 1.35, 0), Vector3(1.5, 2.7, 0.9), "slot_mega", {"uv": "front", "side_tint": Color("4a1a6a"), "mat": {"emit": 0.45}})
	q.box(Vector3(0, 3.05, -0.05), Vector3(1.8, 0.7, 0.7), "marquee_gold", {"uv": "fit", "mat": {"emit": 1.6, "unshaded": true}})
	q.box(Vector3(0, 0.05, 0.1), Vector3(1.7, 0.1, 1.2), "gold", {"mat": {"metal": 0.7, "rough": 0.3}})
	for sx in [-0.85, 0.85]:
		q.box(Vector3(sx, 1.6, 0.1), Vector3(0.12, 3.2, 0.12), "gold", {"mat": {"emit": 0.8, "emit_color": Color(1, 0.8, 0.3)}})
	q.solid(Vector3(0, 1.6, 0), Vector3(1.6, 3.2, 0.95))
	stool(q.p(Vector3(0, 0, 0.95)), Color("ffd84a"), 0.7)
	label(q.p(Vector3(0, 3.62, 0.0)), "МЕГА ДЖЕКПОТ", 24, Color(2.2, 1.8, 0.6), yaw, {"px": 0.01})
	var jl := label(q.p(Vector3(0, 3.05, 0.31)), "5 000", 32, Color(2.4, 2.4, 2.4), yaw, {"px": 0.011, "outline": 8, "outline_col": Color(0.4, 0.1, 0.0)})
	jackpot_labels.append(jl)
	light(q.p(Vector3(0, 2.5, 1.2)), Color("ffcc55"), 1.2, 5.0)



func card_table(pos: Vector3, yaw: float, felt: String, w: float = 2.5, d: float = 1.35, seats: int = 3, rail: Color = Color("4a1a12"), dealer_look: Dictionary = {}, tray_x: float = 0.0, with_shoe: bool = true) -> void:
	var q = P(pos, yaw)
	q.box(Vector3(0, 0.38, -0.05), Vector3(w * 0.7, 0.76, d * 0.55), "wood_dark")
	q.box(Vector3(0, 0.8, 0), Vector3(w + 0.16, 0.1, d + 0.16), "leather", {"tint": rail})
	q.box(Vector3(0, 0.05, -0.05), Vector3(w * 0.8, 0.1, d * 0.7), "wood_dark")
	lb.floor_plane(q.p(Vector3(0, 0.852, 0)), w, d, felt, {"rot": yaw, "tiles": Vector2.ONE, "mat": {"rough": 1.0}})
	q.box(Vector3(0, 0.88, d / 2 + 0.04), Vector3(w + 0.16, 0.08, 0.12), "leather", {"tint": rail.lightened(0.1)})

	q.box(Vector3(tray_x, 0.87, -d / 2 + 0.12), Vector3(0.9, 0.04, 0.18), "wood_mid")
	var cols := ["chip_red", "chip_blue", "chip_green", "chip_black", "chip_purple"]
	for i in 5:
		lb.cyl(q.p(Vector3(tray_x - 0.36 + i * 0.18, 0.92, -d / 2 + 0.12)), 0.06, 0.07 + (i % 3) * 0.02, cols[i], {"sides": 8, "collide": false, "top_fit": true})

	if with_shoe:
		q.box(Vector3(w / 2 - 0.35, 0.92, -d / 2 + 0.25), Vector3(0.22, 0.1, 0.32), "plastic_red", {"tint": Color(0.6, 0.1, 0.1)})
	q.solid(Vector3(0, 0.45, 0), Vector3(w + 0.16, 0.9, d + 0.16))
	for i in seats:
		var sx := (float(i) - (seats - 1) / 2.0) * (w / seats)
		stool(q.p(Vector3(sx, 0, d / 2 + 0.55)), Color("6a1a2a"), 0.72)
	if not dealer_look.is_empty():
		npc(q.p(Vector3(0, 0, -d / 2 - 0.45)), yaw, dealer_look, "deal")


func roulette_table(pos: Vector3, yaw: float, felt: String, station_id: String, vip: bool = false, dealer_look: Dictionary = {}) -> void:
	var w := 3.0
	var d := 1.4
	var q = P(pos, yaw)
	var rail := Color("3a1a0a") if not vip else Color("1a1a1a")
	q.box(Vector3(0.3, 0.38, 0), Vector3(w * 0.8, 0.76, d * 0.6), "wood_dark")
	q.box(Vector3(0.3, 0.8, 0), Vector3(w + 0.16, 0.1, d + 0.16), "leather", {"tint": rail})
	lb.floor_plane(q.p(Vector3(0.3, 0.852, 0)), w, d, felt, {"rot": yaw, "tiles": Vector2.ONE})
	q.box(Vector3(0.3, 0.88, d / 2 + 0.04), Vector3(w + 0.16, 0.08, 0.12), "leather", {"tint": rail.lightened(0.12)})

	var wc := Vector3(-w / 2 - 0.35, 0.0, 0)
	q.box(wc + Vector3(0, 0.42, 0), Vector3(1.2, 0.84, 1.2), "wood_dark")
	lb.cyl(q.p(wc + Vector3(0, 0.9, 0)), 0.62, 0.14, "wood_red", {"sides": 16, "collide": false})
	q.solid(Vector3(0, 0.45, 0), Vector3(w + 1.6, 0.9, d + 0.16))
	var wheel := Node3D.new()
	wheel.set_script(RouletteWheel)
	wheel.name = "Wheel_" + station_id.replace("#", "_")
	nodes.add_child(wheel)
	wheel.position = q.p(wc + Vector3(0, 0.985, 0))
	var face := WheelFace.roulette_mesh(0.54)
	wheel.add_child(face)
	var hub := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.06
	cm.bottom_radius = 0.1
	cm.height = 0.14
	cm.radial_segments = 8
	hub.mesh = cm
	hub.material_override = Assets.mat("gold", {"metal": 0.8, "rough": 0.3})
	hub.position.y = 0.06
	wheel.add_child(hub)
	wheels[station_id] = wheel
	for i in 4:
		var sx := -0.7 + i * 0.7
		stool(q.p(Vector3(sx + 0.3, 0, d / 2 + 0.55)), Color("6a1a2a") if not vip else Color("1a1a1a"), 0.72)
	if not dealer_look.is_empty():
		npc(q.p(Vector3(-0.6, 0, -d / 2 - 0.45)), yaw, dealer_look, "deal")


func craps_table(pos: Vector3, yaw: float, dealer_look: Dictionary = {}) -> void:
	var w := 3.2
	var d := 1.5
	var q = P(pos, yaw)
	q.box(Vector3(0, 0.38, 0), Vector3(w * 0.8, 0.76, d * 0.6), "wood_dark")
	q.box(Vector3(0, 0.8, 0), Vector3(w + 0.2, 0.1, d + 0.2), "leather", {"tint": Color("2a1a10")})
	lb.floor_plane(q.p(Vector3(0, 0.852, 0)), w, d, "felt_craps", {"rot": yaw, "tiles": Vector2.ONE})
	for s in [-1, 1]:
		q.box(Vector3(0, 0.98, s * (d / 2 + 0.06)), Vector3(w + 0.2, 0.3, 0.1), "wood_red")
	for s in [-1, 1]:
		q.box(Vector3(s * (w / 2 + 0.06), 0.98, 0), Vector3(0.1, 0.3, d + 0.2), "wood_red")
	q.solid(Vector3(0, 0.55, 0), Vector3(w + 0.3, 1.1, d + 0.3))
	for i in 4:
		stool(q.p(Vector3(-1.2 + i * 0.8, 0, d / 2 + 0.6)), Color("6a1a2a"), 0.72)
	if not dealer_look.is_empty():
		npc(q.p(Vector3(0, 0, -d / 2 - 0.45)), yaw, dealer_look, "deal")


func kiosk(pos: Vector3, yaw: float, screen: String, title: String, col: Color) -> void:
	var q = P(pos, yaw)
	q.box(Vector3(0, 0.5, 0), Vector3(0.7, 1.0, 0.5), "metal_dark", {"tint": col.darkened(0.5)})
	q.box(Vector3(0, 0.03, 0), Vector3(0.9, 0.06, 0.7), "chrome")
	q.box(Vector3(0, 1.3, -0.05), Vector3(0.82, 0.62, 0.12), "plastic_black", {"rot": 0.0})
	q.plane(Vector3(0, 1.3, 0.012), 0.72, 0.54, screen, {"mat": {"emit": 1.3, "unshaded": true}})
	q.box(Vector3(0, 1.02, 0.12), Vector3(0.6, 0.06, 0.3), "plastic_black")
	q.box(Vector3(0, 1.7, -0.05), Vector3(0.86, 0.14, 0.14), "white", {"tint": col, "mat": {"emit": 1.6, "emit_color": col, "unshaded": true}})
	q.solid(Vector3(0, 0.8, 0), Vector3(0.9, 1.6, 0.6))
	label(q.p(Vector3(0, 1.92, -0.05)), title, 20, Color(col.r * 2, col.g * 2, col.b * 2), yaw, {"px": 0.0085})
	light(q.p(Vector3(0, 1.4, 0.7)), col, 0.5, 2.8)


func atm(pos: Vector3, yaw: float) -> void:
	var q = P(pos, yaw)
	q.box(Vector3(0, 0.95, 0), Vector3(0.9, 1.9, 0.6), "atm_front", {"uv": "front", "side_tint": Color("1a3a8a"), "mat": {"emit": 0.5}})
	q.box(Vector3(0, 2.0, 0.05), Vector3(0.96, 0.22, 0.5), "white", {"tint": Color("2a6ad8"), "mat": {"emit": 1.4, "emit_color": Color("4a8aff"), "unshaded": true}})
	q.solid(Vector3(0, 1.0, 0), Vector3(0.9, 2.1, 0.6))
	label(q.p(Vector3(0, 2.0, 0.31)), "БАНКОМАТ", 16, Color(2.2, 2.2, 2.2), yaw, {"px": 0.008})
	light(q.p(Vector3(0, 1.6, 0.7)), Color("6aa0ff"), 0.6, 3.0)


func plinko_machine(pos: Vector3, yaw: float) -> void:
	var q = P(pos, yaw)
	q.box(Vector3(0, 0.4, 0), Vector3(1.8, 0.8, 0.7), "plastic_black", {"tint": Color("2a1a4a")})
	q.box(Vector3(0, 1.85, -0.2), Vector3(1.9, 2.3, 0.3), "metal_dark", {"tint": Color("3a2a6a")})
	q.box(Vector3(0, 1.85, -0.04), Vector3(1.7, 2.1, 0.02), "white", {"tint": Color("140a2a")})
	var rows := 10
	for r in rows:
		for k in r + 3:
			var x := (k - (r + 2) / 2.0) * 0.14
			q.box(Vector3(x, 2.75 - r * 0.17, -0.01), Vector3(0.035, 0.035, 0.04), "white", {"mat": {"emit": 1.5, "emit_color": Color(0.8, 0.9, 1.0), "unshaded": true}})
	var mcol := [Color("ff2a4a"), Color("ff8a2a"), Color("ffd84a"), Color("4aff7a"), Color("4ad8ff")]
	for k in 13:
		var x := (k - 6) * 0.13
		var ci: int = mini(absi(k - 6), 4)
		q.box(Vector3(x, 0.98, 0.0), Vector3(0.11, 0.14, 0.04), "white", {"tint": mcol[4 - ci], "mat": {"emit": 1.4, "emit_color": mcol[4 - ci], "unshaded": true}})
	q.box(Vector3(0, 3.15, -0.15), Vector3(2.0, 0.36, 0.4), "marquee_purple", {"uv": "fit", "mat": {"emit": 1.5, "unshaded": true}})
	q.solid(Vector3(0, 1.6, -0.05), Vector3(1.9, 3.2, 0.75))
	label(q.p(Vector3(0, 3.15, 0.06)), "ПЛИНКО", 28, Color(2.4, 2.0, 2.4), yaw, {"px": 0.01})
	light(q.p(Vector3(0, 2.0, 0.9)), Color("b06aff"), 0.9, 4.0)


func claw_machine(pos: Vector3, yaw: float, col: Color) -> void:
	var q = P(pos, yaw)
	q.box(Vector3(0, 0.45, 0), Vector3(1.0, 0.9, 1.0), "plastic_white", {"tint": col})
	q.box(Vector3(0, 0.6, 0.505), Vector3(0.3, 0.2, 0.01), "plastic_black")
	q.box(Vector3(0.25, 0.95, 0.42), Vector3(0.05, 0.12, 0.05), "chrome")
	q.box(Vector3(0.25, 1.03, 0.42), Vector3(0.09, 0.09, 0.09), "plastic_red")
	q.box(Vector3(-0.2, 0.95, 0.44), Vector3(0.1, 0.03, 0.1), "plastic_white", {"tint": Color("4aff7a"), "mat": {"emit": 1.0, "emit_color": Color("4aff7a")}})

	q.box(Vector3(0, 1.55, 0), Vector3(0.98, 1.3, 0.98), "white", {"mat": {"blend": true, "tint": Color(0.7, 0.9, 1.0, 0.18), "rough": 0.1}, "skip": ["bottom"]})
	for sx in [-0.48, 0.48]:
		for sz in [-0.48, 0.48]:
			q.box(Vector3(sx, 1.55, sz), Vector3(0.05, 1.3, 0.05), "chrome")
	q.box(Vector3(0, 2.3, 0), Vector3(1.04, 0.22, 1.04), "plastic_white", {"tint": col.lightened(0.2), "mat": {"emit": 0.9, "emit_color": col}})
	var prize_cols := [Color("c88a4a"), Color("f4f0e8"), Color("ffd84a"), Color("ff9a5a"), Color("6aff8a"), Color("c8c8ff"), Color("ff6a8a")]
	for i in 14:
		var px := rng.randf_range(-0.38, 0.3)
		var pz := rng.randf_range(-0.38, 0.38)
		q.box(Vector3(px, 0.98 + rng.randf() * 0.16, pz), Vector3(0.16, 0.16, 0.16), "fabric", {"tint": prize_cols[i % prize_cols.size()], "rot": rng.randf() * 2.0})
	q.box(Vector3(0.36, 1.05, 0.36), Vector3(0.24, 0.3, 0.24), "plastic_black")
	q.box(Vector3(0.1, 2.12, 0.05), Vector3(0.04, 0.3, 0.04), "chrome")
	q.box(Vector3(0.1, 1.94, 0.05), Vector3(0.16, 0.06, 0.16), "chrome")
	q.solid(Vector3(0, 1.2, 0), Vector3(1.0, 2.4, 1.0))
	label(q.p(Vector3(0, 2.3, 0.53)), "ХВАТАЙКА", 16, Color(2.2, 2.2, 2.2), yaw, {"px": 0.008})
	light(q.p(Vector3(0, 1.6, 0)), col, 0.5, 2.5)



func big_screen(pos: Vector3, yaw: float, w: float, h: float, vp: SubViewport) -> MeshInstance3D:
	var q = P(pos, yaw)
	q.box(Vector3(0, 0, -0.06), Vector3(w + 0.3, h + 0.3, 0.12), "plastic_black")
	q.box(Vector3(0, h / 2 + 0.2, -0.04), Vector3(w + 0.4, 0.1, 0.16), "gold", {"mat": {"emit": 1.0, "emit_color": Color(1, 0.8, 0.3)}})
	q.box(Vector3(0, -h / 2 - 0.2, -0.04), Vector3(w + 0.4, 0.1, 0.16), "gold", {"mat": {"emit": 1.0, "emit_color": Color(1, 0.8, 0.3)}})
	var mi := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(w, h)
	mi.mesh = qm
	var m := StandardMaterial3D.new()
	m.albedo_texture = vp.get_texture()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	m.emission_enabled = true
	m.emission_texture = vp.get_texture()
	m.emission_energy_multiplier = 0.35
	mi.material_override = m
	nodes.add_child(mi)
	mi.position = q.p(Vector3(0, 0, 0.005))
	mi.rotation.y = yaw
	light(q.p(Vector3(0, 0, 1.5)), Color("8ab8ff"), 0.9, 6.0)
	return mi


func big_wheel(pos: Vector3, yaw: float, radius: float) -> Node3D:
	var q = P(pos, yaw)

	q.box(Vector3(0, radius * 0.5 + 0.3, -0.35), Vector3(0.5, radius + 0.6, 0.3), "gold", {"mat": {"metal": 0.6, "rough": 0.35}})
	q.box(Vector3(0, 0.25, -0.2), Vector3(radius * 1.6, 0.5, 1.2), "marble_black")
	q.box(Vector3(0, 0.52, -0.2), Vector3(radius * 1.6 + 0.1, 0.04, 1.3), "gold")
	q.solid(Vector3(0, radius + 0.4, -0.2), Vector3(radius * 2.2, radius * 2 + 0.8, 1.2))
	var wheel := Node3D.new()
	wheel.set_script(FortuneWheel)
	wheel.name = "FortuneWheel"
	wheel.yaw = yaw
	nodes.add_child(wheel)
	wheel.position = q.p(Vector3(0, radius + 0.7, 0))
	var face := WheelFace.big_wheel_mesh(radius)
	wheel.add_child(face)
	wheel.add_child(_wheel_rim(radius))

	var ptr := MeshInstance3D.new()
	var pm := PrismMesh.new()
	pm.size = Vector3(0.36, 0.5, 0.12)
	ptr.mesh = pm
	ptr.material_override = Assets.cmat(Color("ffd84a"), {"metal": 0.5, "rough": 0.3, "emit": 0.6, "emit_color": Color("ffb82a")})
	nodes.add_child(ptr)
	ptr.position = q.p(Vector3(0, radius * 2 + 0.85, 0.12))
	ptr.rotation = Vector3(0, yaw, PI)
	wheel.pointer = ptr
	for i in 16:
		var a := TAU * i / 16.0
		var bulb := q.p(Vector3(cos(a) * (radius + 0.12), radius + 0.7 + sin(a) * (radius + 0.12), 0.06))
		lb.box(bulb, Vector3(0.1, 0.1, 0.1), "white", {"collide": false, "mat": {"emit": 2.5, "emit_color": Color("ffe08a"), "unshaded": true}})
	light(q.p(Vector3(0, radius + 0.7, 2.0)), Color("ffd08a"), 1.4, 7.0)
	return wheel



func _wheel_rim(radius: float) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n: int = 51
	var sides := 64
	for i in sides:
		var a0 := TAU * i / sides
		var a1 := TAU * (i + 1) / sides
		var r0 := radius
		var r1 := radius + 0.08
		var quads := [
			[Vector3(sin(a0) * r1, cos(a0) * r1, -0.12), Vector3(sin(a1) * r1, cos(a1) * r1, -0.12), Vector3(sin(a1) * r1, cos(a1) * r1, 0.06), Vector3(sin(a0) * r1, cos(a0) * r1, 0.06)],
			[Vector3(sin(a0) * r0, cos(a0) * r0, 0.06), Vector3(sin(a0) * r1, cos(a0) * r1, 0.06), Vector3(sin(a1) * r1, cos(a1) * r1, 0.06), Vector3(sin(a1) * r0, cos(a1) * r0, 0.06)],
		]
		for qd in quads:
			var nm: Vector3 = (qd[1] - qd[0]).cross(qd[2] - qd[0]).normalized()
			for k in [0, 1, 2, 0, 2, 3]:
				st.set_normal(-nm)
				st.set_color(Color(1, 0.85, 0.4))
				st.add_vertex(qd[k])
	for i in n:
		var a := TAU * (i + 0.5) / n
		var c := Vector3(sin(a) * (radius - 0.04), cos(a) * (radius - 0.04), 0.04)
		var s := 0.025
		var pts := [Vector3(-s, -s, 0), Vector3(s, -s, 0), Vector3(s, s, 0), Vector3(-s, s, 0)]
		for k in [0, 1, 2, 0, 2, 3]:
			st.set_normal(Vector3(0, 0, 1))
			st.set_color(Color(1, 1, 0.9))
			st.add_vertex(c + pts[k] + Vector3(0, 0, 0.05))
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.albedo_color = Color("e0b040")
	m.metallic = 0.7
	m.roughness = 0.3
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = m
	return mi


func fountain(c: Vector3, r: float) -> void:
	lb.cyl(c + Vector3(0, 0.3, 0), r, 0.6, "marble_white", {"sides": 20, "cap": false})
	lb.cyl(c + Vector3(0, 0.62, 0), r + 0.12, 0.08, "marble_white", {"sides": 20, "collide": false, "tint": Color(0.95, 0.92, 0.85)})
	lb.cyl(c + Vector3(0, 0.62, 0), r - 0.25, 0.09, "marble_white", {"sides": 20, "collide": false, "side": true, "cap": false})
	var wm := Assets.mat("water", {"emit": 0.5, "emit_color": Color(0.4, 0.7, 1.0), "rough": 0.05, "spec": 0.8, "blend": true, "tint": Color(0.7, 0.85, 1.0, 0.85)})
	water_mats.append(wm)
	lb.cyl(c + Vector3(0, 0.45, 0), r - 0.12, 0.05, "water", {"sides": 20, "collide": false, "material": wm, "side": false})

	var chips := ["chip_red", "chip_black", "chip_purple", "chip_green"]
	for i in 4:
		lb.cyl(c + Vector3(0, 0.75 + i * 0.32, 0), 0.9 - i * 0.12, 0.3, chips[i], {"sides": 16, "collide": i == 0, "top_fit": true})
	lb.box(c + Vector3(0, 2.38, 0), Vector3(0.8, 0.8, 0.8), "gold", {"rot": PI / 4, "mat": {"metal": 0.8, "rough": 0.25, "emit": 0.25, "emit_color": Color(1, 0.8, 0.3)}})
	light(c + Vector3(0, 1.2, 0), Color("5ab0ff"), 1.0, 6.0)
	var ps := CPUParticles3D.new()
	var pm := BoxMesh.new()
	pm.size = Vector3(0.06, 0.06, 0.06)
	ps.mesh = pm
	ps.material_override = Assets.cmat(Color(0.7, 0.9, 1.0), {"emit": 1.0, "emit_color": Color(0.6, 0.85, 1.0), "unshaded": true})
	ps.amount = 90
	ps.lifetime = 1.4
	ps.direction = Vector3(0, 1, 0)
	ps.spread = 25.0
	ps.initial_velocity_min = 3.0
	ps.initial_velocity_max = 4.0
	ps.gravity = Vector3(0, -6.5, 0)
	ps.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	ps.emission_sphere_radius = 0.1
	nodes.add_child(ps)
	ps.position = c + Vector3(0, 2.8, 0)


func bottle(pos: Vector3, col: Color, h: float = 0.32) -> void:
	lb.cyl(pos + Vector3(0, h * 0.35, 0), 0.045, h * 0.7, "glass", {"sides": 6, "tint": col, "collide": false, "mat": {"rough": 0.15, "emit": 0.25, "emit_color": col}})
	lb.cyl(pos + Vector3(0, h * 0.82, 0), 0.018, h * 0.3, "glass", {"sides": 5, "tint": col.darkened(0.2), "collide": false})


func bar_counter(a: Vector3, length: float, yaw: float, top_tex: String = "marble_black") -> void:

	var q = P(a, yaw)
	q.box(Vector3(0, 0.55, 0), Vector3(length, 1.1, 0.7), "wood_red")
	q.box(Vector3(0, 1.13, 0.05), Vector3(length + 0.1, 0.06, 0.9), top_tex, {"mat": {"rough": 0.3, "spec": 0.6}})
	q.box(Vector3(0, 0.12, 0.36), Vector3(length, 0.06, 0.06), "brass")
	q.box(Vector3(0, 0.9, 0.36), Vector3(length, 0.04, 0.02), "gold", {"mat": {"emit": 0.8, "emit_color": Color(1, 0.75, 0.3)}})
	q.solid(Vector3(0, 0.6, 0.05), Vector3(length + 0.1, 1.2, 0.9))
	var n := int(length / 1.0)
	for i in n:
		stool(q.p(Vector3(-length / 2 + 0.5 + i * length / n, 0, 0.85)), Color("8a1a2a"), 0.8)

	for i in 3:
		q.box(Vector3(-length / 4 + i * 0.25, 1.32, -0.15), Vector3(0.05, 0.32, 0.05), "chrome")
		q.box(Vector3(-length / 4 + i * 0.25, 1.5, -0.15), Vector3(0.08, 0.1, 0.08), "plastic_black", {"tint": [Color("e0b040"), Color("3a1a0a"), Color("c8c8c8")][i]})
	for i in 5:
		lb.cyl(q.p(Vector3(length / 4 + i * 0.16, 1.21, 0.1)), 0.04, 0.1, "glass", {"sides": 6, "tint": Color(0.8, 0.9, 1.0), "collide": false})


func back_shelf(a: Vector3, length: float, yaw: float) -> void:
	var q = P(a, yaw)
	q.box(Vector3(0, 1.6, 0), Vector3(length, 3.0, 0.35), "wood_dark")
	q.box(Vector3(0, 1.8, 0.16), Vector3(length - 0.3, 2.2, 0.02), "chrome", {"mat": {"metal": 1.0, "rough": 0.15}})
	var cols := [Color("3a8a3a"), Color("8a3a1a"), Color("d8b060"), Color("6a1a3a"), Color("c8c8e8"), Color("2a4a8a"), Color("e8a020")]
	for s in 4:
		var y := 0.9 + s * 0.6
		q.box(Vector3(0, y - 0.03, 0.22), Vector3(length - 0.2, 0.04, 0.3), "glass", {"tint": Color(0.8, 0.9, 1.0), "mat": {"emit": 0.6, "emit_color": Color(1, 0.8, 0.5)}})
		var x := -length / 2 + 0.25
		while x < length / 2 - 0.2:
			bottle(q.p(Vector3(x, y, 0.22)), cols[rng.randi() % cols.size()], rng.randf_range(0.26, 0.38))
			x += rng.randf_range(0.12, 0.2)
	q.box(Vector3(0, 0.45, 0.1), Vector3(length, 0.9, 0.55), "wood_red")
	q.solid(Vector3(0, 1.6, 0.1), Vector3(length, 3.2, 0.55))


func dining_table(c: Vector3, col: Color, chairs: int = 4) -> void:
	lb.cyl(c + Vector3(0, 0.76, 0), 0.75, 0.05, "fabric_white", {"sides": 14, "collide": false})
	lb.cyl(c + Vector3(0, 0.6, 0), 0.78, 0.3, "fabric_white", {"sides": 14, "cap": false, "collide": false, "radius_top": 0.76, "tint": Color(0.95, 0.93, 0.9)})
	lb.cyl(c + Vector3(0, 0.38, 0), 0.06, 0.76, "wood_dark", {"sides": 6, "collide": false})
	lb.add_cyl_collider(c + Vector3(0, 0.4, 0), 0.78, 0.8)
	for i in chairs:
		var a := TAU * i / chairs + PI / 4
		var d := Vector3(cos(a), 0, sin(a))
		chair(c + d * 1.05, atan2(-d.x, -d.z) + PI, col)
		lb.cyl(c + d * 0.45 + Vector3(0, 0.79, 0), 0.16, 0.02, "plastic_white", {"sides": 10, "collide": false})
		lb.cyl(c + d * 0.45 + Vector3(0, 0.81, 0), 0.09, 0.03, "plastic_white", {"sides": 8, "collide": false, "tint": [Color("d86a3a"), Color("8ad84a"), Color("e8c86a"), Color("c83a3a")][i % 4]})
		lb.cyl(c + d * 0.5 + d.rotated(Vector3.UP, 0.6) * 0.15 + Vector3(0, 0.86, 0), 0.03, 0.16, "glass", {"sides": 6, "tint": Color(0.9, 0.95, 1.0), "collide": false})
	lb.cyl(c + Vector3(0, 0.86, 0), 0.03, 0.18, "white", {"sides": 6, "collide": false, "tint": Color(1, 0.95, 0.85)})
	lb.box(c + Vector3(0, 0.98, 0), Vector3(0.04, 0.06, 0.04), "white", {"collide": false, "mat": {"emit": 3.0, "emit_color": Color(1, 0.7, 0.3), "unshaded": true}})
	light(c + Vector3(0, 1.1, 0), Color("ffb060"), 0.35, 2.2)


func piano(pos: Vector3, yaw: float) -> void:
	var q = P(pos, yaw)
	q.box(Vector3(0, 0.75, -0.2), Vector3(1.5, 0.35, 1.6), "plastic_black", {"mat": {"rough": 0.15, "spec": 0.8}})
	q.box(Vector3(0.2, 1.25, -0.4), Vector3(1.3, 0.04, 1.3), "plastic_black", {"rot": 0.0, "mat": {"rough": 0.15}})
	q.box(Vector3(0, 0.85, 0.66), Vector3(1.4, 0.08, 0.22), "plastic_white")
	for i in 14:
		q.box(Vector3(-0.6 + i * 0.095, 0.9, 0.62), Vector3(0.04, 0.03, 0.12), "plastic_black")
	for sx in [-0.6, 0.6]:
		q.box(Vector3(sx, 0.3, -0.6), Vector3(0.1, 0.6, 0.1), "plastic_black")
	q.box(Vector3(0, 0.3, 0.5), Vector3(0.1, 0.6, 0.1), "plastic_black")
	q.box(Vector3(0, 0.25, 1.05), Vector3(0.8, 0.5, 0.35), "leather_black")
	q.solid(Vector3(0, 0.6, -0.1), Vector3(1.6, 1.3, 1.9))


func jukebox(pos: Vector3, yaw: float) -> void:
	var q = P(pos, yaw)
	q.box(Vector3(0, 0.7, 0), Vector3(0.9, 1.4, 0.6), "wood_red")
	q.box(Vector3(0, 1.5, 0), Vector3(0.9, 0.3, 0.6), "white", {"tint": Color("ff6a2a"), "mat": {"emit": 1.8, "emit_color": Color("ff8a3a"), "unshaded": true}})
	q.box(Vector3(0, 0.95, 0.305), Vector3(0.6, 0.4, 0.01), "glass", {"tint": Color(0.6, 0.8, 1), "mat": {"emit": 0.9, "emit_color": Color(0.5, 0.8, 1.0)}})
	for i in 5:
		q.box(Vector3(-0.3 + i * 0.15, 0.4, 0.31), Vector3(0.08, 0.5, 0.01), "white", {"tint": Color.from_hsv(i * 0.18, 0.8, 1.0), "mat": {"emit": 1.5, "emit_color": Color.from_hsv(i * 0.18, 0.8, 1.0), "unshaded": true}})
	q.solid(Vector3(0, 0.8, 0), Vector3(0.9, 1.65, 0.6))
	label(q.p(Vector3(0, 1.85, 0)), "МУЗЫКА", 16, Color(2.2, 1.5, 0.8), yaw, {"px": 0.008})
	light(q.p(Vector3(0, 1.0, 0.8)), Color("ff8a3a"), 0.6, 3.0)


func money_stack(pos: Vector3, nx: int, nz: int, ny: int, yaw: float = 0.0) -> void:
	var q = P(pos, yaw)
	for i in nx:
		for j in nz:
			var h := 0.12 * (ny - ((i + j) % 2))
			q.box(Vector3(i * 0.36, h / 2, j * 0.18), Vector3(0.34, h, 0.16), "money_side", {"uv": "world"})
			q.box(Vector3(i * 0.36, h + 0.001, j * 0.18), Vector3(0.34, 0.002, 0.16), "money_top", {"uv": "fit"})


func gold_pile(pos: Vector3, n: int = 10) -> void:
	var k := 0
	for layer in 3:
		for i in maxi(1, n - layer * 3):
			if k >= n * 2:
				return
			var x := (i - (n - layer * 3) / 2.0) * 0.26 + layer * 0.13
			lb.box(pos + Vector3(x, 0.06 + layer * 0.12, 0), Vector3(0.24, 0.12, 0.12), "gold", {"collide": false, "mat": {"metal": 0.85, "rough": 0.25, "emit": 0.15, "emit_color": Color(1, 0.8, 0.3)}})
			k += 1
