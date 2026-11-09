extends RefCounted




const PPM := 32.0
# v0.3: реальное освещение (PBR) — фальшивое затенение вершинами отключено
const SHADE_TOP := 1.0
const SHADE_BOTTOM := 1.0
const SHADE_X := 1.0
const SHADE_Z := 1.0

var root: Node3D
var body: StaticBody3D
var _surf := {}
var _tex_size := {}


func _init(parent: Node3D, name_prefix: String = "Geo") -> void:
	root = Node3D.new()
	root.name = name_prefix
	parent.add_child(root)
	body = StaticBody3D.new()
	body.name = "Collision"
	body.collision_layer = Game.L_WORLD
	body.collision_mask = 0
	root.add_child(body)


func _key_for(tex: String, opts: Dictionary) -> String:
	return tex + "|" + JSON.stringify(opts.get("mat", {}))


func _surface(tex: String, opts: Dictionary) -> Dictionary:
	var k := _key_for(tex, opts)
	if not _surf.has(k):
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var m: Material = opts.get("material", null)
		if m == null:
			m = Assets.mat(tex, opts.get("mat", {})) if tex != "" else Assets.cmat(Color.WHITE, opts.get("mat", {}))
		_surf[k] = {"st": st, "mat": m, "n": 0, "tex": tex}
	return _surf[k]


func tex_px(tex: String) -> Vector2:
	if tex == "":
		return Vector2(64, 64)
	if not _tex_size.has(tex):
		_tex_size[tex] = Assets.tex_size(tex)
	return _tex_size[tex]




func box(center: Vector3, size: Vector3, tex: String = "", opts: Dictionary = {}) -> void:
	var tint: Color = opts.get("tint", Color.WHITE)
	var rot: float = opts.get("rot", 0.0)
	var uvmode: String = opts.get("uv", "world")
	var uvs: float = opts.get("uvs", 1.0)
	var skip: Array = opts.get("skip", [])
	var shade: bool = opts.get("shade", true)
	var s := _surface(tex, opts)
	var st: SurfaceTool = s.st
	var tp := tex_px(tex)
	var h := size * 0.5
	var basis := Basis(Vector3.UP, rot)

	var faces := [
		["px", Vector3(1, 0, 0), Vector3(0, 0, -1), Vector3(0, -1, 0)],
		["nx", Vector3(-1, 0, 0), Vector3(0, 0, 1), Vector3(0, -1, 0)],
		["pz", Vector3(0, 0, 1), Vector3(1, 0, 0), Vector3(0, -1, 0)],
		["nz", Vector3(0, 0, -1), Vector3(-1, 0, 0), Vector3(0, -1, 0)],
		["top", Vector3(0, 1, 0), Vector3(1, 0, 0), Vector3(0, 0, 1)],
		["bottom", Vector3(0, -1, 0), Vector3(1, 0, 0), Vector3(0, 0, -1)],
	]
	for f in faces:
		var fname: String = f[0]
		if fname in skip:
			continue
		var n: Vector3 = f[1]
		var u: Vector3 = f[2]
		var v: Vector3 = f[3]
		var hu := absf(u.dot(h))
		var hv := absf(v.dot(h))
		var hn := absf(n.dot(h))
		var corners := [
			n * hn - u * hu - v * hv, n * hn + u * hu - v * hv,
			n * hn + u * hu + v * hv, n * hn - u * hu + v * hv,
		]
		var uvc := []
		var fit := uvmode == "fit" or (uvmode == "front" and fname == "pz")
		for c in corners:
			if fit:
				var cu: float = (c.dot(u) / (hu * 2.0)) + 0.5
				var cv: float = (c.dot(v) / (hv * 2.0)) + 0.5
				uvc.append(Vector2(cu, cv))
			else:
				var wp: Vector3 = c + (center if rot == 0.0 else Vector3.ZERO)
				uvc.append(Vector2(wp.dot(u), wp.dot(v)) * PPM / tp * uvs)
		var wn := basis * n
		var k := SHADE_TOP
		if shade:
			if absf(wn.y) > 0.5:
				k = SHADE_TOP if wn.y > 0 else SHADE_BOTTOM
			elif absf(wn.x) > absf(wn.z):
				k = SHADE_X
			else:
				k = SHADE_Z
		var col := Color(tint.r * k, tint.g * k, tint.b * k, tint.a)
		if uvmode == "front" and fname != "pz" and opts.has("side_tint"):
			var stt: Color = opts.side_tint
			col = Color(stt.r * k, stt.g * k, stt.b * k, stt.a)
		var idx := [0, 1, 2, 0, 2, 3]
		for i in idx:
			st.set_color(col)
			st.set_normal(wn)
			st.set_uv(uvc[i])
			st.add_vertex(center + basis * corners[i])
		s.n += 6
	if opts.get("collide", true):
		add_collider(center, size, rot)


func add_collider(center: Vector3, size: Vector3, rot: float = 0.0) -> void:
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = size
	cs.shape = sh
	cs.transform = Transform3D(Basis(Vector3.UP, rot), center)
	body.add_child(cs)


func add_cyl_collider(center: Vector3, radius: float, height: float) -> void:
	var cs := CollisionShape3D.new()
	var sh := CylinderShape3D.new()
	sh.radius = radius
	sh.height = height
	cs.shape = sh
	cs.position = center
	body.add_child(cs)



func box_minmax(a: Vector3, b: Vector3, tex: String = "", opts: Dictionary = {}) -> void:
	var mn := Vector3(minf(a.x, b.x), minf(a.y, b.y), minf(a.z, b.z))
	var mx := Vector3(maxf(a.x, b.x), maxf(a.y, b.y), maxf(a.z, b.z))
	box((mn + mx) * 0.5, mx - mn, tex, opts)



func cyl(center: Vector3, radius: float, height: float, tex: String = "", opts: Dictionary = {}) -> void:
	var sides: int = opts.get("sides", 12)
	var tint: Color = opts.get("tint", Color.WHITE)
	var s := _surface(tex, opts)
	var st: SurfaceTool = s.st
	var tp := tex_px(tex)
	var hh := height * 0.5
	var circ := TAU * radius
	var top_fit: bool = opts.get("top_fit", false)
	var r2: float = opts.get("radius_top", radius)
	for i in sides:
		var a0 := TAU * i / sides
		var a1 := TAU * (i + 1) / sides
		var p0 := Vector3(cos(a0) * radius, -hh, sin(a0) * radius)
		var p1 := Vector3(cos(a1) * radius, -hh, sin(a1) * radius)
		var q0 := Vector3(cos(a0) * r2, hh, sin(a0) * r2)
		var q1 := Vector3(cos(a1) * r2, hh, sin(a1) * r2)
		var nm := Vector3(cos((a0 + a1) * 0.5), 0, sin((a0 + a1) * 0.5))
		var k := lerpf(SHADE_X, SHADE_Z, absf(nm.z))
		var col := Color(tint.r * k, tint.g * k, tint.b * k, tint.a)
		var u0 := float(i) / sides * circ * PPM / tp.x
		var u1 := float(i + 1) / sides * circ * PPM / tp.x
		var v0 := height * PPM / tp.y
		var quad := [[p0, Vector2(u0, v0)], [q1, Vector2(u1, 0)], [q0, Vector2(u0, 0)], [p0, Vector2(u0, v0)], [p1, Vector2(u1, v0)], [q1, Vector2(u1, 0)]]
		if opts.get("side", true):
			for e in quad:
				st.set_color(col)
				st.set_normal(nm)
				st.set_uv(e[1])
				st.add_vertex(center + e[0])
			s.n += 6
		if opts.get("cap", true):
			var tcol := Color(tint.r, tint.g, tint.b, tint.a)
			var cen := Vector3(0, hh, 0)
			for e in [[cen, 0.0], [q0, a0], [q1, a1]]:
				var pp: Vector3 = e[0]
				st.set_color(tcol)
				st.set_normal(Vector3.UP)
				if top_fit:
					st.set_uv(Vector2(pp.x / (r2 * 2.0) + 0.5, pp.z / (r2 * 2.0) + 0.5))
				else:
					st.set_uv(Vector2(center.x + pp.x, center.z + pp.z) * PPM / tp)
				st.add_vertex(center + pp)
			if opts.get("bottom", false):
				var bc := Vector3(0, -hh, 0)
				for pp in [bc, p1, p0]:
					st.set_color(tcol * SHADE_BOTTOM)
					st.set_normal(Vector3.DOWN)
					st.set_uv(Vector2(pp.x, pp.z) * PPM / tp)
					st.add_vertex(center + pp)
			s.n += 3
	if opts.get("collide", true):
		add_cyl_collider(center, maxf(radius, r2), height)



func plane(center: Vector3, w: float, h: float, yaw: float, tex: String, opts: Dictionary = {}) -> void:
	var s := _surface(tex, opts)
	var st: SurfaceTool = s.st
	var tint: Color = opts.get("tint", Color.WHITE)
	var b := Basis(Vector3.UP, yaw)
	var n := b * Vector3(0, 0, 1)
	var u := b * Vector3(1, 0, 0)
	var corners := [[-u * w * 0.5 + Vector3(0, h * 0.5, 0), Vector2(0, 0)], [u * w * 0.5 + Vector3(0, h * 0.5, 0), Vector2(1, 0)],
		[u * w * 0.5 - Vector3(0, h * 0.5, 0), Vector2(1, 1)], [-u * w * 0.5 - Vector3(0, h * 0.5, 0), Vector2(0, 1)]]
	var uvr: Rect2 = opts.get("uv_rect", Rect2(0, 0, 1, 1))
	for i in [0, 1, 2, 0, 2, 3]:
		var c = corners[i]
		st.set_color(tint)
		st.set_normal(n)
		st.set_uv(uvr.position + c[1] * uvr.size)
		st.add_vertex(center + c[0])
	s.n += 6



func floor_plane(center: Vector3, w: float, d: float, tex: String, opts: Dictionary = {}) -> void:
	var s := _surface(tex, opts)
	var st: SurfaceTool = s.st
	var tint: Color = opts.get("tint", Color.WHITE)
	var rot: float = opts.get("rot", 0.0)
	var b := Basis(Vector3.UP, rot)
	var corners := [[Vector3(-w / 2, 0, -d / 2), Vector2(0, 0)], [Vector3(w / 2, 0, -d / 2), Vector2(1, 0)],
		[Vector3(w / 2, 0, d / 2), Vector2(1, 1)], [Vector3(-w / 2, 0, d / 2), Vector2(0, 1)]]
	var tiles: Vector2 = opts.get("tiles", Vector2.ONE)
	for i in [0, 1, 2, 0, 2, 3]:
		var c = corners[i]
		st.set_color(tint)
		st.set_normal(Vector3.UP)
		st.set_uv(c[1] * tiles)
		st.add_vertex(center + b * c[0])
	s.n += 6



func commit(cast_shadows: bool = true) -> void:
	for k in _surf:
		var s: Dictionary = _surf[k]
		if s.n == 0:
			continue
		var st: SurfaceTool = s.st
		var sm := s.mat as BaseMaterial3D
		if sm and sm.normal_enabled:
			st.generate_tangents()
		var mesh := st.commit()
		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		mi.material_override = s.mat
		mi.name = "M_" + str(s.tex if s.tex != "" else "color")
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if cast_shadows else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(mi)
	_surf.clear()


func stats() -> Dictionary:
	var verts := 0
	for k in _surf:
		verts += int(_surf[k].n)
	return {"surfaces": _surf.size(), "verts": verts, "colliders": body.get_child_count()}
