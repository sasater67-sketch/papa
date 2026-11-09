extends RefCounted



var lb
var o: Vector3
var yaw: float
var b: Basis


func _init(builder, origin: Vector3, rot: float = 0.0) -> void:
	lb = builder
	o = origin
	yaw = rot
	b = Basis(Vector3.UP, rot)


func p(local: Vector3) -> Vector3:
	return o + b * local


func dir(local: Vector3) -> Vector3:
	return b * local


func box(c: Vector3, size: Vector3, tex: String = "", opts: Dictionary = {}) -> void:
	var op := opts.duplicate()
	op["rot"] = yaw + float(opts.get("rot", 0.0))
	if not op.has("collide"):
		op["collide"] = false
	lb.box(p(c), size, tex, op)


func cyl(c: Vector3, r: float, h: float, tex: String = "", opts: Dictionary = {}) -> void:
	var op := opts.duplicate()
	if not op.has("collide"):
		op["collide"] = false
	lb.cyl(p(c), r, h, tex, op)


func plane(c: Vector3, w: float, h: float, tex: String, opts: Dictionary = {}, local_yaw: float = 0.0) -> void:
	lb.plane(p(c), w, h, yaw + local_yaw, tex, opts)


func solid(c: Vector3, size: Vector3, extra_rot: float = 0.0) -> void:
	lb.add_collider(p(c), size, yaw + extra_rot)


func solid_cyl(c: Vector3, r: float, h: float) -> void:
	lb.add_cyl_collider(p(c), r, h)
