extends Node3D






const HumanRig := preload("res://scripts/kit/human_rig.gd")
const BODY_MESH: Mesh = preload("res://assets/models/human/body.res")
const SKIRT_MESH: Mesh = preload("res://assets/models/human/skirt.res")
const SHADER: Shader = preload("res://assets/shaders/human.gdshader")
const SHADER_2S: Shader = preload("res://assets/shaders/human_2s.gdshader")
const RP := preload("res://scripts/kit/ref_people.gd")
const HAIR_MESH := {
	"short": preload("res://assets/models/human/hair_short.res"),
	"long": preload("res://assets/models/human/hair_long.res"),
	"mohawk": preload("res://assets/models/human/hair_mohawk.res"),
	"bun": preload("res://assets/models/human/hair_bun.res"),
	"spiky": preload("res://assets/models/human/hair_spiky.res"),
	"bob": preload("res://assets/models/human/hair_bob.res"),
	"ponytail": preload("res://assets/models/human/hair_ponytail.res"),
}

const SKINS := [Color("f2c8a0"), Color("e0a878"), Color("c68a5a"), Color("8d5a3a"), Color("5a3a26"), Color("f4cfb8")]
const HAIR_COLORS := [Color("2a1a10"), Color("5a3418"), Color("a8682a"), Color("e8c86a"), Color("1a1a1a"), Color("b8b8c0"), Color("c83a2a")]
const FACES := ["smile", "grin", "neutral", "shades", "mustache", "lady", "glasses", "beard", "wink", "happy"]
const HAIRS := ["short", "long", "bald", "mohawk", "bun", "spiky", "bob", "ponytail"]
const HATS := ["none", "cap", "cowboy", "tophat", "beanie", "fedora", "crown", "chef", "headphones",
	"propeller", "party", "viking", "sombrero", "wizard", "pirate", "halo", "bucket", "duck", "devil",
	"ushanka", "tiara", "hardhat", "jester", "magnate", "unicorn", "empire"]
const HAT_NAMES := ["Без шляпы", "Кепка", "Ковбойская", "Цилиндр", "Шапка", "Федора", "Корона", "Колпак", "Наушники",
	"Кепка с пропеллером", "Праздничный колпак", "Шлем викинга", "Сомбреро", "Колпак волшебника", "Треуголка", "Нимб",
	"Ведро", "Уточка", "Рожки", "Ушанка", "Тиара", "Каска", "Шутовской колпак", "Цилиндр магната", "Рог единорога",
	"Корона Империи"]
# головные уборы, которые не прячут причёску
const HAT_OPEN := ["headphones", "halo", "devil", "tiara"]
const HAIR_NAMES := ["Короткие", "Длинные", "Лысый", "Ирокез", "Пучок", "Ёжик", "Каре", "Хвост"]
const FACE_NAMES := ["Улыбка", "Оскал", "Спокойный", "Очки-капли", "Усы", "Макияж", "Очки", "Борода", "Подмигивает", "Счастливый"]
const SHOES := [Color("2a1a12"), Color("141414"), Color("ecebe6"), Color("3a5a9a"), Color("a82a2a")]
const FORMAL := ["vest", "tux", "suit", "maid", "chef", "apron"]
const BODY_NAMES := ["Женская", "Мужская"]
const BUILDS := [1.0, 0.82, 0.55, 0.0]
const BUILD_NAMES := ["Стройное", "Обычное", "Плотное", "Пышное"]

const TOPS := [["tee", "Футболка", 1], ["long", "Лонгслив", 2], ["polo", "Поло", 14], ["sweater", "Свитер", 15],
	["stripes", "Тельняшка", 18], ["plaid", "Клетчатая рубашка", 17], ["tank", "Майка", 3], ["blouse", "Блузка", 16], ["dress", "Платье", 13]]
const BOTTOMS := [["pants", "Брюки", 0], ["jeans", "Джинсы", 1], ["shorts", "Шорты", 2], ["skirt", "Юбка", 3]]
const EYE_COLORS := [Color("4a2e1c"), Color("2e1c12"), Color("6a5a2a"), Color("3a6a3a"), Color("3a6a9a"), Color("6a7a88")]
const OUTFIT_CODE := {"": 1, "hoodie": 4, "hawaii": 5, "logo": 6, "vest": 7, "tux": 8, "suit": 9, "maid": 10, "chef": 11, "apron": 12}

const EXPR := {
	"smile": {"mouth_curve": 0.5},
	"grin": {"mouth_curve": 0.8, "mouth_open": 0.32, "teeth": 1.0},
	"neutral": {"mouth_curve": 0.06},
	"happy": {"mouth_curve": 0.95, "mouth_open": 0.42, "teeth": 1.0, "happy_eyes": 1.0, "blush": 0.5},
	"content": {"mouth_curve": 0.55, "happy_eyes": 1.0},
	"wink": {"mouth_curve": 0.65, "eye_r": 0.0, "brow_up": 0.3},
	"sad": {"mouth_curve": -0.6, "brow_sad": 1.0, "eye_l": 0.72, "eye_r": 0.72, "gaze_y": -0.6},
	"cry": {"mouth_curve": -0.75, "mouth_open": 0.35, "brow_sad": 1.0, "eye_l": 0.5, "eye_r": 0.5, "tears": 1.0, "blush": 0.6},
	"shock": {"mouth_curve": -0.15, "mouth_open": 1.0, "eye_l": 1.3, "eye_r": 1.3, "brow_up": 1.0},
	"angry": {"mouth_curve": -0.5, "mouth_open": 0.14, "teeth": 1.0, "brow_angry": 1.0, "eye_l": 0.78, "eye_r": 0.78},
	"sleep": {"mouth_curve": 0.05, "mouth_open": 0.12, "eye_l": 0.0, "eye_r": 0.0},
}
const EXPR_KEYS := ["eye_l", "eye_r", "happy_eyes", "mouth_curve", "mouth_open", "teeth", "brow_up", "brow_angry", "brow_sad", "tears", "blush"]
const EXPR_DEF := {"eye_l": 1.0, "eye_r": 1.0}


const B_HIPS := 0
const B_SPINE := 1
const B_CHEST := 2
const B_NECK := 3
const B_HEAD := 4
const B_CLAV := [9, 5]
const B_ARM := [10, 6]
const B_FORE := [11, 7]
const B_HAND := [12, 8]
const B_THIGH := [16, 13]
const B_SHIN := [17, 14]
const B_FOOT := [18, 15]
const HIP_Y := 0.82
const KNEE_Y := 0.455

var look := {}
var anim := "idle"
var speed := 0.0
var head_pitch := 0.0
var drink_lift := -1.0
var female := true
var _phase := 0.0
var _t := 0.0
var _parts := {}
var _base_face := "smile"
var _face_override := ""
var _face_timer := 0.0
var _blink := 0.0
var _blinking := 0.0
var _gaze := Vector2.ZERO
var _gaze_t := 0.0
var tag: Label3D
var _hat_node: Node3D
var _prop: Node3D = null
var _skel: Skeleton3D
var _mats: Array = []
var _expr_cur := {}
var _expr_tgt := {}
var _abd := 0.2
var _sit_y := -0.34

var _p_leg := [Vector3.ZERO, Vector3.ZERO]
var _p_knee := [0.04, 0.04]
var _p_sh := [Vector3(0, 0, 0.07), Vector3(0, 0, 0.07)]
var _p_el := [Vector3(-0.14, 0, 0), Vector3(-0.14, 0, 0)]
var _p_rig_y := 0.0
var _p_rig_rot := Vector3.ZERO
var _p_torso := Vector3.ZERO
var _p_neck := Vector3.ZERO
var _last_anim := ""
var _at := 0.0

static var _skin_res: Skin
# v0.4 «Большие головы»: масштаб головы всех персонажей (ставит мир ТЦ)
static var big_head := 1.0
static var _acc_cache := {}
static var _acc_mat: StandardMaterial3D
static var _lens_mat: StandardMaterial3D
static var _shade_mat: StandardMaterial3D
static var _rdown := [Quaternion(Vector3(0, 0, 1), PI / 2.0), Quaternion(Vector3(0, 0, 1), -PI / 2.0)]


func _ready() -> void:
	_t = randf() * 10.0
	_blink = randf_range(2.0, 5.0)


# прохожие и гости — фото-люди по референсам (лёгкий разброс роста), иначе случайный облик
static func npc_look(rng: RandomNumberGenerator) -> Dictionary:
	var id := RP.random_id(rng)
	if id != "":
		return {"ref": id, "scale": rng.randf_range(0.96, 1.04)}
	return random_look(rng)


static func random_look(rng: RandomNumberGenerator) -> Dictionary:
	var fem := rng.randf() < 0.5
	var hair: int
	if fem:
		hair = [1, 1, 4, 6, 7, 0, 6, 1][rng.randi() % 8]
	else:
		hair = [0, 0, 0, 2, 3, 5, 5, 1][rng.randi() % 8]
	var face: int
	if fem:
		face = [0, 1, 2, 3, 5, 5, 6, 8, 9][rng.randi() % 9]
	else:
		face = [0, 1, 2, 3, 4, 6, 7, 7, 8, 9][rng.randi() % 10]
	var top: int = rng.randi_range(0, 5) if not fem else [0, 1, 3, 4, 6, 7, 7, 8, 0][rng.randi() % 9]
	var bottom: int = [0, 1, 1, 0, 2][rng.randi() % 5] if not fem else [0, 1, 3, 3, 2, 1][rng.randi() % 6]
	return {
		"skin": rng.randi() % SKINS.size(),
		"hair": hair,
		"hair_color": rng.randi() % HAIR_COLORS.size(),
		"hat": 0 if rng.randf() < 0.6 else rng.randi_range(1, 5),
		"face": face,
		"shirt": Color.from_hsv(rng.randf(), rng.randf_range(0.3, 0.7), rng.randf_range(0.35, 0.8)),
		"pants": Color.from_hsv(rng.randf(), rng.randf_range(0.1, 0.4), rng.randf_range(0.15, 0.4)),
		"outfit": ["", "hoodie", "hawaii", "logo", ""][rng.randi() % 5],
		"body": 0 if fem else 1,
		"build": [0, 0, 0, 1, 1, 1, 1, 2, 2, 3][rng.randi() % 10],
		"top": top,
		"bottom": bottom,
	}




static func _hash(l: Dictionary, salt: int) -> int:
	var s := "%s|%s|%s|%s|%s|%s|%s|%d" % [str(l.get("skin", 0)), str(l.get("hair", 0)), str(l.get("hair_color", 0)),
		str(l.get("face", 0)), str(l.get("shirt", "")), str(l.get("pants", "")), str(l.get("outfit", "")), salt]
	return absi(s.hash())


static func face_name(l: Dictionary) -> String:
	return FACES[int(l.get("face", 0)) % FACES.size()] if not (l.get("face") is String) else str(l.face)


static func hair_name(l: Dictionary) -> String:
	return HAIRS[int(l.get("hair", 0)) % HAIRS.size()] if not (l.get("hair") is String) else str(l.hair)


static func hat_name(l: Dictionary) -> String:
	return HATS[int(l.get("hat", 0)) % HATS.size()] if not (l.get("hat") is String) else str(l.hat)



static func is_female(l: Dictionary) -> bool:
	if l.has("body"):
		return int(l.body) == 0
	var f := face_name(l)
	var h := hair_name(l)
	if f == "lady":
		return true
	if f in ["mustache", "beard"]:
		return false
	if h in ["long", "bun", "bob", "ponytail"]:
		return true
	if h in ["bald", "mohawk", "spiky"]:
		return false
	return _hash(l, 1) % 100 < 40


static func build_index(l: Dictionary) -> int:
	if l.has("build"):
		return clampi(int(l.build), 0, BUILDS.size() - 1)
	return [0, 0, 0, 1, 1, 1, 1, 2, 2, 3][_hash(l, 2) % 10]


static func top_index(l: Dictionary) -> int:
	if l.has("top"):
		return clampi(int(l.top), 0, TOPS.size() - 1)
	if is_female(l):
		return [0, 1, 3, 4, 6, 7, 7, 8, 0][_hash(l, 3) % 9]
	return [0, 0, 1, 2, 3, 4, 5][_hash(l, 3) % 7]


static func bottom_index(l: Dictionary) -> int:
	if l.has("bottom"):
		return clampi(int(l.bottom), 0, BOTTOMS.size() - 1)
	if is_female(l):
		return [0, 1, 3, 3, 1][_hash(l, 4) % 5]
	return [0, 1, 1, 0][_hash(l, 4) % 4]




static func _get_skin() -> Skin:
	if _skin_res == null:
		_skin_res = Skin.new()
		_skin_res.set_bind_count(HumanRig.BONES.size())
		for i in HumanRig.BONES.size():
			_skin_res.set_bind_bone(i, i)
			_skin_res.set_bind_pose(i, Transform3D(Basis(), -(HumanRig.BONES[i][2] as Vector3)))
	return _skin_res


func _make_skeleton() -> Skeleton3D:
	var sk := Skeleton3D.new()
	sk.name = "Skeleton"
	for b in HumanRig.BONES:
		sk.add_bone(str(b[0]))
	for i in HumanRig.BONES.size():
		var b: Array = HumanRig.BONES[i]
		var par := int(b[1])
		sk.set_bone_parent(i, par)
		var pos: Vector3 = b[2]
		var rel := pos - ((HumanRig.BONES[par][2] as Vector3) if par >= 0 else Vector3.ZERO)
		sk.set_bone_rest(i, Transform3D(Basis(), rel))
	sk.reset_bone_poses()
	return sk


func _skinned(mesh: Mesh, mat: Material, nm: String) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nm
	mi.mesh = mesh
	mi.skin = _get_skin()
	mi.material_override = mat
	_skel.add_child(mi)
	mi.skeleton = NodePath("..")
	return mi


func _param(nm: String, v) -> void:
	for m in _mats:
		(m as ShaderMaterial).set_shader_parameter(nm, v)


func build(l: Dictionary) -> void:
	look = l
	for c in get_children():
		if c != tag:
			c.queue_free()
	_parts.clear()
	_mats.clear()
	var skin: Color = SKINS[int(l.get("skin", 0)) % SKINS.size()] if not (l.get("skin") is Color) else l.skin
	var shirt: Color = l.get("shirt", Color("2a9df4"))
	var pants: Color = l.get("pants", Color("2a2a3a"))
	var outfit: String = str(l.get("outfit", ""))
	var formal := outfit in FORMAL
	var hair_col: Color = HAIR_COLORS[int(l.get("hair_color", 0)) % HAIR_COLORS.size()] if not (l.get("hair_color") is Color) else l.hair_color
	female = is_female(l)
	var slim: float = BUILDS[build_index(l)]
	var face := face_name(l)
	var style := hair_name(l)
	var hat := hat_name(l)
	var ref_id := str(l.get("ref", ""))
	var is_ref := ref_id != "" and RP.has(ref_id)
	var ref_sc := 1.0
	if is_ref:
		var ri: Dictionary = RP.info(ref_id)
		female = int(ri.get("male", 1)) == 0
		slim = float(ri.get("slim", 0.82))
		face = "neutral"
		style = str(ri.get("hair", ""))
		hat = "none"
		ref_sc = float(ri.get("scale", 1.0))
	var sc: float = float(l.get("scale", 1.0)) * ref_sc * (1.05 if not female else 1.0)
	scale = Vector3.ONE * sc
	_abd = lerpf(0.33, 0.13, slim) + (0.02 if not female else 0.0)
	_sit_y = -(HIP_Y - KNEE_Y) + (HIP_Y - KNEE_Y) * cos(1.5) - 0.012

	var rig := Node3D.new()
	rig.name = "Rig"
	add_child(rig)
	_parts.rig = rig
	_skel = _make_skeleton()
	rig.add_child(_skel)
	_parts.skel = _skel
	if not female:
		for i in 2:
			var s := -1.0 if i == 0 else 1.0
			var bi: int = B_CLAV[i]
			_skel.set_bone_pose_position(bi, _skel.get_bone_rest(bi).origin + Vector3(0.012 * s, 0, 0))

	if not is_ref:
		var mat := ShaderMaterial.new()
		mat.shader = SHADER
		_mats.append(mat)
		var mat2: ShaderMaterial = null
		var top_code: int = OUTFIT_CODE.get(outfit, 1)
		var top_c := shirt
		var top_c2 := Color("f4f0e8")
		var shirt_c := Color("f4f0e8")
		var tie := 0
		var tie_c := Color("b01a2a")
		var bot := bottom_index(l)
		var bot_code: int = BOTTOMS[bot][2]
		var h := _hash(l, 7)
		if outfit == "":
			var t: Array = TOPS[top_index(l)]
			top_code = int(t[2])
			match str(t[0]):
				"stripes":
					top_c2 = Color("f4f0e8") if shirt.get_luminance() < 0.6 else Color("1a2a5a")
				"plaid":
					top_c2 = shirt.lightened(0.55)
				"dress":
					bot_code = 4
		elif outfit == "hawaii":
			top_c2 = [Color("f4f0e8"), Color("ffd84a"), Color("ff8ab0")][h % 3]
		elif outfit == "logo":
			top_c2 = Color("e8b830") if shirt.get_luminance() < 0.55 else Color("8a1a2a")
		elif outfit == "hoodie":
			top_c2 = Color("ecebe6")
		elif outfit == "apron":
			top_c2 = Color("3a2a1e") if h % 2 == 0 else Color("1a1a1e")
		elif outfit == "maid":
			bot_code = 4
			top_c = Color("141418")
		elif outfit == "chef":
			shirt_c = Color("f8f6f0")
		elif outfit == "tux":
			tie = 1
			tie_c = Color("101012")
		elif outfit == "suit":
			tie = 2
			tie_c = [Color("8a1a2a"), Color("1a3a7a"), Color("5a1a4a"), Color("2a2a2a")][h % 4]
		if bool(l.get("bowtie", false)):
			tie = 1
			if outfit != "tux":
				tie_c = Color("c81a2a")
		if formal and bot_code >= 2 and outfit != "maid":
			bot_code = 0
		if outfit in ["vest", "suit", "tux"] and female and bot == 3:
			bot_code = 3

		var shoes: Color
		var shoe_kind := 0
		if l.get("shoes") is Color:
			shoes = l.shoes
		elif formal:
			shoes = Color("141414")
		else:
			shoes = SHOES[(int(l.get("skin", 0)) * 7 + int(l.get("face", 0)) * 3 + int(l.get("hair", 0))) % SHOES.size()]
		if formal:
			shoe_kind = 3 if female and (bot_code >= 3 or outfit == "maid") else 1
		elif not (shoes.get_luminance() > 0.5 or shoes.s > 0.45):
			shoe_kind = 2 if h % 3 == 0 else 1
		var sole := Color("e8e4dc")
		mat.set_shader_parameter("skin_col", skin)
		mat.set_shader_parameter("hair_col", hair_col)
		mat.set_shader_parameter("eye_col", EYE_COLORS[_hash(l, 5) % EYE_COLORS.size()])
		mat.set_shader_parameter("lip_col", skin.lerp(Color(0.72, 0.3, 0.32), 0.42 if female else 0.25))
		mat.set_shader_parameter("top_col", top_c)
		mat.set_shader_parameter("top_col2", top_c2)
		mat.set_shader_parameter("shirt_col", shirt_c)
		mat.set_shader_parameter("bot_col", pants)
		mat.set_shader_parameter("shoe_col", shoes)
		mat.set_shader_parameter("sole_col", sole)
		mat.set_shader_parameter("tie_col", tie_c)
		mat.set_shader_parameter("belt_col", Color("2a1c14") if pants.get_luminance() > 0.12 else Color("4a3626"))
		mat.set_shader_parameter("top_kind", top_code)
		mat.set_shader_parameter("bot_kind", bot_code)
		mat.set_shader_parameter("shoe_kind", shoe_kind)
		mat.set_shader_parameter("tie_kind", tie)
		var beard := 0
		if face == "mustache":
			beard = 1
		elif face == "beard":
			beard = 2
		elif not female and _hash(l, 6) % 5 == 0:
			beard = 3
		mat.set_shader_parameter("beard", beard)
		mat.set_shader_parameter("makeup", 1.0 if face == "lady" else (0.35 if female and _hash(l, 8) % 3 == 0 else 0.0))
		mat.set_shader_parameter("slim", slim)
		mat.set_shader_parameter("male", 0.0 if female else 1.0)

		var body := _skinned(BODY_MESH, mat, "Body")
		body.set_blend_shape_value(0, slim)
		body.set_blend_shape_value(1, 0.0 if female else 1.0)
		_parts.body = body
		_parts.torso = body

		if bot_code >= 3:
			mat2 = ShaderMaterial.new()
			mat2.shader = SHADER_2S
			var sk := _skinned(SKIRT_MESH, mat2, "Skirt")
			sk.set_blend_shape_value(0, slim)

		var hat_on := hat != "none" and not HAT_OPEN.has(hat)
		if hat_on and style in ["mohawk", "spiky", "bun"]:
			style = "short"
		mat.set_shader_parameter("scalp", 0 if style == "bald" else (2 if style in ["long", "bob"] else 1))
		if HAIR_MESH.has(style):
			if style == "long" or style == "ponytail":
				if mat2 == null:
					mat2 = ShaderMaterial.new()
					mat2.shader = SHADER_2S
				_skinned(HAIR_MESH[style], mat2, "Hair")
			else:
				_skinned(HAIR_MESH[style], mat, "Hair")
		if mat2 != null:
			for p in ["skin_col", "hair_col", "top_col", "top_col2", "bot_col", "top_kind", "bot_kind"]:
				mat2.set_shader_parameter(p, mat.get_shader_parameter(p))
			_mats.append(mat2)
	else:
		var rb := _skinned(RP.body_mesh(ref_id, BODY_MESH), RP.body_mat(ref_id), "Body")
		rb.set_blend_shape_value(0, slim)
		rb.set_blend_shape_value(1, 0.0 if female else 1.0)
		_parts.body = rb
		_parts.torso = rb
		if HAIR_MESH.has(style):
			_skinned(HAIR_MESH[style], RP.head_mat(ref_id, false), "Hair")

	var head_att := BoneAttachment3D.new()
	head_att.name = "HeadAtt"
	head_att.bone_name = "Head"
	_skel.add_child(head_att)
	var head_local := Node3D.new()
	head_local.position = -(HumanRig.BONES[B_HEAD][2] as Vector3)
	head_att.add_child(head_local)
	_parts.head = head_local
	_parts.neck = head_att
	_parts.face = _parts.body
	_parts.elbows = []
	for i in 2:
		var fa := BoneAttachment3D.new()
		fa.bone_name = str(HumanRig.BONES[B_FORE[i]][0])
		_skel.add_child(fa)
		var grip := Node3D.new()
		grip.name = "Grip"
		if i == 1:
			grip.basis = Basis(Vector3(0, 1, 0), Vector3(-1, 0, 0), Vector3(0, 0, 1))
		else:
			grip.basis = Basis(Vector3(0, -1, 0), Vector3(1, 0, 0), Vector3(0, 0, 1))
		fa.add_child(grip)
		_parts.elbows.append(grip)
	_parts.shoulders = []
	_parts.hips = []
	_parts.knees = []
	if is_ref:
		_build_ref_hat(head_local, ref_id)
	else:
		_build_hat(head_local, l, hat)
	if face in ["glasses", "shades"] and not is_ref:
		var g := MeshInstance3D.new()
		g.mesh = _glasses_mesh(face == "shades")
		g.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		head_local.add_child(g)
	_base_face = face
	_expr_cur.clear()
	_expr_tgt.clear()
	_set_expr(_base_face, true)
	if tag:
		tag.position = Vector3(0, tag_height(), 0)
	_apply_pose(1.0)




class Acc:
	var v := PackedVector3Array()
	var n := PackedVector3Array()
	var c := PackedColorArray()

	func tri(a: Vector3, b: Vector3, d: Vector3, col: Color) -> void:
		var nn := (d - a).cross(b - a).normalized()
		v.append_array([a, b, d])
		n.append_array([nn, nn, nn])
		c.append_array([col, col, col])

	func quad(a: Vector3, b: Vector3, d: Vector3, e: Vector3, col: Color) -> void:
		tri(a, b, d, col)
		tri(a, d, e, col)


	func lathe(prof: Array, ctr: Vector3, sx: float, sz: float, col: Color, seg: int = 28, smooth := true, warp := Callable()) -> void:
		var rings := []
		for p in prof:
			var ring := []
			for k in seg:
				var a := TAU * k / seg
				var pt := Vector3(sin(a) * p.x * sx, p.y, cos(a) * p.x * sz)
				if warp.is_valid():
					pt = warp.call(pt, a)
				ring.append(ctr + pt)
			rings.append(ring)
		for r in rings.size() - 1:
			for k in seg:
				var k2 := (k + 1) % seg
				var a: Vector3 = rings[r][k]
				var b: Vector3 = rings[r][k2]
				var d: Vector3 = rings[r + 1][k2]
				var e: Vector3 = rings[r + 1][k]
				if smooth:
					var base := v.size()
					quad(a, e, d, b, col)

					for q in 6:
						var pp: Vector3 = v[base + q]
						var rr := Vector3((pp.x - ctr.x) / maxf(sx, 0.01), 0, (pp.z - ctr.z) / maxf(sz, 0.01))
						var nn2: Vector3 = n[base + q]
						n[base + q] = (rr.normalized() * 0.7 + nn2 * 0.3).normalized() if absf(nn2.y) < 0.85 else nn2
				else:
					quad(a, e, d, b, col)

	func box(ctr: Vector3, size: Vector3, col: Color, rot: Basis = Basis()) -> void:
		var h := size * 0.5
		var p := []
		for i in 8:
			p.append(ctr + rot * Vector3(h.x * (1 if i & 1 else -1), h.y * (1 if i & 2 else -1), h.z * (1 if i & 4 else -1)))
		quad(p[0], p[1], p[3], p[2], col)
		quad(p[4], p[6], p[7], p[5], col)
		quad(p[0], p[4], p[5], p[1], col)
		quad(p[2], p[3], p[7], p[6], col)
		quad(p[0], p[2], p[6], p[4], col)
		quad(p[1], p[5], p[7], p[3], col)

	func sphere(ctr: Vector3, r: Vector3, col: Color, seg: int = 12) -> void:
		var prof := []
		for i in seg / 2 + 1:
			var t := PI * i / (seg / 2)
			prof.append(Vector2(sin(t), -cos(t)))
		var rings := []
		for p in prof:
			var ring := []
			for k in seg:
				var a := TAU * k / seg
				ring.append(ctr + Vector3(sin(a) * p.x * r.x, p.y * r.y, cos(a) * p.x * r.z))
			rings.append(ring)
		for i in rings.size() - 1:
			for k in seg:
				var k2 := (k + 1) % seg
				var base := v.size()
				quad(rings[i][k], rings[i + 1][k], rings[i + 1][k2], rings[i][k2], col)
				for q in 6:
					var pp: Vector3 = v[base + q]
					n[base + q] = ((pp - ctr) / r).normalized()


	func tube(pts: Array, r: float, col: Color, closed := false, seg: int = 6) -> void:
		var cnt := pts.size()
		var last := cnt if closed else cnt - 1
		for i in last:
			var a: Vector3 = pts[i]
			var b: Vector3 = pts[(i + 1) % cnt]
			var dir := (b - a).normalized()
			var up := Vector3.UP if absf(dir.y) < 0.9 else Vector3.RIGHT
			var s1 := dir.cross(up).normalized()
			var s2 := dir.cross(s1).normalized()
			for k in seg:
				var a0 := TAU * k / seg
				var a1 := TAU * (k + 1) / seg
				var o0 := (s1 * cos(a0) + s2 * sin(a0)) * r
				var o1 := (s1 * cos(a1) + s2 * sin(a1)) * r
				var base := v.size()
				quad(a + o0, b + o0, b + o1, a + o1, col)
				for q in 6:
					var pp: Vector3 = v[base + q]
					var t := clampf((pp - a).dot(dir) / maxf((b - a).length(), 0.0001), 0.0, 1.0)
					n[base + q] = (pp - a.lerp(b, t)).normalized()

	func mesh(mat: Material) -> ArrayMesh:
		var m := ArrayMesh.new()
		if v.is_empty():
			return m
		var arr := []
		arr.resize(Mesh.ARRAY_MAX)
		arr[Mesh.ARRAY_VERTEX] = v
		arr[Mesh.ARRAY_NORMAL] = n
		arr[Mesh.ARRAY_COLOR] = c
		m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
		m.surface_set_material(0, mat)
		return m


static func _amat() -> StandardMaterial3D:
	if _acc_mat == null:
		_acc_mat = StandardMaterial3D.new()
		_acc_mat.vertex_color_use_as_albedo = true
		_acc_mat.roughness = 0.62
		_acc_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	return _acc_mat



const HAT_C := Vector3(0.0, 1.64, -0.016)
const HAT_RX := 0.096
const HAT_RZ := 0.13


func _build_hat(parent: Node3D, l: Dictionary, hat: String) -> void:
	_prop = null
	if hat == "none":
		_hat_node = null
		return
	var key := hat + str(l.get("hat_color", "")) + (str(l.get("shirt", "")) if hat == "cap" else "")
	var m: ArrayMesh = _acc_cache.get(key)
	if m == null:
		m = _hat_mesh(hat, l)
		_acc_cache[key] = m
	var mi := MeshInstance3D.new()
	mi.name = "Hat"
	mi.mesh = m
	parent.add_child(mi)
	_hat_node = mi
	if hat == "halo":
		mi.material_override = _glow_mat()
	elif hat == "propeller":
		var pm := MeshInstance3D.new()
		if not _acc_cache.has("prop_blades"):
			_acc_cache["prop_blades"] = _prop_mesh()
		pm.mesh = _acc_cache["prop_blades"]
		pm.position = HAT_C + Vector3(0, 0.124, 0)
		mi.add_child(pm)
		_prop = pm


func _build_ref_hat(parent: Node3D, ref_id: String) -> void:
	_prop = null
	_hat_node = null
	var hat := str(RP.info(ref_id).get("hat", ""))
	if hat == "":
		return
	var key := "ref_hat_" + hat
	var m: ArrayMesh = _acc_cache.get(key)
	if m == null:
		m = _ref_hat_mesh(hat)
		_acc_cache[key] = m
	var mi := MeshInstance3D.new()
	mi.name = "Hat"
	mi.mesh = m
	mi.material_override = RP.head_mat(ref_id, true)
	parent.add_child(mi)
	_hat_node = mi


# формы головных уборов фото-людей (цвет берётся проекцией из референса)
static func _ref_hat_mesh(hat: String) -> ArrayMesh:
	if hat == "police":
		return _hat_mesh("guard", {})
	var g := Acc.new()
	var c0 := HAT_C
	var w := Color.WHITE
	match hat:
		"helmet":
			g.lathe([Vector2(1.13, -0.03), Vector2(1.15, 0.0), Vector2(1.12, 0.05), Vector2(1.02, 0.09), Vector2(0.8, 0.125),
				Vector2(0.45, 0.145), Vector2(0.0, 0.15)], c0, HAT_RX, HAT_RZ, w, 28)
			g.lathe([Vector2(1.2, -0.035), Vector2(1.13, -0.03)], c0, HAT_RX, HAT_RZ, w, 28, false)
		"flatcap":
			var warp := func(p: Vector3, a: float) -> Vector3:
				var f := maxf(cos(a), 0.0)
				return p + Vector3(0, -0.022 * f * clampf(p.y / 0.08, 0.0, 1.0), 0.035 * f * clampf(p.y / 0.06, 0.0, 1.0))
			g.lathe([Vector2(1.04, -0.012), Vector2(1.1, 0.03), Vector2(1.08, 0.058), Vector2(0.85, 0.074), Vector2(0.45, 0.082),
				Vector2(0.0, 0.084)], c0, HAT_RX, HAT_RZ, w, 28, true, warp)
			var n := 10
			for k in n:
				var a0 := lerpf(-0.95, 0.95, float(k) / n)
				var a1 := lerpf(-0.95, 0.95, float(k + 1) / n)
				var p0 := c0 + Vector3(sin(a0) * HAT_RX * 1.04, -0.012, cos(a0) * HAT_RZ * 1.04)
				var p1 := c0 + Vector3(sin(a1) * HAT_RX * 1.04, -0.012, cos(a1) * HAT_RZ * 1.04)
				var q0 := c0 + Vector3(sin(a0) * HAT_RX * 1.12, -0.026, cos(a0) * HAT_RZ + 0.045 * cos(a0))
				var q1 := c0 + Vector3(sin(a1) * HAT_RX * 1.12, -0.026, cos(a1) * HAT_RZ + 0.045 * cos(a1))
				g.quad(p0, p1, q1, q0, w)
				g.quad(p0 + Vector3(0, -0.004, 0), q0 + Vector3(0, -0.004, 0), q1 + Vector3(0, -0.004, 0), p1 + Vector3(0, -0.004, 0), w)
		"bucket":
			g.lathe([Vector2(1.03, -0.01), Vector2(1.0, 0.04), Vector2(0.96, 0.08), Vector2(0.8, 0.105), Vector2(0.4, 0.115),
				Vector2(0.0, 0.117)], c0, HAT_RX, HAT_RZ, w, 28)
			g.lathe([Vector2(1.7, -0.06), Vector2(1.4, -0.035), Vector2(1.03, -0.01)], c0, HAT_RX, HAT_RZ, w, 32, false)
			g.lathe([Vector2(1.03, -0.016), Vector2(1.4, -0.041), Vector2(1.7, -0.066)], c0, HAT_RX, HAT_RZ, w, 32, false)
	return g.mesh(_amat())


static func _glow_mat() -> StandardMaterial3D:
	if not _acc_cache.has("glow_mat"):
		var gm := StandardMaterial3D.new()
		gm.vertex_color_use_as_albedo = true
		gm.emission_enabled = true
		gm.emission = Color(1.0, 0.85, 0.4)
		gm.emission_energy_multiplier = 0.9
		gm.cull_mode = BaseMaterial3D.CULL_DISABLED
		_acc_cache["glow_mat"] = gm
	return _acc_cache["glow_mat"]


static func _prop_mesh() -> ArrayMesh:
	var g := Acc.new()
	g.sphere(Vector3.ZERO, Vector3(0.012, 0.008, 0.012), Color("e8283a"), 8)
	for s in [-1.0, 1.0]:
		g.box(Vector3(0.056 * s, 0.0, 0.0), Vector3(0.1, 0.004, 0.026), Color("2a6ae8") if s > 0 else Color("e8283a"), Basis(Vector3.RIGHT, 0.35 * s))
	return g.mesh(_amat())


# цепочка шариков с убывающим радиусом — рога, бивни, рожки колпака
static func _chain(g: Acc, pts: Array, r0: float, r1: float, col: Color, col2: Color = Color(0, 0, 0, 0)) -> void:
	var n := pts.size()
	for i in n:
		var t := float(i) / maxf(1.0, float(n - 1))
		var r := lerpf(r0, r1, t)
		var cc: Color = col if col2.a <= 0.0 or i % 2 == 0 else col2
		g.sphere(pts[i], Vector3(r, r, r), cc, 8)
		if i < n - 1:
			g.tube([pts[i], pts[i + 1]], lerpf(r0, r1, (float(i) + 0.5) / maxf(1.0, float(n - 1))) * 0.92, cc, false, 8)


static func _dome(top: float, k: float = 1.04, y0: float = -0.012) -> Array:
	var prof := []
	for i in 9:
		var t := float(i) / 8.0
		prof.append(Vector2(cos(t * PI * 0.5) * k, y0 + sin(t * PI * 0.5) * top))
	prof.append(Vector2(0.0, y0 + top - 0.012))
	return prof


static func _hat_mesh(hat: String, l: Dictionary) -> ArrayMesh:
	var g := Acc.new()
	var c0 := HAT_C
	match hat:
		"cap":
			var c: Color = l.get("hat_color", l.get("shirt", Color("c81a2a")))
			var prof := []
			for i in 9:
				var t := float(i) / 8.0
				prof.append(Vector2(cos(t * PI * 0.5) * 1.04 + 0.0, -0.012 + sin(t * PI * 0.5) * 0.088))
			prof.append(Vector2(0.0, 0.076))
			g.lathe(prof, c0, HAT_RX, HAT_RZ, c, 28)

			var vis := c.darkened(0.25)
			var n := 10
			for k in n:
				var a0 := lerpf(-1.05, 1.05, float(k) / n)
				var a1 := lerpf(-1.05, 1.05, float(k + 1) / n)
				var p0 := c0 + Vector3(sin(a0) * HAT_RX, -0.012, cos(a0) * HAT_RZ)
				var p1 := c0 + Vector3(sin(a1) * HAT_RX, -0.012, cos(a1) * HAT_RZ)
				var q0 := c0 + Vector3(sin(a0) * HAT_RX * 1.25, -0.022 - 0.006 * cos(a0), cos(a0) * HAT_RZ + 0.075 * cos(a0 * 0.9))
				var q1 := c0 + Vector3(sin(a1) * HAT_RX * 1.25, -0.022 - 0.006 * cos(a1), cos(a1) * HAT_RZ + 0.075 * cos(a1 * 0.9))
				g.quad(p0, p1, q1, q0, vis)
				g.quad(p0 + Vector3(0, -0.004, 0), q0 + Vector3(0, -0.004, 0), q1 + Vector3(0, -0.004, 0), p1 + Vector3(0, -0.004, 0), vis.darkened(0.3))
			g.sphere(c0 + Vector3(0, 0.077, 0), Vector3(0.009, 0.005, 0.009), c.darkened(0.3), 8)
			g.box(c0 + Vector3(0, 0.035, HAT_RZ * 0.93), Vector3(0.05, 0.03, 0.004), Color("f4f0e8"), Basis(Vector3.RIGHT, -0.45))
		"cowboy":
			var c2 := Color("8a5a2a")
			var brim := []
			for i in 7:
				var t := float(i) / 6.0
				brim.append(Vector2(lerpf(1.0, 2.05, t), 0.0))
			g.lathe(brim, c0 + Vector3(0, -0.004, 0), HAT_RX, HAT_RZ, c2, 36, false, func(p: Vector3, a: float) -> Vector3:
				var rr := Vector2(p.x / HAT_RX, p.z / HAT_RZ).length()
				var side := pow(absf(sin(a)), 2.0)
				return p + Vector3(0, maxf(rr - 1.2, 0.0) * (0.055 * side - 0.012 * (1.0 - side)), 0))
			var crown := [Vector2(1.03, -0.004), Vector2(1.0, 0.03), Vector2(0.96, 0.08), Vector2(0.9, 0.12), Vector2(0.55, 0.13), Vector2(0.0, 0.112)]
			g.lathe(crown, c0, HAT_RX, HAT_RZ, c2, 28, true, func(p: Vector3, a: float) -> Vector3:
				return p - Vector3(0, 0.025 * pow(maxf(cos(a), 0.0), 2.0) * clampf((p.y - 0.06) / 0.06, 0.0, 1.0), 0))
			g.lathe([Vector2(1.04, 0.0), Vector2(1.03, 0.022)], c0, HAT_RX, HAT_RZ, Color("3a2210"), 28)
		"tophat":
			var tk := Color("141418")
			g.lathe([Vector2(1.0, -0.004), Vector2(1.55, -0.004), Vector2(1.62, 0.006)], c0, HAT_RX, HAT_RZ, tk, 32, false)
			g.lathe([Vector2(1.62, 0.002), Vector2(1.55, -0.008), Vector2(1.0, -0.008)], c0, HAT_RX, HAT_RZ, tk, 32, false)
			g.lathe([Vector2(1.02, -0.004), Vector2(1.0, 0.04), Vector2(1.04, 0.17), Vector2(1.06, 0.18), Vector2(0.0, 0.18)], c0, HAT_RX, HAT_RZ, tk, 28)
			g.lathe([Vector2(1.03, 0.0), Vector2(1.015, 0.04)], c0, HAT_RX, HAT_RZ, Color("8a1a2a"), 28)
		"beanie":
			var c3: Color = l.get("hat_color", Color("e0b040"))
			var cb := c0 + Vector3(0, -0.035, 0.004)
			g.lathe([Vector2(1.06, 0.0), Vector2(1.07, 0.04)], cb, HAT_RX, HAT_RZ, c3.darkened(0.18), 28)
			var prof := []
			for i in 9:
				var t := float(i) / 8.0
				prof.append(Vector2(cos(t * PI * 0.5) * 1.05, 0.04 + sin(t * PI * 0.5) * 0.095))
			g.lathe(prof, cb, HAT_RX, HAT_RZ, c3, 28)
			g.lathe([Vector2(1.06, 0.06), Vector2(1.055, 0.07)], cb, HAT_RX, HAT_RZ, c3.lightened(0.35), 28)
			g.sphere(cb + Vector3(0, 0.145, 0), Vector3(0.03, 0.028, 0.03), Color("f4f0e8"), 10)
		"fedora":
			var fc := Color("4a3a2a")
			g.lathe([Vector2(1.0, -0.002), Vector2(1.75, -0.002)], c0, HAT_RX, HAT_RZ, fc, 32, false, func(p: Vector3, a: float) -> Vector3:
				var rr := Vector2(p.x / HAT_RX, p.z / HAT_RZ).length()
				return p + Vector3(0, maxf(rr - 1.1, 0.0) * (0.03 * (1.0 - absf(cos(a))) - 0.02 * maxf(cos(a), 0.0)), 0))
			g.lathe([Vector2(1.75, -0.006), Vector2(1.0, -0.006)], c0, HAT_RX, HAT_RZ, fc.darkened(0.2), 32, false, func(p: Vector3, a: float) -> Vector3:
				var rr := Vector2(p.x / HAT_RX, p.z / HAT_RZ).length()
				return p + Vector3(0, maxf(rr - 1.1, 0.0) * (0.03 * (1.0 - absf(cos(a))) - 0.02 * maxf(cos(a), 0.0)), 0))
			g.lathe([Vector2(1.02, -0.002), Vector2(0.98, 0.05), Vector2(0.88, 0.1), Vector2(0.5, 0.115), Vector2(0.0, 0.1)], c0, HAT_RX, HAT_RZ, fc, 28, true, func(p: Vector3, a: float) -> Vector3:
				return p - Vector3(0, 0.02 * pow(absf(cos(a * 0.5)), 6.0) * clampf((p.y - 0.06) / 0.05, 0.0, 1.0), 0))
			g.lathe([Vector2(1.03, 0.0), Vector2(1.01, 0.028)], c0, HAT_RX, HAT_RZ, Color("1a1a1a"), 28)
		"crown":
			var gc := Color("ffd84a")
			g.lathe([Vector2(1.0, -0.004), Vector2(1.0, 0.045)], c0, HAT_RX, HAT_RZ, gc, 24)
			g.lathe([Vector2(0.96, 0.045), Vector2(0.96, -0.004)], c0, HAT_RX, HAT_RZ, gc.darkened(0.3), 24)
			for k in 8:
				var a := TAU * k / 8.0
				var a1 := a - TAU / 16.0
				var a2 := a + TAU / 16.0
				var p1 := c0 + Vector3(sin(a1) * HAT_RX, 0.044, cos(a1) * HAT_RZ)
				var p2 := c0 + Vector3(sin(a2) * HAT_RX, 0.044, cos(a2) * HAT_RZ)
				var tp := c0 + Vector3(sin(a) * HAT_RX * 1.02, 0.1, cos(a) * HAT_RZ * 1.02)
				g.tri(p1, tp, p2, gc)
				g.tri(p2, tp, p1, gc.darkened(0.25))
				g.sphere(tp, Vector3(0.006, 0.006, 0.006), gc.lightened(0.3), 6)
				var gem: Color = [Color("e8283a"), Color("2a6ae8"), Color("2ae86a")][k % 3]
				g.sphere(c0 + Vector3(sin(a + TAU / 16.0) * HAT_RX * 1.01, 0.02, cos(a + TAU / 16.0) * HAT_RZ * 1.01), Vector3(0.007, 0.007, 0.007), gem, 6)
		"chef":
			g.lathe([Vector2(1.0, -0.006), Vector2(1.03, 0.06)], c0, HAT_RX, HAT_RZ, Color("f4f0e8"), 28)
			for p in [Vector3(0, 0.12, 0), Vector3(-0.05, 0.1, 0.05), Vector3(0.055, 0.1, 0.045), Vector3(-0.05, 0.1, -0.06), Vector3(0.05, 0.1, -0.06), Vector3(0, 0.15, -0.01)]:
				g.sphere(c0 + p, Vector3(0.075, 0.06, 0.08), Color("ffffff"), 12)
		"headphones":
			var hb := Color("1a1a24")
			var arc := []
			for k in 13:
				var a := lerpf(-1.25, 1.25, float(k) / 12.0)
				arc.append(Vector3(sin(a) * 0.1, 1.575 + cos(a) * 0.145, -0.01))
			g.tube(arc, 0.008, hb)
			for s in [-1.0, 1.0]:
				var cc := Vector3(0.093 * s, 1.575, -0.01)
				g.lathe([Vector2(0.0, -0.022), Vector2(1.0, -0.022), Vector2(1.0, 0.022), Vector2(0.0, 0.022)], Vector3.ZERO, 0.03, 0.036, Color("e8283a"), 16, true)
				var base := g.v.size() - 16 * 3 * 6
				for q in range(base, g.v.size()):
					var p: Vector3 = g.v[q]
					g.v[q] = cc + Vector3(p.y * s + 0.0, p.x, p.z)
					var nn: Vector3 = g.n[q]
					g.n[q] = Vector3(nn.y * s, nn.x, nn.z)
				g.sphere(cc + Vector3(0.022 * s, 0, 0), Vector3(0.006, 0.02, 0.024), Color("f4f0e8"), 8)
		"propeller":
			g.lathe(_dome(0.088), c0, HAT_RX, HAT_RZ, Color("f0c020"), 28)
			for k in 4:
				var a := TAU * k / 4.0 + TAU / 8.0
				var mer := []
				for i in 8:
					var t := float(i) / 7.0
					mer.append(c0 + Vector3(sin(a) * cos(t * PI * 0.5) * HAT_RX * 1.05, -0.01 + sin(t * PI * 0.5) * 0.089, cos(a) * cos(t * PI * 0.5) * HAT_RZ * 1.05))
				g.tube(mer, 0.007, [Color("e8283a"), Color("2a6ae8"), Color("2ae86a"), Color("e8283a")][k], false, 5)
			var vis := Color("2a6ae8")
			for k in 10:
				var a0 := lerpf(-1.05, 1.05, float(k) / 10.0)
				var a1 := lerpf(-1.05, 1.05, float(k + 1) / 10.0)
				var p0 := c0 + Vector3(sin(a0) * HAT_RX, -0.012, cos(a0) * HAT_RZ)
				var p1 := c0 + Vector3(sin(a1) * HAT_RX, -0.012, cos(a1) * HAT_RZ)
				var q0 := c0 + Vector3(sin(a0) * HAT_RX * 1.25, -0.022 - 0.006 * cos(a0), cos(a0) * HAT_RZ + 0.075 * cos(a0 * 0.9))
				var q1 := c0 + Vector3(sin(a1) * HAT_RX * 1.25, -0.022 - 0.006 * cos(a1), cos(a1) * HAT_RZ + 0.075 * cos(a1 * 0.9))
				g.quad(p0, p1, q1, q0, vis)
			g.lathe([Vector2(0.12, 0.07), Vector2(0.12, 0.122), Vector2(0.0, 0.122)], c0, HAT_RX, HAT_RZ, Color("d0d0d8"), 10)
		"party":
			var pc: Color = l.get("hat_color", Color("ff4d8d"))
			var cb := c0 + Vector3(0, 0.04, 0.006)
			var cols := [pc, Color("ffd84a"), pc, Color("5ee0ff"), pc]
			for i in 5:
				var t0 := float(i) / 5.0
				var t1 := float(i + 1) / 5.0
				g.lathe([Vector2(1.0 - t0, t0 * 0.21), Vector2(1.0 - t1, t1 * 0.21)], cb, 0.072, 0.08, cols[i], 20)
			g.lathe([Vector2(1.05, -0.004), Vector2(1.0, 0.014)], cb, 0.072, 0.08, Color("ffd84a"), 20)
			g.sphere(cb + Vector3(0, 0.215, 0), Vector3(0.022, 0.022, 0.022), Color("fff4d6"), 10)
		"viking":
			g.lathe(_dome(0.1, 1.07, -0.02), c0, HAT_RX, HAT_RZ, Color("8a8f9a"), 28)
			g.lathe([Vector2(1.09, -0.024), Vector2(1.09, 0.012)], c0, HAT_RX, HAT_RZ, Color("8a5a2a"), 28)
			var ridge := []
			for i in 9:
				var t := lerpf(-1.25, 1.25, float(i) / 8.0)
				ridge.append(c0 + Vector3(0, -0.02 + cos(t) * 0.103, sin(t) * HAT_RZ * 1.06))
			g.tube(ridge, 0.008, Color("c8a050"), false, 6)
			for k in 10:
				var a := TAU * k / 10.0
				g.sphere(c0 + Vector3(sin(a) * HAT_RX * 1.1, -0.006, cos(a) * HAT_RZ * 1.1), Vector3(0.006, 0.006, 0.006), Color("e0c060"), 6)
			for sd in [-1.0, 1.0]:
				var hp := []
				for i in 10:
					var t := float(i) / 9.0
					hp.append(c0 + Vector3(sd * (0.085 + t * 0.11), 0.025 + t * t * 0.17 - t * 0.015, 0.01 + t * 0.02))
				_chain(g, hp, 0.032, 0.006, Color("f0e6c8"))
		"sombrero":
			var sc := Color("d8b060")
			g.lathe([Vector2(0.9, 0.0), Vector2(2.7, -0.005), Vector2(2.85, 0.03), Vector2(2.9, 0.048)], c0 + Vector3(0, -0.004, 0), 0.11, 0.11, sc, 40, false)
			g.lathe([Vector2(1.02, -0.004), Vector2(0.95, 0.08), Vector2(0.8, 0.15), Vector2(0.5, 0.175), Vector2(0.0, 0.18)], c0, HAT_RX, HAT_RZ, sc, 28)
			g.lathe([Vector2(1.025, 0.0), Vector2(1.0, 0.045)], c0, HAT_RX, HAT_RZ, Color("c81a2a"), 28)
			for k in 18:
				var a := TAU * k / 18.0
				g.sphere(c0 + Vector3(sin(a) * 0.32, 0.044, cos(a) * 0.32), Vector3(0.013, 0.013, 0.013), [Color("c81a2a"), Color("2ae86a"), Color("ffd84a")][k % 3], 6)
			for k in 10:
				var a := TAU * k / 10.0
				g.sphere(c0 + Vector3(sin(a) * HAT_RX * 1.03, 0.022, cos(a) * HAT_RZ * 1.03), Vector3(0.008, 0.008, 0.008), Color("2ae86a"), 6)
		"wizard":
			var wc: Color = l.get("hat_color", Color("3a3ab0"))
			var bend := func(p: Vector3, _a: float) -> Vector3:
				var t := clampf(p.y / 0.38, 0.0, 1.0)
				return p + Vector3(0, -0.04 * t * t, -0.1 * t * t * t)
			g.lathe([Vector2(0.95, 0.0), Vector2(1.95, -0.006)], c0 + Vector3(0, -0.004, 0), HAT_RX, HAT_RZ, wc.darkened(0.2), 32, false)
			var prof := []
			for i in 11:
				var t := float(i) / 10.0
				prof.append(Vector2(1.02 * (1.0 - t) + 0.001, t * 0.38))
			g.lathe(prof, c0, HAT_RX, HAT_RZ, wc, 24, true, bend)
			g.lathe([Vector2(1.035, 0.0), Vector2(0.95, 0.04)], c0, HAT_RX, HAT_RZ, Color("ffd84a"), 24)
			for st: Vector2 in [Vector2(0.4, 0.3), Vector2(-0.9, 0.45), Vector2(2.2, 0.25), Vector2(-2.4, 0.55), Vector2(1.2, 0.62), Vector2(3.1, 0.4)]:
				var tt := st.y
				var pp := Vector3(sin(st.x) * HAT_RX * 1.05 * (1.0 - tt), tt * 0.38, cos(st.x) * HAT_RZ * 1.05 * (1.0 - tt))
				g.sphere(c0 + bend.call(pp, st.x), Vector3(0.011, 0.011, 0.011), Color("ffe680"), 6)
		"pirate":
			var pk := Color("1a1418")
			g.lathe([Vector2(1.02, -0.004), Vector2(0.98, 0.06), Vector2(0.85, 0.1), Vector2(0.0, 0.11)], c0, HAT_RX, HAT_RZ, pk, 28)
			var tri := func(p: Vector3, a: float) -> Vector3:
				var rr := Vector2(p.x / HAT_RX, p.z / HAT_RZ).length()
				var t := clampf((rr - 1.0) / 0.7, 0.0, 1.0)
				var k := 0.55 + 0.45 * cos(3.0 * a)
				var sc := (1.0 + (rr - 1.0) * k) / maxf(rr, 0.001)
				return Vector3(p.x * sc, p.y + t * 0.1 * (1.15 - k * 0.5), p.z * sc)
			g.lathe([Vector2(1.0, -0.004), Vector2(1.35, -0.004), Vector2(1.7, -0.004)], c0, HAT_RX, HAT_RZ, pk.lightened(0.06), 48, false, tri)
			var edge := []
			for k in 48:
				var a := TAU * k / 48.0
				edge.append(c0 + tri.call(Vector3(sin(a) * 1.7 * HAT_RX, -0.004, cos(a) * 1.7 * HAT_RZ), a))
			g.tube(edge, 0.005, Color("e0b040"), true, 5)
		"halo":
			var ring := []
			for k in 24:
				var a := TAU * k / 24.0
				ring.append(c0 + Vector3(sin(a) * 0.085, 0.165, cos(a) * 0.1))
			g.tube(ring, 0.011, Color("fff0a0"), true, 8)
		"bucket":
			var bc := Color("9aa0aa")
			g.lathe([Vector2(1.12, -0.03), Vector2(1.08, 0.0), Vector2(0.86, 0.16), Vector2(0.0, 0.16)], c0, HAT_RX, HAT_RZ, bc, 24, false)
			g.lathe([Vector2(1.16, -0.036), Vector2(1.16, -0.016)], c0, HAT_RX, HAT_RZ, bc.darkened(0.25), 24)
			for yy in [0.05, 0.11]:
				var f: float = 1.08 - 0.22 * (float(yy) / 0.16)
				g.lathe([Vector2(f + 0.012, yy - 0.005), Vector2(f + 0.012, yy + 0.005)], c0, HAT_RX, HAT_RZ, bc.darkened(0.15), 24)
			var hd := []
			for k in 13:
				var a := PI * float(k) / 12.0
				hd.append(c0 + Vector3(cos(a) * 0.118, -0.03 - sin(a) * 0.05, -sin(a) * 0.16))
			g.tube(hd, 0.004, Color("5a5a60"), false, 5)
		"duck":
			var dy := Color("ffd84a")
			var b0 := c0 + Vector3(0, 0.115, -0.01)
			g.sphere(b0, Vector3(0.065, 0.05, 0.08), dy, 14)
			g.sphere(b0 + Vector3(0, 0.025, -0.075), Vector3(0.025, 0.035, 0.02), dy, 8)
			var hc := b0 + Vector3(0, 0.07, 0.045)
			g.sphere(hc, Vector3(0.042, 0.042, 0.042), dy, 12)
			g.sphere(hc + Vector3(0, -0.008, 0.045), Vector3(0.022, 0.008, 0.022), Color("ff8a20"), 8)
			for sd in [-1.0, 1.0]:
				g.sphere(hc + Vector3(0.02 * sd, 0.012, 0.034), Vector3(0.007, 0.009, 0.006), Color("101010"), 6)
				g.sphere(b0 + Vector3(0.058 * sd, 0.005, -0.005), Vector3(0.012, 0.03, 0.05), dy.darkened(0.12), 8)
		"devil":
			for sd in [-1.0, 1.0]:
				var hp := []
				for i in 7:
					var t := float(i) / 6.0
					hp.append(c0 + Vector3(sd * (0.045 + t * 0.03), 0.055 + t * 0.075, 0.045 - t * t * 0.03))
				_chain(g, hp, 0.019, 0.004, Color("d01a2a"))
		"ushanka":
			var fur := Color("6a4a30")
			g.lathe([Vector2(1.12, -0.02), Vector2(1.14, 0.04), Vector2(1.0, 0.1), Vector2(0.6, 0.13), Vector2(0.0, 0.135)], c0, HAT_RX, HAT_RZ, Color("4a3a30"), 28)
			g.lathe([Vector2(1.16, -0.03), Vector2(1.21, 0.0), Vector2(1.19, 0.045), Vector2(1.1, 0.052)], c0, HAT_RX, HAT_RZ, fur, 28)
			for sd in [-1.0, 1.0]:
				g.sphere(c0 + Vector3(0.112 * sd, -0.075, -0.005), Vector3(0.024, 0.068, 0.062), fur, 10)
			g.sphere(c0 + Vector3(0, 0.035, 0.14), Vector3(0.075, 0.042, 0.022), fur, 10)
			g.sphere(c0 + Vector3(0, 0.04, 0.16), Vector3(0.013, 0.013, 0.006), Color("e8283a"), 6)
		"tiara":
			var tc := Color("e8e8f0")
			var band := []
			for k in 15:
				var a := lerpf(-1.3, 1.3, float(k) / 14.0)
				band.append(c0 + Vector3(sin(a) * HAT_RX * 1.05, 0.03 + 0.012 * cos(a), cos(a) * HAT_RZ * 1.03))
			g.tube(band, 0.005, tc, false, 5)
			for k in 7:
				var a := lerpf(-0.9, 0.9, float(k) / 6.0)
				var hgt := 0.03 + 0.04 * (1.0 - absf(a) / 0.9)
				var b1 := c0 + Vector3(sin(a - 0.12) * HAT_RX * 1.05, 0.034, cos(a - 0.12) * HAT_RZ * 1.03)
				var b2 := c0 + Vector3(sin(a + 0.12) * HAT_RX * 1.05, 0.034, cos(a + 0.12) * HAT_RZ * 1.03)
				var tp := c0 + Vector3(sin(a) * HAT_RX * 1.07, 0.034 + hgt, cos(a) * HAT_RZ * 1.05)
				g.tri(b1, tp, b2, tc)
				g.tri(b2, tp, b1, tc.darkened(0.2))
				g.sphere(tp, Vector3(0.006, 0.006, 0.006), Color("ffffff"), 6)
			g.sphere(c0 + Vector3(0, 0.058, HAT_RZ * 1.06), Vector3(0.016, 0.02, 0.01), Color("ff4d8d"), 8)
		"hardhat":
			var hc2 := Color("f0c020")
			g.lathe([Vector2(1.06, -0.006), Vector2(1.05, 0.04), Vector2(0.92, 0.09), Vector2(0.55, 0.118), Vector2(0.0, 0.124)], c0, HAT_RX, HAT_RZ, hc2, 28)
			g.lathe([Vector2(1.06, -0.004), Vector2(1.32, -0.014)], c0, HAT_RX, HAT_RZ, hc2.darkened(0.08), 32, false, func(p: Vector3, a: float) -> Vector3:
				var rr := Vector2(p.x / HAT_RX, p.z / HAT_RZ).length()
				var f := maxf(cos(a), 0.0)
				var sc := (1.06 + (rr - 1.06) * (0.4 + 1.6 * f * f)) / maxf(rr, 0.001)
				return Vector3(p.x * sc, p.y, p.z * sc))
			var rdg := []
			for i in 9:
				var t := lerpf(-1.1, 1.1, float(i) / 8.0)
				rdg.append(c0 + Vector3(0, cos(t) * 0.125, sin(t) * HAT_RZ * 1.02))
			g.tube(rdg, 0.012, hc2.lightened(0.15), false, 6)
		"jester":
			var jc := [Color("2a9a4a"), Color("c81a2a"), Color("2a6ae8")]
			g.lathe(_dome(0.085), c0, HAT_RX, HAT_RZ, Color("c81a2a"), 28)
			g.lathe([Vector2(1.07, -0.018), Vector2(1.07, 0.012)], c0, HAT_RX, HAT_RZ, Color("ffd84a"), 28)
			for k in 3:
				var a: float = [-PI * 0.5, PI, PI * 0.5][k]
				var dir := Vector3(sin(a), 0, cos(a))
				var hp := []
				for i in 9:
					var t := float(i) / 8.0
					hp.append(c0 + Vector3(0, 0.06, 0) + dir * (0.04 + t * 0.13) + Vector3(0, 0.1 * sin(t * PI * 0.85) - 0.03 * t + (0.04 * t if k == 1 else 0.0), 0))
				_chain(g, hp, 0.03, 0.01, jc[k])
				g.sphere(hp[hp.size() - 1] + Vector3(0, -0.012, 0), Vector3(0.016, 0.016, 0.016), Color("ffd84a"), 8)
		"magnate":
			var mk := Color("3a1a5a")
			g.lathe([Vector2(1.0, -0.004), Vector2(1.6, -0.004), Vector2(1.68, 0.01)], c0, HAT_RX, HAT_RZ, mk, 32, false)
			g.lathe([Vector2(1.68, 0.004), Vector2(1.6, -0.01), Vector2(1.0, -0.01)], c0, HAT_RX, HAT_RZ, mk, 32, false)
			g.lathe([Vector2(1.02, -0.004), Vector2(1.0, 0.05), Vector2(1.06, 0.22), Vector2(1.08, 0.23), Vector2(0.0, 0.23)], c0, HAT_RX, HAT_RZ, mk, 28)
			g.lathe([Vector2(1.035, 0.0), Vector2(1.02, 0.05)], c0, HAT_RX, HAT_RZ, Color("ffd84a"), 28)
			g.sphere(c0 + Vector3(0, 0.025, HAT_RZ * 1.05), Vector3(0.022, 0.022, 0.006), Color("ffe680"), 10)
			g.box(c0 + Vector3(0, 0.025, HAT_RZ * 1.05 + 0.006), Vector3(0.004, 0.026, 0.002), Color("8a6a10"))
		"unicorn":
			var hp := []
			for i in 9:
				var t := float(i) / 8.0
				hp.append(c0 + Vector3(0, 0.06 + t * 0.15, 0.075 + t * 0.06))
			_chain(g, hp, 0.022, 0.004, Color("fff4d6"), Color("ffd84a"))
			for sd in [-1.0, 1.0]:
				g.sphere(c0 + Vector3(0.062 * sd, 0.075, 0.0), Vector3(0.016, 0.03, 0.01), Color("ffb0d8"), 8)
		"empire":
			var gc2 := Color("ffd84a")
			g.lathe([Vector2(0.97, 0.02), Vector2(0.92, 0.09), Vector2(0.5, 0.13), Vector2(0.0, 0.135)], c0, HAT_RX, HAT_RZ, Color("a01a3a"), 24)
			g.lathe([Vector2(1.03, -0.006), Vector2(1.03, 0.06)], c0, HAT_RX, HAT_RZ, gc2, 28)
			g.lathe([Vector2(0.99, 0.06), Vector2(0.99, -0.006)], c0, HAT_RX, HAT_RZ, gc2.darkened(0.3), 28)
			g.lathe([Vector2(1.07, -0.01), Vector2(1.07, 0.008)], c0, HAT_RX, HAT_RZ, Color("f4f0e8"), 28)
			for k in 8:
				var a := TAU * k / 8.0
				var hgt := 0.1 if k % 2 == 0 else 0.072
				var p1 := c0 + Vector3(sin(a - TAU / 16.0) * HAT_RX * 1.03, 0.058, cos(a - TAU / 16.0) * HAT_RZ * 1.03)
				var p2 := c0 + Vector3(sin(a + TAU / 16.0) * HAT_RX * 1.03, 0.058, cos(a + TAU / 16.0) * HAT_RZ * 1.03)
				var tp := c0 + Vector3(sin(a) * HAT_RX * 1.07, 0.058 + hgt, cos(a) * HAT_RZ * 1.07)
				g.tri(p1, tp, p2, gc2)
				g.tri(p2, tp, p1, gc2.darkened(0.25))
				g.sphere(tp, Vector3(0.009, 0.009, 0.009), Color("f4f0e8"), 6)
				var gem: Color = [Color("e8283a"), Color("2a6ae8"), Color("2ae86a"), Color("c070ff")][k % 4]
				g.sphere(c0 + Vector3(sin(a) * HAT_RX * 1.045, 0.028, cos(a) * HAT_RZ * 1.045), Vector3(0.01, 0.01, 0.01), gem, 8)
			var top := c0 + Vector3(0, 0.15, 0)
			g.sphere(top, Vector3(0.02, 0.02, 0.02), gc2, 10)
			g.box(top + Vector3(0, 0.04, 0), Vector3(0.008, 0.045, 0.008), gc2)
			g.box(top + Vector3(0, 0.046, 0), Vector3(0.03, 0.008, 0.008), gc2)
		"guard":
			var gcol := Color("1a2a4a")
			g.lathe([Vector2(1.0, -0.004), Vector2(1.03, 0.045), Vector2(1.25, 0.07), Vector2(1.2, 0.082), Vector2(0.0, 0.085)], c0, HAT_RX, HAT_RZ, gcol, 28)
			var n2 := 10
			for k in n2:
				var a0 := lerpf(-1.0, 1.0, float(k) / n2)
				var a1 := lerpf(-1.0, 1.0, float(k + 1) / n2)
				var p0 := c0 + Vector3(sin(a0) * HAT_RX, -0.004, cos(a0) * HAT_RZ)
				var p1 := c0 + Vector3(sin(a1) * HAT_RX, -0.004, cos(a1) * HAT_RZ)
				var q0 := c0 + Vector3(sin(a0) * HAT_RX * 1.2, -0.02, cos(a0) * HAT_RZ + 0.055 * cos(a0))
				var q1 := c0 + Vector3(sin(a1) * HAT_RX * 1.2, -0.02, cos(a1) * HAT_RZ + 0.055 * cos(a1))
				g.quad(p0, p1, q1, q0, Color("101010"))
			g.box(c0 + Vector3(0, 0.03, HAT_RZ * 1.03), Vector3(0.03, 0.03, 0.006), Color("ffd84a"))
	return g.mesh(_amat())


static func _glasses_mesh(dark: bool) -> ArrayMesh:
	var key := "glasses_dark" if dark else "glasses"
	if _acc_cache.has(key):
		return _acc_cache[key]
	var g := Acc.new()
	var fc := Color("141414") if dark else Color("3a2a1a")
	var lens := []
	var zf := 0.116
	for s in [-1.0, 1.0]:
		var cx: float = 0.032 * s
		var pts := []
		for k in 16:
			var a := TAU * k / 16.0
			var rx := 0.0155 if not dark else 0.0175
			var ry := 0.0115 if not dark else 0.0145
			var yy := sin(a) * ry - (0.003 * maxf(-sin(a), 0.0) if dark else 0.0)
			pts.append(Vector3(cx + cos(a) * rx, 1.5925 + yy, zf - 0.004 * absf(cos(a)) * (1.0 if cos(a) * s > 0 else 0.3)))
		g.tube(pts, 0.0016, fc, true, 5)
		lens.append(pts)

		var ox: float = cx + (0.0175 if not dark else 0.0195) * s
		g.tube([Vector3(ox, 1.596, zf - 0.004), Vector3(0.079 * s, 1.598, 0.07), Vector3(0.083 * s, 1.594, -0.005), Vector3(0.078 * s, 1.575, -0.025)], 0.0014, fc, false, 4)
	g.tube([Vector3(-0.0165, 1.597, zf + 0.001), Vector3(0, 1.6, zf + 0.004), Vector3(0.0165, 1.597, zf + 0.001)], 0.0015, fc, false, 4)
	var m := g.mesh(_amat())

	var lg := Acc.new()
	var lc := Color(0.05, 0.05, 0.07, 0.88) if dark else Color(0.8, 0.9, 1.0, 0.18)
	for pts in lens:
		var ctr := Vector3.ZERO
		for p in pts:
			ctr += p
		ctr /= pts.size()
		for k in pts.size():
			lg.tri(ctr, pts[k], pts[(k + 1) % pts.size()], lc)
	if _lens_mat == null:
		_lens_mat = StandardMaterial3D.new()
		_lens_mat.vertex_color_use_as_albedo = true
		_lens_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_lens_mat.roughness = 0.05
		_lens_mat.metallic_specular = 1.0
		_lens_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = lg.v
	arr[Mesh.ARRAY_NORMAL] = lg.n
	arr[Mesh.ARRAY_COLOR] = lg.c
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	m.surface_set_material(1, _lens_mat)
	_acc_cache[key] = m
	return m



func tag_height() -> float:
	match hat_name(look):
		"wizard":
			return 2.36
		"tophat", "chef", "magnate":
			return 2.26
		"party", "unicorn", "empire", "duck", "propeller", "viking", "jester":
			return 2.17
		"cowboy", "crown", "sombrero", "bucket", "ushanka", "halo", "pirate", "hardhat":
			return 2.12
	return 2.0


func add_tag(text: String, col: Color) -> void:
	if tag == null:
		tag = Label3D.new()
		tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		tag.font = Assets.font_title
		tag.font_size = 32
		tag.pixel_size = 0.006
		tag.outline_size = 8
		tag.outline_modulate = Color(0, 0, 0, 0.85)
		tag.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		tag.no_depth_test = false
		tag.position = Vector3(0, tag_height(), 0)
		tag.fixed_size = false
		tag.visibility_range_begin = 1.8
		add_child(tag)
	tag.text = text
	tag.modulate = col.lightened(0.15)




func set_face(fname: String, seconds: float = 2.0) -> void:
	_face_override = fname
	_face_timer = seconds
	_set_expr(fname)


func _set_expr(fname: String, instant := false) -> void:
	var e: Dictionary = EXPR.get(fname, EXPR.smile)
	if fname == "shades" or fname == "mustache" or fname == "lady":
		e = EXPR.smile
	elif fname == "beard" or fname == "glasses":
		e = {"mouth_curve": 0.3}
	for k in EXPR_KEYS:
		_expr_tgt[k] = float(e.get(k, EXPR_DEF.get(k, 0.0)))
	_expr_tgt["gaze_y"] = float(e.get("gaze_y", 0.0))
	if instant:
		for k in _expr_tgt:
			_expr_cur[k] = _expr_tgt[k]
			if k != "gaze_y":
				_param(k, _expr_cur[k])


func set_hat_visible(v: bool) -> void:
	if _hat_node:
		_hat_node.visible = v


func _update_face(delta: float) -> void:
	if _mats.is_empty():
		return
	var k := clampf(delta * 9.0, 0.0, 1.0)
	var blink := _blinking > 0.0
	for key in EXPR_KEYS:
		var tgt: float = _expr_tgt.get(key, 0.0)
		if blink and (key == "eye_l" or key == "eye_r"):
			tgt = 0.0
		var cur: float = _expr_cur.get(key, tgt)
		var kk := 1.0 if blink and (key == "eye_l" or key == "eye_r") else k
		var nv := lerpf(cur, tgt, kk)
		if absf(nv - cur) > 0.0015 or not _expr_cur.has(key):
			_expr_cur[key] = nv
			_param(key, nv)
		elif cur != tgt and absf(nv - tgt) < 0.0015:
			_expr_cur[key] = tgt
			_param(key, tgt)

	_gaze_t -= delta
	if _gaze_t <= 0.0:
		_gaze_t = randf_range(0.8, 3.2)
		_gaze = Vector2(randf_range(-0.7, 0.7), randf_range(-0.35, 0.35)) if randf() < 0.7 else Vector2.ZERO
	var g := _gaze + Vector2(0, float(_expr_tgt.get("gaze_y", 0.0)))
	var gc: Vector2 = _expr_cur.get("gaze", Vector2.ZERO)
	var gn := gc.lerp(g, clampf(delta * 18.0, 0.0, 1.0))
	if gn.distance_to(gc) > 0.003:
		_expr_cur["gaze"] = gn
		_param("gaze", gn)


func _process(delta: float) -> void:
	if _parts.is_empty():
		return
	_t += delta
	if _prop != null and is_instance_valid(_prop):
		_prop.rotate_y(delta * 14.0)
	if _face_timer > 0.0:
		_face_timer -= delta
		if _face_timer <= 0.0:
			_face_override = ""
			_set_expr(_base_face)
	if _blinking > 0.0:
		_blinking -= delta
	elif anim != "sleep":
		_blink -= delta
		if _blink <= 0.0:
			_blinking = 0.12
			_blink = randf_range(2.5, 6.0)
	if anim == "sleep" and _face_override == "":
		_expr_tgt["eye_l"] = 0.0
		_expr_tgt["eye_r"] = 0.0
	_update_face(delta)
	_animate(delta)
	_tick_rod()


var _rod_rig: Node3D = null


func _tick_rod() -> void:
	# удочка в руках: создаётся сама, когда персонаж рыбачит (игроки, марионетки, боты)
	var want := anim == "fish" and not has_meta("own_rig")
	if _rod_rig != null and not is_instance_valid(_rod_rig):
		_rod_rig = null
	if want and _rod_rig == null:
		_rod_rig = Node3D.new()
		_rod_rig.set_script(load("res://scripts/kit/fish_rig.gd"))
		_rod_rig.set("ch", self)
		_rod_rig.set("gold", bool(get_meta("gold_rod", false)))
		add_child(_rod_rig)
	elif not want and _rod_rig != null:
		if is_instance_valid(_rod_rig):
			_rod_rig.queue_free()
		_rod_rig = null








func _animate(delta: float) -> void:
	var t := _t
	var leg := [Vector3.ZERO, Vector3.ZERO]
	var knee := [0.04, 0.04]
	var sh := [Vector3(0, 0, 0.07), Vector3(0, 0, 0.07)]
	var el := [Vector3(-0.14, 0, 0), Vector3(-0.14, 0, 0)]
	var rig_y := 0.0
	var rig_rot := Vector3.ZERO
	var torso_r := Vector3.ZERO
	var neck_r := Vector3(-head_pitch * 0.6, 0, 0)
	var k := clampf(delta * 12.0, 0.0, 1.0)
	if anim != _last_anim:
		_last_anim = anim
		_at = 0.0
	_at += delta
	var at := _at
	match anim:
		"walk", "run":
			var run := anim == "run"
			var spd := maxf(speed, 0.5)
			_phase += delta * spd * (2.2 if run else 2.6)
			var ph := _phase
			var amp := clampf(spd / 5.0, 0.25, 1.0 if run else 0.8)
			leg[0] = Vector3(sin(ph) * amp * 0.85, 0, 0.02)
			leg[1] = Vector3(-sin(ph) * amp * 0.85, 0, 0.02)
			knee[0] = amp * (0.15 + (1.5 if run else 1.1) * maxf(0.0, -cos(ph)))
			knee[1] = amp * (0.15 + (1.5 if run else 1.1) * maxf(0.0, cos(ph)))
			sh[0] = Vector3(-sin(ph) * amp * 0.7, 0, 0.08)
			sh[1] = Vector3(sin(ph) * amp * 0.7, 0, 0.08)
			var eb := -1.3 if run else -0.3
			el[0] = Vector3(eb - maxf(0.0, -sin(ph)) * 0.3, 0, 0)
			el[1] = Vector3(eb - maxf(0.0, sin(ph)) * 0.3, 0, 0)
			rig_y = cos(ph * 2.0) * (0.035 if run else 0.02) + 0.01
			torso_r = Vector3((0.2 if run else 0.04) * amp, sin(ph) * 0.08 * amp, 0)
			neck_r.x -= torso_r.x * 0.6
		"sit":
			leg[0] = Vector3(-1.5, 0, 0.06)
			leg[1] = Vector3(-1.5, 0, 0.06)
			knee = [1.5, 1.5]
			rig_y = _sit_y
			sh[0] = Vector3(-0.35, 0, 0.04)
			sh[1] = Vector3(-0.35, 0, 0.04)
			el = [Vector3(-0.85, 0, 0), Vector3(-0.85, 0, 0)]
		"deal":
			sh[0] = Vector3(-0.7 + sin(t * 3.0) * 0.2, 0, -0.12)
			sh[1] = Vector3(-0.8 + cos(t * 2.6) * 0.25, 0, -0.12)
			el = [Vector3(-0.6 + sin(t * 3.0) * 0.15, 0, 0), Vector3(-0.5, 0, 0)]
			torso_r.x = 0.08
			neck_r.x = 0.25
		"bar":
			sh[0] = Vector3(-0.6, 0, -0.1)
			el[0] = Vector3(-0.6, 0, 0)
			sh[1] = Vector3(-0.5 + sin(t * 2.0) * 0.35, 0, -0.2 + cos(t * 2.0) * 0.2)
			el[1] = Vector3(-0.7, 0, 0)
			neck_r.x = 0.1
		"wave":
			sh[1] = Vector3(-0.15, 0, 1.6)
			el[1] = Vector3(0, 0, 1.3 + sin(t * 9.0) * 0.4)
			neck_r.y = 0.1
		"cheer":
			var j := absf(sin(t * 8.0))
			sh[0] = Vector3(-0.1, 0, 2.6 + sin(t * 10.0) * 0.15)
			sh[1] = Vector3(-0.1, 0, 2.6 - sin(t * 10.0) * 0.15)
			el = [Vector3(0, 0, 0.25), Vector3(0, 0, 0.25)]
			rig_y = j * 0.12
			knee = [0.25 * (1.0 - j), 0.25 * (1.0 - j)]
			leg = [Vector3(-0.12 * (1.0 - j), 0, 0), Vector3(-0.12 * (1.0 - j), 0, 0)]
		"dance":
			var s6 := sin(t * 6.0)
			sh[0] = Vector3(s6 * 0.6, 0, 1.0 + s6 * 0.5)
			sh[1] = Vector3(-s6 * 0.6, 0, 1.0 - s6 * 0.5)
			el = [Vector3(-0.9, 0, 0), Vector3(-0.9, 0, 0)]
			leg[0] = Vector3(s6 * 0.3, 0, 0.05)
			leg[1] = Vector3(-s6 * 0.3, 0, 0.05)
			knee = [0.3 + maxf(0.0, s6) * 0.4, 0.3 + maxf(0.0, -s6) * 0.4]
			rig_y = absf(s6) * 0.07 - 0.02
			rig_rot.y = sin(t * 3.0) * 0.3
			torso_r.z = s6 * 0.06
		"sit_drink":
			leg[0] = Vector3(-1.5, 0, 0.06)
			leg[1] = Vector3(-1.5, 0, 0.06)
			knee = [1.5, 1.5]
			rig_y = _sit_y
			sh[0] = Vector3(-0.35, 0, 0.04)
			el[0] = Vector3(-0.85, 0, 0)
			var lf := drink_lift
			if lf < 0.0:
				lf = smoothstep(0.55, 0.95, sin(t * 0.8))
			sh[1] = Vector3(-0.5 - lf * 0.75, 0, -0.08 - lf * 0.22)
			el[1] = Vector3(-1.05 - lf * 0.95, 0, 0)
			neck_r.x += -0.12 * lf
		"drink":
			sh[1] = Vector3(-1.25, 0, -0.3)
			el[1] = Vector3(-1.9, 0, 0)
			neck_r.x = -0.25
		"piano":
			sh[0] = Vector3(-0.95, 0, -0.08 + sin(t * 7.0) * 0.05)
			sh[1] = Vector3(-0.95, 0, -0.08 + cos(t * 6.0) * 0.05)
			el = [Vector3(-0.55 + sin(t * 11.0) * 0.06, 0, 0), Vector3(-0.55 + cos(t * 9.0) * 0.06, 0, 0)]
			leg[0] = Vector3(-1.5, 0, 0.05)
			leg[1] = Vector3(-1.5, 0, 0.05)
			knee = [1.5, 1.5]
			rig_y = _sit_y
			neck_r.x = 0.15 + sin(t * 2.0) * 0.05
		"sleep":
			rig_rot.x = -PI / 2
			sh = [Vector3(0, 0, 0.12), Vector3(0, 0, 0.12)]
			knee = [0.1, 0.1]
		"guard":
			sh[0] = Vector3(-0.35, 0, -0.3)
			sh[1] = Vector3(-0.35, 0, -0.3)
			el = [Vector3(-0.75, 0, 0), Vector3(-0.75, 0, 0)]
			leg = [Vector3(0, 0, 0.07), Vector3(0, 0, 0.07)]
			neck_r.y = sin(t * 0.3) * 0.35
		"push":
			k = clampf(delta * 22.0, 0.0, 1.0)
			sh[0] = Vector3(-1.5, 0, -0.12)
			sh[1] = Vector3(-1.5, 0, -0.12)
			el = [Vector3(-0.12, 0, 0), Vector3(-0.12, 0, 0)]
			torso_r.x = 0.3
			leg[0] = Vector3(-0.55, 0, 0)
			leg[1] = Vector3(0.35, 0, 0)
			knee = [0.5, 0.15]
			neck_r.x = -0.15
			rig_y = -0.03
		"stumble":
			k = clampf(delta * 16.0, 0.0, 1.0)
			torso_r = Vector3(-0.3 + sin(t * 12.0) * 0.1, 0, sin(t * 7.0) * 0.12)
			sh[0] = Vector3(-0.5 + cos(t * 13.0) * 0.4, 0, 1.3 + sin(t * 15.0) * 0.5)
			sh[1] = Vector3(-0.3 + sin(t * 11.0) * 0.4, 0, 1.3 + cos(t * 14.0) * 0.5)
			el = [Vector3(-0.4, 0, 0.3), Vector3(-0.4, 0, 0.3)]
			leg[0] = Vector3(0.3, 0, 0.1)
			leg[1] = Vector3(-0.35, 0, 0.1)
			knee = [0.4, 0.2]
			rig_rot.z = sin(t * 9.0) * 0.12
			neck_r.x = -0.2
		"floss":
			var fs := sin(t * 6.5)
			sh[0] = Vector3(0.4 * fs, 0, 0.3 - 0.55 * fs)
			sh[1] = Vector3(-0.4 * fs, 0, 0.3 + 0.55 * fs)
			el = [Vector3(-0.06, 0, 0), Vector3(-0.06, 0, 0)]
			torso_r.z = -0.1 * fs
			rig_rot.z = 0.05 * fs
			rig_rot.y = -0.12 * fs
			leg = [Vector3(0, 0, 0.06 + 0.05 * fs), Vector3(0, 0, 0.06 - 0.05 * fs)]
			knee = [0.12 + 0.12 * maxf(0.0, fs), 0.12 + 0.12 * maxf(0.0, -fs)]
		"riverdance":
			var rp := t * 10.5
			var ra := maxf(0.0, sin(rp))
			var rb := maxf(0.0, -sin(rp))
			sh = [Vector3(0, 0, 0.02), Vector3(0, 0, 0.02)]
			el = [Vector3(0, 0, 0), Vector3(0, 0, 0)]
			leg[0] = Vector3(-0.75 * ra + 0.15 * rb, 0, 0.0)
			leg[1] = Vector3(-0.75 * rb + 0.15 * ra, 0, 0.0)
			knee = [0.1 + 0.8 * ra, 0.1 + 0.8 * rb]
			rig_y = absf(sin(rp)) * 0.05
			neck_r.x = -0.1
		"hype":
			var hp := t * 7.0
			sh[0] = Vector3(-0.25, 0, 1.35)
			sh[1] = Vector3(-0.25, 0, 1.35)
			el[0] = Vector3(-0.2, 0, 0.9 + 0.7 * maxf(0.0, sin(hp)))
			el[1] = Vector3(-0.2, 0, 0.9 + 0.7 * maxf(0.0, -sin(hp)))
			rig_y = absf(sin(hp)) * 0.06 - 0.03
			knee = [0.3 - absf(sin(hp)) * 0.2, 0.3 - absf(sin(hp)) * 0.2]
			leg = [Vector3(-0.15, 0, 0.1), Vector3(-0.15, 0, 0.1)]
			rig_rot.y = sin(t * 2.2) * 0.5
			neck_r.x = -0.15
		"bow":
			torso_r.x = 0.95
			neck_r.x = 0.3
			sh = [Vector3(-0.3, 0, 0.04), Vector3(-0.3, 0, 0.04)]
			el = [Vector3(-0.1, 0, 0), Vector3(-0.1, 0, 0)]
		"kneel":
			leg = [Vector3(0.05, 0, 0.08), Vector3(0.05, 0, 0.08)]
			knee = [1.55, 1.55]
			rig_y = -0.43
			torso_r.x = 0.35
			neck_r.x = 0.5
			sh = [Vector3(-0.35, 0, 0.05), Vector3(-0.35, 0, 0.05)]
			el = [Vector3(-0.3, 0, 0), Vector3(-0.3, 0, 0)]
		"chicken":
			var cf := absf(sin(t * 10.0))
			sh = [Vector3(0.15, 0, 0.5 + 0.5 * cf), Vector3(0.15, 0, 0.5 + 0.5 * cf)]
			el = [Vector3(-2.3, 0, 0), Vector3(-2.3, 0, 0)]
			torso_r.x = 0.3 + 0.1 * sin(t * 5.0)
			neck_r.x = -0.35 + 0.45 * maxf(0.0, sin(t * 10.0))
			leg = [Vector3(-0.4, 0, 0.12), Vector3(-0.4, 0, 0.12)]
			knee = [0.55, 0.55]
			rig_y = -0.07 + absf(sin(t * 5.0)) * 0.04
			rig_rot.y = sin(t * 2.0) * 0.4
		"mop":
			var ms := sin(t * 3.0)
			sh[0] = Vector3(-0.85, 0, -0.05 + 0.2 * ms)
			sh[1] = Vector3(-0.6, 0, -0.1 - 0.2 * ms)
			el = [Vector3(-0.45, 0, 0), Vector3(-0.35, 0, 0)]
			torso_r = Vector3(0.28, ms * 0.25, 0)
			neck_r.x = 0.35
			knee = [0.15, 0.15]
		"point":
			sh[1] = Vector3(-1.5, 0, 0.1)
			el[1] = Vector3(-0.05, 0, 0)
			sh[0] = Vector3(-0.6, 0, 0.25)
			el[0] = Vector3(-1.5, 0, 0)
			torso_r.x = -0.12 + sin(t * 16.0) * 0.05
			neck_r.x = -0.1
		"laugh":
			sh = [Vector3(-0.55, 0, 0.3), Vector3(-0.55, 0, 0.3)]
			el = [Vector3(-1.5, 0, 0), Vector3(-1.5, 0, 0)]
			torso_r.x = -0.2 + sin(t * 15.0) * 0.09
			neck_r.x = -0.35
			rig_y = sin(t * 15.0) * 0.012
		"type":
			torso_r.x = 0.18
			sh = [Vector3(-0.95, 0, -0.05), Vector3(-0.95, 0, -0.05)]
			el = [Vector3(-0.55 + sin(t * 13.0) * 0.06, 0, 0), Vector3(-0.55 + cos(t * 11.0) * 0.06, 0, 0)]
			neck_r.x = 0.22
		"sad":
			neck_r.x = 0.55
			torso_r.x = 0.2
			sh = [Vector3(0.05, 0, 0.0), Vector3(0.05, 0, 0.0)]
			el = [Vector3(-0.05, 0, 0), Vector3(-0.05, 0, 0)]
			knee = [0.1, 0.1]
		"serve":
			sh[1] = Vector3(-0.55, 0, 0.55)
			el[1] = Vector3(-1.6, 0, 0)
			sh[0] = Vector3(0.0, 0, 0.07)
			el[0] = Vector3(-0.2, 0, 0)
			neck_r.x = -0.05
		"clap":
			var cl := 0.12 * sin(t * 18.0)
			sh = [Vector3(-1.05, 0, -0.32 + cl), Vector3(-1.05, 0, -0.32 + cl)]
			el = [Vector3(-0.7, 0, 0), Vector3(-0.7, 0, 0)]
			rig_y = absf(sin(t * 9.0)) * 0.02
		"cry":
			sh = [Vector3(-1.15, 0, -0.15), Vector3(-1.15, 0, -0.15)]
			el = [Vector3(-2.2, 0, 0), Vector3(-2.2, 0, 0)]
			neck_r.x = 0.4 + sin(t * 9.0) * 0.07
			torso_r.x = 0.2 + sin(t * 9.0) * 0.05
			knee = [0.1, 0.1]
		"shiver":
			sh = [Vector3(-0.9, 0, -0.38), Vector3(-0.9, 0, -0.38)]
			el = [Vector3(-1.95, 0, 0), Vector3(-1.95, 0, 0)]
			torso_r = Vector3(0.15, sin(t * 43.0) * 0.05, sin(t * 37.0) * 0.03)
			rig_rot.y = sin(t * 51.0) * 0.03
			knee = [0.15, 0.15]
			neck_r.x = 0.2
		"hold_sign":
			sh = [Vector3(-1.0, 0, 0.12), Vector3(-1.0, 0, 0.12)]
			el = [Vector3(-1.0, 0, 0), Vector3(-1.0, 0, 0)]
			neck_r.x = 0.15
		"lift":
			sh = [Vector3(-0.35, 0, 2.5), Vector3(-0.35, 0, 2.5)]
			el = [Vector3(0, 0, 0.35), Vector3(0, 0, 0.35)]
			neck_r.x = -0.2
		"sit_ground":
			leg = [Vector3(-1.45, 0, 0.12), Vector3(-1.45, 0, 0.12)]
			knee = [0.2, 0.2]
			rig_y = -0.78
			sh = [Vector3(0.7, 0, 0.35), Vector3(0.7, 0, 0.35)]
			el = [Vector3(0, 0, 0), Vector3(0, 0, 0)]
			torso_r.x = -0.12
			neck_r.x = 0.1
		"grovel":
			var gv := maxf(0.0, sin(t * 2.4))
			leg = [Vector3(0.05, 0, 0.08), Vector3(0.05, 0, 0.08)]
			knee = [1.55, 1.55]
			rig_y = -0.43
			torso_r.x = 0.55 + 0.7 * gv
			neck_r.x = 0.1 - 0.25 * gv
			sh = [Vector3(-1.2 - 0.6 * gv, 0, 0.22), Vector3(-1.2 - 0.6 * gv, 0, 0.22)]
			el = [Vector3(-0.15, 0, 0), Vector3(-0.15, 0, 0)]
		"peck":
			var pk := maxf(0.0, sin(t * 8.0))
			sh = [Vector3(0.15, 0, 0.6 + 0.25 * pk), Vector3(0.15, 0, 0.6 + 0.25 * pk)]
			el = [Vector3(-2.3, 0, 0), Vector3(-2.3, 0, 0)]
			torso_r.x = 0.35 + 0.6 * pk
			neck_r.x = 0.15 + 0.35 * pk
			leg = [Vector3(-0.3, 0, 0.12), Vector3(-0.3, 0, 0.12)]
			knee = [0.45, 0.45]
			rig_y = -0.06
		"flail":
			sh[0] = Vector3(-0.6 + sin(t * 11.0) * 0.7, 0, 1.8 + cos(t * 9.0) * 0.6)
			sh[1] = Vector3(-0.6 + cos(t * 10.0) * 0.7, 0, 1.8 + sin(t * 8.0) * 0.6)
			el = [Vector3(-0.5, 0, 0.4), Vector3(-0.5, 0, 0.4)]
			leg = [Vector3(-0.9 + sin(t * 12.0) * 0.4, 0, 0.1), Vector3(-0.9 - sin(t * 12.0) * 0.4, 0, 0.1)]
			knee = [0.6, 0.6]
			torso_r.x = -0.25
			neck_r.x = -0.3
		"punch":
			# серия джебов: правая бьёт, левая — в блоке у лица
			k = clampf(delta * 26.0, 0.0, 1.0)
			var cyc := fmod(at, 0.42) / 0.42
			var ext := sin(clampf(cyc * 2.2, 0.0, 1.0) * PI)
			var right := int(at / 0.42) % 2 == 0
			var a_i := 1 if right else 0
			var g_i := 0 if right else 1
			sh[a_i] = Vector3(-0.35 - 1.25 * ext, 0, 0.18 - 0.1 * ext)
			el[a_i] = Vector3(-1.7 + 1.62 * ext, 0, 0)
			sh[g_i] = Vector3(-0.95, 0, 0.32)
			el[g_i] = Vector3(-2.0, 0, 0)
			rig_rot.y = (0.28 if right else -0.28) * ext
			torso_r = Vector3(0.18 + 0.12 * ext, (0.2 if right else -0.2) * ext, 0)
			leg[0] = Vector3(-0.3, 0, 0.08)
			leg[1] = Vector3(0.25, 0, 0.08)
			knee = [0.35, 0.25]
			rig_y = -0.04
			neck_r.x = 0.05
		"throw":
			# замах из-за головы и бросок
			k = clampf(delta * 24.0, 0.0, 1.0)
			var w := clampf(at / 0.16, 0.0, 1.0)
			var f := clampf((at - 0.16) / 0.18, 0.0, 1.0)
			sh[1] = Vector3(lerpf(0.5 * w, -1.7, f), 0, lerpf(2.5 * w + 0.07 * (1.0 - w), 0.3, f))
			el[1] = Vector3(lerpf(-1.5 * w, -0.08, f), 0, 0)
			sh[0] = Vector3(lerpf(-0.9 * w, 0.3, f), 0, 0.3)
			el[0] = Vector3(-0.5, 0, 0)
			torso_r = Vector3(lerpf(-0.2 * w, 0.4, f), lerpf(-0.35 * w, 0.3, f), 0)
			leg[0] = Vector3(-0.45, 0, 0.06)
			leg[1] = Vector3(0.3, 0, 0.06)
			knee = [0.3, 0.15]
		"ko":
			# нокаут: звёздочкой на полу, голова кругом
			k = clampf(delta * 9.0, 0.0, 1.0)
			rig_rot.x = -PI / 2.0
			rig_y = 0.13
			sh = [Vector3(-0.15, 0, 1.35), Vector3(-0.1, 0, 1.25)]
			el = [Vector3(-0.35, 0, 0), Vector3(-0.5, 0, 0)]
			leg = [Vector3(-0.05, 0, 0.32), Vector3(0.05, 0, 0.28)]
			knee = [0.25, 0.1]
			neck_r = Vector3(0.1, sin(t * 2.2) * 0.35, 0)
		"slip":
			# банан: ноги вверх — и на спину
			k = clampf(delta * 20.0, 0.0, 1.0)
			var fall := smoothstep(0.0, 0.32, at)
			rig_rot.x = -PI / 2.0 * fall
			rig_y = 0.55 * sin(fall * PI) * (1.0 - fall * 0.5) + 0.13 * fall
			leg[0] = Vector3(-1.5 * (1.0 - fall * 0.4), 0, 0.1)
			leg[1] = Vector3(-1.1 * (1.0 - fall * 0.4), 0, 0.1)
			knee = [0.2, 0.5]
			sh = [Vector3(-0.4, 0, 2.2 - fall * 0.9), Vector3(-0.5, 0, 2.3 - fall * 0.9)]
			el = [Vector3(-0.3, 0, 0.3), Vector3(-0.3, 0, 0.3)]
			neck_r.x = -0.4
		"repair":
			# на корточках, молоток в правой
			var hm := sin(t * 11.0)
			leg = [Vector3(-1.2, 0, 0.18), Vector3(-1.2, 0, 0.18)]
			knee = [2.0, 2.0]
			rig_y = -0.42
			torso_r.x = 0.45
			sh[1] = Vector3(-1.25 + hm * 0.45, 0, 0.15)
			el[1] = Vector3(-0.95 - hm * 0.45, 0, 0)
			sh[0] = Vector3(-1.05, 0, 0.12)
			el[0] = Vector3(-0.45, 0, 0)
			neck_r.x = 0.35
		"collect":
			# выгребает выручку из лотка
			var sc := sin(t * 7.0)
			torso_r.x = 0.42
			sh[0] = Vector3(-1.15 + sc * 0.18, 0, 0.12)
			sh[1] = Vector3(-1.15 - sc * 0.18, 0, 0.12)
			el = [Vector3(-0.55 - sc * 0.2, 0, 0), Vector3(-0.55 + sc * 0.2, 0, 0)]
			leg = [Vector3(-0.15, 0, 0.08), Vector3(-0.15, 0, 0.08)]
			knee = [0.35, 0.35]
			rig_y = -0.05
			neck_r.x = 0.3
		"steal":
			# пригнувшись, быстро-быстро, озираясь
			var q14 := sin(t * 15.0)
			leg = [Vector3(-0.6, 0, 0.14), Vector3(-0.6, 0, 0.14)]
			knee = [1.15, 1.15]
			rig_y = -0.2
			torso_r.x = 0.5
			sh[0] = Vector3(-1.15 + q14 * 0.12, 0, 0.1)
			sh[1] = Vector3(-1.15 - q14 * 0.12, 0, 0.1)
			el = [Vector3(-0.8 + q14 * 0.25, 0, 0), Vector3(-0.8 - q14 * 0.25, 0, 0)]
			neck_r = Vector3(-0.1, sin(t * 3.1) * 0.7, 0)
		"carry":
			sh = [Vector3(-0.95, 0, 0.18), Vector3(-0.95, 0, 0.18)]
			el = [Vector3(-1.05, 0, 0), Vector3(-1.05, 0, 0)]
			torso_r.x = -0.08
			if speed > 0.4:
				_phase += delta * speed * 2.6
				leg[0] = Vector3(sin(_phase) * 0.6, 0, 0.02)
				leg[1] = Vector3(-sin(_phase) * 0.6, 0, 0.02)
				knee = [0.1 + 0.8 * maxf(0.0, -cos(_phase)), 0.1 + 0.8 * maxf(0.0, cos(_phase))]
		"dizzy":
			rig_rot.z = sin(t * 2.1) * 0.16
			torso_r = Vector3(0.1, 0, sin(t * 1.7) * 0.12)
			sh = [Vector3(-0.2 + sin(t * 2.3) * 0.3, 0, 0.5), Vector3(-0.2 - sin(t * 2.3) * 0.3, 0, 0.5)]
			el = [Vector3(-0.3, 0, 0), Vector3(-0.3, 0, 0)]
			neck_r = Vector3(0.2, sin(t * 1.3) * 0.4, sin(t * 2.1) * 0.25)
			knee = [0.15 + 0.1 * sin(t * 2.0), 0.15 - 0.1 * sin(t * 2.0)]
		"fish":
			# с удочкой у воды: руки перед собой, взгляд на поплавок, лёгкое покачивание
			var sw := sin(t * 1.3)
			sh[1] = Vector3(-0.62 + sw * 0.03, 0, 0.2)
			el[1] = Vector3(-1.05, 0, 0)
			sh[0] = Vector3(-0.5, 0, 0.12)
			el[0] = Vector3(-1.25 + sw * 0.05, 0, 0)
			torso_r = Vector3(0.1, 0.0, 0)
			leg[0] = Vector3(-0.12, 0, 0.07)
			leg[1] = Vector3(0.14, 0, 0.07)
			knee = [0.12, 0.08]
			neck_r.x += 0.22
			rig_y = sw * 0.004
		"hand":
			# протягивает листовку
			sh[1] = Vector3(-1.35, 0, 0.25)
			el[1] = Vector3(-0.15, 0, 0)
			torso_r.x = 0.12
		_:

			var br := sin(t * 1.6)
			sh[0] = Vector3(br * 0.03, 0, 0.07)
			sh[1] = Vector3(-br * 0.03, 0, 0.07)
			rig_y = br * 0.006
			if is_zero_approx(head_pitch):
				neck_r.y = sin(t * 0.37) * 0.22
	_p_rig_y = lerpf(_p_rig_y, rig_y, k)
	_p_rig_rot = _p_rig_rot.lerp(rig_rot, k)
	_p_torso = _p_torso.lerp(torso_r, k)
	_p_neck = _p_neck.lerp(neck_r, k)
	for i in 2:
		_p_leg[i] = (_p_leg[i] as Vector3).lerp(leg[i], k)
		_p_knee[i] = lerpf(float(_p_knee[i]), float(knee[i]), k)
		_p_sh[i] = (_p_sh[i] as Vector3).lerp(sh[i], k)
		_p_el[i] = (_p_el[i] as Vector3).lerp(el[i], k)
	_apply_pose(k)


func _apply_pose(_k: float) -> void:
	if _skel == null:
		return
	var rig: Node3D = _parts.rig
	rig.position.y = _p_rig_y
	rig.rotation = _p_rig_rot
	var tq := Quaternion.from_euler(_p_torso * 0.5)
	_skel.set_bone_pose_rotation(B_SPINE, tq)
	_skel.set_bone_pose_rotation(B_CHEST, tq)
	_skel.set_bone_pose_rotation(B_NECK, Quaternion.from_euler(_p_neck * 0.45))
	_skel.set_bone_pose_rotation(B_HEAD, Quaternion.from_euler(_p_neck * 0.55))
	if absf(_skel.get_bone_pose_scale(B_HEAD).x - big_head) > 0.001:
		_skel.set_bone_pose_scale(B_HEAD, Vector3.ONE * big_head)
	for i in 2:
		var s := -1.0 if i == 0 else 1.0
		var lv: Vector3 = _p_leg[i]
		var kn: float = _p_knee[i]
		_skel.set_bone_pose_rotation(B_THIGH[i], Quaternion.from_euler(Vector3(lv.x, 0, lv.z * s)))
		_skel.set_bone_pose_rotation(B_SHIN[i], Quaternion(Vector3.RIGHT, kn))
		_skel.set_bone_pose_rotation(B_FOOT[i], Quaternion(Vector3.RIGHT, clampf(-(lv.x + kn) * 0.55, -0.6, 0.6)))
		var sv: Vector3 = _p_sh[i]
		var ev: Vector3 = _p_el[i]
		var rd: Quaternion = _rdown[i]
		var up := clampf(sv.z - 1.4, 0.0, 1.4)
		_skel.set_bone_pose_rotation(B_CLAV[i], Quaternion(Vector3(0, 0, 1), up * 0.22 * s))
		_skel.set_bone_pose_rotation(B_ARM[i], Quaternion.from_euler(Vector3(sv.x, 0, (sv.z + _abd) * s - up * 0.22 * s)) * rd)
		_skel.set_bone_pose_rotation(B_FORE[i], rd.inverse() * Quaternion.from_euler(Vector3(ev.x, 0, ev.z * s)) * rd)
		_skel.set_bone_pose_rotation(B_HAND[i], rd.inverse() * Quaternion(Vector3.RIGHT, -0.12) * rd)
