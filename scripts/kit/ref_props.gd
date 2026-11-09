extends RefCounted
# v0.5: объекты по референсам — картонная коробка, паллет, мусорный контейнер, скамейка,
# золотой автомат-статуя, снек-автомат SNACK-O-MAT 2000, фонарь, кирпичный дом (bld — параллелепипед). Геометрия — визуальная оболочка
# видов (tools/props/props.py → assets/props/*.bin), окраска — проекция фото видов (prop_proj.gdshader).
# Перед объекта = +Z, право = +X, начало — центр низа.

const SHADER := preload("res://assets/shaders/prop_proj.gdshader")
const CARD := preload("res://assets/shaders/prop_card.gdshader")
const SLOT := {"px": "right", "nx": "left", "py": "top", "ny": "bottom", "pz": "front", "nz": "back"}
const LOOK := {
	"box": {"rough": 0.9, "spec": 0.25, "soak": 0.35},
	"pallet": {"rough": 0.9, "spec": 0.2, "soak": 0.35},
	"container": {"rough": 0.55, "spec": 0.4, "soak": 0.1},
	"bench": {"rough": 0.7, "spec": 0.3, "soak": 0.3},
	"statue": {"rough": 0.45, "spec": 0.45, "soak": 0.0, "bright": 0.98},
	"vending": {"rough": 0.35, "spec": 0.5, "soak": 0.0},
	"lamp": {"rough": 0.45, "spec": 0.45, "soak": 0.05},
	"bld": {"rough": 0.85, "spec": 0.2, "soak": 0.3, "top_k": 1.0, "glow_col": Color(1.0, 0.82, 0.55)},
}

static var _d := {}
static var _meshes := {}
static var _mats := {}


static func data(id: String) -> Dictionary:
	if _d.is_empty():
		var j = JSON.parse_string(FileAccess.get_file_as_string("res://scripts/kit/ref_props.json"))
		if j is Dictionary:
			_d = j
	return _d.get(id, {})


static func has(id: String) -> bool:
	return not data(id).is_empty()


# габарит (ширина X, высота Y, глубина Z) в метрах
static func size(id: String) -> Vector3:
	var d := data(id)
	return Vector3(float(d.get("W", 1.0)), float(d.get("H", 1.0)), float(d.get("D", 1.0)))


static func _load_bin(path: String) -> Array:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return []
	var b := f.get_buffer(f.get_length())
	var nv := b.decode_u32(0)
	var ni := b.decode_u32(4)
	var fl := b.slice(8, 8 + nv * 24).to_float32_array()
	var idx := b.slice(8 + nv * 24, 8 + nv * 24 + ni * 4).to_int32_array()
	var vs := PackedVector3Array()
	var ns := PackedVector3Array()
	vs.resize(nv)
	ns.resize(nv)
	for i in nv:
		var k := i * 6
		vs[i] = Vector3(fl[k], fl[k + 1], fl[k + 2])
		ns[i] = Vector3(fl[k + 3], fl[k + 4], fl[k + 5])
	# в файле обход против часовой снаружи; Godot ждёт по часовой
	for t in range(0, idx.size(), 3):
		var q := idx[t + 1]
		idx[t + 1] = idx[t + 2]
		idx[t + 2] = q
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = vs
	arr[Mesh.ARRAY_NORMAL] = ns
	arr[Mesh.ARRAY_INDEX] = idx
	return arr


static func mesh(id: String) -> ArrayMesh:
	if _meshes.has(id):
		return _meshes[id]
	var m := ArrayMesh.new()
	var arr := _load_bin("res://assets/props/%s.bin" % id)
	if not arr.is_empty():
		m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
		m.surface_set_material(0, mat(id))
	var card: Dictionary = data(id).get("card", {})
	if not card.is_empty():
		var c := _card_arrays(card)
		m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, c)
		m.surface_set_material(m.get_surface_count() - 1, card_mat(id))
	_meshes[id] = m
	return m


static func _card_arrays(c: Dictionary) -> Array:
	# плоская вырезка (кронштейн фонаря): прямоугольник в плоскости XY при z = 0
	var r: Array = c.get("rect", [0, 0, 1, 1])
	var x0 := float(r[0])
	var y0 := float(r[1])
	var x1 := float(r[2])
	var y1 := float(r[3])
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = PackedVector3Array([Vector3(x0, y1, 0), Vector3(x1, y1, 0), Vector3(x1, y0, 0), Vector3(x0, y0, 0)])
	arr[Mesh.ARRAY_NORMAL] = PackedVector3Array([Vector3.BACK, Vector3.BACK, Vector3.BACK, Vector3.BACK])
	arr[Mesh.ARRAY_TEX_UV] = PackedVector2Array([Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)])
	arr[Mesh.ARRAY_INDEX] = PackedInt32Array([0, 1, 2, 0, 2, 3])
	return arr


static func _v4(a) -> Vector4:
	if a is Array and a.size() >= 4:
		return Vector4(float(a[0]), float(a[1]), float(a[2]), float(a[3]))
	return Vector4.ZERO


static func mat(id: String) -> ShaderMaterial:
	if _mats.has(id):
		return _mats[id]
	var d := data(id)
	var m := ShaderMaterial.new()
	m.shader = SHADER
	m.set_shader_parameter("atlas", Assets.hd_tex("prop_" + id))
	var maps: Dictionary = d.get("maps", {})
	for s in SLOT:
		var v: String = SLOT[s]
		if not maps.has(v):
			v = {"back": "front", "top": "front", "right": "left", "left": "right", "bottom": "front"}.get(v, "front")
		if not maps.has(v):
			v = "front"
		var mm: Array = maps.get(v, [[0, 0, 0, 0], [0, 0, 0, 0]])
		m.set_shader_parameter(s + "u", _v4(mm[0]))
		m.set_shader_parameter(s + "v", _v4(mm[1]))
	m.set_shader_parameter("has_ny", 1.0 if maps.has("bottom") else 0.0)
	var lk: Dictionary = LOOK.get(id, {})
	for k in lk:
		m.set_shader_parameter(k, lk[k])
	_mats[id] = m
	return m


static func card_mat(id: String) -> ShaderMaterial:
	var key := id + "_card"
	if _mats.has(key):
		return _mats[key]
	var m := ShaderMaterial.new()
	m.shader = CARD
	m.set_shader_parameter("tex", Assets.hd_tex("prop_%s_card" % id))
	var lk: Dictionary = LOOK.get(id, {})
	for k in ["rough", "spec"]:
		if lk.has(k):
			m.set_shader_parameter(k, lk[k])
	_mats[key] = m
	return m


static func all_mats() -> Array:
	return _mats.values()


# поставить объект: xf — положение (низ-центр), sc — масштаб (число или Vector3)
static func put(parent: Node3D, id: String, xf: Transform3D, sc = 1.0, shadows := true) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh(id)
	var s3: Vector3 = sc if sc is Vector3 else Vector3.ONE * float(sc)
	mi.transform = xf * Transform3D(Basis.from_scale(s3), Vector3.ZERO)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadows else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi


# масштаб, чтобы объект имел заданную высоту
static func fit_h(id: String, h: float) -> float:
	return h / maxf(0.01, size(id).y)
