extends Node
## Материалы и текстуры для 3D-китов из Jackpot Hotel (автоматы, столы, люди, машины).
## HD-текстуры лежат в assets/hd (таблица hd.json), старые пиксельные — в assets/tex.

var font_title: Font
var font_body: Font
var _tex := {}
var _mats := {}
var _fallback: ImageTexture
var hd := {}
var _hd_tex := {}
var hd_enabled := true


func _ready() -> void:
	font_title = load("res://fonts/RussoOne-Regular.ttf")
	font_body = load("res://fonts/Rubik.ttf")
	var path := "res://assets/hd/hd.json"
	if FileAccess.file_exists(path):
		var j = JSON.parse_string(FileAccess.get_file_as_string(path))
		if j is Dictionary:
			hd = j


func has_hd(tname: String) -> bool:
	return hd_enabled and hd.has(tname)


func hd_tex(file: String) -> Texture2D:
	if _hd_tex.has(file):
		return _hd_tex[file]
	var p := "res://assets/hd/%s.png" % file
	var t: Texture2D = load(p) if ResourceLoader.exists(p) else null
	_hd_tex[file] = t
	return t


# новые (только HD) текстуры → запасные старые, если HD-текстуры нет
const FALLBACK := {"asphalt": "concrete_dark", "paving": "stone", "sidewalk": "concrete", "curb": "concrete", "facade": "wall_tech",
	"facade_brick": "brick", "roof_tar": "metal_plates", "plaster": "wall_stripes_cream", "tiles_dark": "floor_checker",
	"wood_crate": "wood_light", "metal_brushed": "chrome", "paint": "white", "terrazzo": "marble_white", "carpet_casino": "carpet_red",
	"carpet_blue2": "carpet_blue", "leather_hd": "leather", "felt_hd": "felt_green", "brass_hd": "brass", "gold_hd": "gold",
	"steel": "metal_dark", "glass_hd": "glass", "grass": "leaves", "rubber_hd": "rubber", "plastic_hd": "plastic_black"}


func tex(tname: String) -> Texture2D:
	if _tex.has(tname):
		return _tex[tname]
	var path := "res://assets/tex/%s.png" % tname
	var t: Texture2D
	if ResourceLoader.exists(path):
		t = load(path)
	elif FALLBACK.has(tname):
		t = tex(str(FALLBACK[tname]))
	else:
		t = _fallback_tex()
	_tex[tname] = t
	return t


# размер «старой» текстуры в пикселях (32 px = 1 м); для чисто-HD текстур — 32×32 (1 UV = 1 м)
func tex_size(tname: String) -> Vector2:
	if tname == "":
		return Vector2(64, 64)
	if has_hd(tname) and not ResourceLoader.exists("res://assets/tex/%s.png" % tname):
		return Vector2(32, 32)
	var t := tex(tname)
	return Vector2(t.get_width(), t.get_height())


# материал для MeshKit (UV в метрах)
func kit_mat(tname: String, opts: Dictionary = {}) -> StandardMaterial3D:
	var o := opts.duplicate()
	var uvm: Vector2 = o.get("uv", Vector2.ONE)
	o.erase("uv")
	o["kit"] = 1
	if tname != "" and has_hd(tname) and not o.get("unshaded", false) and not o.get("pixel", false):
		var meters: Array = hd[tname].get("m", [1.0, 1.0])
		o["hd_uv"] = Vector2(uvm.x / float(meters[0]), uvm.y / float(meters[1]))
	elif tname != "":
		var sz := tex_size(tname)
		o["uv"] = Vector2(32.0 / sz.x * uvm.x, 32.0 / sz.y * uvm.y)
		if not o.has("smooth"):
			o["smooth"] = true
	return mat(tname, o)


func has_tex(tname: String) -> bool:
	return _tex.has(tname) or ResourceLoader.exists("res://assets/tex/%s.png" % tname)


func _fallback_tex() -> Texture2D:
	if _fallback == null:
		var img := Image.create(8, 8, false, Image.FORMAT_RGBA8)
		img.fill(Color(0.5, 0.5, 0.5))
		_fallback = ImageTexture.create_from_image(img)
	return _fallback


func mat(tname: String, opts: Dictionary = {}) -> StandardMaterial3D:
	var key := tname + JSON.stringify(opts)
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	var is_hd: bool = tname != "" and has_hd(tname) and not opts.get("unshaded", false) and not opts.get("pixel", false)
	if is_hd:
		var h: Dictionary = hd[tname]
		var file := str(h.get("f", tname))
		m.albedo_texture = hd_tex(file)
		m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		if bool(h.get("n", true)):
			var nt := hd_tex(file + "_n")
			if nt:
				m.normal_enabled = true
				m.normal_texture = nt
				m.normal_scale = float(h.get("ns", 1.0))
		m.roughness_texture = m.albedo_texture
		m.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_ALPHA
		m.roughness = float(opts.get("rough_mul", 1.0))
		m.metallic = float(h.get("metal", opts.get("metal", 0.0)))
		m.metallic_specular = float(h.get("spec", 0.5))
		var old_sz := tex_size(tname)
		var meters: Array = h.get("m", [1.0, 1.0])
		var k := Vector2(old_sz.x / (32.0 * float(meters[0])), old_sz.y / (32.0 * float(meters[1])))
		if opts.has("uv"):
			k *= Vector2(opts.uv.x, opts.uv.y)
		if opts.has("hd_uv"):
			k = Vector2(opts.hd_uv.x, opts.hd_uv.y)
		m.uv1_scale = Vector3(k.x, k.y, 1)
		if h.has("clear"):
			m.clearcoat_enabled = true
			m.clearcoat = float(h.clear)
			m.clearcoat_roughness = 0.15
	elif tname != "":
		m.albedo_texture = tex(tname)
		m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC if opts.get("smooth", false) else BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
		m.roughness = opts.get("rough", 0.8)
		m.metallic = opts.get("metal", 0.0)
		m.metallic_specular = opts.get("spec", 0.4)
		if opts.has("uv"):
			m.uv1_scale = Vector3(opts.uv.x, opts.uv.y, 1)
	else:
		m.roughness = opts.get("rough", 0.6)
		m.metallic = opts.get("metal", 0.0)
		m.metallic_specular = opts.get("spec", 0.5)
	m.albedo_color = opts.get("tint", Color.WHITE)
	m.vertex_color_use_as_albedo = true
	if opts.has("emit"):
		m.emission_enabled = true
		if tname != "":
			m.emission_texture = m.albedo_texture
		m.emission = opts.get("emit_color", Color.WHITE)
		m.emission_energy_multiplier = float(opts.emit)
	if opts.get("alpha", false):
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		m.alpha_scissor_threshold = 0.5
	if opts.get("blend", false):
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if opts.get("unshaded", false):
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if opts.get("double", false):
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
	if opts.has("clearcoat"):
		m.clearcoat_enabled = true
		m.clearcoat = float(opts.clearcoat)
		m.clearcoat_roughness = 0.1
	if opts.has("rim"):
		m.rim_enabled = true
		m.rim = float(opts.rim)
	_mats[key] = m
	return m


# PBR-материал без текстуры (металл, пластик, стекло)
func pbr(c: Color, rough: float, metal: float = 0.0, opts: Dictionary = {}) -> StandardMaterial3D:
	var o := opts.duplicate()
	o["tint"] = c
	o["rough"] = rough
	o["metal"] = metal
	return mat("", o)


func cmat(c: Color, opts: Dictionary = {}) -> StandardMaterial3D:
	var o := opts.duplicate()
	o["tint"] = c
	return mat("", o)
