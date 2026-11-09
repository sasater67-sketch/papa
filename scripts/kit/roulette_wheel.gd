extends Node3D



signal finished(number: int)

const D := preload("res://scripts/kit/wheel_data.gd")
const BALL_TRACK := 0.5
const BALL_POCKET := 0.415

var idle_speed := 0.55
var boost := 0.0
var ball: MeshInstance3D
var spinning := false
var _t := 0.0
var _dur := 6.0
var _a0 := 0.0
var _a1 := 0.0
var _number := 0
var _alpha := 0.0
var _last_click := 0
var auto := false
var _auto_t := randf_range(2.0, 12.0)


func _ready() -> void:
	ball = MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.024
	sm.height = 0.048
	sm.radial_segments = 8
	sm.rings = 4
	ball.mesh = sm
	ball.material_override = Assets.cmat(Color(1, 1, 0.97), {"rough": 0.15, "spec": 0.9, "emit": 0.4, "emit_color": Color(1, 1, 1)})
	add_child(ball)
	ball.visible = false


func spin_to(number: int, dur: float = 6.0) -> void:
	_number = number
	_dur = maxf(dur, 1.0)
	_t = 0.0
	spinning = true
	boost = 2.4
	ball.visible = true
	var idx := D.ROULETTE_ORDER.find(number)
	var target := TAU * idx / 37.0
	_a0 = _alpha
	var turns := 4.0 + randf() * 1.0
	_a1 = target + TAU * ceilf((_a0 - target) / TAU + turns)
	if Game.world:
		Sfx.play_3d("roulette_spin", global_position, -12.0 if auto else -2.0, 1.0, 14.0 if auto else 22.0)


func _ball_pos(alpha: float, r: float, h: float) -> Vector3:
	return Vector3(sin(alpha) * r, h, -cos(alpha) * r)


func _process(delta: float) -> void:
	if auto and not spinning:
		_auto_t -= delta
		if _auto_t <= 0.0:
			_auto_t = randf_range(11.0, 22.0)
			spin_to(int(D.ROULETTE_ORDER[randi() % D.ROULETTE_ORDER.size()]), randf_range(5.0, 6.5))
	rotation.y += (idle_speed + boost) * delta
	boost = maxf(0.0, boost - delta * 0.35)
	if not spinning:
		return
	_t += delta
	var k := clampf(_t / _dur, 0.0, 1.0)
	var e := 1.0 - pow(1.0 - k, 3.0)
	_alpha = lerpf(_a0, _a1, e)
	var r := BALL_TRACK
	var h := 0.035
	if k > 0.62:
		var d := (k - 0.62) / 0.38
		r = lerpf(BALL_TRACK, BALL_POCKET, smoothstep(0.0, 0.55, d))
		h = 0.03 + absf(sin(d * 14.0)) * 0.05 * (1.0 - d)
		var click := int(d * 10.0)
		if click != _last_click and d < 0.8:
			_last_click = click
			Sfx.play_3d("roulette_ball", global_position, -16.0 if auto else -8.0, randf_range(0.9, 1.15), 10.0 if auto else 14.0)
	ball.position = _ball_pos(_alpha, r, h)
	if k >= 1.0:
		spinning = false
		_alpha = fmod(_a1, TAU)
		ball.position = _ball_pos(_alpha, BALL_POCKET, 0.03)
		finished.emit(_number)



func show_result(number: int) -> void:
	var idx := D.ROULETTE_ORDER.find(number)
	_alpha = TAU * idx / 37.0
	ball.visible = true
	ball.position = _ball_pos(_alpha, BALL_POCKET, 0.03)
