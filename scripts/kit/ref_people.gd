extends RefCounted
# Фото-люди по референсам: тело с UV-проекцией трёх видов (спереди/сзади/сбоку) из атласа,
# волосы и головные уборы — аффинная проекция видов головы. Данные: ref_people.json + assets/people/*
const DATA_PATH := "res://scripts/kit/ref_people.json"
const SH_BODY: Shader = preload("res://assets/shaders/human_proj.gdshader")
const SH_HEAD: Shader = preload("res://assets/shaders/human_proj_head.gdshader")
static var _data: Dictionary = {}
static var _meshes: Dictionary = {}
static var _mats: Dictionary = {}


static func data() -> Dictionary:
	if _data.is_empty():
		var f := FileAccess.open(DATA_PATH, FileAccess.READ)
		if f:
			var d = JSON.parse_string(f.get_as_text())
			if d is Dictionary:
				_data = d
	return _data


static func has(id: String) -> bool:
	return data().has(id)


static func info(id: String) -> Dictionary:
	return data().get(id, {})


static func ids() -> Array:
	return data().keys()


static func tex(id: String) -> Texture2D:
	return load("res://assets/hd/ppl_%s.png" % id) as Texture2D


static func body_mesh(id: String, base: Mesh) -> Mesh:
	if _meshes.has(id):
		return _meshes[id]
	var f := FileAccess.open("res://assets/people/%s_uv.bin" % id, FileAccess.READ)
	if f == null:
		return base
	var fl := f.get_buffer(f.get_length()).to_float32_array()
	var arr: Array = base.surface_get_arrays(0)
	var n: int = (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
	if fl.size() < n * 6:
		return base
	var uv := PackedVector2Array()
	uv.resize(n)
	var uv2 := PackedVector2Array()
	uv2.resize(n)
	var c0 := PackedFloat32Array()
	c0.resize(n * 4)
	for i in n:
		var k := i * 6
		uv[i] = Vector2(fl[k], fl[k + 1])
		uv2[i] = Vector2(fl[k + 2], fl[k + 3])
		c0[i * 4] = fl[k + 4]
		c0[i * 4 + 1] = fl[k + 5]
	arr[Mesh.ARRAY_TEX_UV] = uv
	arr[Mesh.ARRAY_TEX_UV2] = uv2
	arr[Mesh.ARRAY_CUSTOM0] = c0
	var m := ArrayMesh.new()
	var am := base as ArrayMesh
	var bs: Array = []
	if am:
		m.blend_shape_mode = am.blend_shape_mode
		for i in am.get_blend_shape_count():
			m.add_blend_shape(am.get_blend_shape_name(i))
		bs = am.surface_get_blend_shape_arrays(0)
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr, bs, {}, Mesh.ARRAY_CUSTOM_RGBA_FLOAT << Mesh.ARRAY_FORMAT_CUSTOM0_SHIFT)
	_meshes[id] = m
	return m


static func _v4(a) -> Vector4:
	if a is Array and a.size() >= 4:
		return Vector4(float(a[0]), float(a[1]), float(a[2]), float(a[3]))
	return Vector4.ZERO


static func body_mat(id: String) -> ShaderMaterial:
	var key := id + "|b"
	if not _mats.has(key):
		var m := ShaderMaterial.new()
		m.shader = SH_BODY
		m.set_shader_parameter("atlas", tex(id))
		_mats[key] = m
	return _mats[key]


# use_vertex: головной убор в координатах позы покоя (не скиннинг), иначе волосы (rp в UV)
static func head_mat(id: String, use_vertex: bool) -> ShaderMaterial:
	var key := id + ("|hv" if use_vertex else "|h")
	if not _mats.has(key):
		var d := info(id)
		var h: Dictionary = d.get("head", {})
		var m := ShaderMaterial.new()
		m.shader = SH_HEAD
		m.set_shader_parameter("atlas", tex(id))
		m.set_shader_parameter("hf", _v4(h.get("F")))
		m.set_shader_parameter("hb", _v4(h.get("B")))
		m.set_shader_parameter("hs", _v4(h.get("S")))
		m.set_shader_parameter("side_w", 0.0 if int(d.get("side_dir", 1)) == 0 else 1.0)
		m.set_shader_parameter("use_vertex", use_vertex)
		_mats[key] = m
	return _mats[key]


static func all_mats() -> Array:
	return _mats.values()


# случайный архетип прохожего (без «служебных»: продавцы, полиция, МЧС)
const STAFF := ["jeweler", "borya", "shawa", "police", "mchs_officer", "mchs", "ded"]


static func random_id(rng: RandomNumberGenerator, allow_staff := false) -> String:
	var pool: Array = []
	for k in ids():
		if allow_staff or not STAFF.has(k):
			pool.append(k)
	if pool.is_empty():
		return ""
	pool.sort()
	return str(pool[rng.randi() % pool.size()])
