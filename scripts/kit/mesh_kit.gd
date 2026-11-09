extends RefCounted
# MeshKit v0.3 — процедурная геометрия высокого качества: скруглённые боксы (фаски), цилиндры с фасками,
# токарные тела (lathe), торы, сферы, экструзия полигонов, трубы. UV — в метрах (материалы Assets.kit_mat),
# нормали гладкие, тангенты генерируются, геометрия сливается по материалам.
# Godot: лицевая сторона треугольника — по часовой стрелке.

var root: Node3D
var body: StaticBody3D = null
var _surf := {}
var _order: Array = []
var shadows := true


func _init(parent: Node3D, nm: String = "Kit", with_body: bool = true) -> void:
	root = Node3D.new()
	root.name = nm
	parent.add_child(root)
	if with_body:
		body = StaticBody3D.new()
		body.name = "Col"
		body.collision_layer = Game.L_WORLD
		body.collision_mask = 0
		root.add_child(body)


static func T(pos: Vector3, yaw: float = 0.0) -> Transform3D:
	return Transform3D(Basis(Vector3.UP, yaw), pos)


static func TR(pos: Vector3, rot: Vector3) -> Transform3D:
	return Transform3D(Basis.from_euler(rot), pos)


func _s(m: Material) -> Dictionary:
	var k := m.get_instance_id()
	if not _surf.has(k):
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		_surf[k] = {"st": st, "mat": m, "n": 0}
		_order.append(k)
	return _surf[k]


static func _uvp(p: Vector3, n: Vector3) -> Vector2:
	var ax := absf(n.x)
	var ay := absf(n.y)
	var az := absf(n.z)
	if ay >= ax and ay >= az:
		return Vector2(p.x, p.z if n.y >= 0.0 else -p.z)
	if ax >= az:
		return Vector2(-p.z if n.x >= 0.0 else p.z, -p.y)
	return Vector2(p.x if n.z >= 0.0 else -p.x, -p.y)


func _v(st: SurfaceTool, p: Vector3, n: Vector3, uv: Vector2, c: Color) -> void:
	st.set_color(c)
	st.set_normal(n)
	st.set_uv(uv)
	st.add_vertex(p)


# треугольник с автоисправлением обхода по нормали
func tri(m: Material, a: Vector3, b: Vector3, c: Vector3, na: Vector3, nb: Vector3, nc: Vector3, ua: Vector2, ub: Vector2, uc: Vector2, col: Color = Color.WHITE) -> void:
	var s := _s(m)
	var st: SurfaceTool = s.st
	var gn := (b - a).cross(c - a)
	if gn.dot(na + nb + nc) > 0.0:
		_v(st, a, na, ua, col)
		_v(st, c, nc, uc, col)
		_v(st, b, nb, ub, col)
	else:
		_v(st, a, na, ua, col)
		_v(st, b, nb, ub, col)
		_v(st, c, nc, uc, col)
	s.n += 3


func quad_n(m: Material, a: Vector3, b: Vector3, c: Vector3, d: Vector3, na: Vector3, nb: Vector3, nc: Vector3, nd: Vector3, ua: Vector2, ub: Vector2, uc: Vector2, ud: Vector2, col: Color = Color.WHITE) -> void:
	tri(m, a, b, c, na, nb, nc, ua, ub, uc, col)
	tri(m, a, c, d, na, nc, nd, ua, uc, ud, col)


# плоский четырёхугольник (мировые UV по нормали)
func quad(m: Material, xf: Transform3D, a: Vector3, b: Vector3, c: Vector3, d: Vector3, col: Color = Color.WHITE, uvk: float = 1.0) -> void:
	var A := xf * a
	var B := xf * b
	var C := xf * c
	var D := xf * d
	var n := (B - A).cross(C - A).normalized() * -1.0
	if n.length() < 0.5:
		n = (C - A).cross(D - A).normalized() * -1.0
	quad_n(m, A, B, C, D, n, n, n, n, _uvp(A, n) * uvk, _uvp(B, n) * uvk, _uvp(C, n) * uvk, _uvp(D, n) * uvk, col)


# вертикальная плоскость с UV 0..1 (для вывесок, экранов, постеров). Лицом к +Z локально.
func panel(m: Material, xf: Transform3D, w: float, h: float, col: Color = Color.WHITE, uv_rect: Rect2 = Rect2(0, 0, 1, 1)) -> void:
	var a := xf * Vector3(-w * 0.5, h * 0.5, 0)
	var b := xf * Vector3(w * 0.5, h * 0.5, 0)
	var c := xf * Vector3(w * 0.5, -h * 0.5, 0)
	var d := xf * Vector3(-w * 0.5, -h * 0.5, 0)
	var n := (xf.basis * Vector3(0, 0, 1)).normalized()
	var p0 := uv_rect.position
	var p1 := uv_rect.position + uv_rect.size
	quad_n(m, a, b, c, d, n, n, n, n, Vector2(p0.x, p0.y), Vector2(p1.x, p0.y), Vector2(p1.x, p1.y), Vector2(p0.x, p1.y), col)


# ------------------------------------------------------------ скруглённый бокс
# size — полный размер; bevel — радиус скругления; seg — сегментов на скругление.
func box(m: Material, xf: Transform3D, size: Vector3, bevel: float = 0.0, opts: Dictionary = {}) -> void:
	var col: Color = opts.get("col", Color.WHITE)
	var uvk: float = opts.get("uvk", 1.0)
	var skip: Array = opts.get("skip", [])
	var h := size * 0.5
	var b := clampf(bevel, 0.0, minf(h.x, minf(h.y, h.z)) * 0.98)
	var seg: int = int(opts.get("seg", 1 if b < 0.04 else 2)) if b > 0.0005 else 0
	var bas := xf.basis
	var faces := [["px", 0, 1, 2, 1.0], ["nx", 0, 1, 2, -1.0], ["py", 1, 2, 0, 1.0], ["ny", 1, 2, 0, -1.0], ["pz", 2, 0, 1, 1.0], ["nz", 2, 0, 1, -1.0]]
	for f in faces:
		if str(f[0]) in skip:
			continue
		var ax: int = f[1]
		var ua: int = f[2]
		var va: int = f[3]
		var sg: float = f[4]
		var gu := _grid(h[ua], b, seg)
		var gv := _grid(h[va], b, seg)
		var pts: Array = []
		var nrm: Array = []
		for j in gv.size():
			var rowp: Array = []
			var rown: Array = []
			for i in gu.size():
				var v := Vector3.ZERO
				v[ax] = h[ax] * sg
				v[ua] = gu[i]
				v[va] = gv[j]
				var inner := Vector3(clampf(v.x, -h.x + b, h.x - b), clampf(v.y, -h.y + b, h.y - b), clampf(v.z, -h.z + b, h.z - b))
				var d := v - inner
				var nn := Vector3.ZERO
				nn[ax] = sg
				if b > 0.0005 and d.length() > 0.00001:
					nn = d.normalized()
				var fp := inner + nn * b if b > 0.0005 else v
				rowp.append(xf * fp)
				rown.append((bas * nn).normalized())
			pts.append(rowp)
			nrm.append(rown)
		var fn := Vector3.ZERO
		fn[ax] = sg
		var wfn := (bas * fn).normalized()
		for j in gv.size() - 1:
			for i in gu.size() - 1:
				var A: Vector3 = pts[j][i]
				var B: Vector3 = pts[j][i + 1]
				var C: Vector3 = pts[j + 1][i + 1]
				var D: Vector3 = pts[j + 1][i]
				quad_n(m, A, B, C, D, nrm[j][i], nrm[j][i + 1], nrm[j + 1][i + 1], nrm[j + 1][i],
					_uvp(A, wfn) * uvk, _uvp(B, wfn) * uvk, _uvp(C, wfn) * uvk, _uvp(D, wfn) * uvk, col)
	if opts.get("collide", false) and body:
		collider(xf, size)


static func _grid(hh: float, b: float, seg: int) -> PackedFloat32Array:
	var g := PackedFloat32Array()
	if seg <= 0 or b <= 0.0005:
		g.append(-hh)
		g.append(hh)
		return g
	for i in seg + 1:
		g.append(-hh + b * float(i) / float(seg))
	if hh - b > -hh + b + 0.0001:
		for i in seg + 1:
			g.append(hh - b + b * float(i) / float(seg))
	else:
		for i in range(1, seg + 1):
			g.append(-hh + b + b * float(i) / float(seg))
	return g


func box_mm(m: Material, a: Vector3, b: Vector3, bevel: float = 0.0, opts: Dictionary = {}) -> void:
	var mn := Vector3(minf(a.x, b.x), minf(a.y, b.y), minf(a.z, b.z))
	var mx := Vector3(maxf(a.x, b.x), maxf(a.y, b.y), maxf(a.z, b.z))
	var xf: Transform3D = opts.get("xf", Transform3D.IDENTITY)
	box(m, xf * Transform3D(Basis(), (mn + mx) * 0.5), mx - mn, bevel, opts)


# ------------------------------------------------------------ токарное тело
# prof — точки (r, y) снизу вверх; ось вращения — локальная Y трансформа xf.
func lathe(m: Material, xf: Transform3D, prof: PackedVector2Array, sides: int = 24, opts: Dictionary = {}) -> void:
	var col: Color = opts.get("col", Color.WHITE)
	var uvk: float = opts.get("uvk", 1.0)
	var a0: float = opts.get("a0", 0.0)
	var a1: float = opts.get("a1", TAU)
	var hard: float = opts.get("hard", 0.75)
	var n := prof.size()
	if n < 2:
		return
	# нормали профиля
	var segn: Array = []
	for i in n - 1:
		var d := prof[i + 1] - prof[i]
		segn.append(Vector2(d.y, -d.x).normalized())
	var vn_lo: Array = []
	var vn_hi: Array = []
	for i in n:
		var lo: Vector2 = segn[maxi(0, i - 1)]
		var hi: Vector2 = segn[mini(n - 2, i)]
		if i > 0 and i < n - 1:
			var s0: Vector2 = segn[i - 1]
			var s1: Vector2 = segn[i]
			if s0.dot(s1) > hard:
				var av := (s0 + s1).normalized()
				lo = av
				hi = av
			else:
				lo = s0
				hi = s1
		vn_lo.append(lo)
		vn_hi.append(hi)
	var vlen := PackedFloat32Array()
	var acc := 0.0
	vlen.append(0.0)
	for i in n - 1:
		acc += (prof[i + 1] - prof[i]).length()
		vlen.append(acc)
	var rmax := 0.0
	for p in prof:
		rmax = maxf(rmax, p.x)
	var circ := rmax * (a1 - a0)
	var bas := xf.basis
	for s in sides:
		var t0 := a0 + (a1 - a0) * float(s) / float(sides)
		var t1 := a0 + (a1 - a0) * float(s + 1) / float(sides)
		var c0 := cos(t0)
		var s0_ := sin(t0)
		var c1 := cos(t1)
		var s1_ := sin(t1)
		var u0 := float(s) / float(sides) * circ * uvk
		var u1 := float(s + 1) / float(sides) * circ * uvk
		for i in n - 1:
			var pa := prof[i]
			var pb := prof[i + 1]
			if pa.x < 0.0001 and pb.x < 0.0001:
				continue
			var na: Vector2 = vn_hi[i]
			var nb: Vector2 = vn_lo[i + 1]
			var A := xf * Vector3(pa.x * c0, pa.y, pa.x * s0_)
			var B := xf * Vector3(pa.x * c1, pa.y, pa.x * s1_)
			var C := xf * Vector3(pb.x * c1, pb.y, pb.x * s1_)
			var D := xf * Vector3(pb.x * c0, pb.y, pb.x * s0_)
			var nA := (bas * Vector3(na.x * c0, na.y, na.x * s0_)).normalized()
			var nB := (bas * Vector3(na.x * c1, na.y, na.x * s1_)).normalized()
			var nC := (bas * Vector3(nb.x * c1, nb.y, nb.x * s1_)).normalized()
			var nD := (bas * Vector3(nb.x * c0, nb.y, nb.x * s0_)).normalized()
			var va := vlen[i] * uvk
			var vb := vlen[i + 1] * uvk
			if pa.x < 0.0001:
				tri(m, A, C, D, nA, nC, nD, Vector2(u0, va), Vector2(u1, vb), Vector2(u0, vb), col)
			elif pb.x < 0.0001:
				tri(m, A, B, C, nA, nB, nC, Vector2(u0, va), Vector2(u1, va), Vector2(u1, vb), col)
			else:
				quad_n(m, A, B, C, D, nA, nB, nC, nD, Vector2(u0, va), Vector2(u1, va), Vector2(u1, vb), Vector2(u0, vb), col)
	if opts.get("collide", false) and body:
		var ymin := 1e9
		var ymax := -1e9
		for p in prof:
			ymin = minf(ymin, p.y)
			ymax = maxf(ymax, p.y)
		cyl_collider(xf * Vector3(0, (ymin + ymax) * 0.5, 0), rmax, ymax - ymin)


# цилиндр (ось Y) с фасками; r_top — для конуса
func cyl(m: Material, xf: Transform3D, r: float, h: float, sides: int = 24, opts: Dictionary = {}) -> void:
	var b: float = opts.get("bevel", 0.0)
	var rt: float = opts.get("r_top", r)
	var caps: bool = opts.get("caps", true)
	var bot: bool = opts.get("bottom", caps)
	var prof := PackedVector2Array()
	var y0 := -h * 0.5
	var y1 := h * 0.5
	if bot:
		prof.append(Vector2(0, y0))
	if b > 0.0005:
		if bot:
			prof.append(Vector2(r - b, y0))
			prof.append(Vector2(r - b * 0.3, y0 + b * 0.3))
		prof.append(Vector2(r, y0 + b))
		prof.append(Vector2(rt, y1 - b))
		if caps:
			prof.append(Vector2(rt - b * 0.3, y1 - b * 0.3))
			prof.append(Vector2(rt - b, y1))
	else:
		prof.append(Vector2(r, y0))
		prof.append(Vector2(rt, y1))
	if caps:
		prof.append(Vector2(0, y1))
	var o := opts.duplicate()
	o.erase("collide")
	lathe(m, xf, prof, sides, o)
	if opts.get("collide", false) and body:
		cyl_collider(xf.origin, maxf(r, rt), h)


func sphere(m: Material, xf: Transform3D, r: float, sides: int = 20, rings: int = 12, opts: Dictionary = {}) -> void:
	var prof := PackedVector2Array()
	var f0: float = opts.get("from", 0.0)
	var f1: float = opts.get("to", 1.0)
	for i in rings + 1:
		var a := PI * (f0 + (f1 - f0) * float(i) / float(rings)) - PI * 0.5
		prof.append(Vector2(cos(a) * r, sin(a) * r))
	if f0 <= 0.0:
		prof[0] = Vector2(0, -r)
	if f1 >= 1.0:
		prof[prof.size() - 1] = Vector2(0, r)
	var o := opts.duplicate()
	o["hard"] = -2.0
	lathe(m, xf, prof, sides, o)


func torus(m: Material, xf: Transform3D, R: float, r: float, sides: int = 24, rings: int = 10, opts: Dictionary = {}) -> void:
	var prof := PackedVector2Array()
	for i in rings + 1:
		var a := TAU * float(i) / float(rings) + PI
		prof.append(Vector2(R + cos(a) * r, -sin(a) * r))
	var o := opts.duplicate()
	o["hard"] = -2.0
	lathe(m, xf, prof, sides, o)


# призма из полигона (x, z) между y0 и y1
func extrude(m: Material, xf: Transform3D, poly: PackedVector2Array, y0: float, y1: float, opts: Dictionary = {}) -> void:
	var col: Color = opts.get("col", Color.WHITE)
	var uvk: float = opts.get("uvk", 1.0)
	var n := poly.size()
	if n < 3:
		return
	var area := 0.0
	for i in n:
		var p := poly[i]
		var q := poly[(i + 1) % n]
		area += p.x * q.y - q.x * p.y
	var bas := xf.basis
	for i in n:
		var p := poly[i]
		var q := poly[(i + 1) % n]
		var A := xf * Vector3(p.x, y1, p.y)
		var B := xf * Vector3(q.x, y1, q.y)
		var C := xf * Vector3(q.x, y0, q.y)
		var D := xf * Vector3(p.x, y0, p.y)
		var e := q - p
		var nl := Vector3(e.y, 0, -e.x).normalized()
		if area < 0.0:
			nl = -nl
		var nw := (bas * nl).normalized()
		quad_n(m, A, B, C, D, nw, nw, nw, nw, _uvp(A, nw) * uvk, _uvp(B, nw) * uvk, _uvp(C, nw) * uvk, _uvp(D, nw) * uvk, col)
	if opts.get("caps", true):
		var idx := Geometry2D.triangulate_polygon(poly)
		var up := (bas * Vector3.UP).normalized()
		for k in range(0, idx.size(), 3):
			var p0 := poly[idx[k]]
			var p1 := poly[idx[k + 1]]
			var p2 := poly[idx[k + 2]]
			var a := xf * Vector3(p0.x, y1, p0.y)
			var b := xf * Vector3(p1.x, y1, p1.y)
			var c := xf * Vector3(p2.x, y1, p2.y)
			tri(m, a, b, c, up, up, up, _uvp(a, up) * uvk, _uvp(b, up) * uvk, _uvp(c, up) * uvk, col)
			if opts.get("bottom", false):
				var a2 := xf * Vector3(p0.x, y0, p0.y)
				var b2 := xf * Vector3(p1.x, y0, p1.y)
				var c2 := xf * Vector3(p2.x, y0, p2.y)
				tri(m, a2, b2, c2, -up, -up, -up, _uvp(a2, -up) * uvk, _uvp(b2, -up) * uvk, _uvp(c2, -up) * uvk, col)


# труба между двумя точками
func tube(m: Material, a: Vector3, b: Vector3, r: float, sides: int = 10, opts: Dictionary = {}) -> void:
	var d := b - a
	var L := d.length()
	if L < 0.0001:
		return
	var y := d / L
	var x := y.cross(Vector3.UP if absf(y.y) < 0.95 else Vector3.RIGHT).normalized()
	var z := x.cross(y).normalized()
	var xf := Transform3D(Basis(x, y, z), (a + b) * 0.5)
	var o := opts.duplicate()
	o["caps"] = opts.get("caps", false)
	cyl(m, xf, r, L, sides, o)


# ломаная труба (поручни): узлы — сферы
func pipe(m: Material, pts: Array, r: float, sides: int = 10, opts: Dictionary = {}) -> void:
	for i in pts.size() - 1:
		tube(m, pts[i], pts[i + 1], r, sides, opts)
	if opts.get("joints", true):
		for i in range(1, pts.size() - 1):
			sphere(m, Transform3D(Basis(), pts[i]), r, sides, 6)


# протяжка профиля вдоль ломаной в плоскости XZ (бортики столов, поручни, карнизы).
# path — точки (Vector3) по контуру; prof — точки (наружу, вверх) относительно точки контура;
# наружная сторона — по правую руку при обходе профиля (как у lathe).
func sweep(m: Material, path: Array, prof: PackedVector2Array, closed: bool = true, opts: Dictionary = {}) -> void:
	var col: Color = opts.get("col", Color.WHITE)
	var uvk: float = opts.get("uvk", 1.0)
	var hard: float = opts.get("hard", 0.75)
	var n := path.size()
	var np := prof.size()
	if n < 2 or np < 2:
		return
	# ориентация контура (знак площади) -> направление «наружу»
	var area := 0.0
	for i in n:
		var a: Vector3 = path[i]
		var b: Vector3 = path[(i + 1) % n]
		area += a.x * b.z - b.x * a.z
	var flip := -1.0 if area > 0.0 else 1.0
	if opts.has("out_sign"):
		flip = float(opts.out_sign)
	var outs: Array = []
	for i in n:
		var p0: Vector3 = path[(i - 1 + n) % n] if (closed or i > 0) else path[i]
		var p1: Vector3 = path[(i + 1) % n] if (closed or i < n - 1) else path[i]
		var t := (p1 - p0)
		t.y = 0.0
		t = t.normalized()
		var o := t.cross(Vector3.UP).normalized() * flip
		# компенсация сужения на углах
		var k := 1.0
		if closed or (i > 0 and i < n - 1):
			var ta: Vector3 = (path[i] - p0)
			var tb: Vector3 = (p1 - path[i])
			ta.y = 0.0
			tb.y = 0.0
			if ta.length() > 0.0001 and tb.length() > 0.0001:
				var oa := ta.normalized().cross(Vector3.UP).normalized() * flip
				k = 1.0 / maxf(0.5, oa.dot(o))
		outs.append(o * k)
	var segn: Array = []
	for j in np - 1:
		var d := prof[j + 1] - prof[j]
		segn.append(Vector2(d.y, -d.x).normalized())
	var vn_lo: Array = []
	var vn_hi: Array = []
	for j in np:
		var lo: Vector2 = segn[maxi(0, j - 1)]
		var hi: Vector2 = segn[mini(np - 2, j)]
		if j > 0 and j < np - 1:
			var s0: Vector2 = segn[j - 1]
			var s1: Vector2 = segn[j]
			if s0.dot(s1) > hard:
				var av := (s0 + s1).normalized()
				lo = av
				hi = av
			else:
				lo = s0
				hi = s1
		vn_lo.append(lo)
		vn_hi.append(hi)
	var vlen := PackedFloat32Array()
	var acc := 0.0
	vlen.append(0.0)
	for j in np - 1:
		acc += (prof[j + 1] - prof[j]).length()
		vlen.append(acc)
	var ulen := PackedFloat32Array()
	var ua := 0.0
	ulen.append(0.0)
	for i in n:
		ua += ((path[(i + 1) % n] as Vector3) - (path[i] as Vector3)).length()
		ulen.append(ua)
	var segs := n if closed else n - 1
	for i in segs:
		var i2 := (i + 1) % n
		var A0: Vector3 = path[i]
		var B0: Vector3 = path[i2]
		var oA: Vector3 = outs[i]
		var oB: Vector3 = outs[i2]
		var nA: Vector3 = oA.normalized()
		var nB: Vector3 = oB.normalized()
		var u0 := ulen[i] * uvk
		var u1 := ulen[i + 1] * uvk
		for j in np - 1:
			var pa := prof[j]
			var pb := prof[j + 1]
			var a1 := A0 + oA * pa.x + Vector3.UP * pa.y
			var b1 := B0 + oB * pa.x + Vector3.UP * pa.y
			var c1 := B0 + oB * pb.x + Vector3.UP * pb.y
			var d1 := A0 + oA * pb.x + Vector3.UP * pb.y
			var ha: Vector2 = vn_hi[j]
			var hb: Vector2 = vn_lo[j + 1]
			var na1 := (nA * ha.x + Vector3.UP * ha.y).normalized()
			var nb1 := (nB * ha.x + Vector3.UP * ha.y).normalized()
			var nc1 := (nB * hb.x + Vector3.UP * hb.y).normalized()
			var nd1 := (nA * hb.x + Vector3.UP * hb.y).normalized()
			quad_n(m, a1, b1, c1, d1, na1, nb1, nc1, nd1, Vector2(u0, vlen[j] * uvk), Vector2(u1, vlen[j] * uvk), Vector2(u1, vlen[j + 1] * uvk), Vector2(u0, vlen[j + 1] * uvk), col)


# плоский многоугольник (x, z) на высоте y с UV из rect (bounding box -> 0..1)
func flat_poly(m: Material, xf: Transform3D, poly: PackedVector2Array, y: float, uv_box: Rect2, col: Color = Color.WHITE) -> void:
	var idx := Geometry2D.triangulate_polygon(poly)
	var up := (xf.basis * Vector3.UP).normalized()
	for t in range(0, idx.size(), 3):
		var q: Array = []
		var uv: Array = []
		for e in 3:
			var p := poly[idx[t + e]]
			q.append(xf * Vector3(p.x, y, p.y))
			uv.append(Vector2((p.x - uv_box.position.x) / uv_box.size.x, (p.y - uv_box.position.y) / uv_box.size.y))
		tri(m, q[0], q[1], q[2], up, up, up, uv[0], uv[1], uv[2], col)


# ------------------------------------------------------------ коллизии

func collider(xf: Transform3D, size: Vector3) -> void:
	if body == null:
		return
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = size
	cs.shape = sh
	cs.transform = xf
	body.add_child(cs)


func collider_mm(a: Vector3, b: Vector3) -> void:
	var mn := Vector3(minf(a.x, b.x), minf(a.y, b.y), minf(a.z, b.z))
	var mx := Vector3(maxf(a.x, b.x), maxf(a.y, b.y), maxf(a.z, b.z))
	collider(Transform3D(Basis(), (mn + mx) * 0.5), mx - mn)


func cyl_collider(pos: Vector3, r: float, h: float) -> void:
	if body == null:
		return
	var cs := CollisionShape3D.new()
	var sh := CylinderShape3D.new()
	sh.radius = r
	sh.height = h
	cs.shape = sh
	cs.position = pos
	body.add_child(cs)


func vert_count() -> int:
	var n := 0
	for k in _surf:
		n += int(_surf[k].n)
	return n


# собрать меши; возвращает MeshInstance3D первого материала (или null)
func commit(cast_shadows: bool = true) -> Array:
	var out: Array = []
	for k in _order:
		var s: Dictionary = _surf[k]
		if int(s.n) == 0:
			continue
		var st: SurfaceTool = s.st
		st.generate_tangents()
		var mesh := st.commit()
		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		mi.material_override = s.mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if cast_shadows else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(mi)
		out.append(mi)
	_surf.clear()
	_order.clear()
	return out


# собрать в один ArrayMesh с несколькими поверхностями (для кэширования одинаковых объектов)
func commit_mesh() -> ArrayMesh:
	var am := ArrayMesh.new()
	for k in _order:
		var s: Dictionary = _surf[k]
		if int(s.n) == 0:
			continue
		var st: SurfaceTool = s.st
		st.generate_tangents()
		st.commit(am)
		am.surface_set_material(am.get_surface_count() - 1, s.mat)
	_surf.clear()
	_order.clear()
	return am
