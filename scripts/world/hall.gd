extends Node3D
## Зал первого этажа казино: в него можно зайти от первого лица.
## Автоматы, столы, мебель и люди — киты из Jackpot Hotel. Координаты локальные для casino_view:
## x вдоль фасада, фасад в z = 0, зал — z от −10 до 0, пол на высоте FLOOR_Y.

const B := preload("res://scripts/world/build.gd")
const CP := preload("res://scripts/kit/casino_props.gd")
const SK := preload("res://scripts/kit/slot_kit.gd")
const TK := preload("res://scripts/kit/table_kit.gd")
const Character := preload("res://scripts/kit/character.gd")

const FLOOR_Y := 0.2
const CEIL_Y := 4.5
# Что появляется в зале, когда построен объект: тип машины (как в Jackpot Hotel), позиция, поворот.
const MACHINES := {
	"slots": [["fruit", Vector3(-7.55, 0, -2.8), PI * 0.5]],
	"slots2": [["gold", Vector3(-7.55, 0, -6.6), PI * 0.5]],
	"dealers": [["bj", Vector3(2.7, 0, -3.3), 0.0], ["roul", Vector3(-2.9, 0, -5.0), 0.0]],
	"vip": [["vip", Vector3(5.3, 0, -6.9), 0.0]],
	"show": [["plinko", Vector3(-2.9, 0, -1.5), 0.0]],
	"dome": [["mega", Vector3(7.55, 0, -3.0), -PI * 0.5]],
	"music": [["jukebox", Vector3(-2.7, 0, -9.35), 0.0]],
	"bar": [["bar", Vector3(-5.6, 0, -8.5), 0.0]],
	"restaurant": [["dining", Vector3(2.9, 0, -7.6), 0.0]],
	"fountain": [["fountain", Vector3(5.6, 0, -1.9), 0.0]],
}

var team := 0
var col := Color.WHITE
var _built := {}
var _seats: Array = []       # [Vector3 позиция (локально), float yaw]
var _guests: Array = []
var _staff := {}
var _till_label: Label3D
var _till_full := false
var _t := 0.0
var _door_l: Node3D
var _door_r: Node3D
var _door_open := 0.0
var _rng := RandomNumberGenerator.new()


func setup(t: int, c: Color, wall_tex: String) -> void:
	team = t
	col = c
	_rng.seed = 4242 + t * 17
	_build_shell(wall_tex)
	_build_cashier()


# =============================================================================
# Стены, пол, потолок, касса, туалет
# =============================================================================
func _build_shell(wall_tex: String) -> void:
	var p := _props(self)
	var lb = p.lb
	# пол и потолок
	lb.box(Vector3(0, FLOOR_Y - 0.1, -5.0), Vector3(17.8, 0.2, 9.8), "carpet_casino", {"collide": false})
	lb.add_collider(Vector3(0, FLOOR_Y - 0.5, -5.0), Vector3(18.0, 1.0, 10.0))
	lb.box(Vector3(0, CEIL_Y + 0.05, -5.0), Vector3(17.8, 0.1, 9.8), "ceil_dark", {"collide": false})
	# стены изнутри (снаружи стоят стены здания из casino_view)
	var h := CEIL_Y - FLOOR_Y
	var cy := FLOOR_Y + h * 0.5
	lb.box(Vector3(-8.85, cy, -5.0), Vector3(0.1, h, 9.8), wall_tex, {"collide": false})
	lb.box(Vector3(8.85, cy, -5.0), Vector3(0.1, h, 9.8), wall_tex, {"collide": false})
	lb.box(Vector3(0, cy, -9.85), Vector3(17.6, h, 0.1), wall_tex, {"collide": false})
	lb.add_collider(Vector3(-9.0, cy, -5.0), Vector3(0.4, h + 1.0, 10.4))
	lb.add_collider(Vector3(9.0, cy, -5.0), Vector3(0.4, h + 1.0, 10.4))
	lb.add_collider(Vector3(0, cy, -10.0), Vector3(18.4, h + 1.0, 0.4))
	# плинтус и молдинг
	for z in [-9.78]:
		lb.box(Vector3(0, FLOOR_Y + 0.08, z), Vector3(17.6, 0.16, 0.06), "gold", {"collide": false})
		lb.box(Vector3(0, CEIL_Y - 0.1, z), Vector3(17.6, 0.2, 0.06), "gold", {"collide": false})
	for sx in [-1, 1]:
		lb.box(Vector3(sx * 8.78, FLOOR_Y + 0.08, -5.0), Vector3(0.06, 0.16, 9.8), "gold", {"collide": false})
		lb.box(Vector3(sx * 8.78, CEIL_Y - 0.1, -5.0), Vector3(0.06, 0.2, 9.8), "gold", {"collide": false})
	# фасад: стекло с проёмом под двери
	for sx in [-1, 1]:
		lb.add_collider(Vector3(sx * 5.3, cy, 0.05), Vector3(7.4, h + 1.0, 0.3))
	lb.add_collider(Vector3(0, CEIL_Y - 0.3, 0.05), Vector3(3.2, 0.9, 0.3))
	# ковровая дорожка от дверей к кассе
	p.rug(Vector3(0, FLOOR_Y, -4.6), 2.2, 7.6, "carpet_red", col.lerp(Color.WHITE, 0.55))
	# касса (стойка с кассиром)
	p.reception_desk(Vector3(0, FLOOR_Y, -8.9), 0.0, 3.2)
	p.lb.box(Vector3(0.9, FLOOR_Y + 1.32, -8.9), Vector3(0.5, 0.36, 0.4), "", {"collide": false, "tint": Color(0.12, 0.12, 0.14), "mat": {"metal": 0.6, "rough": 0.35}})
	p.lb.box(Vector3(0.9, FLOOR_Y + 1.52, -8.98), Vector3(0.44, 0.04, 0.3), "", {"collide": false, "tint": Color(0.2, 1.0, 0.4), "mat": {"emit": 2.0, "emit_color": Color(0.2, 1.0, 0.4), "unshaded": true}})
	p.money_stack(Vector3(-0.8, FLOOR_Y + 1.15, -8.95), 3, 2, 3)
	p.label(Vector3(0, FLOOR_Y + 3.4, -9.75), "КАССА", 52, col * 1.6, 0.0, {"outline": 12})
	_till_label = B.label(self, "", Vector3(0, FLOOR_Y + 2.35, -8.6), 40, Color(1.6, 1.5, 1.2), Color(0.05, 0.02, 0.08), 0.0075, Assets.font_title)
	_till_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_till_label.no_depth_test = false
	# дверь туалета в задней стене
	p.lb.box(Vector3(7.6, FLOOR_Y + 1.1, -9.75), Vector3(1.0, 2.2, 0.1), "wood_dark", {"collide": false})
	p.lb.box(Vector3(7.2, FLOOR_Y + 1.05, -9.68), Vector3(0.08, 0.08, 0.06), "gold", {"collide": false})
	p.label(Vector3(7.6, FLOOR_Y + 2.45, -9.72), "WC", 40, Color(2.0, 2.0, 2.4), 0.0, {"outline": 10})
	# люстры, колонны, растения
	for x in [-4.5, 4.5]:
		p.chandelier(Vector3(x, CEIL_Y - 0.8, -4.8), 1.1, Color(1.0, 0.86, 0.62), 1.6, 11.0)
	for x in [-1.9, 1.9]:
		p.column(Vector3(x, FLOOR_Y, -0.9), CEIL_Y - FLOOR_Y, 0.22, "marble_black", "gold")
	p.plant(Vector3(-8.3, FLOOR_Y, -0.7), 1.4, "plastic_white", true)
	p.plant(Vector3(8.3, FLOOR_Y, -0.7), 1.4, "plastic_white", true)
	p.light(Vector3(0, CEIL_Y - 0.4, -1.5), Color(1.0, 0.8, 0.6), 0.9, 7.0)
	p.lb.commit(false)
	# двери-купе: разъезжаются, когда кто-то рядом
	_door_l = Node3D.new()
	_door_r = Node3D.new()
	for d in [_door_l, _door_r]:
		add_child(d)
		B.box(d, Vector3(1.38, 3.0, 0.06), Vector3(0, FLOOR_Y + 1.5, 0.14), B.glass(Color(0.9, 0.75, 0.45), 0.35), false)
		B.box(d, Vector3(1.38, 0.08, 0.08), Vector3(0, FLOOR_Y + 3.0, 0.14), B.mat(Color(1, 0.8, 0.3), 0.2, 1.0), false)
		B.box(d, Vector3(0.05, 0.6, 0.1), Vector3(0, FLOOR_Y + 1.2, 0.2), B.mat(Color(1, 0.8, 0.3), 0.2, 1.0), false)


func _build_cashier() -> void:
	_staff["cashier"] = _char(_cashier_look(), Vector3(0, FLOOR_Y, -9.45), 0.0, "idle")


# =============================================================================
# Люди
# =============================================================================
func _char(look: Dictionary, pos: Vector3, yaw: float, anim: String) -> Node3D:
	var c := Node3D.new()
	c.set_script(Character)
	add_child(c)
	c.position = pos
	c.rotation.y = yaw
	c.build(look)
	c.anim = anim
	c.add_to_group("lod_char")
	return c


func _cashier_look() -> Dictionary:
	var l := Character.random_look(_rng)
	l.outfit = "vest"
	l.shirt = Color("e8e8e8")
	l.pants = Color("141418")
	l.hat = 0
	return l


static func dealer_look(seed_v: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	var l := Character.random_look(rng)
	l.outfit = "vest"
	l.shirt = Color("e8e8e8")
	l.pants = Color("141418")
	l.hat = 0
	return l


static func guard_look() -> Dictionary:
	return {"skin": 1, "hair": 0, "hair_color": 0, "hat": "guard", "face": 3, "shirt": Color("15151a"), "pants": Color("101014"),
		"outfit": "suit", "body": 1, "build": 3}


# =============================================================================
# Машины и мебель
# =============================================================================
static func _props(parent: Node3D) -> CP:
	var p := CP.new()
	p._setup(parent)
	return p


func _build_item(mid: String, pos: Vector3, yaw: float, seed_v: int) -> void:
	var root := Node3D.new()
	add_child(root)
	root.position = pos + Vector3(0, FLOOR_Y, 0)
	root.rotation.y = yaw
	var info := build_machine(root, mid, seed_v)
	var bx: Basis = root.transform.basis
	var slot := mid in ["fruit", "classic", "vpoker", "gold", "mega", "diamond"]
	for s: Vector3 in info.seats:
		var lp: Vector3 = root.transform * s
		var look_at: Vector3 = root.transform * (Vector3(s.x, 0, -1.0) if slot else Vector3(0, 0, -0.35))
		var d := look_at - lp
		_seats.append([lp, atan2(d.x, d.z), slot])
	if info.dealer != Vector3.INF:
		var dp: Vector3 = root.transform * info.dealer
		var dd := root.transform * Vector3(0, 0, -0.35) - dp
		_staff["dealer_" + mid] = _char(dealer_look(seed_v), dp, atan2(dd.x, dd.z), "deal")
	if mid == "bar":
		_staff["bartender"] = _char(dealer_look(seed_v + 5), root.transform * Vector3(0, 0, -0.75), atan2(bx.z.x, bx.z.z), "bar")
	B.burst(self, root.position + Vector3(0, 1, 0), col, 40, 4.0, 0.25, 1.0, Vector3(0, -4, 0))


## Как build_machine в Jackpot Hotel (mall_level.gd), плюс бар, музыкальный автомат и ресторанный стол.
static func build_machine(parent: Node3D, mid: String, seed_v: int) -> Dictionary:
	var model := Node3D.new()
	parent.add_child(model)
	var p := _props(model)
	p.rng.seed = seed_v
	var seats: Array = []
	var dealer := Vector3.INF
	var sc := 1.0
	match mid:
		"fruit", "classic", "vpoker", "gold":
			var units: Array = []
			for k in 4:
				var x := -1.26 + k * 0.84
				units.append([x, false])
				seats.append(Vector3(x, 0, 0.2))
			SK.bank(model, p.lb, mid, units, -0.55)
		"bj", "poker", "bacc":
			seats = TK.card_table(model, p.lb, mid, Vector3(0, 0, -0.35), 4, seed_v)
			dealer = Vector3(0, 0, -1.45)
		"roul":
			sc = 0.78
			seats = TK.roulette(model, p.lb, Vector3(0.45, 0, -0.3), seed_v, sc)
			dealer = Vector3(-0.2, 0, -1.2)
		"plinko":
			TK.plinko(model, p.lb, Vector3(0, 0, -0.9))
			for k in 3:
				seats.append(Vector3(-0.8 + k * 0.8, 0, 0.35))
			TK.stools(model, p.lb, seats, Color("4a2a8a"))
			p.label(Vector3(0, 3.42, -0.75), "ПЛИНКО", 30, Color(2.4, 2.0, 2.4), 0.0, {"px": 0.011, "outline": 10, "outline_col": Color(0.25, 0.05, 0.4, 0.9)})
		"mega":
			SK.bank(model, p.lb, "mega", [[-1.25, false], [0.0, true], [1.25, false]], -0.55)
			for sx: float in [-1.25, 0.0, 1.25]:
				seats.append(Vector3(sx, 0, 0.2))
			p.label(Vector3(0, 3.3, -0.5), "МЕГА ДЖЕКПОТ", 30, Color(2.4, 1.9, 0.7), 0.0, {"px": 0.01, "outline": 10, "outline_col": Color(0.3, 0.05, 0.4, 0.9)})
		"vip":
			seats = TK.card_table(model, p.lb, "vip", Vector3(0, 0, -0.35), 4, seed_v)
			p.stanchion_line(Vector3(-1.7, 0, -1.6), Vector3(-1.7, 0, 1.2), 3)
			p.stanchion_line(Vector3(1.7, 0, -1.6), Vector3(1.7, 0, 1.2), 3)
			dealer = Vector3(0, 0, -1.5)
		"bar":
			p.bar_counter(Vector3(0, 0, 0), 4.2, 0.0)
			p.back_shelf(Vector3(0, 0, -1.15), 4.2, 0.0)
			for k in 4:
				var x := -1.5 + k * 1.0
				seats.append(Vector3(x, 0, 0.75))
			TK.stools(model, p.lb, seats, Color("8a1a2a"))
		"jukebox":
			p.jukebox(Vector3.ZERO, 0.0)
		"dining":
			p.dining_table(Vector3.ZERO, Color("e8e0d0"), 4)
			for a in 4:
				var ang := TAU * a / 4.0 + PI * 0.25
				seats.append(Vector3(cos(ang) * 0.9, 0, sin(ang) * 0.9))
		"fountain":
			p.fountain(Vector3.ZERO, 1.0)
	model.scale = Vector3.ONE * sc
	p.lb.commit(false)
	var out := []
	for s: Vector3 in seats:
		out.append(s * sc)
	return {"seats": out, "dealer": dealer * sc if dealer != Vector3.INF else dealer, "model": model}


# =============================================================================
# Состояние
# =============================================================================
func apply_state(st: Dictionary) -> void:
	var i := 0
	for id in MACHINES:
		i += 1
		if st.built.has(id) and not _built.has(id):
			_built[id] = true
			var k := 0
			for m in MACHINES[id]:
				_build_item(m[0], m[1], m[2], team * 1000 + i * 10 + k)
				k += 1
	if st.defense.has("guards") and not _staff.has("guard0"):
		for sx in [-1, 1]:
			_staff["guard%d" % (sx + 1)] = _char(guard_look(), Vector3(sx * 2.4, FLOOR_Y, -1.0), 0.0, "guard")
	# гости за автоматами и столами — сколько клиентов внутри
	var want := mini(int(st.inside), _seats.size())
	while _guests.size() < want:
		var s: Array = _seats[_guests.size()]
		var g := _char(Character.npc_look(_rng), s[0] + Vector3(0, 0.3, 0), s[1], "sit" if _rng.randf() < 0.75 else "sit_drink")
		_guests.append(g)
	while _guests.size() > want:
		_guests.pop_back().queue_free()
	var till := float(st.get("till", 0.0))
	var cap := float(st.get("till_cap", 1.0))
	_till_full = till >= cap - 0.5
	if _till_full:
		_till_label.text = "КАССА ПОЛНА!\n%s" % Defs.money(till)
	else:
		_till_label.text = "В кассе: %s\nиз %s" % [Defs.money(till), Defs.money(cap)]


func _process(delta: float) -> void:
	_t += delta
	if _till_full:
		_till_label.modulate = Color(2.4, 0.4, 0.3) if fmod(_t, 0.6) < 0.3 else Color(1.6, 1.4, 1.0)
	else:
		_till_label.modulate = Color(1.6, 1.5, 1.2)
	# двери открываются, если рядом стоит игрок
	var near := false
	for id in Game.fp:
		var e: Dictionary = Game.fp[id]
		var lp := to_local(e.p)
		if absf(lp.x) < 2.6 and absf(lp.z) < 2.8:
			near = true
	_door_open = move_toward(_door_open, 1.0 if near else 0.0, delta * 2.5)
	var k := smoothstep(0.0, 1.0, _door_open)
	_door_l.position.x = -0.7 - k * 1.3
	_door_r.position.x = 0.7 + k * 1.3
