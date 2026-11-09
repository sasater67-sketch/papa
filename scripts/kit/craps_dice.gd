extends Node3D
# Кубики крэпса: раз в несколько секунд их бросают от переднего борта — полёт, удар о дальнюю
# стенку с «пирамидками», отскоки и кувырки; кубики ложатся случайными гранями вверх.

const KL := preload("res://scripts/kit/kit_lib.gd")
const MK := preload("res://scripts/kit/mesh_kit.gd")
const S := 0.036
const FACE_UP := [Vector3.ZERO, Vector3(0, 0, 0), Vector3(-PI * 0.5, 0, 0), Vector3(0, 0, PI * 0.5), Vector3(0, 0, -PI * 0.5), Vector3(PI * 0.5, 0, 0), Vector3(PI, 0, 0)]

var dice: Array[MeshInstance3D] = []
var _t := 0.0
var _dur := 1.5
var _next := 2.0
var _rolling := false
var _p0: Array = []
var _pw: Array = []
var _p1: Array = []
var _axis: Array = []
var _w: Array = []
var _qf: Array = []


func _ready() -> void:
	var mesh := KL.cached("craps_die", _build_die)
	for i in 2:
		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)
		mi.position = Vector3(0.12 + i * 0.09, S * 0.5, 0.15 + i * 0.05)
		mi.rotation = FACE_UP[1 + (i * 3) % 6] + Vector3(0, 0.4 * i, 0)
		dice.append(mi)
	_next = randf_range(1.0, 6.0)


static func _build_die(k) -> void:
	var red := Assets.pbr(Color(0.82, 0.04, 0.07), 0.12, 0.0, {"clearcoat": 1.0})
	var white := Assets.pbr(Color(0.97, 0.97, 0.95), 0.3)
	k.box(red, Transform3D.IDENTITY, Vector3(S, S, S), S * 0.16)
	# грани: +Y=1, +Z=2, +X=3, -X=4, -Z=5, -Y=6
	var faces := {1: [Vector3.UP, Vector3.RIGHT], 2: [Vector3.BACK, Vector3.RIGHT], 3: [Vector3.RIGHT, Vector3.FORWARD],
		4: [Vector3.LEFT, Vector3.BACK], 5: [Vector3.FORWARD, Vector3.LEFT], 6: [Vector3.DOWN, Vector3.RIGHT]}
	var pips := {1: [[0, 0]], 2: [[-1, -1], [1, 1]], 3: [[-1, -1], [0, 0], [1, 1]], 4: [[-1, -1], [1, -1], [-1, 1], [1, 1]],
		5: [[-1, -1], [1, -1], [0, 0], [-1, 1], [1, 1]], 6: [[-1, -1], [1, -1], [-1, 0], [1, 0], [-1, 1], [1, 1]]}
	for f in faces:
		var n: Vector3 = faces[f][0]
		var u: Vector3 = faces[f][1]
		var v := n.cross(u)
		for p in pips[f]:
			var c := n * (S * 0.5 - 0.0012) + u * (float(p[0]) * S * 0.27) + v * (float(p[1]) * S * 0.27)
			k.sphere(white, MK.T(c), S * 0.085, 8, 4)


func _process(delta: float) -> void:
	if not _rolling:
		_next -= delta
		if _next <= 0.0 and is_visible_in_tree():
			_start()
		return
	_t += delta
	var k := clampf(_t / _dur, 0.0, 1.0)
	for i in dice.size():
		var d := dice[i]
		var p: Vector3
		if k < 0.42:
			var s := k / 0.42
			p = (_p0[i] as Vector3).lerp(_pw[i], s) + Vector3.UP * sin(PI * s) * 0.2
		else:
			var s2 := clampf((k - 0.42) / 0.58, 0.0, 1.0)
			var e := 1.0 - pow(maxf(1.0 - s2, 0.0), 2.2)
			p = (_pw[i] as Vector3).lerp(_p1[i], e) + Vector3.UP * absf(sin(PI * s2 * 2.6)) * 0.07 * (1.0 - s2)
		p.y = maxf(p.y, S * 0.5)
		d.position = p
		var spin := Basis((_axis[i] as Vector3), float(_w[i]) * (_t - _t * _t / (2.0 * _dur)))
		var qs := spin.get_rotation_quaternion()
		var qf: Quaternion = _qf[i]
		d.quaternion = qs.slerp(qf, smoothstep(0.72, 1.0, k))
	if k >= 1.0:
		_rolling = false
		_next = randf_range(6.0, 14.0)


func _start() -> void:
	_rolling = true
	_t = 0.0
	_dur = randf_range(1.3, 1.7)
	_p0.clear()
	_pw.clear()
	_p1.clear()
	_axis.clear()
	_w.clear()
	_qf.clear()
	var x0 := randf_range(-0.9, 0.9)
	for i in dice.size():
		_p0.append(Vector3(x0 + i * 0.06, 0.32, 0.5))
		var xw := clampf(x0 * 0.6 + randf_range(-0.5, 0.5), -1.1, 1.1)
		_pw.append(Vector3(xw + i * 0.07, 0.06, -0.5))
		_p1.append(Vector3(clampf(xw + randf_range(-0.25, 0.25), -1.2, 1.2) + i * 0.08, S * 0.5, randf_range(-0.35, -0.05)))
		var ax := Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1))
		_axis.append(ax.normalized() if ax.length() > 0.2 else Vector3(0.6, 0.48, 0.64))
		_w.append(randf_range(16.0, 26.0))
		var b := Basis(Vector3.UP, randf() * TAU) * Basis.from_euler(FACE_UP[randi_range(1, 6)])
		_qf.append(b.get_rotation_quaternion())
	if Game.world:
		Sfx.play_3d("dice_roll", global_position, -8.0, randf_range(0.92, 1.1), 16.0)
