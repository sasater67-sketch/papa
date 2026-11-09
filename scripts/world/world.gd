extends Node3D
## Улица: окружение, дорога, город, два казино и визуалы сущностей из снимков хоста.

const B := preload("res://scripts/world/build.gd")
const CasinoView := preload("res://scripts/world/casino_view.gd")
const PersonView := preload("res://scripts/world/person_view.gd")
const CarView := preload("res://scripts/world/car_view.gd")

const SHOPS := ["ЛОМБАРД 24/7", "МИКРОЗАЙМЫ", "ШАУРМА", "РИТУАЛЬНЫЕ УСЛУГИ", "СКУПКА ЗОЛОТА", "ПИВО • ВОДЫ",
	"КРЕДИТ ЗА 5 МИНУТ", "ЮРИСТ ПО БАНКРОТСТВУ", "АПТЕКА", "ОБМЕН ВАЛЮТ", "ТАТУ", "ПРОДАМ ПОЧКУ", "ЗАЛОГ АВТО",
	"ГАДАЛКА", "ЦВЕТЫ • ВЕНКИ", "БИЛЕТЫ ДОМОЙ"]
const NEON := [Color(1, 0.2, 0.4), Color(0.2, 0.9, 1), Color(1, 0.8, 0.2), Color(0.4, 1, 0.4), Color(0.8, 0.4, 1), Color(1, 0.5, 0.15)]

var casinos: Array = []
var ents := {}
var _seen := {}
var _last_sweep := 0
var font_title: Font
var font_body: Font
var env: Environment
var sun: DirectionalLight3D
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = 1337
	font_title = load("res://fonts/RussoOne-Regular.ttf")
	font_body = load("res://fonts/Rubik.ttf")
	_build_env()
	_build_ground()
	_build_road()
	_build_city()
	for t in 2:
		var c: Node3D = CasinoView.new()
		add_child(c)
		c.position = Vector3(0, 0, -Game.DOOR_Z if t == 0 else Game.DOOR_Z)
		c.rotation.y = 0.0 if t == 0 else PI
		c.setup(t, font_title, font_body)
		casinos.append(c)
	Game.ents_updated.connect(_on_ents)
	Game.state_updated.connect(_on_state)
	Game.bubble.connect(_on_bubble)
	Game.popup.connect(_on_popup)
	Game.fx.connect(_on_fx)
	Defs.settings_changed.connect(_apply_quality)
	_apply_quality()
	if Game.teams.size() == 2:
		_on_state()
	if not Game.last_ents.is_empty():
		_on_ents(Game.last_ents)


# =============================================================================
func _build_env() -> void:
	var we := WorldEnvironment.new()
	env = Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	sky.sky_material = B.smat(B.SKY_SHADER)
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.32, 0.28, 0.5)
	env.ambient_light_energy = 0.85
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.05
	env.glow_enabled = true
	env.glow_intensity = 0.85
	env.glow_strength = 1.0
	env.glow_bloom = 0.06
	env.glow_hdr_threshold = 0.95
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
	env.set_glow_level(0, 0.0)
	env.set_glow_level(1, 1.0)
	env.set_glow_level(2, 0.8)
	env.set_glow_level(3, 0.5)
	env.set_glow_level(4, 0.3)
	env.fog_enabled = true
	env.fog_light_color = Color(0.16, 0.09, 0.22)
	env.fog_density = 0.0045
	env.fog_sky_affect = 0.15
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.15
	env.adjustment_contrast = 1.06
	env.ssao_radius = 1.2
	env.ssao_intensity = 1.6
	env.ssr_max_steps = 48
	env.ssr_fade_in = 0.2
	env.ssr_fade_out = 2.0
	env.volumetric_fog_density = 0.006
	env.volumetric_fog_albedo = Color(0.7, 0.6, 0.9)
	env.volumetric_fog_length = 80.0
	we.environment = env
	add_child(we)
	sun = DirectionalLight3D.new()
	sun.light_color = Color(0.55, 0.62, 1.0)
	sun.light_energy = 0.35
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 140.0
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	add_child(sun)
	sun.transform = Transform3D(Basis.looking_at(-Vector3(-0.45, 0.62, -0.65).normalized(), Vector3.UP), Vector3.ZERO)


func _apply_quality() -> void:
	var q := Defs.quality
	sun.shadow_enabled = q >= 1
	env.ssao_enabled = q >= 1
	env.ssr_enabled = q >= 2
	env.volumetric_fog_enabled = q >= 2
	env.sdfgi_enabled = false
	get_viewport().msaa_3d = Viewport.MSAA_4X if q >= 2 else (Viewport.MSAA_2X if q == 1 else Viewport.MSAA_DISABLED)
	get_viewport().screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA if q >= 1 else Viewport.SCREEN_SPACE_AA_DISABLED


func _build_ground() -> void:
	var ground_mat := B.smat(B.TILES_SHADER, {"color_a": Color(0.1, 0.1, 0.11), "color_b": Color(0.09, 0.09, 0.1), "tile": 3.0})
	for s in [-1, 1]:
		var g := B.box(self, Vector3(420, 0.17, 196), Vector3(0, 0.085, s * (4.0 + 98.0)), ground_mat, false)
		g.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var sw := B.smat(B.TILES_SHADER, {"color_a": Color(0.3, 0.29, 0.3), "color_b": Color(0.26, 0.25, 0.27), "tile": 1.5})
	for s in [-1, 1]:
		B.box(self, Vector3(240, 0.18, 3.0), Vector3(0, 0.09, s * 5.5), sw, false)
		B.box(self, Vector3(240, 0.22, 0.28), Vector3(0, 0.11, s * 4.0), B.mat(Color(0.5, 0.5, 0.52), 0.8), false)


func _build_road() -> void:
	B.box(self, Vector3(240, 0.1, 8.0), Vector3(0, -0.05, 0), B.smat(B.ROAD_SHADER), false)
	var yellow := B.mat(Color(0.9, 0.7, 0.1), 0.6, 0.0, Color(0.9, 0.7, 0.1), 0.25)
	var white := B.mat(Color(0.85, 0.85, 0.85), 0.6, 0.0, Color(1, 1, 1), 0.15)
	for z in [-0.14, 0.14]:
		B.box(self, Vector3(240, 0.02, 0.1), Vector3(0, 0.01, z), yellow, false)
	for z in [-3.6, 3.6]:
		B.box(self, Vector3(240, 0.02, 0.12), Vector3(0, 0.01, z), white, false)
	for cx in Game.CROSS_X:
		for i in 8:
			B.box(self, Vector3(3.0, 0.02, 0.5), Vector3(cx, 0.012, -3.3 + i * 0.94), white, false)
	# Фонари
	for x in [-55.0, -33.0, -11.0, 11.0, 33.0, 55.0]:
		for s in [-1, 1]:
			_lamp(Vector3(x, 0.18, s * 4.45), s)
	# Деревья
	for x in [-66.0, -44.0, -22.0, 22.0, 44.0, 66.0]:
		for s in [-1, 1]:
			_tree(Vector3(x + _rng.randf_range(-1, 1), 0.18, s * 6.6))


func _lamp(pos: Vector3, side: int) -> void:
	var metal := B.mat(Color(0.15, 0.15, 0.17), 0.4, 0.8)
	B.cyl(self, 0.08, 0.12, 6.2, pos + Vector3(0, 3.1, 0), metal, 8)
	B.box(self, Vector3(0.12, 0.12, 1.4), pos + Vector3(0, 6.1, -side * 0.65), metal)
	B.box(self, Vector3(0.5, 0.15, 0.7), pos + Vector3(0, 6.0, -side * 1.3), B.neon(Color(1, 0.85, 0.6), 5.0), false)
	B.light(self, pos + Vector3(0, 5.6, -side * 1.3), Color(1, 0.72, 0.42), 2.2, 12.0)


func _tree(pos: Vector3) -> void:
	B.box(self, Vector3(1.6, 0.4, 1.6), pos + Vector3(0, 0.2, 0), B.mat(Color(0.35, 0.33, 0.32), 0.9))
	B.cyl(self, 0.12, 0.18, 2.4, pos + Vector3(0, 1.4, 0), B.mat(Color(0.25, 0.16, 0.1), 0.9), 8)
	var leaf := B.mat(Color(0.08, 0.22, 0.12), 0.9)
	B.sphere(self, 1.3, pos + Vector3(0, 3.2, 0), leaf, false, 10)
	B.sphere(self, 0.9, pos + Vector3(0.5, 3.9, 0.3), leaf, false, 10)


func _build_city() -> void:
	# Соседние лавки вдоль дороги
	var shop_i := 0
	for s in [-1, 1]:
		for xs in [-1, 1]:
			var x := 22.0
			while x < 78.0:
				var w := _rng.randf_range(7.0, 11.0)
				var cx: float = xs * (x + w * 0.5)
				_shop(Vector3(cx, 0.17, s * 8.2), w, s, SHOPS[shop_i % SHOPS.size()])
				shop_i += 1
				x += w + 0.6
	# Задний план — высотки
	for s in [-1, 1]:
		var x := -110.0
		while x < 110.0:
			var w := _rng.randf_range(10.0, 18.0)
			var h := _rng.randf_range(14.0, 48.0)
			var z: float = s * _rng.randf_range(44.0, 56.0)
			if absf(x) < 20.0:
				h *= 0.8
			var m := B.smat(B.BUILDING_SHADER, {"base_color": Color(0.07, 0.07, 0.1).lerp(Color(0.15, 0.1, 0.18), _rng.randf()),
				"trim_color": NEON[_rng.randi() % NEON.size()], "window_color": Color(1.0, 0.85, 0.6).lerp(Color(0.6, 0.8, 1.0), _rng.randf()),
				"lit_ratio": _rng.randf_range(0.2, 0.45), "window_energy": 0.55, "seed": _rng.randf() * 100.0, "trim_energy": 0.0, "ground_h": 0.5, "cell": Vector2(3.0, 2.6)})
			B.box(self, Vector3(w, h, 12), Vector3(x + w * 0.5, h * 0.5, z), m)
			if _rng.randf() < 0.3:
				B.box(self, Vector3(w + 0.1, 0.25, 12.1), Vector3(x + w * 0.5, h, z), B.neon(NEON[_rng.randi() % NEON.size()], 3.0), false)
			x += w + _rng.randf_range(0.5, 3.0)
	# Здания в торцах улицы
	for xs in [-1, 1]:
		for s in [-1, 1]:
			var h := _rng.randf_range(20, 40)
			B.box(self, Vector3(14, h, 16), Vector3(xs * 105.0, h * 0.5, s * 18.0), B.smat(B.BUILDING_SHADER, {
				"base_color": Color(0.08, 0.08, 0.1), "window_color": Color(1, 0.85, 0.6), "lit_ratio": 0.35, "window_energy": 0.55, "seed": _rng.randf() * 50.0, "ground_h": 0.5, "cell": Vector2(3.0, 2.6)}))


func _shop(pos: Vector3, w: float, side: int, text: String) -> void:
	var n := Node3D.new()
	n.position = pos
	n.rotation.y = 0.0 if side < 0 else PI
	add_child(n)
	# side<0: лавка на стороне Лотоса, фасад смотрит в +z (к дороге)
	var h := _rng.randf_range(4.0, 8.0)
	var c: Color = NEON[_rng.randi() % NEON.size()]
	B.box(n, Vector3(w, h, 9.0), Vector3(0, h * 0.5, -4.5), B.smat(B.BUILDING_SHADER, {
		"base_color": Color(0.12, 0.11, 0.13).lerp(Color(0.2, 0.15, 0.12), _rng.randf()), "trim_color": c,
		"window_color": Color(1, 0.8, 0.55), "lit_ratio": 0.5, "window_energy": 0.9, "seed": _rng.randf() * 80.0, "trim_energy": 0.0, "ground_h": 3.5, "cell": Vector2(2.0, 1.8)}))
	B.box(n, Vector3(w * 0.8, 2.4, 0.08), Vector3(0, 1.5, 0.02), B.mat(Color(0.1, 0.08, 0.05), 0.1, 0.3, Color(1, 0.8, 0.55), 0.8))
	B.box(n, Vector3(w * 0.92, 0.9, 0.25), Vector3(0, 3.2, 0.15), B.mat(Color(0.05, 0.04, 0.06), 0.6))
	var l := B.label(n, text, Vector3(0, 3.2, 0.3), 64, c * 2.2, c.darkened(0.6), 0.0105, font_title)
	l.width = w * 90.0
	if _rng.randf() < 0.5:
		var aw := B.box(n, Vector3(w * 0.85, 0.08, 1.4), Vector3(0, 2.75, 0.75), B.mat(c.darkened(0.4), 0.7))
		aw.rotation.x = 0.3
	B.light(n, Vector3(0, 2.6, 1.6), c, 1.0, 5.5)


# =============================================================================
# Синхронизация визуалов
# =============================================================================
func _on_state() -> void:
	if Game.teams.size() != 2:
		return
	for t in 2:
		casinos[t].apply_state(Game.teams[t])


func _ground_y(z: float) -> float:
	return 0.0 if absf(z) < 3.95 else 0.18


func _on_ents(arr: PackedFloat32Array) -> void:
	var now := Time.get_ticks_msec()
	var n := arr.size() / 8
	for i in n:
		var b := i * 8
		var id := int(arr[b])
		var kind := int(arr[b + 1])
		var pos := Vector3(arr[b + 4], _ground_y(arr[b + 5]), arr[b + 5])
		_seen[id] = now
		var node: Node3D = ents.get(id)
		if node == null:
			if kind == 0:
				node = PersonView.new()
				add_child(node)
				node.setup(Defs.CLIENT_TYPES[clampi(int(arr[b + 2]), 0, Defs.CLIENT_TYPES.size() - 1)], int(arr[b + 3]), font_body)
			else:
				node = CarView.new()
				add_child(node)
				node.setup(int(arr[b + 2]), font_title)
			node.position = pos
			node.rotation.y = arr[b + 6]
			ents[id] = node
		node.target_pos = pos
		node.target_yaw = arr[b + 6]
		if kind == 0:
			node.moving = arr[b + 7] > 0.5
		else:
			node.speed = arr[b + 7]


# Снимки приходят порциями и могут теряться — убираем только давно не обновлявшиеся сущности.
func _process(_delta: float) -> void:
	var now := Time.get_ticks_msec()
	if now - _last_sweep < 150:
		return
	_last_sweep = now
	for id in ents.keys():
		if now - int(_seen.get(id, 0)) > 450:
			ents[id].queue_free()
			ents.erase(id)
			_seen.erase(id)


func _on_bubble(id: int, text: String) -> void:
	var node = ents.get(id)
	if node and node.has_method("say"):
		node.say(text)


func _on_popup(t: int, text: String, kind: String) -> void:
	var c := Color(0.4, 1.0, 0.45)
	match kind:
		"bad":
			c = Color(1.0, 0.3, 0.3)
		"good":
			c = Color(0.5, 0.85, 1.0)
	var l := Label3D.new()
	l.text = text
	l.font = font_title
	l.font_size = 72 if kind != "money" else 60
	l.outline_size = 14
	l.pixel_size = 0.012
	l.modulate = c * 1.6
	l.outline_modulate = Color(0, 0, 0, 0.9)
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.render_priority = 5
	add_child(l)
	var base := Vector3(randf_range(-2.5, 2.5), 5.5, (-1.0 if t == 0 else 1.0) * (Game.DOOR_Z - 3.5))
	l.position = base
	var tw := create_tween().set_parallel(true)
	tw.tween_property(l, "position:y", base.y + 3.5, 1.8).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "modulate:a", 0.0, 1.8).set_delay(0.6)
	tw.tween_property(l, "outline_modulate:a", 0.0, 1.8).set_delay(0.6)
	tw.chain().tween_callback(l.queue_free)
	if kind == "money" and t == Net.my_team() and not Game.demo:
		Sfx.play("coin", -10.0, randf_range(0.95, 1.1))


func _on_fx(t: int, name: String) -> void:
	casinos[t].play_fx(name)
	if Game.demo:
		return
	var mine := t == Net.my_team()
	if name == "levelup":
		Sfx.play("levelup", 0.0 if mine else -8.0)
	elif name.begins_with("build:"):
		Sfx.play("build", -2.0 if mine else -12.0)
	elif name == "caught":
		Sfx.play("caught" if mine else "good")
	elif name.begins_with("hit:"):
		Sfx.play("hit" if mine else "sabotage")
		if name == "hit:exodus" or name == "hit:news":
			Sfx.play("alarm", -6.0)
	elif name == "brawl":
		Sfx.play("hit", -4.0)
	elif name == "grand_raffle":
		Sfx.play("win", -4.0)
	elif name in ["cleanup", "pr", "party"]:
		Sfx.play("good", -4.0 if mine else -12.0)
