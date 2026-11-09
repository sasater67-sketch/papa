extends Node3D
## Камера-стратег: вращение (ПКМ / Q,E), панорама (СКМ / WASD), зум (колесо), пресеты 1/2/3.

var target := Vector3(0, 2, 0)
var yaw := 1.0
var elev := 0.72
var dist := 62.0
var auto_orbit := false
var input_enabled := true

var _cur_target := Vector3(0, 2, 0)
var _cur_yaw := 1.0
var _cur_elev := 0.72
var _cur_dist := 62.0
var _drag_rot := false
var _drag_pan := false
var _shake := 0.0
var cam: Camera3D


func _ready() -> void:
	cam = Camera3D.new()
	cam.fov = 50.0
	cam.near = 0.3
	cam.far = 600.0
	add_child(cam)
	cam.current = true
	snap()


func snap() -> void:
	_cur_target = target
	_cur_yaw = yaw
	_cur_elev = elev
	_cur_dist = dist
	_update_cam()


func preset(name: String, team: int) -> void:
	var s := -1.0 if team == 0 else 1.0
	match name:
		"own":
			target = Vector3(0, 8.0, s * 11.0)
			yaw = (0.0 if team == 0 else PI) + 0.25
			elev = 0.98
			dist = 50.0
		"enemy":
			target = Vector3(0, 8.0, -s * 11.0)
			yaw = (PI if team == 0 else 0.0) - 0.25
			elev = 0.98
			dist = 50.0
		_:
			# Вдоль дороги, с небольшим уклоном к своему фасаду: видны оба казино.
			target = Vector3(0, 2.0, 0)
			yaw = 1.2 if team == 0 else 1.2 + PI
			elev = 0.62
			dist = 66.0


func shake(amount: float) -> void:
	_shake = maxf(_shake, amount)


func _unhandled_input(event: InputEvent) -> void:
	if not input_enabled:
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		match mb.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				if mb.pressed:
					dist = clampf(dist * 0.88, 10.0, 120.0)
			MOUSE_BUTTON_WHEEL_DOWN:
				if mb.pressed:
					dist = clampf(dist * 1.12, 10.0, 120.0)
			MOUSE_BUTTON_RIGHT:
				_drag_rot = mb.pressed
			MOUSE_BUTTON_MIDDLE:
				_drag_pan = mb.pressed
	elif event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		if _drag_rot:
			yaw -= mm.relative.x * 0.006
			elev = clampf(elev + mm.relative.y * 0.004, 0.12, 1.45)
		elif _drag_pan:
			_pan(Vector2(-mm.relative.x, -mm.relative.y) * dist * 0.0016)
	elif event is InputEventPanGesture:
		var pg := event as InputEventPanGesture
		dist = clampf(dist * (1.0 + pg.delta.y * 0.05), 10.0, 120.0)
	elif event is InputEventMagnifyGesture:
		var mg := event as InputEventMagnifyGesture
		dist = clampf(dist / mg.factor, 10.0, 120.0)


func _pan(v: Vector2) -> void:
	var right := Vector3(cos(yaw), 0, -sin(yaw))
	var fwd := Vector3(-sin(yaw), 0, -cos(yaw))
	target += right * v.x - fwd * v.y
	target.x = clampf(target.x, -75.0, 75.0)
	target.z = clampf(target.z, -45.0, 45.0)


func _process(delta: float) -> void:
	if auto_orbit:
		yaw += delta * 0.04
	elif input_enabled and not (get_viewport().gui_get_focus_owner() is LineEdit):
		var mv := Vector2.ZERO
		if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
			mv.y -= 1
		if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
			mv.y += 1
		if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
			mv.x -= 1
		if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
			mv.x += 1
		if mv != Vector2.ZERO:
			_pan(mv.normalized() * dist * 0.9 * delta)
		if Input.is_physical_key_pressed(KEY_Q):
			yaw += delta * 1.4
		if Input.is_physical_key_pressed(KEY_E):
			yaw -= delta * 1.4
	var k := minf(1.0, delta * 6.0)
	_cur_target = _cur_target.lerp(target, k)
	_cur_yaw = lerp_angle(_cur_yaw, yaw, k)
	_cur_elev = lerpf(_cur_elev, elev, k)
	_cur_dist = lerpf(_cur_dist, dist, k)
	_shake = maxf(0.0, _shake - delta * 2.0)
	_update_cam()


func _update_cam() -> void:
	var off := Vector3(sin(_cur_yaw) * cos(_cur_elev), sin(_cur_elev), cos(_cur_yaw) * cos(_cur_elev)) * _cur_dist
	var sh := Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)) * _shake * 0.4
	cam.position = _cur_target + off + sh
	cam.look_at(_cur_target + sh * 0.5, Vector3.UP)
