# DEPRECATED for turn-based 3D. Rooms are pre-built scenes, not procedural.
class_name DungeonRoomTemplate
extends Node3D

func build_room(room_type: int, width: float = 10.0, depth: float = 14.0, height: float = 4.5):
	var wall_mat = StandardMaterial3D.new()
	wall_mat.albedo_color = Color(0.32, 0.24, 0.17)
	wall_mat.roughness = 0.82

	var floor_mat = StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.24, 0.20, 0.14)
	floor_mat.roughness = 0.72

	var ceil_mat = StandardMaterial3D.new()
	ceil_mat.albedo_color = Color(0.10, 0.07, 0.05)
	ceil_mat.roughness = 0.95

	var hw = width / 2.0
	var hd = depth / 2.0

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
	add_child(floor_node)

	for side in [-1, 1]:
		var wall_l = StaticBody3D.new()
		var mi_l = MeshInstance3D.new()
		var m_l = BoxMesh.new()
		m_l.size = Vector3(0.3, height, depth)
		mi_l.mesh = m_l
		mi_l.material_override = wall_mat
		wall_l.add_child(mi_l)
		var col_l = CollisionShape3D.new()
		col_l.shape = BoxShape3D.new()
		(col_l.shape as BoxShape3D).size = m_l.size
		wall_l.add_child(col_l)
		wall_l.position = Vector3(side * (hw + 0.15), height / 2, 0)
		add_child(wall_l)

	var front_wall = StaticBody3D.new()
	var mi_f = MeshInstance3D.new()
	var m_f = BoxMesh.new()
	m_f.size = Vector3(width, height, 0.3)
	mi_f.mesh = m_f
	mi_f.material_override = wall_mat
	front_wall.add_child(mi_f)
	var col_f = CollisionShape3D.new()
	col_f.shape = BoxShape3D.new()
	(col_f.shape as BoxShape3D).size = m_f.size
	front_wall.add_child(col_f)
	front_wall.position = Vector3(0, height / 2, hd)
	add_child(front_wall)

	var back_wall = StaticBody3D.new()
	var mi_b = MeshInstance3D.new()
	var m_b = BoxMesh.new()
	m_b.size = Vector3(width, height, 0.3)
	mi_b.mesh = m_b
	mi_b.material_override = wall_mat
	back_wall.add_child(mi_b)
	var col_b = CollisionShape3D.new()
	col_b.shape = BoxShape3D.new()
	(col_b.shape as BoxShape3D).size = m_b.size
	back_wall.add_child(col_b)
	back_wall.position = Vector3(0, height / 2, -hd)
	add_child(back_wall)

	var nav = NavigationRegion3D.new()
	nav.position = Vector3(0, 0.1, 0)
	add_child(nav)
