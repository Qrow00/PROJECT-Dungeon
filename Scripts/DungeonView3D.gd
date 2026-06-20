extends Control

var room_type := 0
var theme_name := "Dark Caverns"
var has_enemies := false
var has_treasure := false
var variant := 0
var torch_time := 0.0

var idling := false
var anim_callback: Callable = Callable()

var sv: SubViewport
var camera: Camera3D
var world_env: WorldEnvironment
var torch_light: OmniLight3D
var corridor_root: Node3D
var feature_root: Node3D
var wall_left: MeshInstance3D
var wall_right: MeshInstance3D
var floor_mesh: MeshInstance3D
var ceil_mesh: MeshInstance3D

var wall_mat: Material
var floor_mat: Material
var ceil_mat: Material

var torch_lights: Array = []
var fog_particles: GPUParticles3D
var flame_mat_outer: Material
var flame_mat_inner: Material

var enemy_labels: Array = []
var treasure_label: Label3D
var boss_label: Label3D
var portal_label: Label3D
var rest_label: Label3D

var particles: GPUParticles3D
var wall_tex: Texture2D
var floor_tex: Texture2D

const TH := 0.3
const WALL_W := 16.0
const CW := 8.0
const CH := 5.0
const CD := 40.0

const THEMES := {
	"Dark Caverns": {
		"wall": Color("#7a5533"), "wall_mortar": Color("#4a3020"),
		"floor": Color("#aa8844"), "floor_grout": Color("#6a5533"),
		"ceil": Color("#221111"),
		"ambient": Color("#221111"), "fog": Color("#1a0f0a"), "bg": Color("#140a08")
	},
	"Ancient Ruins": {
		"wall": Color("#8a6a44"), "wall_mortar": Color("#5a4430"),
		"floor": Color("#9a7a44"), "floor_grout": Color("#6a5533"),
		"ceil": Color("#1a1110"),
		"ambient": Color("#1a1110"), "fog": Color("#15100a"), "bg": Color("#100a08")
	},
	"Crystal Caves": {
		"wall": Color("#557799"), "wall_mortar": Color("#334466"),
		"floor": Color("#557766"), "floor_grout": Color("#334455"),
		"ceil": Color("#112233"),
		"ambient": Color("#112233"), "fog": Color("#0a1520"), "bg": Color("#080e18")
	},
	"Lava Tunnels": {
		"wall": Color("#994433"), "wall_mortar": Color("#552220"),
		"floor": Color("#996633"), "floor_grout": Color("#553322"),
		"ceil": Color("#1a0808"),
		"ambient": Color("#1a0808"), "fog": Color("#150a0a"), "bg": Color("#100608")
	},
	"Frozen Depths": {
		"wall": Color("#7788aa"), "wall_mortar": Color("#445577"),
		"floor": Color("#779988"), "floor_grout": Color("#445566"),
		"ceil": Color("#112244"),
		"ambient": Color("#112244"), "fog": Color("#0a1a22"), "bg": Color("#081018")
	},
	"Abyssal Vaults": {
		"wall": Color("#553377"), "wall_mortar": Color("#332255"),
		"floor": Color("#665588"), "floor_grout": Color("#443366"),
		"ceil": Color("#0a001a"),
		"ambient": Color("#0a001a"), "fog": Color("#08001a"), "bg": Color("#060010")
	}
}

func _init():
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _ready():
	_setup_viewport()
	_setup_environment()
	_setup_camera()
	_setup_corridor()
	_setup_lighting()
	_setup_features()
	_setup_particles()
	_setup_end_fog()
	_load_textures()
	_setup_vegetation()
	_setup_torches()
	_apply_theme("Dark Caverns")

func _setup_viewport():
	var svc = SubViewportContainer.new()
	svc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	svc.stretch = true
	svc.anchors_preset = Control.PRESET_FULL_RECT
	svc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(svc)

	sv = SubViewport.new()
	sv.disable_3d = false
	sv.msaa_3d = Viewport.MSAA_2X
	svc.add_child(sv)

func _setup_environment():
	world_env = WorldEnvironment.new()
	sv.add_child(world_env)
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#140a08")
	env.glow_enabled = false
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.fog_enabled = true
	env.fog_density = 0.012
	env.fog_height_density = 0.0
	env.fog_aerial_perspective = 0.5
	world_env.environment = env

func _setup_camera():
	camera = Camera3D.new()
	camera.current = true
	camera.look_at_from_position(Vector3(0, 1.4, 0.5), Vector3(0, 1.4, -25))
	camera.near = 0.05
	camera.far = 80.0
	camera.fov = 85
	sv.add_child(camera)

func _setup_corridor():
	corridor_root = Node3D.new()
	sv.add_child(corridor_root)

	var bm = BoxMesh.new()

	bm.size = Vector3(WALL_W, CH, CD)
	wall_left = MeshInstance3D.new()
	wall_left.mesh = bm
	wall_left.position = Vector3(-CW/2 - WALL_W/2, CH/2, -CD/2)
	corridor_root.add_child(wall_left)

	bm = BoxMesh.new()
	bm.size = Vector3(WALL_W, CH, CD)
	wall_right = MeshInstance3D.new()
	wall_right.mesh = bm
	wall_right.position = Vector3(CW/2 + WALL_W/2, CH/2, -CD/2)
	corridor_root.add_child(wall_right)

	bm = BoxMesh.new()
	bm.size = Vector3(CW + WALL_W*2, TH, CD)
	floor_mesh = MeshInstance3D.new()
	floor_mesh.mesh = bm
	floor_mesh.position = Vector3(0, -TH/2, -CD/2)
	corridor_root.add_child(floor_mesh)

	bm = BoxMesh.new()
	bm.size = Vector3(CW + WALL_W*2, TH, CD)
	ceil_mesh = MeshInstance3D.new()
	ceil_mesh.mesh = bm
	ceil_mesh.position = Vector3(0, CH + TH/2, -CD/2)
	corridor_root.add_child(ceil_mesh)

func _setup_lighting():
	torch_light = OmniLight3D.new()
	torch_light.position = Vector3(0.4, 1.4, 0.4)
	torch_light.light_color = Color(1.0, 0.7, 0.35)
	torch_light.light_energy = 2.5
	torch_light.light_specular = 0.2
	torch_light.omni_range = 50.0
	sv.add_child(torch_light)

func _setup_features():
	feature_root = Node3D.new()
	sv.add_child(feature_root)

	var char_positions = [
		Vector3(-0.8, 2.0, -12),
		Vector3(0.8, 2.0, -13),
		Vector3(-0.3, 1.8, -14),
		Vector3(0.3, 1.8, -15)
	]
	for i in range(4):
		var lbl = _make_char_label("M", Color("#ee3333"))
		lbl.position = char_positions[i]
		lbl.visible = false
		feature_root.add_child(lbl)
		enemy_labels.append(lbl)

	treasure_label = _make_char_label("$", Color("#ffcc00"))
	treasure_label.position = Vector3(0, 2.2, -10)
	treasure_label.visible = false
	feature_root.add_child(treasure_label)

	boss_label = _make_char_label("B", Color("#ee2222"))
	boss_label.position = Vector3(0, 2.4, -14)
	boss_label.pixel_size = 0.006
	boss_label.visible = false
	feature_root.add_child(boss_label)

	portal_label = _make_char_label("*", Color("#44bbff"))
	portal_label.position = Vector3(0, 2.2, -9)
	portal_label.visible = false
	feature_root.add_child(portal_label)

	rest_label = _make_char_label("+", Color("#ee4466"))
	rest_label.position = Vector3(0, 2.0, -10)
	rest_label.visible = false
	feature_root.add_child(rest_label)

func _make_char_label(text: String, color: Color) -> Label3D:
	var lbl = Label3D.new()
	lbl.text = text
	lbl.modulate = color
	lbl.font_size = 64
	lbl.pixel_size = 0.004
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.no_depth_test = true
	lbl.outline_modulate = Color(0, 0, 0, 0.6)
	lbl.outline_size = 4
	return lbl

func _setup_particles():
	particles = GPUParticles3D.new()
	var pm = ParticleProcessMaterial.new()
	pm.gravity = Vector3(0, -0.03, 0)
	pm.initial_velocity_min = 0.01
	pm.initial_velocity_max = 0.04
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 45.0
	pm.color = Color(0.7, 0.6, 0.5, 0.3)
	pm.angle_min = 0
	pm.angle_max = 360
	pm.scale_min = 0.03
	pm.scale_max = 0.08
	particles.process_material = pm
	particles.amount = 24
	particles.lifetime = 4.0
	particles.one_shot = false
	particles.explosiveness = 0.0
	particles.randomness = 0.5
	particles.fixed_fps = 15
	particles.position = Vector3(0, 1.2, -10)
	particles.visibility_aabb = AABB(Vector3(-3, -2, -18), Vector3(6, 8, 30))
	sv.add_child(particles)

func _setup_end_fog():
	fog_particles = GPUParticles3D.new()
	var pm = ParticleProcessMaterial.new()
	pm.gravity = Vector3(0, -0.005, 0)
	pm.initial_velocity_min = 0.01
	pm.initial_velocity_max = 0.06
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 70.0
	pm.color = Color(0.5, 0.45, 0.4, 0.08)
	pm.angle_min = 0
	pm.angle_max = 360
	pm.scale_min = 0.4
	pm.scale_max = 1.2
	pm.linear_accel_min = -0.005
	pm.linear_accel_max = 0.005
	fog_particles.process_material = pm
	fog_particles.amount = 60
	fog_particles.lifetime = 8.0
	fog_particles.one_shot = false
	fog_particles.explosiveness = 0.3
	fog_particles.randomness = 0.8
	fog_particles.fixed_fps = 8
	fog_particles.position = Vector3(0, 0.3, -CD + 4)
	fog_particles.visibility_aabb = AABB(Vector3(-12, -4, -CD - 4), Vector3(24, 10, 16))
	sv.add_child(fog_particles)

func _setup_torches():
	var rng = RandomNumberGenerator.new()
	rng.seed = hash("torches" + str(CD))
	var torch_count = rng.randi_range(6, 10)
	var segs = 20

	var mat_wood = StandardMaterial3D.new()
	mat_wood.albedo_color = Color("#6a4a2a")
	mat_wood.roughness = 0.95

	var mat_wood_dark = StandardMaterial3D.new()
	mat_wood_dark.albedo_color = Color("#4a3020")
	mat_wood_dark.roughness = 0.95

	var mat_wrap = StandardMaterial3D.new()
	mat_wrap.albedo_color = Color("#3a2a1a")
	mat_wrap.roughness = 0.9

	var mat_burnt = StandardMaterial3D.new()
	mat_burnt.albedo_color = Color("#1a0f08")
	mat_burnt.roughness = 0.95

	var mat_iron = StandardMaterial3D.new()
	mat_iron.albedo_color = Color("#1a1008")
	mat_iron.metallic = 0.6
	mat_iron.roughness = 0.5

	var soft_shader := Shader.new()
	soft_shader.code = """
shader_type spatial;
render_mode blend_mix, unshaded;
uniform vec4 u_color : source_color;
uniform float u_alpha : hint_range(0, 1) = 0.7;
uniform float u_emission_strength : hint_range(0, 5) = 1.5;
void fragment() {
	vec2 uv = (UV - 0.5) * 2.0;
	float d = length(uv);
	float alpha = 1.0 - smoothstep(0.6, 1.0, d);
	float a = alpha * u_alpha;
	ALBEDO = u_color.rgb;
	ALPHA = a;
	EMISSION = u_color.rgb * a * u_emission_strength;
}
"""

	flame_mat_outer = ShaderMaterial.new()
	flame_mat_outer.shader = soft_shader
	flame_mat_outer.set_shader_parameter("u_color", Color(1.0, 0.5, 0.1))
	flame_mat_outer.set_shader_parameter("u_alpha", 0.5)
	flame_mat_outer.set_shader_parameter("u_emission_strength", 3.0)

	flame_mat_inner = ShaderMaterial.new()
	flame_mat_inner.shader = soft_shader
	flame_mat_inner.set_shader_parameter("u_color", Color(1.0, 0.85, 0.3))
	flame_mat_inner.set_shader_parameter("u_alpha", 0.75)
	flame_mat_inner.set_shader_parameter("u_emission_strength", 3.5)

	var fp_proto = ParticleProcessMaterial.new()
	fp_proto.gravity = Vector3(0, 0.3, 0)
	fp_proto.initial_velocity_min = 0.15
	fp_proto.initial_velocity_max = 0.35
	fp_proto.direction = Vector3(0, 1, 0)
	fp_proto.spread = 8.0
	fp_proto.color = Color(1, 1, 1, 0.5)
	fp_proto.scale_min = 0.2
	fp_proto.scale_max = 0.5
	fp_proto.angular_velocity_min = -0.5
	fp_proto.angular_velocity_max = 0.5
	fp_proto.hue_variation_max = 0.08

	var fp2_proto = ParticleProcessMaterial.new()
	fp2_proto.gravity = Vector3(0, 0.15, 0)
	fp2_proto.initial_velocity_min = 0.08
	fp2_proto.initial_velocity_max = 0.2
	fp2_proto.direction = Vector3(0, 1, 0)
	fp2_proto.spread = 6.0
	fp2_proto.color = Color(1, 1, 1, 0.6)
	fp2_proto.scale_min = 0.12
	fp2_proto.scale_max = 0.3




	var wall_face = CW / 2
	var max_depth = CD - 3.0
	for i in range(torch_count):
		var side = 1 if i % 2 == 0 else -1
		var depth = -1.0 - (i + 0.5) * max_depth / torch_count + rng.randf_range(-0.3, 0.3)
		var height = 0.7 + rng.randf_range(-0.2, 0.5)
		var is_lit = rng.randf() > 0.35

		var tx = Node3D.new()
		tx.position = Vector3(side * (wall_face - 0.12), height, depth)
		tx.rotation_degrees.z = rng.randf_range(-1.5, 1.5)
		corridor_root.add_child(tx)

		var arm = MeshInstance3D.new()
		var am = CylinderMesh.new()
		am.top_radius = 0.025
		am.bottom_radius = 0.03
		am.height = 0.22
		am.radial_segments = segs
		arm.mesh = am
		arm.position = Vector3(side * -0.12, 0, 0)
		arm.rotation_degrees.z = side * -90
		arm.set_surface_override_material(0, mat_iron)
		tx.add_child(arm)

		var plate = MeshInstance3D.new()
		var pm = CylinderMesh.new()
		pm.top_radius = 0.04
		pm.bottom_radius = 0.04
		pm.height = 0.025
		pm.radial_segments = segs
		plate.mesh = pm
		plate.position = Vector3(side * -0.23, 0, 0)
		plate.set_surface_override_material(0, mat_iron)
		tx.add_child(plate)

		var stick = MeshInstance3D.new()
		var sm = CylinderMesh.new()
		sm.top_radius = 0.035 + rng.randf_range(0, 0.01)
		sm.bottom_radius = 0.05 + rng.randf_range(0, 0.01)
		sm.height = 0.55
		sm.radial_segments = segs
		stick.mesh = sm
		stick.position = Vector3(0, -0.28, 0)
		stick.rotation_degrees.z = rng.randf_range(-1, 1)
		stick.set_surface_override_material(0, mat_wood)
		tx.add_child(stick)

		var collar = MeshInstance3D.new()
		var com = CylinderMesh.new()
		com.top_radius = 0.055
		com.bottom_radius = 0.05
		com.height = 0.04
		com.radial_segments = segs
		collar.mesh = com
		collar.position = Vector3(0, -0.02, 0)
		collar.set_surface_override_material(0, mat_iron)
		tx.add_child(collar)

		var wrap_low = MeshInstance3D.new()
		var wlm = CylinderMesh.new()
		wlm.top_radius = 0.065
		wlm.bottom_radius = 0.055
		wlm.height = 0.08
		wlm.radial_segments = segs
		wrap_low.mesh = wlm
		wrap_low.position = Vector3(0, 0.05, 0)
		wrap_low.set_surface_override_material(0, mat_wrap)
		tx.add_child(wrap_low)

		var wrap_mid = MeshInstance3D.new()
		var wmm = CylinderMesh.new()
		wmm.top_radius = 0.065
		wmm.bottom_radius = 0.065
		wmm.height = 0.06
		wmm.radial_segments = segs
		wrap_mid.mesh = wmm
		wrap_mid.position = Vector3(0, 0.11, 0)
		wrap_mid.scale = Vector3(1, 1, 0.85 + rng.randf_range(0, 0.15))
		wrap_mid.rotation_degrees.y = rng.randf_range(0, 360)
		wrap_mid.set_surface_override_material(0, mat_wrap)
		tx.add_child(wrap_mid)

		var wrap_top = MeshInstance3D.new()
		var wtm = SphereMesh.new()
		wtm.radius = 0.055
		wtm.height = 0.06
		wtm.radial_segments = segs
		wtm.rings = segs / 2
		wrap_top.mesh = wtm
		wrap_top.position = Vector3(0, 0.15, 0)
		wrap_top.scale = Vector3(1, 0.4, 1)
		wrap_top.set_surface_override_material(0, mat_wrap)
		tx.add_child(wrap_top)

		var band1 = MeshInstance3D.new()
		var b1m = CylinderMesh.new()
		b1m.top_radius = 0.005
		b1m.bottom_radius = 0.005
		b1m.height = 0.005
		b1m.radial_segments = segs
		band1.mesh = b1m
		band1.position = Vector3(0, 0.05, 0)
		band1.scale = Vector3(1, 1, 0.8)
		band1.set_surface_override_material(0, mat_wood_dark)
		tx.add_child(band1)

		var band2 = MeshInstance3D.new()
		var b2m = CylinderMesh.new()
		b2m.top_radius = 0.005
		b2m.bottom_radius = 0.005
		b2m.height = 0.005
		b2m.radial_segments = segs
		band2.mesh = b2m
		band2.position = Vector3(0, 0.1, 0)
		band2.scale = Vector3(1, 1, 0.8)
		band2.set_surface_override_material(0, mat_wood_dark)
		tx.add_child(band2)

		if is_lit:
			var qm := QuadMesh.new()
			qm.size = Vector2(1, 1)
			var qm2 := QuadMesh.new()
			qm2.size = Vector2(1, 1)

			var fp = GPUParticles3D.new()
			fp.process_material = fp_proto.duplicate()
			fp.draw_pass_1 = qm
			fp.material_override = flame_mat_outer
			fp.amount = 50
			fp.lifetime = 0.8
			fp.one_shot = false
			fp.randomness = 0.2
			fp.local_coords = true
			fp.transform_align = 1
			fp.position = Vector3(0, 0.15, 0)
			fp.visibility_aabb = AABB(Vector3(-3, -3, -3), Vector3(6, 6, 6))
			tx.add_child(fp)

			var fp2 = GPUParticles3D.new()
			fp2.process_material = fp2_proto.duplicate()
			fp2.draw_pass_1 = qm2
			fp2.material_override = flame_mat_inner
			fp2.amount = 30
			fp2.lifetime = 0.6
			fp2.one_shot = false
			fp2.randomness = 0.15
			fp2.local_coords = true
			fp2.transform_align = 1
			fp2.position = Vector3(0, 0.18, 0)
			fp2.visibility_aabb = AABB(Vector3(-3, -3, -3), Vector3(6, 6, 6))
			tx.add_child(fp2)

			var light = OmniLight3D.new()
			var base_energy = 0.9 + rng.randf_range(-0.1, 0.1)
			light.set_meta("base_energy", base_energy)
			light.light_color = Color(1.0, 0.4, 0.1)
			light.light_energy = base_energy
			light.light_specular = 0.06
			light.omni_range = 8.0 + rng.randf_range(-0.5, 0.5)
			light.position = Vector3(0, 0.35, 0)
			tx.add_child(light)
			torch_lights.append(light)
		else:
			var stub = MeshInstance3D.new()
			var stm = SphereMesh.new()
			stm.radius = 0.045
			stm.height = 0.06
			stm.radial_segments = segs
			stm.rings = segs / 2
			stub.mesh = stm
			stub.position = Vector3(0, 0.12, 0)
			stub.scale = Vector3(1, 0.6, 1)
			stub.set_surface_override_material(0, mat_burnt)
			tx.add_child(stub)

func _make_leaf_mesh(h: float) -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var hw = h * 0.3
	var v = [
		Vector3(0, h * 0.35, 0),
		Vector3(-hw, 0, -hw * 0.3),
		Vector3(hw, 0, -hw * 0.3),
		Vector3(0, -h * 0.4, hw * 0.2)
	]
	var idx = [0, 1, 3, 0, 3, 2, 1, 3, 2]
	for i in idx:
		st.set_color(Color(0.25, 0.5, 0.15))
		st.add_vertex(v[i])
	st.generate_normals()
	return st.commit()

func _setup_vegetation():
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.55, 0.15)
	mat.metallic = 0.0
	mat.roughness = 0.85

	var rng = RandomNumberGenerator.new()
	rng.seed = hash("dungeon" + str(CD))
	for i in range(14):
		var d = -1.5 - i * 2.8 + rng.randf_range(-0.4, 0.4)
		var side = 1 if i % 2 == 0 else -1
		var h = 0.6 + rng.randf_range(0, 1.5)

		var mi = MeshInstance3D.new()
		mi.mesh = _make_leaf_mesh(h)
		mi.position = Vector3(side * (CW/2 - 0.05), h / 2, d)
		mi.rotation_degrees.y = -90 * side + rng.randf_range(-20, 20)
		mi.set_material_override(mat)
		corridor_root.add_child(mi)

	for i in range(24):
		var d = -0.5 - i * 1.6 + rng.randf_range(-0.3, 0.3)
		var fx = rng.randf_range(-CW/2 + 0.5, CW/2 - 0.5)
		var mi = MeshInstance3D.new()
		mi.mesh = _make_leaf_mesh(0.4 + rng.randf_range(0, 0.3))
		mi.position = Vector3(fx, 0.01, d)
		mi.rotation_degrees.x = -90
		mi.rotation_degrees.z = rng.randf_range(-180, 180)
		mi.set_material_override(mat)
		corridor_root.add_child(mi)

func set_room(type: int, theme: String, enemies: bool = false, treasure: bool = false):
	room_type = type
	theme_name = theme
	has_enemies = enemies
	has_treasure = treasure
	variant = randi() % 6
	_apply_theme(theme)

	for lbl in enemy_labels:
		lbl.visible = false
	treasure_label.visible = false
	boss_label.visible = false
	portal_label.visible = false
	rest_label.visible = false

	if type == 6:
		boss_label.visible = true
	elif type == 7:
		portal_label.visible = true
	elif type == 5:
		rest_label.visible = true
	else:
		if enemies:
			for i in range(min(enemy_labels.size(), 2)):
				enemy_labels[i].text = ["M", "W", "G", "S"][(i + variant) % 4]
				enemy_labels[i].visible = true
		if treasure:
			treasure_label.visible = true

func _apply_theme(name: String):
	var cfg = THEMES.get(name, THEMES["Dark Caverns"])
	wall_mat = _make_brick_material(cfg.wall, cfg.wall_mortar)
	floor_mat = _make_tile_material(cfg.floor, cfg.floor_grout)
	ceil_mat = StandardMaterial3D.new()
	ceil_mat.albedo_color = cfg.ceil
	ceil_mat.metallic = 0.0
	ceil_mat.roughness = 0.95

	wall_left.set_material_override(wall_mat)
	wall_right.set_material_override(wall_mat)
	floor_mesh.set_material_override(floor_mat)
	ceil_mesh.set_material_override(ceil_mat)

	world_env.environment.fog_light_color = cfg.fog
	world_env.environment.background_color = cfg.bg
	world_env.environment.ambient_light_color = cfg.ambient
	world_env.environment.ambient_light_energy = 0.4
	world_env.environment.ambient_light_sky_contribution = 0.0

	var pmat = particles.process_material as ParticleProcessMaterial
	if name == "Lava Tunnels":
		pmat.color = Color(0.8, 0.3, 0.1, 0.4)
		pmat.gravity = Vector3(0, -0.02, 0)
	elif name == "Frozen Depths":
		pmat.color = Color(0.6, 0.7, 0.9, 0.25)
	elif name == "Crystal Caves":
		pmat.color = Color(0.3, 0.6, 0.8, 0.3)
	else:
		pmat.color = Color(0.7, 0.6, 0.5, 0.3)
		pmat.gravity = Vector3(0, -0.03, 0)

func _load_textures():
	var img = Image.load_from_file("res://assets/wall_texture.jpg")
	if img:
		wall_tex = ImageTexture.create_from_image(img)
	img = Image.load_from_file("res://assets/floor_texture.jpg")
	if img:
		floor_tex = ImageTexture.create_from_image(img)

func _make_brick_material(base: Color, mortar: Color) -> Material:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color.WHITE
	mat.metallic = 0.0
	mat.roughness = 0.85
	mat.uv1_scale = Vector3(48, 5, 0)
	if wall_tex:
		mat.albedo_texture = wall_tex
		mat.texture_repeat = 1
	return mat

func _make_tile_material(base: Color, grout: Color) -> Material:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color.WHITE
	mat.metallic = 0.0
	mat.roughness = 0.75
	mat.uv1_scale = Vector3(36, 36, 0)
	if floor_tex:
		mat.albedo_texture = floor_tex
		mat.texture_repeat = 1
	return mat

func play_turn(direction: String, callback: Callable = Callable()):
	anim_callback = callback
	var dir = 1 if direction == "left" else -1
	var target_angle = 0.7 * dir
	var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(camera, "rotation:y", target_angle, 0.3)
	tween.tween_property(camera, "rotation:y", 0.0, 0.3)
	tween.parallel().tween_property(camera, "position:z", 0.7, 0.15)
	tween.tween_property(camera, "position:z", 0.5, 0.15)
	tween.finished.connect(_on_anim_end)

func play_walk(callback: Callable = Callable()):
	anim_callback = callback
	var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(camera, "position:z", -0.8, 0.25)
	tween.parallel().tween_property(camera, "position:y", 1.2, 0.12)
	tween.tween_property(camera, "position:z", 0.5, 0.35)
	tween.parallel().tween_property(camera, "position:y", 1.6, 0.15)
	tween.finished.connect(_on_anim_end)

func _on_anim_end():
	if anim_callback.is_valid():
		var cb = anim_callback
		anim_callback = Callable()
		cb.call()

func _process(delta):
	torch_time += delta
	var main_flicker = 0.82 + sin(torch_time * 7.3) * 0.08 + sin(torch_time * 11.7 + 1.3) * 0.05
	torch_light.light_energy = 1.8 * main_flicker

	world_env.environment.fog_density = 0.025 + sin(torch_time * 1.8) * 0.008

	for i in range(torch_lights.size()):
		var l = torch_lights[i]
		var tf = 0.7 + sin(torch_time * 9.3 + i * 1.7) * 0.15 + sin(torch_time * 14.7 + i * 2.3) * 0.1 + sin(torch_time * 5.1 + i * 0.9) * 0.05
		l.light_energy = l.get_meta("base_energy") * tf

	if not idling:
		idling = true
		var idle = create_tween().set_loops()
		idle.tween_property(camera, "position:y", 1.42, 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		idle.tween_property(camera, "position:y", 1.38, 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func set_room_type(type: int):
	room_type = type

func set_dungeon_theme(theme: String):
	theme_name = theme
	_apply_theme(theme)

func set_enemies_present(present: bool):
	has_enemies = present
	for lbl in enemy_labels:
		lbl.visible = present

func set_treasure_present(present: bool):
	has_treasure = present
	treasure_label.visible = present
