# DEPRECATED for turn-based 3D. Rooms are pre-built scenes, not procedural.
class_name RoomGenerator
extends Node

static func generate_room_basic(room_type: int, width: float = 8.0, depth: float = 12.0, height: float = 4.0) -> Node3D:
	var room = Node3D.new()

	var floor_mat = StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.25, 0.2, 0.15)
	floor_mat.roughness = 0.8

	var wall_mat = StandardMaterial3D.new()
	wall_mat.albedo_color = Color(0.35, 0.25, 0.18)
	wall_mat.roughness = 0.85

	var ceil_mat = StandardMaterial3D.new()
	ceil_mat.albedo_color = Color(0.12, 0.08, 0.05)
	ceil_mat.roughness = 0.95

	var floor_mesh = BoxMesh.new()
	floor_mesh.size = Vector3(width, 0.2, depth)
	var floor_node = StaticBody3D.new()
	var floor_mi = MeshInstance3D.new()
	floor_mi.mesh = floor_mesh
	floor_mi.material_override = floor_mat
	floor_node.add_child(floor_mi)
	var floor_col = CollisionShape3D.new()
	floor_col.shape = BoxShape3D.new()
	(floor_col.shape as BoxShape3D).size = floor_mesh.size
	floor_node.add_child(floor_col)
	floor_node.position = Vector3(0, -0.1, 0)
	room.add_child(floor_node)

	var nav = NavigationRegion3D.new()
	var nav_mesh = NavigationMesh.new()
	nav_mesh.cell_size = 0.25
	nav_mesh.agent_radius = 0.3
	nav_mesh.agent_height = 1.8
	nav_mesh.agent_max_slope = 45.0
	var vertices = PackedVector3Array([
		Vector3(-width/2 + 0.3, 0, -depth/2 + 0.3),
		Vector3(width/2 - 0.3, 0, -depth/2 + 0.3),
		Vector3(width/2 - 0.3, 0, depth/2 - 0.3),
		Vector3(-width/2 + 0.3, 0, depth/2 - 0.3),
	])
	var indices = PackedInt32Array([0, 1, 2, 0, 2, 3])
	var poly = NavigationMeshSourceGeometryData3D.new()
	poly.add_faces(vertices, indices)
	nav_mesh.cells = vertices
	nav.bake_navigation_mesh(false)
	nav.position = Vector3(0, 0.1, 0)
	room.add_child(nav)

	for side in [-1, 1]:
		var wall_mesh = BoxMesh.new()
		wall_mesh.size = Vector3(0.2, height, depth)
		var wall = StaticBody3D.new()
		var wall_mi = MeshInstance3D.new()
		wall_mi.mesh = wall_mesh
		wall_mi.material_override = wall_mat
		wall.add_child(wall_mi)
		var wall_col = CollisionShape3D.new()
		wall_col.shape = BoxShape3D.new()
		(wall_col.shape as BoxShape3D).size = wall_mesh.size
		wall.add_child(wall_col)
		wall.position = Vector3(side * width/2, height/2, 0)
		room.add_child(wall)

	for side in [-1, 1]:
		var wall_mesh = BoxMesh.new()
		wall_mesh.size = Vector3(width, height, 0.2)
		var wall = StaticBody3D.new()
		var wall_mi = MeshInstance3D.new()
		wall_mi.mesh = wall_mesh
		wall_mi.material_override = wall_mat
		wall.add_child(wall_mi)
		var wall_col = CollisionShape3D.new()
		wall_col.shape = BoxShape3D.new()
		(wall_col.shape as BoxShape3D).size = wall_mesh.size
		wall.add_child(wall_col)
		wall.position = Vector3(0, height/2, side * depth/2)
		room.add_child(wall)

	var ceil_mesh = BoxMesh.new()
	ceil_mesh.size = Vector3(width + 0.4, 0.2, depth + 0.4)
	var ceil_node = StaticBody3D.new()
	var ceil_mi = MeshInstance3D.new()
	ceil_mi.mesh = ceil_mesh
	ceil_mi.material_override = ceil_mat
	ceil_node.add_child(ceil_mi)
	ceil_node.position = Vector3(0, height, 0)
	room.add_child(ceil_node)

	var light = OmniLight3D.new()
	light.light_color = Color(1.0, 0.7, 0.35)
	light.light_energy = 0.8
	light.omni_range = 10.0
	light.position = Vector3(0, height - 0.5, 0)
	room.add_child(light)

	return room
