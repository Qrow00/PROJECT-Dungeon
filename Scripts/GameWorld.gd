class_name GameWorld
extends Node3D

signal room_ready()

var current_room_type: int = -1
var room_node: Node3D = null
var camera: Camera3D
var camera_tween: Tween
var _hallway_nodes: Array[Node] = []

func _ready():
	camera = $Camera3D as Camera3D

func show_room(room_type: int, theme: String, is_combat: bool = false, is_boss: bool = false):
	_clear_current()
	var scene_path = _get_scene_for_type(room_type, is_boss)
	if not ResourceLoader.exists(scene_path):
		scene_path = "res://Scenes/environments/dungeon_room.tscn"
	var scene = load(scene_path)
	if not scene:
		return
	room_node = scene.instantiate()
	add_child(room_node)
	_build_hallway()
	_build_endless_background(is_boss)
	_fix_room_lights()
	_place_camera()
	_apply_theme(theme)
	_make_meshes_two_sided()
	room_ready.emit()

func _get_scene_for_type(room_type: int, is_boss: bool) -> String:
	if is_boss:
		return "res://Scenes/environments/boss_lair.tscn"
	var dm = GameManager.dungeon
	if not dm:
		return "res://Scenes/environments/dungeon_room.tscn"
	var room_map = {
		0: "dungeon_room",
		1: "treasure_hoard",
		2: "rest_site",
		5: "boss_lair",
	}
	var name = room_map.get(room_type, "dungeon_room")
	return "res://Scenes/environments/%s.tscn" % name

func _load_tex(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var tex = load(path)
		if tex is Texture2D:
			return tex
	var f = FileAccess.open(path, FileAccess.READ)
	if not f:
		return null
	var buf = f.get_buffer(f.get_length())
	var img = Image.new()
	var ext = path.get_extension()
	var err = img.load_jpg_from_buffer(buf) if ext == "jpg" or ext == "jpeg" else img.load_png_from_buffer(buf)
	if err == OK:
		return ImageTexture.create_from_image(img)
	return null

func _make_mat(tex: Texture2D, uv_scale: Vector3, color: Color) -> StandardMaterial3D:
	var m = StandardMaterial3D.new()
	m.albedo_color = color
	if tex:
		m.albedo_texture = tex
		m.uv1_scale = uv_scale
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	m.texture_repeat = 1
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m

func _make_torch(side: int, zpos: float, hw: float, height: float, rng: RandomNumberGenerator) -> StaticBody3D:
	var torch = StaticBody3D.new()
	var tilt_angle = side * deg_to_rad(30)
	
	# Iron material for sconce
	var iron_mat = StandardMaterial3D.new()
	iron_mat.albedo_color = Color(0.1, 0.1, 0.1, 1)
	iron_mat.metallic = 0.8
	iron_mat.roughness = 0.6
	
	# Bracket into the wall
	var bracket = MeshInstance3D.new()
	var bracket_mesh = BoxMesh.new()
	bracket_mesh.size = Vector3(0.15, 0.03, 0.03)
	bracket.mesh = bracket_mesh
	bracket.material_override = iron_mat
	bracket.position = Vector3(side * 0.075, 0, 0)
	torch.add_child(bracket)
	
	# Ring holding the torch
	var ring = MeshInstance3D.new()
	var ring_mesh = TorusMesh.new()
	ring_mesh.inner_radius = 0.035
	ring_mesh.outer_radius = 0.045
	ring.mesh = ring_mesh
	ring.material_override = iron_mat
	ring.rotation.z = tilt_angle # tilt with torch
	torch.add_child(ring)

	# Stick wrapper (to rotate easily)
	var stick_pivot = Node3D.new()
	stick_pivot.rotation.z = tilt_angle
	torch.add_child(stick_pivot)

	# Wood material
	var stick_mat = StandardMaterial3D.new()
	stick_mat.albedo_color = Color(0.2 + rng.randf() * 0.1, 0.12 + rng.randf() * 0.06, 0.06 + rng.randf() * 0.04, 1)

	var stick = MeshInstance3D.new()
	var stick_mesh = CylinderMesh.new()
	stick_mesh.top_radius = 0.02 + rng.randf() * 0.015
	stick_mesh.bottom_radius = 0.015 + rng.randf() * 0.01
	var stick_height = 0.35 + rng.randf() * 0.1
	stick_mesh.height = stick_height
	stick.mesh = stick_mesh
	stick.material_override = stick_mat
	# Shift stick so the pivot point is lower down (where the ring is)
	stick.position = Vector3(0, stick_height * 0.2, 0) 
	stick_pivot.add_child(stick)
	
	# Pitch wrap at the top
	var pitch_mat = StandardMaterial3D.new()
	pitch_mat.albedo_color = Color(0.05, 0.04, 0.03, 1)
	pitch_mat.roughness = 0.9
	var wrap = MeshInstance3D.new()
	var wrap_mesh = CylinderMesh.new()
	wrap_mesh.top_radius = stick_mesh.top_radius * 1.3
	wrap_mesh.bottom_radius = stick_mesh.top_radius * 1.1
	wrap_mesh.height = 0.08
	wrap.mesh = wrap_mesh
	wrap.material_override = pitch_mat
	wrap.position = Vector3(0, stick_height / 2 - 0.04, 0)
	stick.add_child(wrap)

	# Calculate top of the stick in local space of torch
	var tip_dist = stick_height * 0.7
	var tip_pos = Vector3(-sin(tilt_angle) * tip_dist, cos(tilt_angle) * tip_dist, 0)
	
	# Particles and Light
	var warm = rng.randf_range(0.9, 1.0)
	var particles = GPUParticles3D.new()
	particles.position = tip_pos
	
	var pmat = ParticleProcessMaterial.new()
	pmat.direction = Vector3(0, 1, 0)
	pmat.spread = rng.randf_range(5.0, 10.0)
	pmat.initial_velocity_min = 0.2
	pmat.initial_velocity_max = 0.5
	pmat.gravity = Vector3(0, 1.5, 0)
	pmat.scale_min = 0.15
	pmat.scale_max = 0.25
	var scale_curve = Curve.new()
	scale_curve.add_point(Vector2(0, 0.5))
	scale_curve.add_point(Vector2(0.2, 1))
	scale_curve.add_point(Vector2(0.5, 0.7))
	scale_curve.add_point(Vector2(1, 0))
	pmat.scale_curve = scale_curve
	var ramp = Gradient.new()
	ramp.colors = PackedColorArray([
		Color(warm, warm * 0.95, warm * 0.55, 1),
		Color(warm, warm * 0.8, warm * 0.25, 0.9),
		Color(warm * 0.65, warm * 0.15, 0.02, 0.3),
	])
	ramp.offsets = PackedFloat32Array([0, 0.35, 1])
	pmat.color_ramp = ramp
	pmat.angular_velocity_min = -3.0
	pmat.angular_velocity_max = 3.0
	particles.process_material = pmat
	particles.amount = rng.randi_range(60, 80)
	particles.lifetime = rng.randf_range(0.4, 0.6)
	particles.explosiveness = 0.0
	particles.randomness = rng.randf_range(0.2, 0.35)
	particles.fixed_fps = 0
	particles.local_coords = true
	particles.one_shot = false
	particles.emitting = true
	
	var flame_quad = QuadMesh.new()
	flame_quad.size = Vector2(0.1, 0.16)
	var add_mat = ShaderMaterial.new()
	add_mat.shader = preload("res://Shaders/particle_add.gdshader")
	flame_quad.material = add_mat
	particles.draw_pass_1 = flame_quad
	torch.add_child(particles)

	var light = OmniLight3D.new()
	light.light_color = Color(1, 0.7, 0.35, 1)
	light.light_energy = 4.0
	light.omni_range = 10.0
	light.light_indirect_energy = 1.0
	light.position = tip_pos
	torch.add_child(light)

	torch.position = Vector3(side * (hw - 0.15), height, zpos)
	torch.set_script(preload("res://Scripts/TorchFlicker.gd"))
	return torch

func _fix_room_lights():
	if not room_node:
		return
	for light in room_node.find_children("*", "OmniLight3D"):
		light.light_color = Color(1, 0.65, 0.3, 1)
		light.light_energy = 0.8
		light.omni_range = 10.0

func _build_hallway():
	if not room_node:
		return
	var hw = 2.5
	var hh = 2.25
	var hlen = 20.0
	var start_z = 7.15
	var t = 0.2

	var wall_tex = _load_tex("res://Assets/wall_texture.jpg")
	var floor_tex = _load_tex("res://Assets/floor_texture.jpg")
	var wall_mat = StandardMaterial3D.new()
	wall_mat.albedo_texture = wall_tex
	wall_mat.albedo_color = Color(0.4, 0.4, 0.4)
	wall_mat.uv1_scale = Vector3(20, 6, 1)
	wall_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	wall_mat.texture_repeat = 1
	wall_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var floor_mat = StandardMaterial3D.new()
	floor_mat.albedo_texture = floor_tex
	floor_mat.albedo_color = Color(0.7, 0.7, 0.7)
	floor_mat.uv1_scale = Vector3(2, 8, 1)
	floor_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	floor_mat.texture_repeat = 1
	floor_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var ceil_mat = StandardMaterial3D.new()
	ceil_mat.albedo_color = Color(0.12, 0.12, 0.1)
	ceil_mat.cull_mode = BaseMaterial3D.CULL_DISABLED

	for side in [-1, 1]:
		var wall = StaticBody3D.new()
		var mi = MeshInstance3D.new()
		var mesh = BoxMesh.new()
		mesh.size = Vector3(t, hh * 2, hlen)
		mi.mesh = mesh
		mi.material_override = wall_mat.duplicate()
		wall.add_child(mi)
		wall.position = Vector3(side * hw, hh, start_z + hlen / 2)
		room_node.add_child(wall)
		_hallway_nodes.append(wall)

	var floor_node = StaticBody3D.new()
	var floor_mi = MeshInstance3D.new()
	var floor_mesh = BoxMesh.new()
	floor_mesh.size = Vector3(hw * 2, t, hlen)
	floor_mi.mesh = floor_mesh
	floor_mi.material_override = floor_mat.duplicate()
	floor_node.add_child(floor_mi)
	floor_node.position = Vector3(0, -t / 2, start_z + hlen / 2)
	room_node.add_child(floor_node)
	_hallway_nodes.append(floor_node)

	var ceil_node = StaticBody3D.new()
	var ceil_mi = MeshInstance3D.new()
	var ceil_mesh = BoxMesh.new()
	ceil_mesh.size = Vector3(hw * 2 + t * 2, t, hlen)
	ceil_mi.mesh = ceil_mesh
	ceil_mi.material_override = ceil_mat.duplicate()
	ceil_node.add_child(ceil_mi)
	ceil_node.position = Vector3(0, hh * 2, start_z + hlen / 2)
	room_node.add_child(ceil_node)
	_hallway_nodes.append(ceil_node)

	var end_wall = StaticBody3D.new()
	var end_mi = MeshInstance3D.new()
	var end_mesh = BoxMesh.new()
	end_mesh.size = Vector3(hw * 2 + t * 2, hh * 2, t)
	end_mi.mesh = end_mesh
	end_mi.material_override = wall_mat.duplicate()
	end_wall.add_child(end_mi)
	end_wall.position = Vector3(0, hh, start_z + hlen + t / 2)
	room_node.add_child(end_wall)
	_hallway_nodes.append(end_wall)

	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var count = rng.randi_range(4, 7)
	var spacing = (hlen - 4.0) / float(count)
	for i in count:
		var side = -1 if rng.randf() < 0.5 else 1
		var z = start_z + 2.0 + spacing * i + rng.randf_range(-0.8, 0.8)
		var y = rng.randf_range(1.0, 2.0)
		var torch = _make_torch(side, z, hw, y, rng)
		room_node.add_child(torch)
		_hallway_nodes.append(torch)

func _place_camera():
	if not room_node: return
	var cam_pos = room_node.get_node_or_null("CameraPosition")
	if cam_pos:
		camera.global_position = cam_pos.global_position
		var look = cam_pos.get_node_or_null("LookAt")
		if look:
			camera.look_at(look.global_position)
		else:
			camera.look_at(room_node.global_position)
	else:
		camera.position = Vector3(0, 2.0, 26)
		camera.look_at(Vector3(0, 0.5, 0))

func play_walk_animation():
	if not camera: return
	var t = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	t.tween_property(camera, "position:z", camera.position.z - 1.0, 0.25)
	t.tween_property(camera, "position:z", camera.position.z, 0.3)

func play_turn_animation(direction: String):
	if not camera: return
	var dir = 1.0 if direction == "left" else -1.0
	var t = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	t.tween_property(camera, "rotation:y", 0.4 * dir, 0.2)
	t.tween_property(camera, "rotation:y", 0.0, 0.25)

func _apply_theme(theme: String):
	var colors = {
		"Dark Caverns": Color(0.2, 0.2, 0.2),
		"Ancient Ruins": Color(0.2, 0.2, 0.2),
		"Crystal Caves": Color(0.2, 0.2, 0.2),
		"Lava Tunnels": Color(0.2, 0.2, 0.2),
		"Frozen Depths": Color(0.2, 0.2, 0.2),
		"Abyssal Vaults": Color(0.2, 0.2, 0.2),
	}
	var env = get_node_or_null("WorldEnvironment")
	if not env:
		env = WorldEnvironment.new()
		var new_env = Environment.new()
		env.environment = new_env
		add_child(env)
		
	if env and env.environment:
		env.environment.ambient_light_color = colors.get(theme, Color(0, 0, 0))
		env.environment.ambient_light_energy = 0.0
		env.environment.ambient_light_sky_contribution = 0.0
		env.environment.fog_enabled = true
		env.environment.fog_mode = Environment.FOG_MODE_EXPONENTIAL
		env.environment.fog_density = 0.035
		env.environment.fog_light_color = Color(0.02, 0.015, 0.01) # Very dark fog


func _make_meshes_two_sided():
	for child in room_node.find_children("*", "MeshInstance3D"):
		var mat = child.material_override
		if not mat:
			mat = StandardMaterial3D.new()
			mat.cull_mode = BaseMaterial3D.CULL_DISABLED
			child.material_override = mat
		elif mat is StandardMaterial3D:
			mat = mat.duplicate()
			mat.cull_mode = BaseMaterial3D.CULL_DISABLED
			child.material_override = mat

func _clear_current():
	if room_node:
		room_node.queue_free()
		room_node = null

func get_enemy_spawns() -> Array:
	if not room_node: return []
	var spawns = []
	for child in room_node.find_children("*EnemySpawn*", "Marker3D"):
		spawns.append(child)
	return spawns

func _build_endless_background(is_boss: bool):
	if not room_node: return
	
	# Hide default back wall (in dungeon_room.tscn, it's Walls/WallBack)
	var back_wall = room_node.get_node_or_null("Walls/WallBack")
	if back_wall:
		back_wall.hide()
		
	var hw = 2.5
	var hh = 2.25
	var start_z = -7.15
	var hlen = 20.0 if is_boss else 80.0
	var t = 0.2
	
	var wall_tex = _load_tex("res://Assets/wall_texture.jpg")
	var floor_tex = _load_tex("res://Assets/floor_texture.jpg")
	var wall_mat = StandardMaterial3D.new()
	wall_mat.albedo_texture = wall_tex
	wall_mat.albedo_color = Color(0.4, 0.4, 0.4)
	wall_mat.uv1_scale = Vector3(hlen, 6, 1)
	wall_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	wall_mat.texture_repeat = 1
	wall_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	
	var floor_mat = StandardMaterial3D.new()
	floor_mat.albedo_texture = floor_tex
	floor_mat.albedo_color = Color(0.7, 0.7, 0.7)
	floor_mat.uv1_scale = Vector3(2, hlen / 2.5, 1)
	floor_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	floor_mat.texture_repeat = 1
	floor_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	
	var ceil_mat = StandardMaterial3D.new()
	ceil_mat.albedo_color = Color(0.12, 0.12, 0.1)
	ceil_mat.cull_mode = BaseMaterial3D.CULL_DISABLED

	for side in [-1, 1]:
		var wall = StaticBody3D.new()
		var mi = MeshInstance3D.new()
		var mesh = BoxMesh.new()
		mesh.size = Vector3(t, hh * 2, hlen)
		mi.mesh = mesh
		mi.material_override = wall_mat.duplicate()
		wall.add_child(mi)
		wall.position = Vector3(side * hw, hh, start_z - hlen / 2)
		room_node.add_child(wall)
		_hallway_nodes.append(wall)

	var floor_node = StaticBody3D.new()
	var floor_mi = MeshInstance3D.new()
	var floor_mesh = BoxMesh.new()
	floor_mesh.size = Vector3(hw * 2, t, hlen)
	floor_mi.mesh = floor_mesh
	floor_mi.material_override = floor_mat.duplicate()
	floor_node.add_child(floor_mi)
	floor_node.position = Vector3(0, -t / 2, start_z - hlen / 2)
	room_node.add_child(floor_node)
	_hallway_nodes.append(floor_node)

	var ceil_node = StaticBody3D.new()
	var ceil_mi = MeshInstance3D.new()
	var ceil_mesh = BoxMesh.new()
	ceil_mesh.size = Vector3(hw * 2 + t * 2, t, hlen)
	ceil_mi.mesh = ceil_mesh
	ceil_mi.material_override = ceil_mat.duplicate()
	ceil_node.add_child(ceil_mi)
	ceil_node.position = Vector3(0, hh * 2, start_z - hlen / 2)
	room_node.add_child(ceil_node)
	_hallway_nodes.append(ceil_node)

	var end_z = start_z - hlen

	if is_boss:
		# Huge Double Doors
		var door_left = StaticBody3D.new()
		var dl_mi = MeshInstance3D.new()
		var dl_mesh = BoxMesh.new()
		dl_mesh.size = Vector3(hw, hh * 2, 0.4)
		dl_mi.mesh = dl_mesh
		var door_mat = StandardMaterial3D.new()
		door_mat.albedo_color = Color(0.12, 0.08, 0.05)
		door_mat.roughness = 0.9
		dl_mi.material_override = door_mat
		door_left.add_child(dl_mi)
		door_left.position = Vector3(-hw / 2, hh, end_z)
		room_node.add_child(door_left)
		_hallway_nodes.append(door_left)
		
		var door_right = StaticBody3D.new()
		var dr_mi = MeshInstance3D.new()
		var dr_mesh = BoxMesh.new()
		dr_mesh.size = Vector3(hw, hh * 2, 0.4)
		dr_mi.mesh = dr_mesh
		dr_mi.material_override = door_mat
		door_right.add_child(dr_mi)
		door_right.position = Vector3(hw / 2, hh, end_z)
		room_node.add_child(door_right)
		_hallway_nodes.append(door_right)
		
		for side in [-1, 1]:
			var handle = MeshInstance3D.new()
			var h_mesh = TorusMesh.new()
			h_mesh.inner_radius = 0.15
			h_mesh.outer_radius = 0.2
			handle.mesh = h_mesh
			var h_mat = StandardMaterial3D.new()
			h_mat.albedo_color = Color(0.8, 0.7, 0.2)
			h_mat.metallic = 0.9
			handle.material_override = h_mat
			handle.rotation.x = deg_to_rad(90)
			handle.position = Vector3(side * 0.4, hh, end_z + 0.25)
			room_node.add_child(handle)
			_hallway_nodes.append(handle)
	else:
		# T-Junction (L-Turn)
		var turn_back_wall = StaticBody3D.new()
		var bw_mi = MeshInstance3D.new()
		var bw_mesh = BoxMesh.new()
		bw_mesh.size = Vector3(40.0, hh * 2, t)
		bw_mi.mesh = bw_mesh
		bw_mi.material_override = wall_mat.duplicate()
		turn_back_wall.add_child(bw_mi)
		turn_back_wall.position = Vector3(0, hh, end_z - hw)
		room_node.add_child(turn_back_wall)
		_hallway_nodes.append(turn_back_wall)
		
		var front_wall_left = StaticBody3D.new()
		var fwl_mi = MeshInstance3D.new()
		var fwl_mesh = BoxMesh.new()
		fwl_mesh.size = Vector3(20.0, hh * 2, t)
		fwl_mi.mesh = fwl_mesh
		fwl_mi.material_override = wall_mat.duplicate()
		front_wall_left.add_child(fwl_mi)
		front_wall_left.position = Vector3(-hw - 10.0, hh, end_z + hw)
		room_node.add_child(front_wall_left)
		_hallway_nodes.append(front_wall_left)
		
		var front_wall_right = StaticBody3D.new()
		var fwr_mi = MeshInstance3D.new()
		var fwr_mesh = BoxMesh.new()
		fwr_mesh.size = Vector3(20.0, hh * 2, t)
		fwr_mi.mesh = fwr_mesh
		fwr_mi.material_override = wall_mat.duplicate()
		front_wall_right.add_child(fwr_mi)
		front_wall_right.position = Vector3(hw + 10.0, hh, end_z + hw)
		room_node.add_child(front_wall_right)
		_hallway_nodes.append(front_wall_right)

	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var count = 8 if is_boss else 16
	var spacing = (hlen - 4.0) / float(count)
	for i in count:
		var side = -1 if rng.randf() < 0.5 else 1
		var z = start_z - 2.0 - spacing * i - rng.randf_range(-0.8, 0.8)
		var y = rng.randf_range(1.0, 2.0)
		var torch = _make_torch(side, z, hw, y, rng)
		room_node.add_child(torch)
		_hallway_nodes.append(torch)
