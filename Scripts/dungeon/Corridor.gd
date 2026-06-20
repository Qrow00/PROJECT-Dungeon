# DEPRECATED for turn-based 3D. Procedural corridors replaced by room scenes.
class_name Corridor
extends Node3D

const CORRIDOR_WIDTH: float = 4.0
const CORRIDOR_HEIGHT: float = 4.0
const CORRIDOR_DEPTH: float = 16.0
const WALL_THICKNESS: float = 0.3

func _ready():
	build_corridor()

func build_corridor():
	var wall_mat = StandardMaterial3D.new()
	wall_mat.albedo_color = Color(0.3, 0.22, 0.16)
	wall_mat.roughness = 0.85

	var floor_mat = StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.22, 0.18, 0.12)
	floor_mat.roughness = 0.75

	var ceil_mat = StandardMaterial3D.new()
	ceil_mat.albedo_color = Color(0.1, 0.07, 0.05)
	ceil_mat.roughness = 0.95

	var hw = CORRIDOR_WIDTH / 2.0
	var hd = CORRIDOR_DEPTH / 2.0
	var hh = CORRIDOR_HEIGHT / 2.0

	for side in [-1, 1]:
		var wall = StaticBody3D.new()
		var mi = MeshInstance3D.new()
		var mesh = BoxMesh.new()
		mesh.size = Vector3(WALL_THICKNESS, CORRIDOR_HEIGHT, CORRIDOR_DEPTH)
		mi.mesh = mesh
		mi.material_override = wall_mat
		wall.add_child(mi)
		var col = CollisionShape3D.new()
		col.shape = BoxShape3D.new()
		(col.shape as BoxShape3D).size = mesh.size
		wall.add_child(col)
		wall.position = Vector3(side * (hw + WALL_THICKNESS / 2), hh, 0)
		add_child(wall)

	var floor_node = StaticBody3D.new()
	var floor_mi = MeshInstance3D.new()
	var floor_mesh = BoxMesh.new()
	floor_mesh.size = Vector3(CORRIDOR_WIDTH, 0.2, CORRIDOR_DEPTH)
	floor_mi.mesh = floor_mesh
	floor_mi.material_override = floor_mat
	floor_node.add_child(floor_mi)
	var floor_col = CollisionShape3D.new()
	floor_col.shape = BoxShape3D.new()
	(floor_col.shape as BoxShape3D).size = floor_mesh.size
	floor_node.add_child(floor_col)
	floor_node.position = Vector3(0, -0.1, 0)
	add_child(floor_node)

	var nav = NavigationRegion3D.new()
	nav.position = Vector3(0, 0.1, 0)
	add_child(nav)

	var ceil_node = StaticBody3D.new()
	var ceil_mi = MeshInstance3D.new()
	var ceil_mesh = BoxMesh.new()
	ceil_mesh.size = Vector3(CORRIDOR_WIDTH + WALL_THICKNESS * 2, 0.2, CORRIDOR_DEPTH)
	ceil_mi.mesh = ceil_mesh
	ceil_mi.material_override = ceil_mat
	ceil_node.add_child(ceil_mi)
	ceil_node.position = Vector3(0, CORRIDOR_HEIGHT, 0)
	add_child(ceil_node)

	_add_torches(hw, hh)

func _add_torches(hw: float, hh: float):
	var torch_count = 4
	var torch_mat = StandardMaterial3D.new()
	torch_mat.albedo_color = Color(0.4, 0.3, 0.15)
	torch_mat.emission_enabled = true
	torch_mat.emission = Color(1.0, 0.5, 0.1)

	for i in range(torch_count):
		var side = 1 if i % 2 == 0 else -1
		var depth = -CORRIDOR_DEPTH / 2 + 2.0 + i * (CORRIDOR_DEPTH - 4.0) / (torch_count - 1)

		var torch = MeshInstance3D.new()
		var mesh = CylinderMesh.new()
		mesh.top_radius = 0.04
		mesh.bottom_radius = 0.06
		mesh.height = 0.3
		torch.mesh = mesh
		torch.material_override = torch_mat
		torch.position = Vector3(side * (hw - 0.1), hh - 0.3, depth)
		add_child(torch)

		var light = OmniLight3D.new()
		light.light_color = Color(1.0, 0.5, 0.1)
		light.light_energy = 0.6
		light.omni_range = 6.0
		light.position = Vector3(side * (hw - 0.1), hh - 0.1, depth)
		add_child(light)
