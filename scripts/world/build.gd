extends RefCounted
## Помощники для процедурной 3D-графики: материалы, шейдеры, меши.

static var _mat_cache := {}
static var _shader_cache := {}

const SKY_SHADER := """
shader_type sky;
uniform vec3 top_color : source_color = vec3(0.015, 0.02, 0.07);
uniform vec3 horizon_color : source_color = vec3(0.22, 0.07, 0.28);
uniform vec3 glow_color : source_color = vec3(0.9, 0.35, 0.55);
void sky() {
	float y = EYEDIR.y;
	vec3 c = mix(horizon_color, top_color, clamp(pow(max(y, 0.0), 0.45), 0.0, 1.0));
	c += glow_color * exp(-abs(y) * 9.0) * 0.35;
	vec3 d = EYEDIR * 220.0;
	vec3 id = floor(d);
	float s = fract(sin(dot(id, vec3(12.9898, 78.233, 37.719))) * 43758.5453);
	float star = step(0.9982, s) * smoothstep(0.02, 0.25, y);
	c += vec3(star) * (1.2 + 0.8 * sin(TIME * 2.0 + s * 300.0));
	vec3 mdir = normalize(vec3(-0.45, 0.42, -0.75));
	float m = dot(EYEDIR, mdir);
	c += vec3(1.0, 0.96, 0.86) * smoothstep(0.9990, 0.9994, m) * 4.0;
	c += vec3(0.35, 0.35, 0.6) * pow(max(m, 0.0), 120.0) * 0.4;
	if (y < 0.0) { c = mix(horizon_color * 0.4, vec3(0.01), clamp(-y * 4.0, 0.0, 1.0)); }
	COLOR = c;
}
"""

const BUILDING_SHADER := """
shader_type spatial;
uniform vec3 base_color : source_color = vec3(0.15, 0.12, 0.18);
uniform vec3 trim_color : source_color = vec3(1.0, 0.7, 0.2);
uniform vec3 window_color : source_color = vec3(1.0, 0.78, 0.45);
uniform float lit_ratio = 0.55;
uniform float window_energy = 2.2;
uniform vec2 cell = vec2(2.2, 2.0);
uniform float ground_h = 4.6;
uniform float seed = 0.0;
uniform float dim = 1.0;
uniform float trim_energy = 0.0;
varying vec3 wpos;
varying vec3 wnrm;
float h(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7)) + seed * 17.13) * 43758.5453); }
void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}
void fragment() {
	vec3 col = base_color;
	vec3 em = vec3(0.0);
	float rough = 0.75;
	float metal = 0.0;
	if (abs(wnrm.y) < 0.5) {
		vec2 c = abs(wnrm.z) > 0.5 ? vec2(wpos.x, wpos.y) : vec2(wpos.z, wpos.y);
		vec2 g = c / cell;
		vec2 id = floor(g);
		vec2 f = fract(g);
		float win = step(0.16, f.x) * step(f.x, 0.84) * step(0.22, f.y) * step(f.y, 0.80);
		float trim = step(fract(wpos.y / cell.y), 0.07);
		if (wpos.y > ground_h && win > 0.5) {
			float r = h(id + floor(wnrm.xz * 3.0 + 3.0));
			float lit = step(1.0 - lit_ratio, r);
			float flick = step(0.985, h(id + vec2(floor(TIME * 0.25 + r * 7.0))));
			lit = clamp(lit - flick, 0.0, 1.0);
			col = vec3(0.03, 0.04, 0.07);
			rough = 0.08;
			metal = 0.6;
			em = window_color * (0.55 + 0.6 * h(id * 1.7)) * lit * window_energy * dim;
		} else if (wpos.y > ground_h) {
			col = mix(base_color, trim_color * 0.5, trim);
			em = trim_color * trim * trim_energy * dim;
		}
	}
	ALBEDO = col;
	EMISSION = em;
	ROUGHNESS = rough;
	METALLIC = metal;
}
"""

const BULBS_SHADER := """
shader_type spatial;
render_mode unshaded;
uniform vec3 color : source_color = vec3(1.0, 0.8, 0.3);
uniform float energy = 5.0;
uniform float spacing = 0.45;
uniform float speed = 2.0;
varying vec3 wpos;
void vertex() { wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	float a = wpos.x + wpos.z + wpos.y * 0.7;
	float k = fract(a / spacing);
	float b = smoothstep(0.32, 0.12, abs(k - 0.5));
	float chase = step(0.45, fract(a / (spacing * 3.0) - TIME * speed * 0.35));
	ALBEDO = color * 0.15;
	EMISSION = color * energy * b * (0.2 + 0.8 * chase) + color * 0.15;
}
"""

const ROAD_SHADER := """
shader_type spatial;
varying vec3 wpos;
float h(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float n(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h(i), h(i + vec2(1, 0)), f.x), mix(h(i + vec2(0, 1)), h(i + vec2(1, 1)), f.x), f.y);
}
void vertex() { wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	float v = n(wpos.xz * 0.35) * 0.6 + n(wpos.xz * 2.5) * 0.25 + h(floor(wpos.xz * 25.0)) * 0.15;
	ALBEDO = vec3(0.045, 0.045, 0.055) * (0.75 + v * 0.6);
	float wet = smoothstep(0.42, 0.62, n(wpos.xz * 0.11 + vec2(3.0, 7.0)));
	ROUGHNESS = mix(0.85, 0.06, wet);
	SPECULAR = 0.5 + wet * 0.4;
}
"""

const TILES_SHADER := """
shader_type spatial;
uniform vec3 color_a : source_color = vec3(0.16, 0.15, 0.17);
uniform vec3 color_b : source_color = vec3(0.12, 0.11, 0.13);
uniform vec3 accent : source_color = vec3(0.0);
uniform float tile = 1.0;
uniform float accent_energy = 0.0;
varying vec3 wpos;
void vertex() { wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	vec2 g = wpos.xz / tile;
	vec2 f = fract(g);
	float grout = 1.0 - step(0.04, f.x) * step(0.04, f.y);
	float chk = mod(floor(g.x) + floor(g.y), 2.0);
	vec3 c = mix(color_a, color_b, chk);
	c = mix(c, vec3(0.05), grout * 0.8);
	float big = 1.0 - step(0.02, fract(g.x / 4.0)) * step(0.02, fract(g.y / 4.0));
	ALBEDO = c;
	EMISSION = accent * big * accent_energy;
	ROUGHNESS = 0.55 + chk * 0.2;
}
"""

const BEAM_SHADER := """
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;
uniform vec3 color : source_color = vec3(1.0);
uniform float strength = 0.35;
varying float vy;
void vertex() { vy = UV.y; }
void fragment() {
	float edge = pow(1.0 - abs(dot(NORMAL, VIEW)), 1.5);
	ALBEDO = color;
	ALPHA = strength * (1.0 - vy) * (1.0 - edge * 0.8);
	EMISSION = color;
}
"""


static func shader(code: String) -> Shader:
	if not _shader_cache.has(code):
		var s := Shader.new()
		s.code = code
		_shader_cache[code] = s
	return _shader_cache[code]


static func smat(code: String, params := {}) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = shader(code)
	for k in params:
		m.set_shader_parameter(k, params[k])
	return m


static func mat(color: Color, rough := 0.7, metal := 0.0, emission := Color.BLACK, energy := 1.0) -> StandardMaterial3D:
	var key := "%s|%.2f|%.2f|%s|%.2f" % [color.to_html(), rough, metal, emission.to_html(), energy]
	if _mat_cache.has(key):
		return _mat_cache[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	m.metallic = metal
	if emission != Color.BLACK:
		m.emission_enabled = true
		m.emission = emission
		m.emission_energy_multiplier = energy
	_mat_cache[key] = m
	return m


static func neon(color: Color, energy := 4.0) -> StandardMaterial3D:
	var key := "neon|%s|%.2f" % [color.to_html(), energy]
	if _mat_cache.has(key):
		return _mat_cache[key]
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = color
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = energy
	_mat_cache[key] = m
	return m


static func glass(color: Color, alpha := 0.3) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(color.r, color.g, color.b, alpha)
	m.roughness = 0.05
	m.metallic = 0.3
	return m


static func box(parent: Node, size: Vector3, pos: Vector3, material: Material, shadows := true) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var m := BoxMesh.new()
	m.size = size
	mi.mesh = m
	mi.position = pos
	mi.material_override = material
	if not shadows:
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi


static func cyl(parent: Node, r_top: float, r_bot: float, h: float, pos: Vector3, material: Material, segs := 16) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var m := CylinderMesh.new()
	m.top_radius = r_top
	m.bottom_radius = r_bot
	m.height = h
	m.radial_segments = segs
	m.rings = 1
	mi.mesh = m
	mi.position = pos
	mi.material_override = material
	parent.add_child(mi)
	return mi


static func sphere(parent: Node, r: float, pos: Vector3, material: Material, hemi := false, segs := 16) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var m := SphereMesh.new()
	m.radius = r
	m.height = r * (1.0 if hemi else 2.0)
	m.is_hemisphere = hemi
	m.radial_segments = segs
	m.rings = maxi(4, segs / 2)
	mi.mesh = m
	mi.position = pos
	mi.material_override = material
	parent.add_child(mi)
	return mi


static func capsule(parent: Node, r: float, h: float, pos: Vector3, material: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var m := CapsuleMesh.new()
	m.radius = r
	m.height = h
	m.radial_segments = 12
	m.rings = 4
	mi.mesh = m
	mi.position = pos
	mi.material_override = material
	parent.add_child(mi)
	return mi


static func label(parent: Node, text: String, pos: Vector3, size := 64, color := Color.WHITE, outline := Color.BLACK, px := 0.01, font: Font = null) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font_size = size
	l.outline_size = maxi(4, size / 6)
	l.pixel_size = px
	l.modulate = color
	l.outline_modulate = outline
	l.position = pos
	l.double_sided = false
	l.shaded = false
	if font:
		l.font = font
	parent.add_child(l)
	return l


## Двусторонняя табличка: текст читается с обеих сторон.
static func sign2(parent: Node, text: String, pos: Vector3, size: int, color: Color, outline: Color, px: float, font: Font = null) -> Array:
	var a := label(parent, text, pos + Vector3(0, 0, 0.02), size, color, outline, px, font)
	var b := label(parent, text, pos - Vector3(0, 0, 0.02), size, color, outline, px, font)
	b.rotation.y = PI
	return [a, b]


static func light(parent: Node, pos: Vector3, color: Color, energy := 1.0, rng := 8.0) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.position = pos
	l.light_color = color
	l.light_energy = energy
	l.omni_range = rng
	l.omni_attenuation = 1.4
	l.shadow_enabled = false
	parent.add_child(l)
	return l


static func spot(parent: Node, pos: Vector3, look_dir: Vector3, color: Color, energy := 3.0, rng := 20.0, angle := 25.0) -> SpotLight3D:
	var l := SpotLight3D.new()
	l.light_color = color
	l.light_energy = energy
	l.spot_range = rng
	l.spot_angle = angle
	l.spot_attenuation = 1.0
	l.shadow_enabled = false
	parent.add_child(l)
	var up := Vector3.UP if absf(look_dir.normalized().y) < 0.99 else Vector3.FORWARD
	l.transform = Transform3D(Basis.looking_at(look_dir, up), pos)
	return l


static func beam(parent: Node, color: Color, length := 18.0, radius := 1.6, strength := 0.25) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var m := CylinderMesh.new()
	m.top_radius = 0.12
	m.bottom_radius = radius
	m.height = length
	m.radial_segments = 16
	m.cap_top = false
	m.cap_bottom = false
	mi.mesh = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.material_override = smat(BEAM_SHADER, {"color": color, "strength": strength})
	parent.add_child(mi)
	return mi


static func particles(parent: Node, pos: Vector3, amount: int, lifetime: float, color: Color, size: float, velocity: Vector3, spread: float, gravity: Vector3, emit_box := Vector3.ZERO, glow := 0.0) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.position = pos
	p.amount = amount
	p.lifetime = lifetime
	var qm := QuadMesh.new()
	qm.size = Vector2(size, size)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.vertex_color_use_as_albedo = true
	m.albedo_color = Color.WHITE
	if glow > 0.0:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = glow
	qm.material = m
	p.mesh = qm
	p.color = color
	var grad := Gradient.new()
	grad.set_color(0, Color(1, 1, 1, color.a))
	grad.set_color(1, Color(1, 1, 1, 0))
	p.color_ramp = grad
	p.direction = velocity.normalized() if velocity.length() > 0.0 else Vector3.UP
	p.initial_velocity_min = velocity.length() * 0.6
	p.initial_velocity_max = velocity.length()
	p.spread = spread
	p.gravity = gravity
	if emit_box != Vector3.ZERO:
		p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
		p.emission_box_extents = emit_box
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(p)
	return p


static func burst(parent: Node, pos: Vector3, color: Color, amount := 60, speed := 9.0, size := 0.35, lifetime := 1.6, gravity := Vector3(0, -6, 0)) -> CPUParticles3D:
	var p := particles(parent, pos, amount, lifetime, color, size, Vector3.UP * speed, 180.0, gravity, Vector3.ZERO, 6.0)
	p.one_shot = true
	p.explosiveness = 0.95
	p.emitting = true
	p.finished.connect(p.queue_free)
	return p


## Невидимое препятствие для игрока от первого лица.
static func solid(parent: Node, size: Vector3, pos: Vector3, rot_y := 0.0) -> StaticBody3D:
	var b := StaticBody3D.new()
	b.collision_layer = 1
	b.collision_mask = 0
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = size
	cs.shape = sh
	b.add_child(cs)
	b.position = pos
	b.rotation.y = rot_y
	parent.add_child(b)
	return b


static func set_solid(n: Node, on: bool) -> void:
	for b in n.find_children("*", "StaticBody3D", true, false):
		(b as StaticBody3D).collision_layer = 1 if on else 0
