extends RefCounted



const LevelBuilder := preload("res://scripts/kit/level_builder.gd")
const Prop := preload("res://scripts/kit/prop.gd")
const Character := preload("res://scripts/kit/character.gd")

const RPR := preload("res://scripts/kit/ref_props.gd")
var lb
var root: Node3D
var nodes: Node3D
var interacts: Node3D
var npcs: Array = []
var anim_nodes: Array = []
var rng := RandomNumberGenerator.new()
var light_count := 0


func _setup(parent: Node3D) -> void:
	root = parent
	lb = LevelBuilder.new(parent, "Static")
	nodes = Node3D.new()
	nodes.name = "Nodes"
	parent.add_child(nodes)
	interacts = Node3D.new()
	interacts.name = "Interacts"
	parent.add_child(interacts)
	rng.seed = 777


func P(pos: Vector3, yaw: float = 0.0):
	return Prop.new(lb, pos, yaw)



func light(pos: Vector3, col: Color, energy: float = 1.0, rng_m: float = 6.0, shadow: bool = false) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.position = pos
	l.light_color = col
	l.light_energy = energy
	l.omni_range = rng_m
	l.omni_attenuation = 1.1
	l.shadow_enabled = shadow
	l.light_specular = 0.25
	nodes.add_child(l)
	light_count += 1
	return l


func spot(pos: Vector3, target: Vector3, col: Color, energy: float = 2.0, rng_m: float = 10.0, angle: float = 35.0, shadow: bool = false) -> SpotLight3D:
	var l := SpotLight3D.new()
	l.light_color = col
	l.light_energy = energy
	l.spot_range = rng_m
	l.spot_angle = angle
	l.shadow_enabled = shadow
	nodes.add_child(l)
	l.position = pos
	l.look_at_from_position(pos, target, Vector3.UP if absf((target - pos).normalized().y) < 0.99 else Vector3.FORWARD)
	light_count += 1
	return l


func label(pos: Vector3, text: String, size: int = 32, col: Color = Game.C_GOLD, yaw: float = 0.0, opts: Dictionary = {}) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font = Assets.font_title if opts.get("title", true) else Assets.font_body
	l.font_size = size
	l.pixel_size = opts.get("px", 0.01)
	l.modulate = col
	l.outline_size = opts.get("outline", 6)
	l.outline_modulate = opts.get("outline_col", Color(0, 0, 0, 0.8))
	l.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	l.double_sided = false
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED if opts.get("billboard", false) else BaseMaterial3D.BILLBOARD_DISABLED
	l.horizontal_alignment = opts.get("align", HORIZONTAL_ALIGNMENT_CENTER)
	l.width = opts.get("width", 500.0)
	if opts.has("width"):
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.position = pos
	l.rotation.y = yaw
	nodes.add_child(l)
	return l



func neon(pos: Vector3, text: String, col: Color, yaw: float = 0.0, size: int = 48, with_light: bool = true) -> Label3D:
	var l := label(pos, text, size, Color(col.r * 2.2, col.g * 2.2, col.b * 2.2), yaw, {"outline": 10, "outline_col": Color(col.r * 0.5, col.g * 0.5, col.b * 0.5, 0.9), "px": 0.012})
	if with_light:
		light(pos + Basis(Vector3.UP, yaw) * Vector3(0, 0, 0.6), col, 0.8, 4.0)
	return l


func interact(center: Vector3, size: Vector3, kind: String, data: Dictionary = {}, prompt: String = "", rot: float = 0.0) -> Area3D:
	var a := Area3D.new()
	a.collision_layer = Game.L_INTERACT
	a.collision_mask = 0
	a.monitoring = false
	a.monitorable = true
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	cs.shape = bs
	a.add_child(cs)
	a.position = center
	a.rotation.y = rot
	a.set_meta("kind", kind)
	a.set_meta("data", data)
	a.set_meta("prompt", prompt)
	interacts.add_child(a)
	return a


func npc(pos: Vector3, yaw: float, look: Dictionary, anim: String = "idle", tag_text: String = "", tag_col: Color = Game.C_INFO) -> Node3D:
	var c := Node3D.new()
	c.set_script(Character)
	nodes.add_child(c)
	c.position = pos
	c.rotation.y = yaw
	c.build(look)
	c.anim = anim
	if tag_text != "":
		c.add_tag(tag_text, tag_col)
	npcs.append(c)
	return c


func mesh(m: Mesh, mat: Material, pos: Vector3, rot: Vector3 = Vector3.ZERO, parent: Node3D = null) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = m
	mi.material_override = mat
	(parent if parent else nodes).add_child(mi)
	mi.position = pos
	mi.rotation = rot
	return mi



func bed(pos: Vector3, yaw: float, blanket: Color) -> void:
	var q = P(pos, yaw)

	q.box(Vector3(0, 0.2, 0), Vector3(1.9, 0.3, 2.15), "wood_dark")
	q.box(Vector3(0, 0.45, 0.05), Vector3(1.8, 0.2, 2.0), "fabric_white", {"tint": Color(0.98, 0.97, 0.94)})
	q.box(Vector3(0, 0.57, 0.35), Vector3(1.84, 0.06, 1.4), "fabric", {"tint": blanket})
	q.box(Vector3(0, 0.45, 1.06), Vector3(1.84, 0.26, 0.04), "fabric", {"tint": blanket.darkened(0.15)})
	q.box(Vector3(0, 0.75, -1.05), Vector3(2.0, 1.1, 0.12), "leather", {"tint": blanket.darkened(0.45)})
	q.box(Vector3(0, 1.32, -1.05), Vector3(2.04, 0.06, 0.16), "wood_dark")
	for sx in [-0.45, 0.45]:
		q.box(Vector3(sx, 0.62, -0.75), Vector3(0.7, 0.14, 0.38), "fabric_white")
	q.solid(Vector3(0, 0.3, 0), Vector3(1.9, 0.6, 2.15))
	q.solid(Vector3(0, 0.7, -1.05), Vector3(2.0, 1.4, 0.15))


func nightstand(pos: Vector3, yaw: float, lamp_col: Color = Color("ffd8a0")) -> void:
	var q = P(pos, yaw)
	q.box(Vector3(0, 0.28, 0), Vector3(0.5, 0.56, 0.45), "wood_mid")
	q.box(Vector3(0, 0.36, 0.226), Vector3(0.38, 0.12, 0.01), "wood_dark")
	q.box(Vector3(0, 0.37, 0.232), Vector3(0.08, 0.03, 0.02), "gold")
	q.box(Vector3(0, 0.62, 0), Vector3(0.12, 0.12, 0.12), "brass")
	q.box(Vector3(0, 0.8, 0), Vector3(0.28, 0.24, 0.28), "fabric_white", {"mat": {"emit": 0.7, "emit_color": lamp_col}})
	q.solid(Vector3(0, 0.28, 0), Vector3(0.5, 0.56, 0.45))
	light(q.p(Vector3(0, 1.0, 0.1)), lamp_col, 0.55, 3.5)


func wardrobe(pos: Vector3, yaw: float) -> void:
	var q = P(pos, yaw)
	q.box(Vector3(0, 1.1, 0), Vector3(1.6, 2.2, 0.62), "wood_mid")
	q.box(Vector3(-0.4, 1.12, 0.315), Vector3(0.76, 2.0, 0.02), "wood_light")
	q.box(Vector3(0.4, 1.12, 0.315), Vector3(0.76, 2.0, 0.02), "wood_light")
	q.box(Vector3(-0.06, 1.1, 0.335), Vector3(0.03, 0.3, 0.03), "gold")
	q.box(Vector3(0.06, 1.1, 0.335), Vector3(0.03, 0.3, 0.03), "gold")
	q.box(Vector3(0, 2.23, 0), Vector3(1.66, 0.06, 0.66), "wood_dark")
	q.solid(Vector3(0, 1.1, 0), Vector3(1.6, 2.2, 0.62))


func desk(pos: Vector3, yaw: float, with_chair: bool = true) -> void:
	var q = P(pos, yaw)
	q.box(Vector3(0, 0.74, 0), Vector3(1.3, 0.05, 0.6), "wood_mid")
	for sx in [-0.6, 0.6]:
		q.box(Vector3(sx, 0.36, 0), Vector3(0.05, 0.72, 0.56), "wood_dark")
	q.box(Vector3(0.35, 0.55, 0), Vector3(0.5, 0.35, 0.55), "wood_dark")
	q.box(Vector3(-0.3, 0.78, -0.1), Vector3(0.4, 0.02, 0.28), "paper")
	q.box(Vector3(0.35, 0.87, -0.12), Vector3(0.08, 0.2, 0.08), "brass")
	q.box(Vector3(0.35, 1.0, -0.12), Vector3(0.2, 0.12, 0.2), "fabric_white", {"mat": {"emit": 0.6, "emit_color": Color("ffe0a8")}})
	q.solid(Vector3(0, 0.38, 0), Vector3(1.3, 0.76, 0.6))
	if with_chair:
		chair(q.p(Vector3(-0.15, 0, 0.55)), yaw + PI)


func chair(pos: Vector3, yaw: float, col: Color = Color("6a2a2a"), tex: String = "wood_dark") -> void:
	var q = P(pos, yaw)
	q.box(Vector3(0, 0.46, 0), Vector3(0.46, 0.06, 0.46), "fabric", {"tint": col})
	for sx in [-0.2, 0.2]:
		for sz in [-0.2, 0.2]:
			q.box(Vector3(sx, 0.22, sz), Vector3(0.05, 0.44, 0.05), tex)
	q.box(Vector3(0, 0.8, -0.21), Vector3(0.46, 0.6, 0.05), tex)
	q.box(Vector3(0, 0.82, -0.18), Vector3(0.36, 0.42, 0.02), "fabric", {"tint": col})
	q.solid(Vector3(0, 0.45, 0), Vector3(0.46, 0.9, 0.46))


func stool(pos: Vector3, col: Color = Color("8a1a2a"), h: float = 0.75) -> void:
	lb.cyl(pos + Vector3(0, h, 0), 0.2, 0.08, "leather", {"tint": col, "sides": 10, "collide": false})
	lb.cyl(pos + Vector3(0, h * 0.5, 0), 0.04, h, "chrome", {"sides": 6, "cap": false, "collide": false})
	lb.cyl(pos + Vector3(0, 0.02, 0), 0.2, 0.04, "chrome", {"sides": 10, "collide": false})
	lb.cyl(pos + Vector3(0, h * 0.35, 0), 0.16, 0.025, "chrome", {"sides": 10, "collide": false})
	lb.add_cyl_collider(pos + Vector3(0, h * 0.5, 0), 0.2, h)


func sofa(pos: Vector3, yaw: float, length: float = 2.0, col: Color = Color("7a1a2a"), tex: String = "leather") -> void:
	var q = P(pos, yaw)
	q.box(Vector3(0, 0.22, 0), Vector3(length, 0.3, 0.85), tex, {"tint": col.darkened(0.2)})
	q.box(Vector3(0, 0.45, 0.05), Vector3(length - 0.3, 0.16, 0.72), tex, {"tint": col})
	q.box(Vector3(0, 0.72, -0.34), Vector3(length, 0.62, 0.2), tex, {"tint": col})
	for sx in [-1, 1]:
		q.box(Vector3(sx * (length / 2 - 0.1), 0.55, 0), Vector3(0.2, 0.36, 0.85), tex, {"tint": col.darkened(0.08)})
	var n := int(length / 0.9)
	for i in n:
		var x := -length / 2 + 0.25 + (length - 0.5) * (i + 0.5) / n
		q.box(Vector3(x, 0.78, -0.22), Vector3((length - 0.5) / n - 0.06, 0.38, 0.1), tex, {"tint": col.lightened(0.06)})
	q.solid(Vector3(0, 0.45, 0), Vector3(length, 0.9, 0.85))


func armchair(pos: Vector3, yaw: float, col: Color = Color("2a4a7a")) -> void:
	sofa(pos, yaw, 1.0, col, "fabric")


func coffee_table(pos: Vector3, yaw: float, w: float = 1.1, d: float = 0.6) -> void:
	var q = P(pos, yaw)
	q.box(Vector3(0, 0.42, 0), Vector3(w, 0.05, d), "glass", {"tint": Color(0.7, 0.85, 0.9)})
	q.box(Vector3(0, 0.2, 0), Vector3(w - 0.1, 0.04, d - 0.1), "wood_dark")
	for sx in [-1, 1]:
		for sz in [-1, 1]:
			q.box(Vector3(sx * (w / 2 - 0.06), 0.21, sz * (d / 2 - 0.06)), Vector3(0.05, 0.42, 0.05), "gold")
	q.solid(Vector3(0, 0.22, 0), Vector3(w, 0.45, d))


func tv(pos: Vector3, yaw: float, w: float = 1.3, h: float = 0.75, screen: String = "logo") -> void:
	var q = P(pos, yaw)
	q.box(Vector3(0, 0, 0), Vector3(w + 0.08, h + 0.08, 0.06), "plastic_black")
	q.plane(Vector3(0, 0, 0.032), w, h, screen, {"mat": {"emit": 1.2, "unshaded": true}})


func dresser(pos: Vector3, yaw: float, w: float = 1.6) -> void:
	var q = P(pos, yaw)
	q.box(Vector3(0, 0.4, 0), Vector3(w, 0.8, 0.5), "wood_mid")
	for row in 2:
		for col in 2:
			q.box(Vector3(-w / 4 + col * w / 2, 0.22 + row * 0.36, 0.255), Vector3(w / 2 - 0.06, 0.3, 0.01), "wood_light")
			q.box(Vector3(-w / 4 + col * w / 2, 0.22 + row * 0.36, 0.265), Vector3(0.16, 0.03, 0.02), "gold")
	q.box(Vector3(0, 0.81, 0), Vector3(w + 0.04, 0.03, 0.54), "wood_dark")
	q.solid(Vector3(0, 0.4, 0), Vector3(w, 0.8, 0.5))


func rug(pos: Vector3, w: float, d: float, tex: String, tint: Color = Color.WHITE, rot: float = 0.0) -> void:
	lb.floor_plane(pos + Vector3(0, 0.012, 0), w, d, tex, {"tint": tint, "rot": rot, "tiles": Vector2(w, d) * 0.5})
	var q = P(pos, rot)
	q.box(Vector3(0, 0.006, -d / 2 - 0.02), Vector3(w + 0.08, 0.012, 0.06), "gold", {"tint": tint.darkened(0.2)})
	q.box(Vector3(0, 0.006, d / 2 + 0.02), Vector3(w + 0.08, 0.012, 0.06), "gold", {"tint": tint.darkened(0.2)})


func plant(pos: Vector3, h: float = 1.2, pot: String = "plastic_white", big: bool = false) -> void:
	var r := 0.28 if not big else 0.42
	lb.cyl(pos + Vector3(0, 0.25, 0), r, 0.5, pot, {"sides": 8, "radius_top": r * 1.15, "collide": false})
	lb.cyl(pos + Vector3(0, 0.49, 0), r * 1.05, 0.02, "soil", {"sides": 8, "collide": false})
	lb.add_cyl_collider(pos + Vector3(0, 0.5, 0), r * 1.1, 1.0)
	var leaves_n := 5 if not big else 8
	for i in leaves_n:
		var a := TAU * i / leaves_n + rng.randf() * 0.4
		var rr := rng.randf_range(0.08, r * 0.9)
		var hh := rng.randf_range(0.6, 1.0) * h
		var c := pos + Vector3(cos(a) * rr, 0.5 + hh * 0.55, sin(a) * rr)
		var s := Vector3(rng.randf_range(0.25, 0.4), hh * 0.5, rng.randf_range(0.25, 0.4)) * (1.3 if big else 1.0)
		lb.box(c, s, "leaves" if i % 2 == 0 else "leaves_dark", {"collide": false, "rot": a})
	lb.box(pos + Vector3(0, 0.5 + h * 0.7, 0), Vector3(0.35, h * 0.35, 0.35) * (1.4 if big else 1.0), "leaves", {"collide": false, "rot": 0.6})


func palm(pos: Vector3, h: float = 3.2) -> void:
	lb.cyl(pos + Vector3(0, 0.3, 0), 0.5, 0.6, "marble_white", {"sides": 8, "collide": false})
	lb.add_cyl_collider(pos + Vector3(0, 0.5, 0), 0.5, 1.0)
	for i in 6:
		lb.cyl(pos + Vector3(sin(i * 0.7) * 0.04, 0.6 + i * h / 6.0 * 0.8 + 0.2, 0), 0.12 - i * 0.008, h / 6.0 * 0.8, "wood_light", {"sides": 6, "collide": false, "tint": Color(0.75, 0.6, 0.45)})
	var top := pos + Vector3(0, 0.6 + h * 0.8, 0)
	for i in 7:
		var a := TAU * i / 7.0
		var d := Vector3(cos(a), 0, sin(a))
		lb.box(top + d * 0.7 + Vector3(0, -0.1, 0), Vector3(1.4, 0.06, 0.4), "leaves", {"collide": false, "rot": -a})
		lb.box(top + d * 1.3 + Vector3(0, -0.4, 0), Vector3(0.6, 0.05, 0.32), "leaves_dark", {"collide": false, "rot": -a})


func floor_lamp(pos: Vector3, col: Color = Color("ffd8a0")) -> void:
	lb.cyl(pos + Vector3(0, 0.02, 0), 0.2, 0.04, "brass", {"sides": 8, "collide": false})
	lb.cyl(pos + Vector3(0, 0.8, 0), 0.025, 1.6, "brass", {"sides": 6, "cap": false, "collide": false})
	lb.cyl(pos + Vector3(0, 1.65, 0), 0.25, 0.3, "fabric_white", {"sides": 8, "radius_top": 0.17, "collide": false, "mat": {"emit": 0.8, "emit_color": col}})
	lb.add_cyl_collider(pos + Vector3(0, 0.9, 0), 0.2, 1.8)
	light(pos + Vector3(0, 1.6, 0), col, 0.6, 4.0)


func chandelier(pos: Vector3, size: float = 1.0, col: Color = Color("ffe0a8"), energy: float = 1.4, rng_m: float = 10.0, shadow: bool = false) -> void:
	lb.cyl(pos + Vector3(0, 0.5 * size, 0), 0.03, 1.0 * size, "gold", {"sides": 4, "cap": false, "collide": false})
	lb.cyl(pos, 0.5 * size, 0.12 * size, "gold", {"sides": 12, "collide": false, "mat": {"metal": 0.7, "rough": 0.3}})
	lb.cyl(pos + Vector3(0, -0.18 * size, 0), 0.3 * size, 0.24 * size, "glass", {"sides": 12, "radius_top": 0.45 * size, "collide": false, "mat": {"emit": 1.6, "emit_color": col}})
	for i in 8:
		var a := TAU * i / 8.0
		var p := pos + Vector3(cos(a) * 0.62 * size, 0.06 * size, sin(a) * 0.62 * size)
		lb.box(p, Vector3(0.06, 0.14, 0.06) * size, "white", {"collide": false, "mat": {"emit": 2.5, "emit_color": col, "unshaded": true}})
		lb.box(p + Vector3(0, -0.2 * size, 0), Vector3(0.04, 0.16, 0.04) * size, "glass", {"collide": false, "mat": {"emit": 0.6, "emit_color": Color(0.8, 0.9, 1.0)}})
	light(pos + Vector3(0, -0.4, 0), col, energy, rng_m, shadow)


func ceiling_lamp(pos: Vector3, col: Color = Color("fff0d0"), energy: float = 0.9, rng_m: float = 6.0) -> void:
	lb.cyl(pos, 0.35, 0.08, "white", {"sides": 10, "collide": false, "mat": {"emit": 1.5, "emit_color": col}})
	lb.cyl(pos + Vector3(0, 0.05, 0), 0.38, 0.03, "brass", {"sides": 10, "collide": false})
	light(pos + Vector3(0, -0.3, 0), col, energy, rng_m)


func sconce(pos: Vector3, yaw: float, col: Color = Color("ffd8a0"), with_light: bool = true) -> void:
	var q = P(pos, yaw)
	q.box(Vector3(0, 0, 0.04), Vector3(0.14, 0.24, 0.08), "brass")
	q.box(Vector3(0, 0.12, 0.12), Vector3(0.18, 0.2, 0.16), "fabric_white", {"mat": {"emit": 1.2, "emit_color": col}})
	if with_light:
		light(q.p(Vector3(0, 0.15, 0.35)), col, 0.45, 3.2)


func painting(pos: Vector3, yaw: float, tex: String, w: float = 1.2, h: float = 0.9, frame_tex: String = "gold") -> void:
	var q = P(pos, yaw)
	q.box(Vector3(0, 0, 0.02), Vector3(w + 0.12, h + 0.12, 0.04), frame_tex, {"mat": {"metal": 0.5, "rough": 0.4}})
	q.plane(Vector3(0, 0, 0.042), w, h, tex)


func window(pos: Vector3, yaw: float, w: float = 2.2, h: float = 1.4, tex: String = "window_city", curtains: Color = Color("6a1a2a")) -> void:
	var q = P(pos, yaw)
	q.plane(Vector3(0, 0, 0.01), w, h, tex, {"mat": {"emit": 0.9, "unshaded": true}})
	q.box(Vector3(0, h / 2 + 0.05, 0.04), Vector3(w + 0.2, 0.1, 0.1), "white")
	q.box(Vector3(0, -h / 2 - 0.05, 0.08), Vector3(w + 0.3, 0.06, 0.2), "white")
	q.box(Vector3(-w / 2 - 0.05, 0, 0.04), Vector3(0.1, h, 0.1), "white")
	q.box(Vector3(w / 2 + 0.05, 0, 0.04), Vector3(0.1, h, 0.1), "white")
	q.box(Vector3(0, 0, 0.03), Vector3(0.05, h, 0.05), "white")
	if curtains.a > 0:
		for sx in [-1, 1]:
			q.box(Vector3(sx * (w / 2 + 0.25), -0.05, 0.12), Vector3(0.45, h + 0.6, 0.06), "fabric", {"tint": curtains})
		q.box(Vector3(0, h / 2 + 0.35, 0.12), Vector3(w + 1.2, 0.05, 0.05), "brass")
	light(q.p(Vector3(0, 0, 0.6)), Color("8ab0ff"), 0.35, 3.0)


func mirror(pos: Vector3, yaw: float, w: float = 0.7, h: float = 1.6) -> void:
	var q = P(pos, yaw)
	q.box(Vector3(0, 0, 0.02), Vector3(w + 0.1, h + 0.1, 0.04), "gold")
	q.box(Vector3(0, 0, 0.045), Vector3(w, h, 0.01), "chrome", {"mat": {"metal": 1.0, "rough": 0.05, "spec": 1.0}})


func minibar(pos: Vector3, yaw: float) -> void:
	var q = P(pos, yaw)
	q.box(Vector3(0, 0.4, 0), Vector3(0.55, 0.8, 0.5), "plastic_white", {"tint": Color(0.85, 0.85, 0.9)})
	q.box(Vector3(0.2, 0.5, 0.255), Vector3(0.04, 0.3, 0.02), "chrome")
	q.box(Vector3(0, 0.83, 0), Vector3(0.5, 0.06, 0.45), "wood_dark")
	for i in 3:
		lb.cyl(q.p(Vector3(-0.15 + i * 0.15, 0.95, 0)), 0.035, 0.18, "glass", {"tint": [Color("3a8a3a"), Color("8a3a1a"), Color("d8d8e8")][i], "sides": 6, "collide": false})
	q.solid(Vector3(0, 0.45, 0), Vector3(0.55, 0.9, 0.5))


func suitcase(pos: Vector3, yaw: float, col: Color) -> void:
	var q = P(pos, yaw)

	for sx in [-0.32, 0.32]:
		q.box(Vector3(sx, 0.22, 0), Vector3(0.04, 0.44, 0.5), "wood_dark")
	q.box(Vector3(0, 0.45, 0), Vector3(0.74, 0.03, 0.52), "fabric", {"tint": Color("3a2a1a")})

	q.box(Vector3(0, 0.64, 0), Vector3(0.68, 0.36, 0.46), "metal_plates", {"tint": col.lerp(Color(0.8, 0.8, 0.85), 0.55)})
	q.box(Vector3(0, 0.83, 0), Vector3(0.7, 0.03, 0.48), "chrome")
	q.box(Vector3(0, 0.88, 0), Vector3(0.26, 0.06, 0.06), "leather_black")
	for sx in [-0.2, 0.2]:
		q.box(Vector3(sx, 0.74, 0.235), Vector3(0.08, 0.06, 0.02), "gold")
	q.box(Vector3(0, 0.66, 0.234), Vector3(0.14, 0.1, 0.01), "plastic_black")
	q.solid(Vector3(0, 0.45, 0), Vector3(0.74, 0.9, 0.52))


func bookshelf(pos: Vector3, yaw: float, w: float = 1.2, h: float = 2.0) -> void:
	var q = P(pos, yaw)
	q.box(Vector3(0, h / 2, 0), Vector3(w, h, 0.35), "wood_dark")
	var shelves := 4
	for s in shelves:
		var y := 0.25 + s * (h - 0.3) / shelves
		var x := -w / 2 + 0.08
		while x < w / 2 - 0.12:
			var bw := rng.randf_range(0.05, 0.1)
			var bh := rng.randf_range(0.22, 0.34)
			q.box(Vector3(x + bw / 2, y + bh / 2, 0.06), Vector3(bw, bh, 0.24), "leather", {"tint": Color.from_hsv(rng.randf(), 0.5, rng.randf_range(0.3, 0.7))})
			x += bw + 0.01
	q.solid(Vector3(0, h / 2, 0), Vector3(w, h, 0.35))


func column(pos: Vector3, h: float, r: float = 0.45, tex: String = "marble_white", cap_tex: String = "gold") -> void:
	lb.cyl(pos + Vector3(0, h / 2, 0), r, h, tex, {"sides": 12})
	lb.cyl(pos + Vector3(0, 0.15, 0), r * 1.3, 0.3, cap_tex, {"sides": 12, "collide": false})
	lb.cyl(pos + Vector3(0, h - 0.2, 0), r * 1.35, 0.4, cap_tex, {"sides": 12, "collide": false, "radius_top": r * 1.6})


func stanchion_line(a: Vector3, b: Vector3, n: int = 4, rope: Color = Color("a81a2a")) -> void:
	for i in n:
		var p := a.lerp(b, float(i) / (n - 1))
		lb.cyl(p + Vector3(0, 0.5, 0), 0.04, 1.0, "gold", {"sides": 6, "collide": false})
		lb.cyl(p + Vector3(0, 0.02, 0), 0.16, 0.04, "gold", {"sides": 8, "collide": false})
		lb.box(p + Vector3(0, 1.02, 0), Vector3(0.1, 0.06, 0.1), "gold", {"collide": false})
		if i < n - 1:
			var p2 := a.lerp(b, float(i + 1) / (n - 1))
			var mid := (p + p2) / 2 + Vector3(0, 0.82, 0)
			var d := p2 - p
			lb.box(mid, Vector3(d.length(), 0.05, 0.05), "fabric", {"collide": false, "tint": rope, "rot": -atan2(d.z, d.x)})
	var dd := b - a
	lb.add_collider((a + b) / 2 + Vector3(0, 0.5, 0), Vector3(dd.length(), 1.0, 0.2), -atan2(dd.z, dd.x))


func trash_bin(pos: Vector3) -> void:
	lb.cyl(pos + Vector3(0, 0.35, 0), 0.2, 0.7, "chrome", {"sides": 8})
	lb.cyl(pos + Vector3(0, 0.71, 0), 0.21, 0.03, "metal_dark", {"sides": 8, "collide": false})


func water_cooler(pos: Vector3, yaw: float) -> void:
	var q = P(pos, yaw)
	q.box(Vector3(0, 0.5, 0), Vector3(0.36, 1.0, 0.36), "plastic_white")
	lb.cyl(q.p(Vector3(0, 1.2, 0)), 0.15, 0.4, "glass", {"sides": 8, "tint": Color(0.6, 0.8, 1.0), "collide": false})
	q.box(Vector3(-0.07, 0.8, 0.19), Vector3(0.05, 0.05, 0.04), "plastic_red")
	q.box(Vector3(0.07, 0.8, 0.19), Vector3(0.05, 0.05, 0.04), "plastic_white", {"tint": Color(0.5, 0.6, 1.0)})
	q.solid(Vector3(0, 0.6, 0), Vector3(0.36, 1.2, 0.36))


func vending(pos: Vector3, yaw: float, col: Color = Color("c81a2a"), title: String = "НАПИТКИ") -> void:
	var q = P(pos, yaw)
	# v0.5: снек-автомат SNACK-O-MAT 2000 по референсу
	if title == "СНЕКИ" and RPR.has("vending"):
		var vs: Vector3 = RPR.size("vending")
		RPR.put(nodes, "vending", Transform3D(Basis(Vector3.UP, yaw), pos))
		q.solid(Vector3(0, vs.y * 0.5, 0), vs)
		return
	q.box(Vector3(0, 0.95, 0), Vector3(0.95, 1.9, 0.8), "plastic_white", {"tint": col})
	q.box(Vector3(-0.12, 1.05, 0.405), Vector3(0.6, 1.3, 0.01), "glass", {"tint": Color(0.5, 0.6, 0.7), "mat": {"emit": 0.3, "emit_color": Color(0.8, 0.9, 1.0)}})
	for r in 4:
		for c in 4:
			q.box(Vector3(-0.36 + c * 0.16, 0.55 + r * 0.3, 0.3), Vector3(0.08, 0.16, 0.08), "plastic_white", {"tint": Color.from_hsv(fmod(r * 0.27 + c * 0.13, 1.0), 0.7, 0.9)})
	q.box(Vector3(0.33, 1.2, 0.405), Vector3(0.2, 0.4, 0.01), "plastic_black", {"mat": {"emit": 0.6, "emit_color": Color(0.3, 1, 0.5)}})
	q.box(Vector3(0, 0.22, 0.405), Vector3(0.6, 0.18, 0.02), "plastic_black")
	q.solid(Vector3(0, 0.95, 0), Vector3(0.95, 1.9, 0.8))
	label(q.p(Vector3(0, 1.82, 0.41)), title, 24, Color(2, 2, 2), yaw, {"px": 0.008})


func elevator_doors(pos: Vector3, yaw: float) -> void:
	var q = P(pos, yaw)
	q.box(Vector3(0, 1.2, 0.02), Vector3(1.9, 2.5, 0.06), "gold")
	q.plane(Vector3(-0.42, 1.12, 0.06), 0.82, 2.2, "elevator")
	q.plane(Vector3(0.42, 1.12, 0.06), 0.82, 2.2, "elevator")
	q.box(Vector3(1.2, 1.2, 0.04), Vector3(0.16, 0.3, 0.04), "chrome")
	q.box(Vector3(1.2, 1.25, 0.065), Vector3(0.06, 0.06, 0.01), "white", {"mat": {"emit": 2.0, "emit_color": Color(1, 0.8, 0.3), "unshaded": true}})
	label(q.p(Vector3(0, 2.6, 0.06)), "▲ ЛИФТ ▼", 20, Color(1.8, 1.4, 0.6), yaw, {"px": 0.008})


func reception_desk(pos: Vector3, yaw: float, w: float = 3.0) -> void:
	var q = P(pos, yaw)
	q.box(Vector3(0, 0.55, 0), Vector3(w, 1.1, 0.7), "marble_black")
	q.box(Vector3(0, 1.12, 0.05), Vector3(w + 0.1, 0.06, 0.8), "marble_white")
	q.box(Vector3(0, 0.55, 0.36), Vector3(w - 0.2, 0.06, 0.02), "gold", {"mat": {"emit": 0.6, "emit_color": Color(1, 0.8, 0.3)}})
	q.box(Vector3(w / 2 - 0.4, 1.2, -0.1), Vector3(0.18, 0.06, 0.12), "gold")
	q.solid(Vector3(0, 0.55, 0), Vector3(w, 1.1, 0.7))
