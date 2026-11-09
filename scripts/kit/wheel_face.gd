extends RefCounted




static func disk_mesh(radius: float, segs: int, vertical: bool) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := Vector3(0, 0, 1) if vertical else Vector3(0, 1, 0)
	for i in segs:
		var a0 := TAU * i / segs
		var a1 := TAU * (i + 1) / segs
		for a in [-1.0, a0, a1]:
			var sx := 0.0 if a < 0.0 else sin(a)
			var sy := 0.0 if a < 0.0 else - cos(a)
			st.set_normal(n)
			st.set_uv(Vector2(0.5 + 0.5 * sx, 0.5 + 0.5 * sy))
			if vertical:
				st.add_vertex(Vector3(sx * radius, -sy * radius, 0))
			else:
				st.add_vertex(Vector3(sx * radius, 0, sy * radius))
	return st.commit()


static func roulette_mesh(radius: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = disk_mesh(radius, 48, false)
	var m := StandardMaterial3D.new()
	m.albedo_texture = Assets.tex("wheel_roulette")
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	m.roughness = 0.45
	m.metallic_specular = 0.6
	m.emission_enabled = true
	m.emission_texture = m.albedo_texture
	m.emission_energy_multiplier = 0.25
	mi.material_override = m
	mi.name = "Face"
	return mi


static func big_wheel_mesh(radius: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = disk_mesh(radius, 64, true)
	var m := StandardMaterial3D.new()
	m.albedo_texture = Assets.tex("wheel_big")
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	m.roughness = 0.6
	m.emission_enabled = true
	m.emission_texture = m.albedo_texture
	m.emission_energy_multiplier = 0.45
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	m.alpha_scissor_threshold = 0.5
	mi.material_override = m
	mi.name = "Face"
	return mi
