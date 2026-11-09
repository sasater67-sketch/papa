extends Node3D
# Рыбки в аквариуме: плавают по эллипсам, виляют хвостом, разворачиваются по ходу движения; пузырьки.

const KL := preload("res://scripts/kit/kit_lib.gd")
const MK := preload("res://scripts/kit/mesh_kit.gd")
const COLS := [Color(1.0, 0.5, 0.1), Color(1.0, 0.85, 0.2), Color(0.95, 0.3, 0.5), Color(0.3, 0.85, 1.0), Color(0.95, 0.95, 0.95), Color(0.6, 0.4, 1.0)]

var fish: Array = []
var _t := 0.0


func _ready() -> void:
	var mesh := KL.cached("aqua_fish", _build_fish)
	for i in 6:
		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		var c: Color = COLS[i % COLS.size()]
		mi.material_override = Assets.pbr(c, 0.3, 0.1, {"emit": 0.35, "emit_color": c, "clearcoat": 0.6})
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)
		var s := randf_range(0.7, 1.2)
		mi.scale = Vector3.ONE * s
		fish.append({"mi": mi, "ax": randf_range(0.35, 0.62), "az": randf_range(0.08, 0.2), "y": randf_range(1.0, 1.58),
			"w": randf_range(0.35, 0.7) * (1.0 if i % 2 == 0 else -1.0), "ph": randf() * TAU, "wag": randf_range(9.0, 14.0)})
	var ps := CPUParticles3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.008
	sm.height = 0.016
	sm.radial_segments = 6
	sm.rings = 3
	ps.mesh = sm
	ps.material_override = Assets.cmat(Color(0.85, 0.95, 1.0, 0.8), {"emit": 0.6, "emit_color": Color(0.8, 0.95, 1.0), "blend": true})
	ps.amount = 24
	ps.lifetime = 2.2
	ps.direction = Vector3.UP
	ps.spread = 6.0
	ps.gravity = Vector3(0, 0.15, 0)
	ps.initial_velocity_min = 0.3
	ps.initial_velocity_max = 0.45
	ps.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	ps.emission_box_extents = Vector3(0.05, 0.01, 0.05)
	add_child(ps)
	ps.position = Vector3(-0.55, 0.9, -0.15)


static func _build_fish(k) -> void:
	var white := Assets.pbr(Color.WHITE, 0.3)
	# тело вдоль +X (голова), токарный профиль, приплюснут по Z
	var prof := PackedVector2Array([Vector2(0, -0.07), Vector2(0.018, -0.06), Vector2(0.03, -0.03), Vector2(0.032, 0.0), Vector2(0.026, 0.03), Vector2(0.012, 0.055), Vector2(0, 0.065)])
	var xf := Transform3D(Basis(Vector3(0, -1, 0), Vector3(1, 0, 0), Vector3(0, 0, 1)) * Basis().scaled(Vector3(1.0, 1.0, 0.55)), Vector3.ZERO)
	k.lathe(white, xf, prof, 12)
	var xz := Basis(Vector3(1, 0, 0), Vector3(0, 0, -1), Vector3(0, 1, 0))
	k.extrude(white, Transform3D(xz, Vector3.ZERO), PackedVector2Array([Vector2(-0.065, 0.0), Vector2(-0.11, 0.04), Vector2(-0.1, 0.0), Vector2(-0.11, -0.04)]), -0.003, 0.003, {"bottom": true})
	k.extrude(white, Transform3D(xz, Vector3.ZERO), PackedVector2Array([Vector2(-0.02, 0.025), Vector2(0.015, 0.03), Vector2(-0.03, 0.055)]), -0.002, 0.002, {"bottom": true})
	k.sphere(KL.m_dark(), MK.T(Vector3(0.045, 0.008, 0.016)), 0.006, 6, 3)
	k.sphere(KL.m_dark(), MK.T(Vector3(0.045, 0.008, -0.016)), 0.006, 6, 3)


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_t += delta
	for f: Dictionary in fish:
		var mi: MeshInstance3D = f.mi
		var a := _t * float(f.w) + float(f.ph)
		var p := Vector3(cos(a) * float(f.ax), float(f.y) + sin(a * 1.7) * 0.05, sin(a) * float(f.az) - 0.02)
		var v := Vector3(-sin(a) * float(f.ax), 0.0, cos(a) * float(f.az)) * signf(float(f.w))
		mi.position = p
		var yaw := atan2(-v.z, v.x)
		mi.rotation = Vector3(0, yaw + sin(_t * float(f.wag)) * 0.18, 0)
