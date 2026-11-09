extends Node3D
## Визуал одного казино. Локальные координаты: фасад на z=0, дорога в сторону +z, здание уходит в −z.

const B := preload("res://scripts/world/build.gd")
const PV := preload("res://scripts/world/person_view.gd")
const Hall := preload("res://scripts/world/hall.gd")
const GROUND_H := 4.6

var _hall: Node3D

var team := 0
var level := 0
var height := 7.6
var col := Color.WHITE
var acc := Color.WHITE
var font_title: Font
var font_body: Font

var _initialized := false
var _tower: MeshInstance3D
var _tower_mat: ShaderMaterial
var _roof: Node3D
var _scalers: Array = []   # узлы, растущие по высоте
var _modules := {}
var _effects := {}
var _sign_small: Node3D
var _sign_big: Node3D
var _sign_labels: Array = []
var _hotel: MeshInstance3D
var _hotel_sign: Node3D
var _speakers: Array = []
var _lift_cabin: Node3D
var _lift_shaft: MeshInstance3D
var _stage_beams: Array = []
var _fw_t := 3.0
var _cleaner: Node3D
var _roach_mm: MultiMeshInstance3D
var _roach_data: Array = []
var _alarm_light: OmniLight3D
var _lightning: OmniLight3D
var _party_lights: Array = []
var _raffle_wheel: Node3D
var _raffle_beams: Array = []
var _rumor_labels: Array = []
var _police: Node3D
var _police_t := 0.0
var _flash: OmniLight3D
var _flash_t := 0.0
var _pr_label: Label3D
var _pr_i := 0
var _pr_t := 0.0
var _t := 0.0
var _state_sign := ""
var _sign_scale := 1.0
var _blink_mats: Array = []


func setup(t: int, ft: Font, fb: Font) -> void:
	team = t
	font_title = ft
	font_body = fb
	col = Defs.TEAM_COLORS[t]
	acc = Defs.TEAM_ACCENT[t]
	_build_lot()
	_build_tower()
	_build_modules()
	_build_effects()


func h_for(lvl: int) -> float:
	return 6.0 + lvl * 1.6


# =============================================================================
# Статичная часть
# =============================================================================
func _build_lot() -> void:
	var lot := B.box(self, Vector3(36, 0.18, 9.2), Vector3(0, 0.09, 4.6), B.smat(B.TILES_SHADER, {
		"color_a": Color(0.17, 0.15, 0.19), "color_b": Color(0.13, 0.12, 0.15), "accent": col, "accent_energy": 0.3, "tile": 1.2}))
	lot.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Дорожка ко входу
	B.box(self, Vector3(2.6, 0.02, 9.0), Vector3(0, 0.19, 4.5), B.mat(col.darkened(0.75), 0.4, 0.3), false)
	# Клумбы вдоль границы участка
	for sx in [-1, 1]:
		B.box(self, Vector3(0.5, 0.5, 9.0), Vector3(sx * 17.8, 0.25, 4.5), B.mat(Color(0.2, 0.2, 0.22)))
		B.box(self, Vector3(0.4, 0.15, 8.8), Vector3(sx * 17.8, 0.55, 4.5), B.mat(Color(0.1, 0.3, 0.12), 0.9))


func _build_tower() -> void:
	_tower_mat = B.smat(B.BUILDING_SHADER, {
		"base_color": col.darkened(0.82), "trim_color": col, "window_color": Color(1.0, 0.82, 0.5).lerp(col, 0.25),
		"lit_ratio": 0.6, "window_energy": 1.25, "seed": float(team) * 3.7 + 1.0, "trim_energy": 0.5, "cell": Vector2(2.25, 1.6)})
	_tower = B.box(self, Vector3(18, 1, 10), Vector3(0, 0.5, -5), _tower_mat)
	# Первый этаж — зал, в который можно зайти. Снаружи — стены здания и стеклянная витрина.
	for sx in [-1, 1]:
		B.box(self, Vector3(0.1, GROUND_H, 10), Vector3(sx * 8.95, GROUND_H * 0.5, -5), _tower_mat)
	B.box(self, Vector3(18, GROUND_H, 0.1), Vector3(0, GROUND_H * 0.5, -9.95), _tower_mat)
	var glass := B.glass(Color(1.0, 0.85, 0.6).lerp(col, 0.2), 0.16)
	for sx in [-1, 1]:
		B.box(self, Vector3(7.2, 4.2, 0.05), Vector3(sx * 5.1, 2.3, 0.03), glass, false)
	B.box(self, Vector3(3.0, 1.1, 0.05), Vector3(0, 3.85, 0.03), glass, false)
	for i in 7:
		if i == 3:
			continue
		var x := -7.5 + i * 2.5
		B.box(self, Vector3(0.18, 4.3, 0.2), Vector3(x, 2.2, 0.1), B.mat(col.darkened(0.5), 0.3, 0.8))
	B.box(self, Vector3(18.3, 0.3, 0.35), Vector3(0, 4.55, 0.12), B.neon(col, 3.5))
	# Рама дверей
	var gold := B.mat(Color(0.8, 0.6, 0.2), 0.2, 1.0)
	B.box(self, Vector3(3.4, 0.3, 0.3), Vector3(0, 3.45, 0.12), gold)
	for sx in [-1, 1]:
		B.box(self, Vector3(0.2, 3.3, 0.3), Vector3(sx * 1.6, 1.85, 0.12), gold)
	# Кондиционер и электрощиток: соседи подкидывают сюда тухлую рыбу и портят музыку
	var ac := Game.SPOT.ac
	B.box(self, Vector3(1.1, 0.75, 0.5), Vector3(ac.x, 3.1, 0.32), B.mat(Color(0.82, 0.84, 0.86), 0.4, 0.3))
	B.cyl(self, 0.28, 0.28, 0.04, Vector3(ac.x - 0.2, 3.1, 0.58), B.mat(Color(0.2, 0.2, 0.22), 0.5, 0.6), 14).rotation.x = PI * 0.5
	B.box(self, Vector3(0.06, 2.9, 0.06), Vector3(ac.x + 0.45, 1.55, 0.18), B.mat(Color(0.6, 0.6, 0.62), 0.4, 0.8))
	var panel := Game.SPOT.panel
	B.box(self, Vector3(0.8, 1.0, 0.2), Vector3(panel.x, 3.0, 0.22), B.mat(Color(0.45, 0.47, 0.5), 0.5, 0.6))
	B.label(self, "⚡ ЩИТОК", Vector3(panel.x, 3.0, 0.34), 32, Color(1.0, 0.85, 0.1), Color.BLACK, 0.008, font_title)
	_hall = Hall.new()
	add_child(_hall)
	_hall.setup(team, col, "wall_damask_red" if team == 0 else "wall_damask_teal")
	# Неоновые углы — растут с уровнем
	for sx in [-1, 1]:
		var strip := B.box(self, Vector3(0.22, 1, 0.22), Vector3(sx * 9.05, 0.5, 0.05), B.neon(acc, 4.0), false)
		_scalers.append(strip)
		var strip2 := B.box(self, Vector3(0.22, 1, 0.22), Vector3(sx * 9.05, 0.5, -10.0), B.neon(col, 3.0), false)
		_scalers.append(strip2)
	# Козырёк с бегущими огнями
	B.box(self, Vector3(9, 0.45, 3.2), Vector3(0, 4.25, 1.6), B.mat(Color(0.08, 0.05, 0.1), 0.4, 0.5))
	var bulbs := B.smat(B.BULBS_SHADER, {"color": Color(1, 0.85, 0.45), "energy": 6.0})
	B.box(self, Vector3(9.1, 0.2, 0.08), Vector3(0, 4.25, 3.22), bulbs, false)
	B.box(self, Vector3(0.08, 0.2, 3.2), Vector3(-4.55, 4.25, 1.6), bulbs, false)
	B.box(self, Vector3(0.08, 0.2, 3.2), Vector3(4.55, 4.25, 1.6), bulbs, false)
	B.box(self, Vector3(8.6, 0.05, 2.9), Vector3(0, 4.0, 1.6), B.neon(Color(1, 0.8, 0.5), 1.5), false)
	B.light(self, Vector3(0, 3.4, 2.4), Color(1, 0.75, 0.45), 2.2, 9.0)
	# Подсветка фасада
	for sx in [-1, 1]:
		B.spot(self, Vector3(sx * 8.0, 0.3, 2.2), Vector3(0, 1, -0.22), col, 7.0, 26.0, 18.0)
	# Крыша
	_roof = Node3D.new()
	add_child(_roof)
	B.box(_roof, Vector3(18.4, 0.35, 10.4), Vector3(0, 0.17, -5), B.mat(Color(0.12, 0.1, 0.13), 0.8))
	B.box(_roof, Vector3(18.5, 0.22, 0.25), Vector3(0, 0.4, 0.1), B.neon(acc, 4.0), false)
	B.box(_roof, Vector3(2.2, 1.2, 1.6), Vector3(6.5, 0.9, -8.0), B.mat(Color(0.5, 0.5, 0.55), 0.5, 0.6))
	B.box(_roof, Vector3(1.6, 0.9, 1.6), Vector3(-7.0, 0.8, -8.5), B.mat(Color(0.5, 0.5, 0.55), 0.5, 0.6))
	# Маленькая вывеска (до покупки неона)
	_sign_small = Node3D.new()
	_roof.add_child(_sign_small)
	B.box(_sign_small, Vector3(7, 1.5, 0.3), Vector3(0, 1.2, -0.5), B.mat(Color(0.15, 0.13, 0.12), 0.9))
	B.sign2(_sign_small, "КАЗИНО", Vector3(0, 1.2, -0.3), 110, Color(0.85, 0.82, 0.7), Color(0.1, 0.1, 0.1), 0.01, font_title)
	_sign_small.get_child(2).position.z = -0.67
	# Большая неоновая вывеска
	_sign_big = Node3D.new()
	_sign_big.position = Vector3(0, 0.3, -0.6)
	_roof.add_child(_sign_big)
	for sx in [-1, 1]:
		B.box(_sign_big, Vector3(0.25, 1.4, 0.25), Vector3(sx * 5.0, 0.7, 0), B.mat(Color(0.2, 0.2, 0.22), 0.5, 0.8))
	B.box(_sign_big, Vector3(16, 3.6, 0.5), Vector3(0, 3.1, 0), B.mat(Color(0.06, 0.03, 0.08), 0.6))
	var sb := B.smat(B.BULBS_SHADER, {"color": col, "energy": 7.0, "speed": 3.0})
	B.box(_sign_big, Vector3(16.2, 0.18, 0.6), Vector3(0, 4.95, 0), sb, false)
	B.box(_sign_big, Vector3(16.2, 0.18, 0.6), Vector3(0, 1.25, 0), sb, false)
	B.box(_sign_big, Vector3(0.18, 3.7, 0.6), Vector3(-8.05, 3.1, 0), sb, false)
	B.box(_sign_big, Vector3(0.18, 3.7, 0.6), Vector3(8.05, 3.1, 0), sb, false)
	_sign_labels = B.sign2(_sign_big, Defs.TEAM_NAMES[team].to_upper(), Vector3(0, 3.35, 0.24), 150, col * 2.2, acc, 0.0105, font_title)
	_sign_labels[1].position.z = -0.27
	for l in B.sign2(_sign_big, "КАЗИНО • 24/7 • ДЖЕКПОТ", Vector3(0, 2.0, 0.24), 54, Color(1.6, 1.5, 1.4), Color(0.1, 0.05, 0.1), 0.0105, font_body):
		_sign_labels.append(l)
	_sign_labels[3].position.z = -0.27
	_sign_big.visible = false
	# Отель (позади), прячется до покупки
	_hotel = B.box(self, Vector3(14, 1, 7), Vector3(0, 0.5, -13.6), B.smat(B.BUILDING_SHADER, {
		"base_color": Color(0.12, 0.12, 0.16), "trim_color": Color(0.8, 0.85, 1.0), "window_color": Color(1.0, 0.9, 0.7),
		"lit_ratio": 0.6, "window_energy": 1.1, "seed": float(team) + 9.0, "trim_energy": 0.15, "cell": Vector2(1.8, 1.6), "ground_h": 1.0}))
	_hotel.visible = false
	_hotel_sign = Node3D.new()
	add_child(_hotel_sign)
	_hotel_sign.visible = false
	for l in B.sign2(_hotel_sign, "H\nO\nT\nE\nL", Vector3(0, 0, 0), 120, Color(2.2, 2.2, 2.6), Color(0.3, 0.3, 0.9), 0.012, font_title):
		l.position.z = 0.02 if l.rotation.y == 0 else -0.02
	_hotel_sign.position = Vector3(5.6, 0, -10.05)
	_set_height(1, false)


func _set_height(lvl: int, animate: bool) -> void:
	level = lvl
	var h := h_for(lvl)
	if animate:
		var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_method(_apply_height, height, h, 1.6)
	else:
		_apply_height(h)


func _apply_height(h: float) -> void:
	height = h
	_tower.scale.y = h - GROUND_H
	_tower.position.y = GROUND_H + (h - GROUND_H) * 0.5
	for s in _scalers:
		s.scale.y = h
		s.position.y = h * 0.5
	_roof.position.y = h
	var hh := h + 10.0
	_hotel.scale.y = hh
	_hotel.position.y = hh * 0.5
	_hotel_sign.position.y = h + 6.0
	if _lift_shaft:
		_lift_shaft.scale.y = h
		_lift_shaft.position.y = h * 0.5


# =============================================================================
# Модули зданий и защиты
# =============================================================================
func _mod(id: String) -> Node3D:
	var n := Node3D.new()
	n.name = id
	add_child(n)
	n.visible = false
	_modules[id] = n
	return n


func _npc(parent: Node3D, type: String, pos: Vector3, yaw := 0.0) -> Node3D:
	var p: Node3D = PV.new()
	parent.add_child(p)
	p.setup(type, randi(), font_body)
	p.set_detail(true)
	p.position = pos
	p.target_pos = pos
	p.rotation.y = yaw
	p.target_yaw = yaw
	return p


func _slot_row(parent: Node3D, x0: float, gold: bool) -> void:
	for i in 4:
		var x := x0 + i * 1.4
		var body_c := Color(0.85, 0.65, 0.15) if gold else Color(0.55, 0.05, 0.1)
		B.box(parent, Vector3(1.05, 1.8, 0.8), Vector3(x, 1.08, 1.6), B.mat(body_c, 0.25, 0.8 if gold else 0.3))
		var scr_c := Color(0.3, 1.0, 0.6) if i % 2 == 0 else Color(1.0, 0.4, 0.9)
		if gold:
			scr_c = Color(1.0, 0.9, 0.4)
		B.box(parent, Vector3(0.75, 0.55, 0.05), Vector3(x, 1.4, 2.02), B.neon(scr_c, 2.5), false)
		var top := B.sphere(parent, 0.16, Vector3(x, 2.15, 1.6), B.neon(Color(1, 0.2, 0.2) if not gold else Color(1, 1, 0.6), 5.0), false, 10)
		_blink_mats.append(top)
		B.cyl(parent, 0.04, 0.04, 0.5, Vector3(x + 0.6, 1.4, 1.6), B.mat(Color(0.8, 0.8, 0.85), 0.2, 1.0), 6)
		B.sphere(parent, 0.08, Vector3(x + 0.6, 1.68, 1.6), B.mat(Color(0.9, 0.1, 0.1), 0.3), false, 8)
	B.box(parent, Vector3(5.8, 0.15, 1.6), Vector3(x0 + 2.1, 2.55, 1.6), B.mat(Color(0.1, 0.05, 0.12), 0.4, 0.4))
	B.box(parent, Vector3(5.9, 0.12, 0.06), Vector3(x0 + 2.1, 2.55, 2.42), B.smat(B.BULBS_SHADER, {"color": Color(1, 0.3, 0.3) if not gold else Color(1, 0.85, 0.3), "energy": 6.0}), false)


func _build_modules() -> void:
	var m: Node3D
	# --- Автоматы
	m = _mod("slots")
	_slot_row(m, -8.4, false)
	B.solid(m, Vector3(5.8, 2.6, 0.8), Vector3(-6.3, 1.3, 1.6))
	m = _mod("slots2")
	_slot_row(m, 3.6, true)
	B.solid(m, Vector3(5.8, 2.6, 0.8), Vector3(5.7, 1.3, 1.6))
	# --- Бар
	m = _mod("bar")
	B.box(m, Vector3(6, 4, 8), Vector3(-12.6, 2.0, -3.0), B.mat(Color(0.25, 0.12, 0.06), 0.8))
	B.solid(m, Vector3(6, 4, 8), Vector3(-12.6, 2.0, -3.0))
	B.box(m, Vector3(5.2, 2.2, 0.1), Vector3(-12.6, 1.6, 1.02), B.mat(Color(0.2, 0.1, 0.03), 0.1, 0.0, Color(1, 0.55, 0.2), 1.6))
	B.box(m, Vector3(6.3, 0.3, 8.3), Vector3(-12.6, 4.1, -3.0), B.mat(Color(0.12, 0.08, 0.05)))
	for l in B.sign2(m, "BAR", Vector3(-12.6, 3.3, 1.1), 130, Color(2.6, 1.3, 0.4), Color(0.6, 0.1, 0.0), 0.01, font_title):
		pass
	B.label(m, "«ПОСЛЕДНЯЯ РЮМКА»", Vector3(-12.6, 2.85, 1.1), 36, Color(1.5, 1.2, 0.9), Color.BLACK, 0.01, font_body)
	B.light(m, Vector3(-12.6, 2.0, 2.4), Color(1, 0.55, 0.2), 1.6, 7.0)
	# --- Туалет
	m = _mod("toilet")
	B.box(m, Vector3(1.8, 2.5, 1.8), Vector3(-16.4, 1.43, 4.0), B.mat(Color(0.2, 0.45, 0.85), 0.5))
	B.solid(m, Vector3(1.8, 2.6, 1.8), Vector3(-16.4, 1.3, 4.0))
	B.box(m, Vector3(1.0, 1.9, 0.06), Vector3(-16.4, 1.15, 4.92), B.mat(Color(0.9, 0.9, 0.95), 0.4))
	B.label(m, "WC", Vector3(-16.4, 2.4, 4.95), 72, Color(2, 2, 2.4), Color(0.1, 0.2, 0.6), 0.01, font_title)
	# --- Музыка
	m = _mod("music")
	for sx in [-1, 1]:
		var sp := Node3D.new()
		sp.position = Vector3(sx * 3.0, 0.18, 0.8)
		m.add_child(sp)
		B.box(sp, Vector3(0.95, 1.9, 0.8), Vector3(0, 0.95, 0), B.mat(Color(0.05, 0.05, 0.06), 0.6))
		B.cyl(sp, 0.32, 0.32, 0.06, Vector3(0, 0.6, 0.41), B.mat(Color(0.15, 0.15, 0.18), 0.4, 0.5)).rotation.x = PI * 0.5
		B.cyl(sp, 0.17, 0.17, 0.06, Vector3(0, 1.4, 0.41), B.mat(Color(0.15, 0.15, 0.18), 0.4, 0.5)).rotation.x = PI * 0.5
		B.box(sp, Vector3(0.96, 0.06, 0.82), Vector3(0, 1.9, 0), B.neon(Color(0.6, 0.4, 1.0), 4.0), false)
		_speakers.append(sp)
		B.solid(m, Vector3(0.95, 2.0, 0.8), Vector3(sx * 3.0, 1.1, 0.8))
	# --- Аромат
	m = _mod("aroma")
	for sx in [-1, 1]:
		B.cyl(m, 0.18, 0.24, 1.1, Vector3(sx * 1.95, 0.73, 0.6), B.mat(Color(0.2, 0.9, 0.5), 0.3, 0.5, Color(0.2, 1.0, 0.5), 1.0), 10)
		var p := B.particles(m, Vector3(sx * 1.95, 1.4, 0.6), 16, 3.0, Color(0.5, 1.0, 0.6, 0.35), 0.5, Vector3(0, 0.6, 0.4), 25.0, Vector3(0, 0.05, 0), Vector3.ZERO, 1.0)
		p.emitting = true
	# --- Фонтан
	m = _mod("fountain")
	B.cyl(m, 2.0, 2.2, 0.6, Vector3(-7.0, 0.48, 5.4), B.mat(Color(0.6, 0.58, 0.55), 0.6), 24)
	B.solid(m, Vector3(3.6, 1.2, 3.6), Vector3(-7.0, 0.6, 5.4))
	B.cyl(m, 1.8, 1.8, 0.05, Vector3(-7.0, 0.76, 5.4), B.mat(Color(0.1, 0.35, 0.6), 0.02, 0.2, Color(0.1, 0.4, 0.8), 0.8), 24)
	B.cyl(m, 0.25, 0.35, 1.6, Vector3(-7.0, 1.3, 5.4), B.mat(Color(0.65, 0.62, 0.58), 0.5), 12)
	B.sphere(m, 0.35, Vector3(-7.0, 2.2, 5.4), B.mat(Color(1, 0.8, 0.2), 0.2, 1.0, Color(1, 0.7, 0.2), 0.8), false, 12)
	var water := B.particles(m, Vector3(-7.0, 2.3, 5.4), 60, 1.3, Color(0.6, 0.85, 1.0, 0.7), 0.16, Vector3(0, 4.0, 0), 20.0, Vector3(0, -9.0, 0), Vector3.ZERO, 1.5)
	water.emitting = true
	B.light(m, Vector3(-7.0, 1.0, 5.4), Color(0.3, 0.6, 1.0), 1.5, 5.0)
	# --- Ресторан
	m = _mod("restaurant")
	B.box(m, Vector3(6, 4, 8), Vector3(12.6, 2.0, -3.0), B.mat(Color(0.5, 0.42, 0.35), 0.8))
	B.solid(m, Vector3(6, 4, 8), Vector3(12.6, 2.0, -3.0))
	B.box(m, Vector3(5.2, 2.4, 0.1), Vector3(12.6, 1.6, 1.02), B.mat(Color(0.2, 0.1, 0.03), 0.1, 0.0, Color(1, 0.8, 0.5), 1.4))
	for i in 8:
		var c := Color(0.85, 0.1, 0.1) if i % 2 == 0 else Color(0.95, 0.95, 0.9)
		var aw := B.box(m, Vector3(0.75, 0.08, 2.0), Vector3(9.97 + i * 0.75, 3.2, 1.8), B.mat(c, 0.7))
		aw.rotation.x = 0.35
	B.label(m, "РЕСТОРАН «ПОСЛЕДНИЙ УЖИН»", Vector3(12.6, 3.75, 1.06), 44, Color(2.4, 2.0, 1.4), Color(0.4, 0.1, 0.0), 0.01, font_body)
	for tx in [11.8, 14.8]:
		B.cyl(m, 0.7, 0.7, 0.06, Vector3(tx, 0.95, 4.2), B.mat(Color(0.95, 0.95, 0.95), 0.5), 16)
		B.cyl(m, 0.06, 0.06, 0.8, Vector3(tx, 0.55, 4.2), B.mat(Color(0.2, 0.2, 0.2)), 6)
		B.cyl(m, 0.04, 0.04, 2.2, Vector3(tx, 1.9, 4.2), B.mat(Color(0.8, 0.8, 0.8)), 6)
		B.cyl(m, 0.05, 1.4, 0.5, Vector3(tx, 3.0, 4.2), B.mat(Color(0.9, 0.2, 0.2), 0.7), 12)
		B.light(m, Vector3(tx, 2.2, 4.2), Color(1, 0.75, 0.45), 0.8, 4.0)
	# --- Отель — отдельная логика (_hotel)
	B.solid(_mod("hotel"), Vector3(14, 60, 7), Vector3(0, 30, -13.6))
	# --- VIP
	m = _mod("vip")
	B.box(m, Vector3(2.2, 0.03, 8.8), Vector3(0, 0.21, 4.6), B.mat(Color(0.6, 0.02, 0.06), 0.9), false)
	for z in [1.5, 3.5, 5.5, 7.5]:
		for sx in [-1, 1]:
			B.cyl(m, 0.06, 0.09, 1.0, Vector3(sx * 1.35, 0.68, z), B.mat(Color(1, 0.8, 0.25), 0.2, 1.0), 8)
			B.sphere(m, 0.1, Vector3(sx * 1.35, 1.22, z), B.mat(Color(1, 0.8, 0.25), 0.2, 1.0), false, 8)
	for sx in [-1, 1]:
		for z in [2.5, 4.5, 6.5]:
			var rope := B.cyl(m, 0.035, 0.035, 2.0, Vector3(sx * 1.35, 1.05, z), B.mat(Color(0.55, 0.0, 0.08), 0.6), 6)
			rope.rotation.x = PI * 0.5
	B.box(m, Vector3(8, 0.25, 1.6), Vector3(0, 6.4, 0.8), B.mat(Color(1, 0.8, 0.25), 0.15, 1.0))
	B.box(m, Vector3(8, 0.7, 0.06), Vector3(0, 6.85, 1.58), B.mat(Color(1, 0.8, 0.25), 0.15, 1.0))
	B.label(m, "V I P", Vector3(0, 5.45, 0.25), 100, Color(2.8, 2.2, 0.8), Color(0.4, 0.2, 0.0), 0.01, font_title)
	# --- Крупье
	m = _mod("dealers")
	for tx in [6.0, 9.4]:
		B.cyl(m, 1.1, 1.0, 0.85, Vector3(tx, 0.6, 5.6), B.mat(Color(0.35, 0.2, 0.1), 0.5), 20)
		B.cyl(m, 1.05, 1.05, 0.04, Vector3(tx, 1.04, 5.6), B.mat(Color(0.05, 0.45, 0.2), 0.9), 20)
		for k in 3:
			B.box(m, Vector3(0.12, 0.08, 0.12), Vector3(tx - 0.4 + k * 0.4, 1.1, 5.9), B.mat([Color(0.9, 0.1, 0.1), Color(0.1, 0.1, 0.9), Color(0.1, 0.8, 0.2)][k], 0.4), false)
		_npc(m, "dealer", Vector3(tx, 0.18, 4.3), 0.0)
		B.solid(m, Vector3(2.1, 1.2, 2.1), Vector3(tx, 0.6, 5.6))
		B.light(m, Vector3(tx, 2.6, 5.6), Color(1, 0.9, 0.7), 1.2, 4.5)
	# --- Шоу на крыше
	m = _mod("show")
	_reparent_to_roof(m)
	B.box(m, Vector3(7, 0.5, 5), Vector3(-4.5, 0.6, -6.2), B.mat(Color(0.1, 0.05, 0.12), 0.3, 0.6))
	B.box(m, Vector3(7.1, 0.12, 5.1), Vector3(-4.5, 0.9, -6.2), B.smat(B.BULBS_SHADER, {"color": Color(1, 0.4, 0.9), "energy": 5.0}), false)
	for i in 3:
		_npc(m, "dancer", Vector3(-6.3 + i * 1.8, 0.95, -6.0), 0.0)
	for sx in [-1, 1]:
		var piv := Node3D.new()
		piv.position = Vector3(-4.5 + sx * 3.2, 0.9, -8.3)
		m.add_child(piv)
		var bm := B.beam(piv, Color(1, 0.5, 0.9) if sx < 0 else Color(0.5, 0.8, 1), 22.0, 2.2, 0.18)
		bm.position = Vector3(0, 11, 0)
		bm.rotation.x = PI
		_stage_beams.append(piv)
	B.light(m, Vector3(-4.5, 3.0, -4.0), Color(1, 0.4, 0.9), 3.0, 9.0)
	# --- Лифт
	m = _mod("lift")
	_lift_shaft = B.box(m, Vector3(1.6, 1, 1.2), Vector3(7.6, 0.5, 0.65), B.glass(Color(0.6, 1, 1), 0.25), false)
	B.solid(m, Vector3(1.6, 8.0, 1.2), Vector3(7.6, 4.0, 0.65))
	_lift_cabin = Node3D.new()
	m.add_child(_lift_cabin)
	B.box(_lift_cabin, Vector3(1.4, 1.9, 1.0), Vector3(7.6, 1.0, 0.65), B.mat(Color(0.9, 1, 1), 0.1, 0.5, Color(0.6, 1, 1), 2.0), false)
	# --- Салют (эмиттер на крыше, логика в _process)
	m = _mod("fireworks")
	_reparent_to_roof(m)
	for sx in [-1, 1]:
		B.cyl(m, 0.25, 0.3, 1.0, Vector3(sx * 7.5, 0.8, -2.0), B.mat(Color(0.3, 0.3, 0.32), 0.5, 0.7), 8)
	# --- Купол
	m = _mod("dome")
	_reparent_to_roof(m)
	B.sphere(m, 3.6, Vector3(4.0, 0.35, -5.5), B.mat(Color(1, 0.78, 0.2), 0.12, 1.0, Color(1, 0.6, 0.1), 0.25), true, 32)
	B.cyl(m, 0.08, 0.2, 3.0, Vector3(4.0, 5.3, -5.5), B.mat(Color(1, 0.78, 0.2), 0.12, 1.0), 8)
	B.sphere(m, 0.3, Vector3(4.0, 6.9, -5.5), B.neon(Color(1, 0.9, 0.5), 8.0), false, 10)
	B.light(m, Vector3(4.0, 6.0, -2.0), Color(1, 0.8, 0.4), 3.0, 12.0)
	# --- Защита: камеры
	m = _mod("cameras")
	for sx in [-1, 1]:
		var cam := Node3D.new()
		cam.position = Vector3(sx * 8.4, 5.6, 0.35)
		m.add_child(cam)
		B.box(cam, Vector3(0.12, 0.12, 0.5), Vector3(0, 0, 0.1), B.mat(Color(0.6, 0.6, 0.65), 0.3, 0.8))
		B.box(cam, Vector3(0.35, 0.3, 0.6), Vector3(0, -0.15, 0.5), B.mat(Color(0.85, 0.85, 0.88), 0.3, 0.4))
		var dot := B.sphere(cam, 0.05, Vector3(0.1, -0.05, 0.82), B.neon(Color(1, 0, 0), 8.0), false, 6)
		_blink_mats.append(dot)
		cam.rotation.y = -sx * 0.5
		cam.rotation.x = -0.35
	# --- Чистильщик
	m = _mod("cleaner")
	_cleaner = _npc(m, "cleaner", Vector3(-4.0, 0.18, 7.0))
	# --- Охрана
	m = _mod("guards")
	for sx in [-1, 1]:
		_npc(m, "guard", Vector3(sx * 1.75, 0.18, 1.9), 0.0)
	# --- Юрист
	m = _mod("lawyer")
	_npc(m, "lawyer", Vector3(3.2, 0.18, 4.2), -0.4)
	# --- PR: рекламный щит у тротуара
	m = _mod("pr")
	for sx in [-1, 1]:
		B.cyl(m, 0.1, 0.1, 4.4, Vector3(10.6 + sx * 2.0, 2.4, 8.4), B.mat(Color(0.3, 0.3, 0.32), 0.5, 0.8), 6)
		B.solid(m, Vector3(0.3, 4.4, 0.3), Vector3(10.6 + sx * 2.0, 2.2, 8.4))
	B.box(m, Vector3(5.6, 2.6, 0.25), Vector3(10.6, 4.6, 8.4), B.mat(Color(0.95, 0.95, 0.9), 0.6, 0.0, Color(1, 1, 0.95), 0.4))
	_pr_label = B.label(m, "", Vector3(10.6, 4.6, 8.56), 64, Color(0.75, 0.05, 0.1), Color(1, 1, 1), 0.0085, font_title)
	_pr_label.width = 600
	_pr_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var back := B.label(m, "МЫ ЧЕСТНЕЕ!", Vector3(10.6, 4.6, 8.24), 64, Color(0.75, 0.05, 0.1), Color.WHITE, 0.0085, font_title)
	back.rotation.y = PI
	B.spot(m, Vector3(10.6, 2.8, 10.0), Vector3(0, 0.6, -0.5), Color(1, 1, 0.9), 4.0, 8.0, 35.0)
	# --- Детектив
	m = _mod("detective")
	_npc(m, "detective", Vector3(-3.0, 0.18, 8.5), 0.0)
	B.box(m, Vector3(0.4, 0.8, 0.4), Vector3(-2.2, 0.6, 8.5), B.mat(Color(0.3, 0.25, 0.2)))
	for id in _modules:
		B.set_solid(_modules[id], false)


func _reparent_to_roof(n: Node3D) -> void:
	remove_child(n)
	_roof.add_child(n)


# =============================================================================
# Визуалы пакостей и баффов
# =============================================================================
func _eff(id: String, roof := false) -> Node3D:
	var n := Node3D.new()
	n.name = "fx_" + id
	if roof:
		_roof.add_child(n)
	else:
		add_child(n)
	n.visible = false
	_effects[id] = n
	return n


func _build_effects() -> void:
	var e: Node3D
	# Тараканы — мультимеш
	e = _eff("roaches")
	_roach_mm = MultiMeshInstance3D.new()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var rm := SphereMesh.new()
	rm.radius = 0.12
	rm.height = 0.1
	rm.radial_segments = 6
	rm.rings = 3
	rm.material = B.mat(Color(0.18, 0.08, 0.03), 0.3, 0.3)
	mm.mesh = rm
	mm.instance_count = 70
	_roach_mm.multimesh = mm
	_roach_mm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	e.add_child(_roach_mm)
	for i in 70:
		var on_wall := i < 25
		_roach_data.append({"p": Vector3(randf_range(-8, 8), randf_range(0.5, 6) if on_wall else 0.22, 0.12 if on_wall else randf_range(0.5, 8.5)),
			"a": randf() * TAU, "wall": on_wall, "s": randf_range(0.8, 1.6)})
	B.label(e, "ДЕЗИНСЕКЦИЯ?", Vector3(0, 5.2, 3.3), 44, Color(0.8, 0.5, 0.2), Color.BLACK, 0.01, font_title).billboard = BaseMaterial3D.BILLBOARD_ENABLED
	# Вонь
	e = _eff("stink")
	var fog := B.particles(e, Vector3(0, 0.8, 4.5), 40, 4.0, Color(0.45, 0.8, 0.1, 0.35), 3.0, Vector3(0, 0.4, 0), 60.0, Vector3(0, 0.1, 0), Vector3(8, 0.5, 4), 0.6)
	fog.emitting = true
	var flies := B.particles(e, Vector3(0, 1.8, 3.0), 40, 2.0, Color(0.05, 0.05, 0.05, 1), 0.1, Vector3(0, 0.5, 0), 180.0, Vector3.ZERO, Vector3(6, 1.2, 3))
	flies.emitting = true
	# Порча музыки
	e = _eff("music_break")
	var smoke := B.particles(e, Vector3(0, 2.2, 0.9), 30, 2.5, Color(0.35, 0.35, 0.35, 0.6), 1.0, Vector3(0, 1.2, 0), 25.0, Vector3(0, 0.3, 0), Vector3(3.2, 0.2, 0.2))
	smoke.emitting = true
	var mb := B.label(e, "♪ ХРРР ♪ ШАНСОН ♪", Vector3(0, 6.5, 2.0), 64, Color(1.2, 0.2, 0.2), Color(0.1, 0.0, 0.0), 0.01, font_title)
	mb.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	# Слухи
	e = _eff("rumor")
	var texts := ["БЛА-БЛА", "ГОВОРЯТ...", "?!", "ЖУЛИКИ!", "ТРАВЯТ?"]
	for i in texts.size():
		var l := B.label(e, texts[i], Vector3(-7 + i * 3.5, 6 + (i % 2) * 2.0, 3.0), 56, Color(1, 1, 1), Color(0.5, 0.0, 0.3), 0.01, font_title)
		l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_rumor_labels.append(l)
	# Потоп
	e = _eff("plumbing")
	var gey := B.particles(e, Vector3(-16.4, 2.8, 4.0), 80, 1.6, Color(0.55, 0.8, 1.0, 0.8), 0.25, Vector3(0, 7, 0), 12.0, Vector3(0, -9, 0), Vector3.ZERO, 1.0)
	gey.emitting = true
	var gey2 := B.particles(e, Vector3(0, 0.4, 0.6), 50, 1.2, Color(0.55, 0.75, 0.6, 0.8), 0.22, Vector3(0, 3, 2), 25.0, Vector3(0, -9, 0), Vector3(1, 0, 0), 0.5)
	gey2.emitting = true
	var puddle := B.cyl(e, 6.5, 6.5, 0.03, Vector3(-3, 0.2, 4.5), B.mat(Color(0.15, 0.25, 0.3), 0.02, 0.3), 24)
	puddle.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	puddle.scale = Vector3(1.4, 1, 0.6)
	B.label(e, "ЛИФТ НЕ РАБОТАЕТ", Vector3(0, 3.0, 0.2), 40, Color(1, 0.9, 0.2), Color.BLACK, 0.01, font_title)
	# Фальшивки
	e = _eff("fakemoney")
	var notes := B.particles(e, Vector3(0, 5, 3), 40, 3.0, Color(0.5, 0.9, 0.4, 1.0), 0.35, Vector3(0, -0.5, 0), 60.0, Vector3(0, -1.0, 0), Vector3(7, 1, 3))
	notes.emitting = true
	var fm := B.label(e, "$ ФАЛЬШИВКИ $", Vector3(0, 7.5, 2.0), 64, Color(0.5, 2.0, 0.5), Color(0.3, 0.0, 0.0), 0.01, font_title)
	fm.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	# Подкуп крупье — монеты утекают к дороге
	e = _eff("dealer_bribe")
	var coins := B.particles(e, Vector3(0, 1.5, 1.0), 50, 2.0, Color(1, 0.85, 0.2, 1), 0.25, Vector3(0, 4, 6), 20.0, Vector3(0, -6, 0), Vector3(1, 0.2, 0.2), 3.0)
	coins.emitting = true
	# Новости — фургон
	e = _eff("news")
	var van := Node3D.new()
	van.position = Vector3(-12.5, 0.18, 7.8)
	e.add_child(van)
	B.box(van, Vector3(5.0, 2.3, 2.2), Vector3(0, 1.55, 0), B.mat(Color(0.95, 0.95, 0.97), 0.4, 0.2))
	B.box(van, Vector3(5.02, 0.4, 2.22), Vector3(0, 1.4, 0), B.mat(Color(0.8, 0.1, 0.1)))
	for wx in [-1.6, 1.6]:
		for wz in [-1.0, 1.0]:
			var w := B.cyl(van, 0.4, 0.4, 0.3, Vector3(wx, 0.4, wz), B.mat(Color(0.05, 0.05, 0.05)), 10)
			w.rotation.x = PI * 0.5
	B.cyl(van, 0.05, 0.05, 1.2, Vector3(1.0, 3.2, 0), B.mat(Color(0.7, 0.7, 0.7)), 6)
	var dish := B.sphere(van, 0.8, Vector3(1.0, 3.9, 0), B.mat(Color(0.9, 0.9, 0.9), 0.3, 0.5), true, 14)
	dish.rotation.x = -1.0
	for l in B.sign2(van, "НОВОСТИ 24", Vector3(0, 1.95, 1.13), 60, Color(0.8, 0.1, 0.1), Color.WHITE, 0.01, font_title):
		l.position.z = 1.13 if l.rotation.y == 0 else -1.13
	_npc(e, "reporter", Vector3(-9.5, 0.18, 5.5), PI * 0.8)
	B.spot(e, Vector3(-9.0, 2.2, 6.0), Vector3(0.5, 0.15, -1), Color(1, 1, 0.95), 10.0, 18.0, 25.0)
	var nl := B.label(e, "СКАНДАЛ!", Vector3(0, 8.5, 2.5), 90, Color(2.5, 0.3, 0.3), Color(1, 1, 1), 0.01, font_title)
	nl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	# Массовый уход — тревога
	e = _eff("exodus")
	_alarm_light = B.light(e, Vector3(0, 4.0, 3.0), Color(1, 0.05, 0.05), 6.0, 18.0)
	var al := B.label(e, "ТРЕВОГА!", Vector3(0, 5.6, 3.3), 80, Color(2.5, 0.2, 0.2), Color(1, 1, 0.2), 0.01, font_title)
	al.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	# Чёрный понедельник — туча, дождь, молнии
	e = _eff("black_monday", true)
	for i in 9:
		var cl := B.sphere(e, randf_range(2.5, 4.0), Vector3(randf_range(-9, 9), 9.0 + randf_range(-0.5, 1.0), randf_range(-9, 3)), B.mat(Color(0.12, 0.12, 0.14), 1.0), false, 12)
		cl.scale.y = 0.5
		cl.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var rain := B.particles(e, Vector3(0, 8.0, -1), 220, 1.2, Color(0.6, 0.7, 0.9, 0.6), 0.08, Vector3(0, -14, 0), 2.0, Vector3(0, -20, 0), Vector3(11, 0.5, 8))
	rain.emitting = true
	_lightning = B.light(e, Vector3(0, 7.0, 0), Color(0.8, 0.85, 1.0), 0.0, 40.0)
	var bml := B.label(e, "ЧЁРНЫЙ ПОНЕДЕЛЬНИК", Vector3(0, 13.5, -2), 90, Color(0.6, 0.6, 0.7), Color.BLACK, 0.012, font_title)
	bml.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	# Операция Дорога — ремонт
	e = _eff("road_op")
	for i in 7:
		var cone := Node3D.new()
		cone.position = Vector3(-4.5 + i * 1.5, 0.18, 8.7)
		e.add_child(cone)
		B.cyl(cone, 0.04, 0.3, 0.8, Vector3(0, 0.4, 0), B.mat(Color(1, 0.4, 0.05), 0.5, 0.0, Color(1, 0.35, 0.0), 0.5), 10)
		B.cyl(cone, 0.18, 0.21, 0.12, Vector3(0, 0.45, 0), B.mat(Color(1, 1, 1), 0.5), 10)
	for sx in [-1, 1]:
		for k in 3:
			var bar := B.box(e, Vector3(1.4, 0.25, 0.1), Vector3(sx * 1.5 + (k - 1) * 0.0, 0.7 + k * 0.0, 8.2), B.mat(Color(1, 1, 1) if k % 2 == 0 else Color(0.9, 0.1, 0.1)))
			bar.position.x = sx * 1.5
			bar.position.y = 0.5 + k * 0.3
	var exc := Node3D.new()
	exc.position = Vector3(5.5, 0.18, 10.3)
	exc.rotation.y = 0.4
	e.add_child(exc)
	var yel := B.mat(Color(1, 0.75, 0.05), 0.5, 0.2)
	B.box(exc, Vector3(3.2, 0.7, 2.0), Vector3(0, 0.45, 0), B.mat(Color(0.15, 0.15, 0.15)))
	B.box(exc, Vector3(2.6, 1.2, 2.0), Vector3(0, 1.4, 0), yel)
	B.box(exc, Vector3(1.2, 1.2, 1.4), Vector3(-0.6, 2.6, 0), B.glass(Color(0.4, 0.6, 0.8), 0.5))
	var arm := B.box(exc, Vector3(0.4, 0.4, 3.4), Vector3(0.6, 2.8, -1.4), yel)
	arm.rotation.x = 0.6
	B.box(exc, Vector3(1.0, 0.8, 0.6), Vector3(0.6, 1.6, -3.0), yel)
	var beacon := B.sphere(exc, 0.15, Vector3(-0.6, 3.3, 0), B.neon(Color(1, 0.6, 0.0), 8.0), false, 8)
	_blink_mats.append(beacon)
	var rl := B.label(e, "РЕМОНТ ДОРОГИ\nПРОХОДА НЕТ", Vector3(0, 2.3, 8.25), 48, Color(1, 0.9, 0.2), Color.BLACK, 0.01, font_title)
	B.solid(e, Vector3(11.0, 1.4, 0.5), Vector3(0, 0.7, 8.3))
	rl.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	B.light(e, Vector3(0, 2.0, 9.5), Color(1, 0.6, 0.1), 2.0, 8.0)
	# Война вывесок обрабатывается в apply_state
	# Баффы: коктейли
	e = _eff("party")
	for i in 3:
		var pl := B.light(e, Vector3(-3 + i * 3, 3.5, 5.0), [Color(1, 0.2, 0.6), Color(0.2, 0.6, 1), Color(0.4, 1, 0.3)][i], 3.0, 9.0)
		_party_lights.append(pl)
	var conf := B.particles(e, Vector3(0, 6, 4), 80, 3.0, Color(1, 0.6, 0.9, 1), 0.18, Vector3(0, 1, 0), 180.0, Vector3(0, -2.0, 0), Vector3(6, 0.5, 3), 2.0)
	conf.emitting = true
	var fd := B.label(e, "FREE DRINKS!", Vector3(0, 6.5, 3.4), 72, Color(0.6, 2.4, 1.6), Color(0.3, 0, 0.3), 0.01, font_title)
	fd.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	# Баффы: большой розыгрыш
	e = _eff("grand_raffle", true)
	_raffle_wheel = Node3D.new()
	_raffle_wheel.position = Vector3(0, 7.5, -3.5)
	e.add_child(_raffle_wheel)
	var segs := 12
	for i in segs:
		var spoke := Node3D.new()
		spoke.rotation.z = TAU * i / segs
		_raffle_wheel.add_child(spoke)
		var c: Color = [Color(1, 0.2, 0.3), Color(1, 0.85, 0.2), Color(0.2, 0.7, 1), Color(0.3, 1, 0.4)][i % 4]
		B.box(spoke, Vector3(1.4, 3.2, 0.2), Vector3(0, 1.75, 0), B.mat(c, 0.4, 0.2, c, 1.2))
	B.cyl(_raffle_wheel, 0.5, 0.5, 0.5, Vector3.ZERO, B.mat(Color(1, 0.8, 0.2), 0.2, 1.0), 12).rotation.x = PI * 0.5
	B.box(e, Vector3(0.4, 7.5, 0.4), Vector3(0, 3.75, -3.8), B.mat(Color(0.3, 0.3, 0.35), 0.4, 0.8))
	var rc := B.particles(e, Vector3(0, 9, 0), 120, 4.0, Color(1, 0.85, 0.3, 1), 0.22, Vector3(0, 3, 0), 180.0, Vector3(0, -2.0, 0), Vector3(9, 0.5, 6), 3.0)
	rc.emitting = true
	for sx in [-1, 1]:
		var piv := Node3D.new()
		piv.position = Vector3(sx * 8.0, 0.5, -9.0)
		e.add_child(piv)
		var bm := B.beam(piv, Color(1, 0.95, 0.7), 40.0, 3.0, 0.15)
		bm.position = Vector3(0, 20, 0)
		bm.rotation.x = PI
		_raffle_beams.append(piv)
	var gl := B.label(e, "БОЛЬШОЙ РОЗЫГРЫШ!", Vector3(0, 12.0, -3.5), 110, Color(2.5, 2.0, 0.5), Color(0.5, 0.0, 0.2), 0.012, font_title)
	gl.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	# Свои таксисты
	e = _eff("taxi")
	B.box(e, Vector3(0.12, 3.0, 0.12), Vector3(4.0, 1.6, 8.8), B.mat(Color(0.4, 0.4, 0.4), 0.5, 0.8))
	B.box(e, Vector3(1.6, 0.8, 0.12), Vector3(4.0, 3.2, 8.8), B.neon(Color(1, 0.85, 0.1), 3.0))
	B.sign2(e, "TAXI", Vector3(4.0, 3.2, 8.88), 60, Color(0.1, 0.1, 0.1), Color(1, 0.9, 0.3), 0.01, font_title)[1].position.z = 8.72
	# Полиция (вспышка при поимке)
	_police = Node3D.new()
	add_child(_police)
	_police.visible = false
	var pr := B.light(_police, Vector3(-1.5, 2.5, 6.5), Color(1, 0.1, 0.1), 0.0, 14.0)
	var pb := B.light(_police, Vector3(1.5, 2.5, 6.5), Color(0.1, 0.3, 1), 0.0, 14.0)
	_police.set_meta("lights", [pr, pb])
	var pl2 := B.label(_police, "ПОЙМАН!", Vector3(0, 7.5, 4.0), 110, Color(2.6, 0.3, 0.3), Color(1, 1, 1), 0.012, font_title)
	pl2.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_flash = B.light(self, Vector3(0, 4.0, 4.0), Color(1, 0.15, 0.1), 0.0, 20.0)
	for id in _effects:
		B.set_solid(_effects[id], false)


# =============================================================================
# Применение состояния
# =============================================================================
func apply_state(st: Dictionary) -> void:
	var first := not _initialized
	_initialized = true
	if int(st.level) != level:
		_set_height(int(st.level), not first)
	for id in _modules:
		var want: bool = st.built.has(id) or st.defense.has(id)
		var n: Node3D = _modules[id]
		if want != n.visible:
			n.visible = want
			B.set_solid(n, want)
			if want and not first:
				_pop(n)
	_hall.apply_state(st)
	_hotel.visible = st.built.has("hotel")
	_hotel_sign.visible = _hotel.visible
	var has_sign: bool = st.built.has("sign")
	_sign_small.visible = not has_sign
	_sign_big.visible = has_sign
	var sign_mode := "normal"
	if st.effects.has("sign_war"):
		sign_mode = "off"
	elif st.buffs.has("sign_war_own"):
		sign_mode = "mega"
	if sign_mode != _state_sign:
		_state_sign = sign_mode
		_sign_scale = 1.9 if sign_mode == "mega" else 1.0
		var tw := create_tween()
		tw.tween_property(_sign_big, "scale", Vector3.ONE * _sign_scale, 0.8).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		if sign_mode != "off":
			for l in _sign_labels:
				l.modulate.a = 1.0
	for id in _effects:
		var on: bool = st.effects.has(id) or st.buffs.has(id)
		if _effects[id].visible != on:
			_effects[id].visible = on
			B.set_solid(_effects[id], on)
	_tower_mat.set_shader_parameter("dim", 0.25 if st.effects.has("black_monday") else 1.0)


func _pop(n: Node3D) -> void:
	n.scale = Vector3(1, 0.01, 1)
	var tw := create_tween()
	tw.tween_property(n, "scale", Vector3.ONE, 0.7).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func play_fx(name: String) -> void:
	if name == "levelup":
		for i in 6:
			get_tree().create_timer(i * 0.25).timeout.connect(_firework)
	elif name.begins_with("build:"):
		var id := name.substr(6)
		var pos := Vector3(0, 1, 4)
		if _modules.has(id) and _modules[id].get_child_count() > 0:
			var c = _modules[id].get_child(0)
			if c is Node3D:
				pos = to_local(c.global_position)
		B.burst(self, pos + Vector3(0, 0.5, 0), col, 40, 5.0, 0.3, 1.0, Vector3(0, -4, 0))
		B.burst(self, pos + Vector3(0, 0.5, 0), Color(0.8, 0.75, 0.7, 0.8), 25, 2.0, 0.8, 1.2, Vector3(0, 0.5, 0))
	elif name == "caught":
		_police_t = 4.0
		_police.visible = true
	elif name.begins_with("hit:") or name == "brawl":
		_flash_t = 1.2
		if name == "brawl":
			var l := B.label(self, "!!! СКАНДАЛ !!!", Vector3(0, 4.5, 6.0), 80, Color(2.5, 0.4, 0.2), Color.BLACK, 0.01, font_title)
			l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			var tw := create_tween()
			tw.tween_property(l, "position:y", 7.0, 2.0)
			tw.tween_callback(l.queue_free)
	elif name == "cleanup":
		B.burst(self, Vector3(0, 1, 4), Color(0.6, 1, 1), 60, 6.0, 0.25, 1.2, Vector3(0, -3, 0))
	elif name == "pr":
		B.burst(self, Vector3(0, 6, 2), Color(1, 0.85, 0.3), 70, 7.0, 0.3, 1.5)
	elif name == "party" or name == "grand_raffle":
		for i in 3:
			get_tree().create_timer(i * 0.3).timeout.connect(_firework)


func _firework() -> void:
	if not is_inside_tree():
		return
	var c: Color = [Color(1, 0.3, 0.3), Color(0.3, 1, 0.5), Color(0.4, 0.6, 1), Color(1, 0.9, 0.3), Color(1, 0.4, 1), col][randi() % 6]
	var pos := Vector3(randf_range(-7, 7), height + randf_range(9, 15), randf_range(-8, 2))
	B.burst(self, pos, c, 90, 9.0, 0.35, 1.8, Vector3(0, -3, 0))
	var fl := B.light(self, pos, c, 6.0, 30.0)
	var tw := create_tween()
	tw.tween_property(fl, "light_energy", 0.0, 0.8)
	tw.tween_callback(fl.queue_free)
	Sfx.play("boom", -12.0, randf_range(0.8, 1.2))


# =============================================================================
# Анимации
# =============================================================================
func _process(delta: float) -> void:
	_t += delta
	var beat := absf(sin(_t * 4.2))
	for sp in _speakers:
		var k := 1.0 + beat * 0.06 if not _effects["music_break"].visible else 1.0 + randf() * 0.03
		sp.scale = Vector3(k, k, k)
	if _lift_cabin and _modules["lift"].visible:
		_lift_cabin.position.y = (sin(_t * 0.35) * 0.5 + 0.5) * maxf(0.0, height - 2.2)
	for i in _stage_beams.size():
		_stage_beams[i].rotation = Vector3(sin(_t * 0.9 + i * 2.0) * 0.6, 0, cos(_t * 0.7 + i) * 0.5)
	if _modules["fireworks"].visible:
		_fw_t -= delta
		if _fw_t <= 0.0:
			_fw_t = randf_range(5.0, 9.0)
			for i in 3:
				get_tree().create_timer(i * 0.3).timeout.connect(_firework)
	if _cleaner and _modules["cleaner"].visible:
		var p := Vector3(-4.0 + sin(_t * 0.25) * 4.0, 0.18, 6.8 + sin(_t * 0.5) * 0.8)
		_cleaner.moving = true
		_cleaner.target_yaw = atan2(p.x - _cleaner.target_pos.x, p.z - _cleaner.target_pos.z)
		_cleaner.target_pos = p
	var blink := fmod(_t, 1.0) < 0.5
	for b in _blink_mats:
		b.visible = blink
	if _effects["roaches"].visible:
		_update_roaches(delta)
	if _effects["exodus"].visible:
		_alarm_light.light_energy = 8.0 if fmod(_t, 0.5) < 0.25 else 0.5
	if _effects["black_monday"].visible:
		_lightning.light_energy = 12.0 if randf() < 0.012 else maxf(0.0, _lightning.light_energy - delta * 40.0)
	for i in _party_lights.size():
		var pl: OmniLight3D = _party_lights[i]
		pl.position = Vector3(sin(_t * 1.5 + i * 2.1) * 6.0, 3.5, 4.5 + cos(_t * 1.3 + i) * 3.0)
	if _effects["grand_raffle"].visible:
		_raffle_wheel.rotation.z += delta * 2.5
		for i in _raffle_beams.size():
			_raffle_beams[i].rotation = Vector3(sin(_t * 0.6 + i * 3.0) * 0.5, 0, cos(_t * 0.5 + i) * 0.45)
	for i in _rumor_labels.size():
		var l: Label3D = _rumor_labels[i]
		l.position.y = 6.5 + (i % 2) * 2.0 + sin(_t * 2.0 + i) * 0.4
	if _state_sign == "off":
		var a := 0.05 if randf() < 0.9 else 0.8
		for l in _sign_labels:
			l.modulate.a = a
	elif _state_sign == "mega":
		var pulse := 0.75 + absf(sin(_t * 6.0)) * 0.25
		for l in _sign_labels:
			l.modulate.a = pulse
	if _modules["pr"].visible:
		_pr_t -= delta
		if _pr_t <= 0.0:
			_pr_t = 4.0
			var slogans := ["МЫ ЧЕСТНЕЕ СОСЕДЕЙ!", "У НАС НЕТ ТАРАКАНОВ*\n*почти", "ТРАВИМ ТОЛЬКО АНЕКДОТЫ", "ВАШИ ДЕНЬГИ В НАДЁЖНЫХ РУКАХ. НАШИХ.", "СОСЕДИ ВРУТ!"]
			_pr_label.text = slogans[_pr_i % slogans.size()]
			_pr_i += 1
	if _police_t > 0.0:
		_police_t -= delta
		var ls: Array = _police.get_meta("lights")
		var on := fmod(_t, 0.4) < 0.2
		ls[0].light_energy = 9.0 if on else 0.0
		ls[1].light_energy = 0.0 if on else 9.0
		if _police_t <= 0.0:
			_police.visible = false
	if _flash_t > 0.0:
		_flash_t -= delta
		_flash.light_energy = maxf(0.0, _flash_t) * 8.0


func _update_roaches(delta: float) -> void:
	var mm := _roach_mm.multimesh
	for i in _roach_data.size():
		var r: Dictionary = _roach_data[i]
		r.a += randf_range(-3.0, 3.0) * delta
		var sp: float = r.s * delta * 1.2
		var p: Vector3 = r.p
		if r.wall:
			p.x += cos(r.a) * sp
			p.y += sin(r.a) * sp
			p.x = wrapf(p.x, -8.5, 8.5)
			p.y = clampf(p.y, 0.4, maxf(1.0, height - 0.5))
			r.p = p
			var basis := Basis(Vector3.RIGHT, PI * 0.5).rotated(Vector3.FORWARD, r.a)
			mm.set_instance_transform(i, Transform3D(basis.scaled(Vector3(1.0, 0.6, 1.6)), p))
		else:
			p.x += cos(r.a) * sp
			p.z += sin(r.a) * sp
			p.x = wrapf(p.x, -12, 12)
			p.z = wrapf(p.z, 0.3, 8.8)
			r.p = p
			var basis2 := Basis(Vector3.UP, -r.a)
			mm.set_instance_transform(i, Transform3D(basis2.scaled(Vector3(1.6, 0.6, 1.0)), p))
