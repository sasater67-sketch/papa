extends Node3D
# Шарики плинко: падают из воронки, отскакивая от колышков, и попадают в лунку с множителем.

const TK := preload("res://scripts/kit/table_kit.gd")
const KL := preload("res://scripts/kit/kit_lib.gd")
const SEG := 0.105

var balls: Array = []


func _ready() -> void:
	var sm := SphereMesh.new()
	sm.radius = 0.03
	sm.height = 0.06
	sm.radial_segments = 14
	sm.rings = 7
	for i in 3:
		var mi := MeshInstance3D.new()
		mi.mesh = sm
		mi.material_override = KL.m_gold() if i != 1 else KL.m_chrome()
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.visible = false
		add_child(mi)
		balls.append({"mi": mi, "pts": PackedVector3Array(), "t": 0.0, "wait": randf_range(0.5, 3.0) + i * 2.2, "done": 0.0})


func _path() -> PackedVector3Array:
	var pts := PackedVector3Array()
	var z := TK.PLINKO_Z
	var x := 0.0
	pts.append(Vector3(randf_range(-0.01, 0.01), 3.02, z))
	for r in TK.PLINKO_ROWS:
		var y := TK.PLINKO_Y0 - float(r) * TK.PLINKO_DY + 0.041
		pts.append(Vector3(x + randf_range(-0.004, 0.004), y, z))
		x += TK.PLINKO_DX * 0.5 * (1.0 if randf() < 0.5 else -1.0)
	pts.append(Vector3(x, 1.05, z))
	return pts


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	for b: Dictionary in balls:
		var mi: MeshInstance3D = b.mi
		if float(b.wait) > 0.0:
			b.wait = float(b.wait) - delta
			if float(b.wait) <= 0.0:
				b.pts = _path()
				b.t = 0.0
				b.done = 0.0
				mi.visible = true
			continue
		var pts: PackedVector3Array = b.pts
		var nseg := pts.size() - 1
		b.t = float(b.t) + delta
		var f := float(b.t) / SEG
		var i := int(f)
		if i >= nseg:
			mi.position = pts[nseg]
			if float(b.done) == 0.0 and Game.world:
				Audio.play_3d("plinko", global_position + Vector3(0, 1.1, 0), -12.0, randf_range(0.9, 1.2), 12.0)
			b.done = float(b.done) + delta
			if float(b.done) > 0.9:
				mi.visible = false
				b.wait = randf_range(1.0, 4.5)
			continue
		var s := f - float(i)
		var a := pts[i]
		var c := pts[i + 1]
		var hop := 0.045 if i > 0 and i < nseg - 1 else 0.0
		var p := a.lerp(c, s)
		# отскок: сначала вверх-в сторону, затем падение к следующему колышку
		p.y += sin(PI * s) * hop
		if i == nseg - 1:
			p.y = lerpf(a.y, c.y, s * s)
		mi.position = p
