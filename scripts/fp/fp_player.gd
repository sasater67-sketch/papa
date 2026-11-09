extends CharacterBody3D
## Хозяин казино от первого лица. Основа — контроллер игрока из Jackpot Hotel:
## ходьба, бег, прыжок, покачивание камеры, нокаут и т.д. Плюс действия этой игры:
## касса, починка, пакости руками, кража из кассы соседа, флаеры прохожим, удары.

const Character := preload("res://scripts/kit/character.gd")
const WALK := 4.2
const RUN := 6.9
const JUMP := 4.7
const GRAVITY := 13.5
const EYE := 1.62
const STEP_H := 0.4
const REACH := 2.3

const F_MOVE := 1
const F_RUN := 2
const F_AIR := 4
const F_KO := 8
const F_PUNCH := 16
const F_WORK := 32
const F_STUN := 64
const F_FP := 128

const FIX_TEXT := {"roaches": "Вымести тараканов", "stink": "Вытащить тухлую рыбу из кондиционера",
	"music_break": "Починить музыку", "plumbing": "Прочистить туалет"}
const PLANT_TEXT := {"door": "Подбросить тараканов под дверь", "ac": "Засунуть тухлую рыбу в кондиционер",
	"panel": "Перемкнуть щиток (шансон задом наперёд)"}

var team := 0
var role := "boss"
var world: Node3D
var active := false        # управление от первого лица
var controls := false      # мышь захвачена, нет открытых окон
var third := false
var yaw := 0.0
var pitch := 0.0
var head: Node3D
var arm: SpringArm3D
var cam: Camera3D
var model: Node3D
var focus := {}
var hold := 0.0            # прогресс удержания E, 0..1
var stun_t := 0.0
var ko_t := 0.0
var punch_t := 0.0
var flash := 0.0           # красная вспышка на экране (читает HUD)
var _hold_key := ""
var _punch_cd := 0.0
var _step := 0.0
var _t := 0.0
var _shake := 0.0
var _send_t := 0.0
var _focus_t := 0.0
var _was_floor := true
var _down := 0.0
var _roll := 1.0
var _md := Vector2.ZERO
var _safe := Vector3.ZERO


func _ready() -> void:
	collision_layer = Game.L_PLAYER
	collision_mask = Game.L_WORLD
	floor_snap_length = 0.45
	floor_max_angle = deg_to_rad(50)
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.3
	cap.height = 1.76
	cs.shape = cap
	cs.position.y = 0.88
	add_child(cs)
	head = Node3D.new()
	head.position.y = EYE
	add_child(head)
	arm = SpringArm3D.new()
	arm.collision_mask = Game.L_WORLD
	arm.spring_length = 0.0
	arm.margin = 0.15
	var sph := SphereShape3D.new()
	sph.radius = 0.2
	arm.shape = sph
	arm.add_excluded_object(get_rid())
	head.add_child(arm)
	cam = Camera3D.new()
	cam.near = 0.05
	cam.far = 500.0
	cam.fov = float(Game.settings.fov)
	arm.add_child(cam)
	model = Node3D.new()
	model.set_script(Character)
	add_child(model)
	model.rotation.y = PI
	model.build(look_for(multiplayer.get_unique_id(), team, role))
	Game.fp_event.connect(_on_fp_event)


static func look_for(peer: int, t: int, r: String) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = peer * 7919 + 13
	var l := Character.random_look(rng)
	l.outfit = "suit" if r != "saboteur" else "hoodie"
	l.shirt = Defs.TEAM_COLORS[t].darkened(0.35)
	l.pants = Color("16141c")
	l.hat = {"boss": "magnate", "director": "tophat", "saboteur": "beanie"}.get(r, "magnate")
	l.face = 3 if r == "saboteur" else l.face
	return l


func teleport(pos: Vector3, new_yaw: float) -> void:
	global_position = pos
	velocity = Vector3.ZERO
	yaw = new_yaw
	pitch = 0.0
	_safe = pos
	_apply_rot()


func set_active(on: bool) -> void:
	active = on
	cam.current = on
	_update_model_vis()


func _update_model_vis() -> void:
	model.visible = (not active) or third


func shake(amount: float) -> void:
	_shake = maxf(_shake, amount)


func _apply_rot() -> void:
	rotation.y = yaw
	head.rotation.x = pitch


# =============================================================================
# Ввод
# =============================================================================
func _unhandled_input(ev: InputEvent) -> void:
	if not active:
		return
	if ev is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_md += (ev as InputEventMouseMotion).relative
	elif ev is InputEventMouseButton and (ev as InputEventMouseButton).pressed and controls:
		if (ev as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
			_try_punch()
	elif ev is InputEventKey and ev.pressed and not ev.echo and controls:
		match (ev as InputEventKey).physical_keycode:
			KEY_V:
				third = not third
				_update_model_vis()
			KEY_E:
				_press_e()
			_:
				return
		get_viewport().set_input_as_handled()


func _key(k: Key) -> bool:
	return controls and Input.is_physical_key_pressed(k)


func _process(delta: float) -> void:
	_t += delta
	_punch_cd = maxf(0.0, _punch_cd - delta)
	punch_t = maxf(0.0, punch_t - delta)
	flash = maxf(0.0, flash - delta * 1.5)
	if ko_t > 0.0:
		ko_t = maxf(0.0, ko_t - delta)
	if active and controls:
		var sens := float(Game.settings.sensitivity) * 0.01
		yaw -= _md.x * sens
		pitch = clampf(pitch - _md.y * sens, deg_to_rad(-85), deg_to_rad(85))
	_md = Vector2.ZERO
	_apply_rot()
	if active:
		_update_camera(delta)
		_focus_t -= delta
		if _focus_t <= 0.0:
			_focus_t = 0.1
			_update_focus()
		_update_hold(delta)
	_update_model()
	_send_t -= delta
	if _send_t <= 0.0:
		_send_t = 0.05
		Game.fp_send(global_position, yaw, _flags())


func _update_camera(delta: float) -> void:
	var target_len := 3.2 if third else 0.0
	arm.spring_length = lerpf(arm.spring_length, target_len, clampf(delta * 10.0, 0.0, 1.0))
	arm.position = Vector3(0.45, 0.15, 0) if third else Vector3.ZERO
	var roll := 0.0
	var bob := Vector3.ZERO
	var hv := Vector2(velocity.x, velocity.z).length()
	if not third:
		bob.y += sin(_t * 1.3) * 0.0045
		bob.x += sin(_t * 0.61) * 0.003
		if is_on_floor() and hv > 0.5:
			bob.y += sin(_step * TAU / 1.1) * 0.035
			bob.x += sin(_step * TAU / 2.2) * 0.022
			roll += sin(_step * TAU / 2.2) * 0.005
	if _shake > 0.0:
		_shake = maxf(0.0, _shake - delta * 2.5)
		bob += Vector3(randf_range(-1, 1), randf_range(-1, 1), 0) * _shake * 0.08
	var want_down := 1.0 if ko_t > 0.0 else 0.0
	_down = move_toward(_down, want_down, delta * (5.0 if want_down > _down else 2.0))
	var dk := smoothstep(0.0, 1.0, _down)
	head.position.y = lerpf(EYE, 0.32, dk)
	roll += dk * 1.25 * _roll
	if ko_t > 0.0:
		bob.y += sin(_t * 2.0) * 0.02 * dk
	cam.position = bob
	cam.rotation = Vector3(0, 0, roll)
	var want_fov := float(Game.settings.fov) + (6.0 if _key(KEY_SHIFT) and hv > 5.0 else 0.0)
	cam.fov = lerpf(cam.fov, want_fov, clampf(delta * 5.0, 0.0, 1.0))


func _physics_process(delta: float) -> void:
	stun_t = maxf(0.0, stun_t - delta)
	var free := active and controls and stun_t <= 0.0 and ko_t <= 0.0
	var dir := Vector3.ZERO
	if free:
		var iv := Vector2.ZERO
		if _key(KEY_W) or _key(KEY_UP):
			iv.y -= 1
		if _key(KEY_S) or _key(KEY_DOWN):
			iv.y += 1
		if _key(KEY_A) or _key(KEY_LEFT):
			iv.x -= 1
		if _key(KEY_D) or _key(KEY_RIGHT):
			iv.x += 1
		dir = Basis(Vector3.UP, yaw) * Vector3(iv.x, 0, iv.y).limit_length(1.0)
	var running := free and _key(KEY_SHIFT)
	var target := dir * (RUN if running else WALK)
	var accel := 14.0 if is_on_floor() else 3.5
	if stun_t > 0.0:
		accel = 2.2
	if ko_t > 0.0:
		accel = 6.0
	velocity.x = lerpf(velocity.x, target.x, clampf(accel * delta, 0.0, 1.0))
	velocity.z = lerpf(velocity.z, target.z, clampf(accel * delta, 0.0, 1.0))
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	elif free and _key(KEY_SPACE):
		velocity.y = JUMP
		Sfx.play("jump", -10.0, randf_range(0.95, 1.05))
	var before := global_position
	move_and_slide()
	_step_up(before, delta)
	var on_floor := is_on_floor()
	if on_floor and not _was_floor and active:
		Sfx.play("land", -12.0)
	_was_floor = on_floor
	if on_floor:
		_safe = global_position
		var hv := Vector2(velocity.x, velocity.z).length()
		if hv > 0.6:
			var b := _step
			_step += hv * delta
			var stride := 0.62 if running else 0.55
			if active and floor(b / stride) != floor(_step / stride):
				Sfx.play("step", -13.0 if not running else -10.0, randf_range(0.9, 1.1))
	if global_position.y < -6.0:
		teleport(_safe + Vector3(0, 0.5, 0), yaw)


## Бордюры и пороги: если упёрлись в невысокую ступеньку — поднимаемся на неё.
func _step_up(before: Vector3, delta: float) -> void:
	var want := Vector3(velocity.x, 0, velocity.z) * delta
	if want.length() < 0.001 or not is_on_wall():
		return
	var moved := global_position - before
	moved.y = 0.0
	if moved.length() > want.length() * 0.6:
		return
	var up := Vector3(0, STEP_H, 0)
	var xf := global_transform
	if test_move(xf, up):
		return
	var xf2 := xf.translated(up)
	if test_move(xf2, want):
		return
	var xf3 := xf2.translated(want)
	var col := KinematicCollision3D.new()
	if test_move(xf3, -up * 1.2, col):
		var land := xf3.origin + col.get_travel()
		if land.y > before.y + 0.02:
			global_position = land
			velocity.y = 0.0


func _update_model() -> void:
	if not model.visible:
		return
	var hv := Vector2(velocity.x, velocity.z).length()
	if ko_t > 0.0:
		model.anim = "ko"
	elif punch_t > 0.0:
		model.anim = "punch"
	elif hold > 0.0:
		model.anim = "steal" if focus.get("op", "") == "steal" else "repair"
	elif stun_t > 0.0:
		model.anim = "stumble"
	elif hv > 0.4:
		model.anim = "run" if hv > 5.0 else "walk"
		model.speed = hv
	elif not active:
		model.anim = "type"
	else:
		model.anim = "idle"


func _flags() -> int:
	var f := 0
	var hv := Vector2(velocity.x, velocity.z).length()
	if hv > 0.4:
		f |= F_MOVE
	if hv > 5.0:
		f |= F_RUN
	if not is_on_floor():
		f |= F_AIR
	if ko_t > 0.0:
		f |= F_KO
	if punch_t > 0.0:
		f |= F_PUNCH
	if hold > 0.0:
		f |= F_WORK
	if stun_t > 0.0:
		f |= F_STUN
	if active:
		f |= F_FP
	return f


# =============================================================================
# Что под прицелом
# =============================================================================
func _fwd2() -> Vector2:
	var f := -cam.global_transform.basis.z
	return Vector2(f.x, f.z).normalized()


func _update_focus() -> void:
	var prev := String(focus.get("key", ""))
	focus = {}
	if ko_t > 0.0 or Game.teams.size() != 2:
		return
	var me := global_position
	var fwd := _fwd2()
	var best := 99.0
	for t in 2:
		for s in Game.SPOT:
			var sp := Game.spot_pos(t, s)
			var d := Vector2(sp.x - me.x, sp.z - me.z)
			var dist := d.length()
			if dist > REACH or absf(sp.y - me.y) > 2.5:
				continue
			if dist > 0.7 and fwd.dot(d / dist) < 0.25:
				continue
			var f := _spot_focus(t, s)
			if not f.is_empty() and dist < best:
				best = dist
				focus = f
	if focus.is_empty() and world:
		var ped = world.ped_in_front(me, fwd, 2.6)
		if ped != null:
			focus = {"key": "ped%d" % ped.get_meta("id"), "op": "lure", "arg": int(ped.get_meta("id")), "hold": 0.0, "ok": true,
				"prompt": "[E] Всучить флаер «У нас лучше!» (%s)" % Defs.money(Game.LURE_COST)}
	if String(focus.get("key", "")) != prev:
		hold = 0.0


func _spot_focus(t: int, s: String) -> Dictionary:
	var mine := t == team
	var st: Dictionary = Game.teams[t]
	var key := "%d:%s" % [t, s]
	if s == "till":
		var till := float(st.get("till", 0.0))
		if mine:
			return {"key": key, "op": "collect", "hold": 0.0, "ok": till >= 1.0,
				"prompt": ("[E] Забрать выручку из кассы: %s" % Defs.money(till)) if till >= 1.0 else "Касса пуста — клиенты ещё не наиграли"}
		var risk := Game.steal_chance(team, role, global_position)
		return {"key": key, "op": "steal", "hold": 2.5, "ok": till >= 1.0, "bad": true,
			"prompt": ("[Держать E] Обчистить кассу соседа: %s — риск %d%%" % [Defs.money(till * Game.STEAL_SHARE), int(risk * 100)]) if till >= 1.0 else "Касса соседа пуста"}
	if mine:
		for e in Game.FIX_SPOT:
			if Game.FIX_SPOT[e] == s and st.effects.has(e):
				return {"key": key + e, "op": "fix", "arg": e, "hold": 1.6, "ok": true, "prompt": "[Держать E] %s" % FIX_TEXT[e]}
		return {}
	if not Game.HAND_SAB.has(s):
		return {}
	var sid: String = Game.HAND_SAB[s]
	var err := Game.hand_can(team, role, sid)
	if err != "":
		return {"key": key, "op": "", "ok": false, "hold": 0.0, "prompt": "%s: %s" % [Defs.sab_by_id[sid].name, err]}
	var risk := Game.catch_chance(team, role, sid, Game.witness_bonus(team, global_position))
	return {"key": key, "op": "plant", "arg": s, "hold": 1.2, "ok": true, "bad": true,
		"prompt": "[Держать E] %s — %s, риск %d%%" % [PLANT_TEXT[s], Defs.money(Game.hand_price(team, role, sid)), int(risk * 100)]}


func _press_e() -> void:
	if focus.is_empty() or not bool(focus.get("ok", false)) or ko_t > 0.0:
		if not focus.is_empty():
			Sfx.play("error", -8.0)
		return
	if float(focus.hold) <= 0.0:
		_send(focus)
	else:
		_hold_key = String(focus.key)


func _update_hold(delta: float) -> void:
	if _hold_key == "" or focus.is_empty() or String(focus.get("key", "")) != _hold_key or not _key(KEY_E) or ko_t > 0.0 or stun_t > 0.0:
		_hold_key = ""
		hold = 0.0
		return
	hold += delta / maxf(0.1, float(focus.hold))
	if fmod(hold, 0.25) < delta * 2.0:
		Sfx.play("scratch" if focus.op != "steal" else "safe_click", -14.0, randf_range(0.9, 1.1))
	if hold >= 1.0:
		_send(focus)
		_hold_key = ""
		hold = 0.0


func _send(f: Dictionary) -> void:
	Game.request({"a": "fp", "op": f.op, "arg": f.get("arg", "")})
	match String(f.op):
		"lure":
			Sfx.play("paper_slide", -6.0, randf_range(1.0, 1.2))
			punch_t = 0.3
		"plant":
			Sfx.play("drop", -6.0)
	_focus_t = 0.0


func _try_punch() -> void:
	if _punch_cd > 0.0 or ko_t > 0.0 or stun_t > 0.0 or not world:
		return
	_punch_cd = 0.45
	punch_t = 0.36
	Sfx.play("whoosh", -10.0, randf_range(1.15, 1.35))
	var me := global_position
	var fwd := _fwd2()
	var target: int = world.player_in_front(me, fwd, 2.2, team)
	if target > 0:
		Game.request({"a": "fp", "op": "punch", "peer": target})
		Sfx.play("hit", -6.0, randf_range(1.1, 1.3))
		shake(0.15)
		return
	var ped = world.ped_in_front(me, fwd, 1.9)
	if ped != null:
		Game.request({"a": "fp", "op": "punch", "ped": int(ped.get_meta("id"))})
		Sfx.play("hit", -8.0, randf_range(1.1, 1.3))
		shake(0.1)


# =============================================================================
# События с сервера
# =============================================================================
func _on_fp_event(kind: String, data: Dictionary) -> void:
	match kind:
		"hit":
			_push(data.get("dir", Vector3.ZERO), 2.5, 0.22)
			shake(0.55)
			flash = 0.4
			Sfx.play("hit", -2.0)
		"ko":
			ko_t = Game.KO_TIME
			_roll = -1.0 if randf() < 0.5 else 1.0
			velocity = Vector3(velocity.x * 0.3, 2.0, velocity.z * 0.3)
			shake(1.2)
			flash = 1.0
			Sfx.play("body_fall", 0.0)
		"car":
			_push(data.get("dir", Vector3.RIGHT), 9.0, 1.8)
			velocity.y = 5.0
			shake(1.4)
			flash = 1.0
			Sfx.play("crash_boom", -2.0)
		"horn":
			Sfx.play("horn", -4.0)
		"kicked":
			var t := int(data.get("team", 1 - team))
			var out := Game.to_world(t, Vector3(randf_range(-4, 4), 0.3, 10.8))
			teleport(out, yaw)
			_push(Vector3(0, 0, -Game.sgn(t)), 4.0, 1.2)
			shake(1.0)
			flash = 0.8
			Sfx.play("door_slam", 0.0)
		"cash":
			Sfx.play("cash", -2.0)
			Sfx.play("coin", -6.0)
		"fixed":
			Sfx.play("job_ok", -4.0)


func _push(dir: Vector3, force: float, t: float) -> void:
	var d := Vector3(dir.x, 0.0, dir.z)
	d = d.normalized() if d.length() > 0.01 else Basis(Vector3.UP, yaw) * Vector3(0, 0, 1)
	velocity = d * force + Vector3(0, 1.5 + force * 0.2, 0)
	stun_t = maxf(stun_t, t)
