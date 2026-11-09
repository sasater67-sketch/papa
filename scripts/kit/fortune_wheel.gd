extends Node3D



signal finished(segment: int)

const D := preload("res://scripts/kit/wheel_data.gd")

var pointer: Node3D
var yaw := 0.0
var spin := 0.0
var spinning := false
var _t := 0.0
var _dur := 7.0
var _s0 := 0.0
var _s1 := 0.0
var _seg := 0
var _last_peg := 0
var _flap := 0.0
var _last_tick := 0
var auto := false
var _auto_t := randf_range(3.0, 14.0)


func _ready() -> void:
	_apply()


func _apply() -> void:
	rotation = Vector3(0, yaw, spin)


func segment_angle(i: int) -> float:
	return TAU * i / float(D.WHEEL_SEGMENTS.size())


func spin_to(segment: int, dur: float = 7.0) -> void:
	_seg = segment
	_dur = maxf(1.0, dur)
	_t = 0.0
	spinning = true
	_s0 = spin
	var n := D.WHEEL_SEGMENTS.size()
	var jitter := (randf() - 0.5) * 0.7 * TAU / n
	var target := segment_angle(segment) + jitter

	var base := target - TAU * ceilf((target - _s0) / TAU)
	_s1 = base - TAU * 3.0


func show_segment(segment: int) -> void:
	spin = segment_angle(segment)
	spinning = false
	_apply()


func _process(delta: float) -> void:
	if auto and not spinning:
		_auto_t -= delta
		if _auto_t <= 0.0:
			_auto_t = randf_range(14.0, 26.0)
			spin_to(randi() % D.WHEEL_SEGMENTS.size(), randf_range(6.0, 8.0))
	if spinning:
		_t += delta
		var k := clampf(_t / _dur, 0.0, 1.0)
		var e := 1.0 - pow(1.0 - k, 3.2)
		spin = lerpf(_s0, _s1, e)
		if k >= 1.0:
			spinning = false
			spin = fmod(_s1, TAU)
			finished.emit(_seg)
		_apply()
	var n := D.WHEEL_SEGMENTS.size()
	var seg := TAU / n
	var peg := int(floor((spin + seg * 0.5) / seg))
	if peg != _last_peg:
		_last_peg = peg
		_flap = 1.0
		var now := Time.get_ticks_msec()
		if spinning and now - _last_tick > 45:
			_last_tick = now
			Audio.play_3d("wheel_tick", global_position + Vector3(0, 2.0, 0), -15.0 if auto else -4.0, randf_range(0.95, 1.08), 12.0 if auto else 26.0)
	_flap = maxf(0.0, _flap - delta * 9.0)
	if pointer:
		pointer.rotation.z = PI + _flap * 0.35
