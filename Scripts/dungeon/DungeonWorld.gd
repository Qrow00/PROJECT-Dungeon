class_name DungeonWorld
extends Node3D

const EnemyFactory = preload("res://Scripts/enemies/EnemyFactory.gd")

signal room_changed(room_type: int, theme: String)
signal all_floors_cleared()

var game_world
var combat_manager
var enemies_3d: Array = []

func _ready():
	game_world = get_node("/root/GameBoard/GameWorldContainer/SubViewport/SubViewport/GameWorld")
	combat_manager = get_node("/root/GameBoard/GameWorldContainer/SubViewport/SubViewport/GameWorld/CombatManager")

func generate_current_floor():
	if game_world:
		game_world.show_room(
			GameManager.dungeon.get_current_room_type(),
			GameManager.dungeon.floor_theme
		)

func advance_to_next_room():
	var has_next = GameManager.advance_room()
	if not has_next:
		all_floors_cleared.emit()
		return
	_clear_enemies()
	if game_world:
		game_world.show_room(
			GameManager.dungeon.get_current_room_type(),
			GameManager.dungeon.floor_theme
		)
	room_changed.emit(GameManager.dungeon.get_current_room_type(), GameManager.dungeon.floor_theme)

func spawn_encounter_enemies(monster_datas: Array):
	_clear_enemies()
	if not game_world or not game_world.room_node:
		return
	var room = game_world.room_node
	var factory = EnemyFactory.new()
	add_child(factory)
	var spawns = game_world.get_enemy_spawns()
	for i in monster_datas.size():
		var md = monster_datas[i]
		if md is MonsterData:
			var pos = spawns[i].global_position if i < spawns.size() else room.global_position + Vector3(i * 2 - 2, 0, -1)
			var enemy = factory.spawn_enemy(md, pos, room)
			if enemy:
				enemies_3d.append(enemy)
	factory.queue_free()

func _clear_enemies():
	for e in enemies_3d:
		if is_instance_valid(e):
			e.queue_free()
	enemies_3d.clear()

func play_walk_animation():
	if game_world:
		game_world.play_walk_animation()

func play_turn_animation(direction: String):
	if game_world:
		game_world.play_turn_animation(direction)
