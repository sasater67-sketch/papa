extends Node3D
## Визуал пешехода. Двигается к целевой точке из снимка хоста и анимирует шаг.

const B := preload("res://scripts/world/build.gd")

const SKIN := [Color(1.0, 0.82, 0.68), Color(0.87, 0.65, 0.48), Color(0.62, 0.43, 0.3), Color(0.42, 0.28, 0.2)]
const CLOTH := [Color(0.8, 0.2, 0.25), Color(0.2, 0.4, 0.85), Color(0.95, 0.75, 0.2), Color(0.25, 0.7, 0.4),
	Color(0.55, 0.3, 0.75), Color(0.9, 0.5, 0.2), Color(0.85, 0.85, 0.9), Color(0.3, 0.75, 0.8), Color(0.95, 0.45, 0.65)]
const PANTS := [Color(0.12, 0.13, 0.2), Color(0.25, 0.22, 0.2), Color(0.18, 0.25, 0.4), Color(0.1, 0.1, 0.1)]

var type := "normal"
var target_pos := Vector3.ZERO
var target_yaw := 0.0
var moving := false
var _figures: Array = []  # [root, l_leg, r_leg, l_arm, r_arm]
var _phase := 0.0
var _t := 0.0
var _bubble: Label3D
var _bubble_t := 0.0
var _visual: Node3D
var _font: Font


func setup(p_type: String, seed: int, font: Font) -> void:
	type = p_type
	_font = font
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	_visual = Node3D.new()
	# Чуть крупнее реального роста — иначе с высоты стратегической камеры людей не разглядеть.
	_visual.scale = Vector3.ONE * 1.2
	add_child(_visual)
	match type:
		"family":
			_figure(rng, 1.0, Vector3(0, 0, 0), {})
			_figure(rng, 0.58, Vector3(0.62, 0, -0.15), {})
			_figure(rng, 0.52, Vector3(-0.6, 0, -0.1), {})
		"vip":
			_figure(rng, 1.03, Vector3.ZERO, {"shirt": Color(0.06, 0.06, 0.08), "pants": Color(0.05, 0.05, 0.06), "tophat": true, "gold": true})
		"drunk":
			_figure(rng, 1.0, Vector3.ZERO, {"shirt": Color(0.75, 0.7, 0.55), "nose": true, "bottle": true})
		"cheater":
			_figure(rng, 0.98, Vector3.ZERO, {"shirt": Color(0.15, 0.15, 0.17), "pants": Color(0.1, 0.1, 0.12), "shades": true, "hood": true})
		"brawler":
			_figure(rng, 1.12, Vector3.ZERO, {"shirt": Color(0.85, 0.1, 0.1), "pants": Color(0.2, 0.2, 0.25), "bald": true, "wide": true})
		"guard":
			_figure(rng, 1.08, Vector3.ZERO, {"shirt": Color(0.05, 0.05, 0.06), "pants": Color(0.05, 0.05, 0.06), "shades": true, "bald": true, "wide": true})
		"lawyer":
			_figure(rng, 1.0, Vector3.ZERO, {"shirt": Color(0.35, 0.37, 0.42), "pants": Color(0.25, 0.26, 0.3), "briefcase": true})
		"detective":
			_figure(rng, 1.02, Vector3.ZERO, {"shirt": Color(0.68, 0.55, 0.36), "pants": Color(0.4, 0.33, 0.24), "fedora": true, "coat": true})
		"cleaner":
			_figure(rng, 0.98, Vector3.ZERO, {"shirt": Color(0.2, 0.6, 0.35), "pants": Color(0.15, 0.4, 0.25), "mop": true, "cap": true})
		"dancer":
			_figure(rng, 1.0, Vector3.ZERO, {"shirt": Color(1.0, 0.3, 0.8), "pants": Color(0.95, 0.85, 0.3), "glow": true})
		"dealer":
			_figure(rng, 1.0, Vector3.ZERO, {"shirt": Color(0.95, 0.95, 0.95), "pants": Color(0.1, 0.1, 0.1), "vest": true})
		"reporter":
			_figure(rng, 1.0, Vector3.ZERO, {"shirt": Color(0.25, 0.35, 0.6), "camera": true})
		_:
			_figure(rng, rng.randf_range(0.92, 1.06), Vector3.ZERO, {})


func _figure(rng: RandomNumberGenerator, s: float, offset: Vector3, o: Dictionary) -> void:
	var root := Node3D.new()
	root.position = offset
	root.scale = Vector3.ONE * s
	_visual.add_child(root)
	var skin: Color = SKIN[rng.randi() % SKIN.size()]
	var shirt: Color = o.get("shirt", CLOTH[rng.randi() % CLOTH.size()])
	var pants: Color = o.get("pants", PANTS[rng.randi() % PANTS.size()])
	var m_skin := B.mat(skin, 0.8)
	var m_shirt := B.mat(shirt, 0.75, 0.0, shirt, 0.35) if not o.get("glow", false) else B.mat(shirt, 0.4, 0.0, shirt, 1.5)
	var m_pants := B.mat(pants, 0.8)
	var w := 1.25 if o.get("wide", false) else 1.0
	var legs := []
	for side in [-1, 1]:
		var hip := Node3D.new()
		hip.position = Vector3(0.11 * side, 0.82, 0)
		root.add_child(hip)
		B.box(hip, Vector3(0.17, 0.8, 0.2), Vector3(0, -0.4, 0), m_pants)
		B.box(hip, Vector3(0.18, 0.08, 0.28), Vector3(0, -0.78, 0.04), B.mat(Color(0.08, 0.07, 0.07), 0.6))
		legs.append(hip)
	var torso_h := 0.62
	B.capsule(root, 0.2 * w, torso_h + 0.25, Vector3(0, 1.17, 0), m_shirt)
	if o.get("coat", false):
		B.box(root, Vector3(0.48, 0.75, 0.32), Vector3(0, 1.0, 0), m_shirt)
	if o.get("vest", false):
		B.box(root, Vector3(0.38, 0.4, 0.27), Vector3(0, 1.2, 0.02), B.mat(Color(0.1, 0.1, 0.12)))
		B.box(root, Vector3(0.14, 0.05, 0.02), Vector3(0, 1.45, 0.14), B.mat(Color(0.6, 0.05, 0.1)))
	var arms := []
	for side in [-1, 1]:
		var sh := Node3D.new()
		sh.position = Vector3((0.27 * w) * side, 1.43, 0)
		root.add_child(sh)
		B.box(sh, Vector3(0.12, 0.62, 0.14), Vector3(0, -0.3, 0), m_shirt)
		B.sphere(sh, 0.065, Vector3(0, -0.63, 0), m_skin, false, 8)
		arms.append(sh)
	B.sphere(root, 0.07, Vector3(0, 1.56, 0), m_skin, false, 8)
	var head := B.sphere(root, 0.17, Vector3(0, 1.72, 0), m_skin, false, 12)
	var hair_c := Color(0.1, 0.07, 0.05) if rng.randf() < 0.6 else Color(0.55, 0.35, 0.15)
	if rng.randf() < 0.15:
		hair_c = Color(0.85, 0.75, 0.4)
	if not o.get("bald", false) and not o.get("hood", false):
		B.sphere(head, 0.175, Vector3(0, 0.04, -0.02), B.mat(hair_c, 0.9), true, 12)
	# Глаза
	for side in [-1, 1]:
		B.box(head, Vector3(0.035, 0.035, 0.02), Vector3(0.06 * side, 0.02, 0.16), B.mat(Color(0.05, 0.05, 0.05)), false)
	if o.get("tophat", false):
		B.cyl(head, 0.2, 0.2, 0.03, Vector3(0, 0.15, 0), B.mat(Color(0.05, 0.05, 0.05)))
		B.cyl(head, 0.12, 0.12, 0.28, Vector3(0, 0.3, 0), B.mat(Color(0.05, 0.05, 0.05)))
		B.cyl(head, 0.125, 0.125, 0.05, Vector3(0, 0.2, 0), B.mat(Color(0.7, 0.1, 0.1)))
	if o.get("gold", false):
		B.box(root, Vector3(0.24, 0.03, 0.02), Vector3(0, 1.38, 0.2), B.mat(Color(1, 0.8, 0.2), 0.2, 1.0, Color(1, 0.7, 0.2), 0.6))
	if o.get("fedora", false):
		B.cyl(head, 0.24, 0.24, 0.03, Vector3(0, 0.13, 0), B.mat(Color(0.35, 0.27, 0.18)))
		B.cyl(head, 0.13, 0.15, 0.14, Vector3(0, 0.2, 0), B.mat(Color(0.35, 0.27, 0.18)))
	if o.get("cap", false):
		B.sphere(head, 0.18, Vector3(0, 0.05, 0), B.mat(Color(0.9, 0.9, 0.2)), true, 10)
		B.box(head, Vector3(0.2, 0.02, 0.14), Vector3(0, 0.07, 0.18), B.mat(Color(0.9, 0.9, 0.2)))
	if o.get("hood", false):
		B.sphere(head, 0.2, Vector3(0, 0.0, -0.03), m_shirt, false, 10)
	if o.get("shades", false):
		B.box(head, Vector3(0.24, 0.06, 0.03), Vector3(0, 0.03, 0.17), B.mat(Color(0.02, 0.02, 0.02), 0.1, 0.8), false)
	if o.get("nose", false):
		B.sphere(head, 0.045, Vector3(0, -0.02, 0.18), B.mat(Color(0.95, 0.15, 0.15), 0.5, 0.0, Color(0.9, 0.1, 0.1), 0.6), false, 8)
	if o.get("bottle", false):
		B.cyl(arms[1], 0.04, 0.05, 0.25, Vector3(0, -0.68, 0.06), B.mat(Color(0.15, 0.5, 0.2), 0.1, 0.0))
	if o.get("briefcase", false):
		B.box(arms[1], Vector3(0.08, 0.28, 0.4), Vector3(0.02, -0.75, 0), B.mat(Color(0.3, 0.18, 0.08), 0.5))
	if o.get("mop", false):
		B.cyl(arms[1], 0.02, 0.02, 1.4, Vector3(0, -0.6, 0.25), B.mat(Color(0.6, 0.45, 0.25)))
		B.box(arms[1], Vector3(0.35, 0.08, 0.15), Vector3(0, -1.3, 0.25), B.mat(Color(0.9, 0.9, 0.85)))
	if o.get("camera", false):
		B.box(arms[1], Vector3(0.25, 0.25, 0.45), Vector3(0, -0.2, 0.2), B.mat(Color(0.1, 0.1, 0.1), 0.4, 0.5))
	_figures.append([root, legs[0], legs[1], arms[0], arms[1]])


func _process(delta: float) -> void:
	_t += delta
	var d := target_pos - position
	if d.length() > 6.0:
		position = target_pos
	else:
		position = position.lerp(target_pos, minf(1.0, delta * 9.0))
	rotation.y = lerp_angle(rotation.y, target_yaw, minf(1.0, delta * 10.0))
	var spd := 1.0 if type != "drunk" else 0.7
	if moving:
		_phase += delta * 7.5 * spd
	else:
		_phase = lerpf(_phase, roundf(_phase / PI) * PI, minf(1.0, delta * 8.0))
	var sw := sin(_phase)
	for f in _figures:
		f[1].rotation.x = sw * 0.6
		f[2].rotation.x = -sw * 0.6
		f[3].rotation.x = -sw * 0.5
		f[4].rotation.x = sw * 0.5
		f[0].position.y = absf(cos(_phase)) * 0.04 if moving else 0.0
	match type:
		"drunk":
			_visual.rotation.z = sin(_t * 2.3) * 0.18
			_visual.position.x = sin(_t * 1.7) * 0.25
		"brawler":
			_figures[0][3].rotation.x = -2.6 + sin(_t * 9.0) * 0.4
			_figures[0][4].rotation.x = -2.6 + cos(_t * 9.0) * 0.4
		"guard":
			_figures[0][3].rotation.z = -0.6
			_figures[0][4].rotation.z = 0.6
		"dancer":
			_visual.rotation.y = sin(_t * 3.0) * 0.9
			_figures[0][0].position.y = absf(sin(_t * 6.0)) * 0.25
			_figures[0][3].rotation.x = -2.8 + sin(_t * 6.0) * 0.5
			_figures[0][4].rotation.x = -2.8 - sin(_t * 6.0) * 0.5
	if _bubble:
		_bubble_t -= delta
		if _bubble_t < 0.5:
			_bubble.modulate.a = maxf(0.0, _bubble_t / 0.5)
			_bubble.outline_modulate.a = _bubble.modulate.a
		if _bubble_t <= 0.0:
			_bubble.queue_free()
			_bubble = null


func say(text: String) -> void:
	if _bubble:
		_bubble.queue_free()
	_bubble = Label3D.new()
	_bubble.text = text
	_bubble.font_size = 40
	_bubble.outline_size = 14
	_bubble.pixel_size = 0.0075
	_bubble.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_bubble.no_depth_test = true
	_bubble.fixed_size = false
	_bubble.render_priority = 10
	_bubble.outline_render_priority = 9
	_bubble.modulate = Color(1, 1, 1)
	_bubble.outline_modulate = Color(0.08, 0.02, 0.12)
	_bubble.position = Vector3(0, 2.45, 0)
	_bubble.width = 420
	_bubble.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if _font:
		_bubble.font = _font
	add_child(_bubble)
	_bubble_t = 3.2
	var tw := create_tween()
	_bubble.scale = Vector3.ONE * 0.3
	tw.tween_property(_bubble, "scale", Vector3.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
