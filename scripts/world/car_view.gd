extends Node3D
## Визуал машины / такси.

const B := preload("res://scripts/world/build.gd")
const COLORS := [Color(0.75, 0.08, 0.1), Color(0.1, 0.25, 0.7), Color(0.85, 0.85, 0.88), Color(0.08, 0.08, 0.1),
	Color(0.2, 0.55, 0.3), Color(0.45, 0.45, 0.5)]

var target_pos := Vector3.ZERO
var target_yaw := 0.0
var speed := 0.0
var _wheels: Array = []


func setup(sub: int, font: Font) -> void:
	var taxi := sub == 10
	var col: Color = Color(1.0, 0.78, 0.1) if taxi else COLORS[sub % COLORS.size()]
	var body := B.mat(col, 0.25, 0.6)
	B.box(self, Vector3(1.8, 0.6, 4.3), Vector3(0, 0.55, 0), body)
	B.box(self, Vector3(1.6, 0.55, 2.2), Vector3(0, 1.1, -0.2), body)
	B.box(self, Vector3(1.62, 0.42, 2.0), Vector3(0, 1.12, -0.2), B.mat(Color(0.05, 0.08, 0.12), 0.05, 0.8))
	for sx in [-0.65, 0.65]:
		B.box(self, Vector3(0.35, 0.15, 0.05), Vector3(sx, 0.62, 2.16), B.neon(Color(1, 0.95, 0.8), 6.0), false)
		B.box(self, Vector3(0.35, 0.12, 0.05), Vector3(sx, 0.65, -2.16), B.neon(Color(1, 0.1, 0.1), 4.0), false)
		for sz in [-1.35, 1.35]:
			var w := B.cyl(self, 0.36, 0.36, 0.28, Vector3(sx * 1.3, 0.36, sz), B.mat(Color(0.06, 0.06, 0.06), 0.9), 12)
			w.rotation.z = PI * 0.5
			_wheels.append(w)
	if taxi:
		B.box(self, Vector3(0.7, 0.25, 0.35), Vector3(0, 1.5, -0.2), B.neon(Color(1, 0.95, 0.6), 2.5))
		var labels := B.sign2(self, "TAXI", Vector3(0, 1.5, -0.2), 48, Color(0.1, 0.1, 0.1), Color(1, 0.9, 0.4), 0.006, font)
		for l in labels:
			l.rotation.y += PI * 0.5
		B.box(self, Vector3(1.82, 0.12, 4.32), Vector3(0, 0.75, 0), B.mat(Color(0.1, 0.1, 0.1)))


func _process(delta: float) -> void:
	var d := target_pos - position
	if d.length() > 8.0:
		position = target_pos
	else:
		position = position.lerp(target_pos, minf(1.0, delta * 10.0))
	rotation.y = target_yaw
	for w in _wheels:
		w.rotation.x += speed * delta / 0.36
