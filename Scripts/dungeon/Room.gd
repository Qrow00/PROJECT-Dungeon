# DEPRECATED for turn-based 3D. Room scenes managed by GameWorld directly.
class_name Room
extends Node3D

signal encounter_triggered(room: Room)

@export var room_type: int = 0
@export var room_index: int = 0
@export var enemy_spawn_points: Array[Node3D] = []
@export var loot_spawn_points: Array[Node3D] = []
@export var cleared: bool = false

var encounter_active: bool = false

func _ready():
	for child in find_children("*", "Marker3D"):
		if "EnemySpawn" in child.name:
			enemy_spawn_points.append(child)
		elif "LootSpawn" in child.name:
			loot_spawn_points.append(child)

func get_random_enemy_spawn() -> Vector3:
	if enemy_spawn_points.is_empty():
		return global_position + Vector3(randf_range(-3, 3), 0, randf_range(-3, 3))
	var sp = enemy_spawn_points.pick_random()
	return sp.global_position

func get_random_loot_spawn() -> Vector3:
	if loot_spawn_points.is_empty():
		return global_position + Vector3(randf_range(-2, 2), 0, randf_range(-2, 2))
	var sp = loot_spawn_points.pick_random()
	return sp.global_position

func on_encounter_started():
	encounter_active = true
	encounter_triggered.emit(self)

func on_cleared():
	cleared = true
	encounter_active = false
