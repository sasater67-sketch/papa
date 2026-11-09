extends RefCounted
# v0.5: машины по референсам (жёлтая «Свифт-Матиз», красный Suzuki Swift, синяя Lada Vesta SW Cross).
# Кузов — лофт по силуэтам видов сбоку/сверху/спереди/сзади (ref_cars.json, tools/ref/cars.py),
# окраска — проекция фото этих видов (car_proj.gdshader). Вперёд = +X, вправо = +Z.

const MK := preload("res://scripts/kit/mesh_kit.gd")
const SHADER := preload("res://assets/shaders/car_proj.gdshader")
const KINDS := ["matiz", "swift", "vesta"]
const NUM_TEX := {"k789": "plate_k789_hd", "a123": "plate_a123_hd", "m456": "plate_m456_hd"}

static var _d := {}
static var _mats := {}
static var _cache := {}
static var _plate_mats := {}


static func data(kind: String) -> Dictionary:
	if _d.is_empty():
		var j = JSON.parse_string(FileAccess.get_file_as_string("res://scripts/kit/ref_cars.json"))
		if j is Dictionary:
			_d = j
	return _d.get(kind, {})


static func car_len(kind: String) -> float:
	return float(data(kind).get("L", 4.0))


# материал кузова: lights — фары включены (ночь / движение)
static func body_mat(kind: String, lights: bool) -> ShaderMaterial:
	var key := kind + ("_on" if lights else "_off")
	if _mats.has(key):
		return _mats[key]
	var d := data(kind)
	var m := ShaderMaterial.new()
	m.shader = SHADER
	m.set_shader_parameter("atlas", Assets.hd_tex("car_%s_proj" % kind))
	var mp: Dictionary = d.get("maps", {})
	for v in ["sr", "sl", "top", "front", "rear"]:
		var a: Array = mp.get(v, [0, 0, 0, 0])
		m.set_shader_parameter("m_" + v, Vector4(float(a[0]), float(a[1]), float(a[2]), float(a[3])))
	m.set_shader_parameter("lights", 1.0 if lights else 0.0)
	m.set_shader_parameter("front_pow", 6.0)
	_mats[key] = m
	return m


static func all_mats() -> Array:
	return _mats.values()


static func _plate_mat(num: String) -> StandardMaterial3D:
	if _plate_mats.has(num):
		return _plate_mats[num]
	var m := StandardMaterial3D.new()
	m.albedo_texture = Assets.hd_tex(str(NUM_TEX.get(num, "plate_k789_hd")))
	m.roughness = 0.45
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	_plate_mats[num] = m
	return m


static func mesh(kind: String) -> ArrayMesh:
	if _cache.has(kind):
		return _cache[kind]
	var tmp := Node3D.new()
	var k = MK.new(tmp, "car_" + kind, false)
	_build(k, kind)
	var am: ArrayMesh = k.commit_mesh()
	tmp.free()
	_cache[kind] = am
	return am


# ------------------------------------------------------------------ профили

class Prof:
	var d: Dictionary
	var L := 4.0
	var roof := 1.5
	var pmax := 1.0
	var clear := 0.17
	var wheels: Array = []

	static func samp(arr: Array, f: float) -> float:
		var n := arr.size() - 1
		var x := clampf(f, 0.0, 1.0) * n
		var i := mini(int(floor(x)), n - 1)
		var t := x - i
		return lerpf(float(arr[i]), float(arr[i + 1]), t)

	func _init(dd: Dictionary) -> void:
		d = dd
		L = float(d.L)
		roof = float(d.roof)
		var pm := 0.0
		for v in d.plan:
			pm = maxf(pm, float(v))
		pmax = pm
		clear = 0.2 if L > 4.2 else 0.19
		for w in d.wheels:
			wheels.append(Vector2(float(w[0]), float(w[1])))

	func hw(t: float, y: float) -> float:
		var f := clampf(y / roof, 0.0, 1.0)
		var tf := samp(d.tmpl_front, f)
		var tr := samp(d.tmpl_rear, f)
		var b := smoothstep(0.3, 0.7, t)
		var s := samp(d.plan, t) / pmax
		return maxf(0.004, lerpf(tr, tf, b) * maxf(s, 0.03))

	func bot(t: float) -> float:
		var x := -L * 0.5 + t * L
		for w: Vector2 in wheels:
			var R := w.y * 1.07 + 0.015
			var dx := absf(x - w.x)
			if dx < R:
				return maxf(clear, w.y + sqrt(R * R - dx * dx))
		return maxf(samp(d.bot, t), clear)

	func top(t: float) -> float:
		return maxf(samp(d.top, t), bot(t) + 0.02)


# правая половина сечения: от низа по центру к верху по центру
static func _ring(p: Prof, t: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	var b := p.bot(t)
	var tp := p.top(t)
	var crown := clampf((tp - b) * 0.25, 0.0, 0.045)
	var ys := tp - crown
	var hwb := p.hw(t, b + 0.01) * 0.96
	out.append(Vector2(0, b))
	out.append(Vector2(hwb * 0.5, b))
	out.append(Vector2(hwb * 0.88, b))
	var NS := 18
	for i in NS + 1:
		var f := float(i) / NS
		f = f * f * (3.0 - 2.0 * f) * 0.5 + f * 0.5
		var y := lerpf(b, ys, f)
		out.append(Vector2(p.hw(t, y), y))
	var hts := p.hw(t, ys)
	for j in range(1, 7):
		var s := float(j) / 6.0
		var ss := 1.0 - s
		out.append(Vector2(hts * ss * (1.0 + 0.04 * s * ss), tp - crown * ss * ss))
	out[out.size() - 1] = Vector2(0, tp)
	return out


static func _full(r: PackedVector2Array) -> PackedVector2Array:
	# замкнутое кольцо: правая половина (низ→верх), затем левая (верх→низ)
	var o := PackedVector2Array(r)
	for i in range(r.size() - 2, 0, -1):
		o.append(Vector2(-r[i].x, r[i].y))
	return o


static func _build(k, kind: String) -> void:
	var d := data(kind)
	if d.is_empty():
		return
	var p := Prof.new(d)
	var L := p.L
	var bm := body_mat(kind, false)
	var NT := 72
	var rings: Array = []
	for i in NT + 1:
		var t := float(i) / NT
		rings.append(_full(_ring(p, t)))
	var M: int = (rings[0] as PackedVector2Array).size()
	var P: Array = []
	for i in NT + 1:
		var x := -L * 0.5 + float(i) / NT * L
		var row := PackedVector3Array()
		for j in M:
			var q: Vector2 = rings[i][j]
			row.append(Vector3(x, q.y, q.x))
		P.append(row)
	# нормали по сетке
	var Nn: Array = []
	for i in NT + 1:
		var row := PackedVector3Array()
		for j in M:
			var a: Vector3 = P[mini(i + 1, NT)][j] - P[maxi(i - 1, 0)][j]
			var b: Vector3 = P[i][(j + 1) % M] - P[i][(j - 1 + M) % M]
			var n := b.cross(a)
			var c := Vector3(P[i][j].x, (p.bot(float(i) / NT) + p.top(float(i) / NT)) * 0.5, 0.0)
			if n.dot(P[i][j] - c) < 0.0:
				n = -n
			if n.length_squared() < 1e-12:
				n = (P[i][j] - c)
			row.append(n.normalized())
		Nn.append(row)
	for i in NT:
		for j in M:
			var j2 := (j + 1) % M
			var a: Vector3 = P[i][j]
			var b: Vector3 = P[i + 1][j]
			var c: Vector3 = P[i + 1][j2]
			var e: Vector3 = P[i][j2]
			var na: Vector3 = Nn[i][j]
			var nb: Vector3 = Nn[i + 1][j]
			var nc: Vector3 = Nn[i + 1][j2]
			var ne: Vector3 = Nn[i][j2]
			if (b - a).length_squared() + (e - a).length_squared() < 1e-10:
				continue
			k.tri(bm, a, b, c, na, nb, nc, Vector2(a.x, a.y), Vector2(b.x, b.y), Vector2(c.x, c.y))
			k.tri(bm, a, c, e, na, nc, ne, Vector2(a.x, a.y), Vector2(c.x, c.y), Vector2(e.x, e.y))
	# торцы
	for end in [0, NT]:
		var row: PackedVector3Array = P[end]
		var cc := Vector3.ZERO
		for v in row:
			cc += v
		cc /= row.size()
		var nx := Vector3(1, 0, 0) if end == NT else Vector3(-1, 0, 0)
		for j in M:
			var a: Vector3 = row[j]
			var b: Vector3 = row[(j + 1) % M]
			k.tri(bm, cc, a, b, nx, nx, nx, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO)
	_wheels(k, p, bm)
	_mirrors(k, p, d, bm)
	_plates(k, p, d)
	_antenna(k, p)


static func _t_of(p: Prof, x: float) -> float:
	return clampf((x + p.L * 0.5) / p.L, 0.0, 1.0)


static func _wheels(k, p: Prof, bm: Material) -> void:
	for w: Vector2 in p.wheels:
		var r := w.y
		var t := _t_of(p, w.x)
		var zo := p.hw(t, r) - 0.035
		var zi := zo - 0.2
		var prof := PackedVector2Array([Vector2(0.0, zi + 0.04), Vector2(r * 0.6, zi), Vector2(r * 0.9, zi), Vector2(r, zi + 0.035),
			Vector2(r, zo - 0.035), Vector2(r * 0.93, zo), Vector2(r * 0.66, zo + 0.004), Vector2(r * 0.6, zo - 0.012), Vector2(r * 0.3, zo - 0.02), Vector2(0.0, zo - 0.01)])
		for s: float in [-1.0, 1.0]:
			var bas := Basis(Vector3.RIGHT, PI / 2.0) if s > 0.0 else Basis(Vector3.RIGHT, -PI / 2.0)
			k.lathe(bm, Transform3D(bas, Vector3(w.x, r, 0.0)), prof, 28)


static func _mirrors(k, p: Prof, d: Dictionary, bm: Material) -> void:
	if not d.has("mirror_t") or not d.has("mirror_y"):
		return
	var t0 := float(d.mirror_t[0])
	var t1 := float(d.mirror_t[1])
	var y0 := float(d.mirror_y[0])
	var y1 := float(d.mirror_y[1])
	var tm := (t0 + t1) * 0.5
	var ym := (y0 + y1) * 0.5
	var x0 := -p.L * 0.5 + t0 * p.L
	var x1 := -p.L * 0.5 + t1 * p.L
	var zin := p.hw(tm, ym) - 0.05
	var zout := minf(float(d.get("mirror_w", zin + 0.2)), zin + 0.24)
	var hx := maxf(x1 - x0, 0.1) * 0.5
	var hy := clampf((y1 - y0) * 0.5, 0.05, 0.075)
	var hz := (zout - zin) * 0.5
	for s: float in [-1.0, 1.0]:
		var c := Vector3((x0 + x1) * 0.5, ym, s * (zin + zout) * 0.5)
		k.sphere(bm, Transform3D(Basis.from_scale(Vector3(hx, hy, hz)), c), 1.0, 14, 9)
		k.box(bm, MK.T(Vector3(c.x + hx * 0.4, ym - hy * 0.5, s * (zin + 0.02))), Vector3(0.08, 0.04, 0.08), 0.015)


static func _front_x(p: Prof, y: float, front: bool) -> float:
	# крайняя точка кузова по центру на высоте y
	var steps := 200
	for i in steps + 1:
		var t := 1.0 - float(i) / steps if front else float(i) / steps
		if p.bot(t) <= y and p.top(t) >= y:
			return -p.L * 0.5 + t * p.L
	return p.L * 0.5 if front else -p.L * 0.5


static func _plates(k, p: Prof, d: Dictionary) -> void:
	var pm := _plate_mat(str(d.get("num", "k789")))
	for key in ["plate_front", "plate_rear"]:
		if not d.has(key):
			continue
		var r: Array = d[key]
		var z0 := float(r[0])
		var z1 := float(r[1])
		var y0 := float(r[2])
		var y1 := float(r[3])
		var front: bool = key == "plate_front"
		var yc := (y0 + y1) * 0.5
		var xc := _front_x(p, yc, front)
		# где кузов перекрывает всю ширину номера (края номера) — оттуда до центра закрываем рамкой
		var t := _t_of(p, xc)
		var stepv := -0.004 if front else 0.004
		var guard := 0
		while p.hw(t, yc) < maxf(absf(z0), absf(z1)) * 0.95 and guard < 150:
			t += stepv
			guard += 1
		var xe := -p.L * 0.5 + t * p.L
		var sg := 1.0 if front else -1.0
		var depth := absf(xc - xe) + 0.02
		var zc := (z0 + z1) * 0.5
		var xf := Transform3D(Basis(Vector3.UP, PI / 2.0 if front else -PI / 2.0), Vector3(xc + sg * 0.016, yc, zc))
		k.panel(pm, xf, z1 - z0, y1 - y0)
		k.box(Assets.pbr(Color(0.04, 0.04, 0.045), 0.5), Transform3D(Basis(), Vector3(xc + sg * (0.01 - depth * 0.5), yc, zc)), Vector3(depth, y1 - y0 + 0.02, z1 - z0 + 0.02), 0.004)


static func _antenna(k, p: Prof) -> void:
	var t := 0.23
	var x := -p.L * 0.5 + t * p.L
	var y := p.top(t)
	k.tube(Assets.pbr(Color(0.03, 0.03, 0.03), 0.4), Vector3(x, y - 0.01, 0), Vector3(x - 0.1, y + 0.24, 0), 0.006, 6)
	k.cyl(Assets.pbr(Color(0.03, 0.03, 0.03), 0.4), MK.T(Vector3(x, y, 0)), 0.018, 0.03, 8)
