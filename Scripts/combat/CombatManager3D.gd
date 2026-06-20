class_name CombatManager3D
extends Node3D

signal combat_finished(result: Dictionary)

var is_in_combat: bool = false
var card_combat_ui: Control = null
var combat_enemies: Array = []

func _ready():
	add_to_group("combat_manager")

func start_3d_combat(monster_datas: Array):
	if is_in_combat:
		return
	is_in_combat = true

	var dungeon_world = _get_dungeon_world()
	if dungeon_world:
		dungeon_world.spawn_encounter_enemies(monster_datas)
		combat_enemies = dungeon_world.enemies_3d

	GameManager.start_combat(monster_datas)
	_show_card_combat_ui()

func start_boss_combat():
	if is_in_combat:
		return
	is_in_combat = true
	GameManager.start_boss_combat()
	_show_card_combat_ui()

func _show_card_combat_ui():
	var scene = load("res://Scenes/ui/CardCombat3D.tscn")
	if not scene:
		return
	card_combat_ui = scene.instantiate()
	var ui_layer = _find_or_create_ui_layer()
	ui_layer.add_child(card_combat_ui)
	card_combat_ui.setup(GameManager.combat, combat_enemies, self)

func _find_or_create_ui_layer() -> CanvasLayer:
	var tree = get_tree()
	var root = tree.current_scene
	for child in root.get_children():
		if child is CanvasLayer:
			return child
	var layer = CanvasLayer.new()
	root.add_child(layer)
	layer.layer = 1
	return layer

func end_combat_victory():
	_cleanup_combat()
	var dungeon_world = _get_dungeon_world()
	if dungeon_world:
		dungeon_world._clear_enemies()
	combat_finished.emit({ "victory": true })

func end_combat_defeat():
	_cleanup_combat()
	combat_finished.emit({ "defeat": true })

func flee_combat():
	_cleanup_combat()
	var dungeon_world = _get_dungeon_world()
	if dungeon_world:
		dungeon_world._clear_enemies()
	combat_finished.emit({ "fled": true })

func _cleanup_combat():
	if card_combat_ui:
		card_combat_ui.queue_free()
		card_combat_ui = null
	is_in_combat = false

func _get_dungeon_world():
	var tree = get_tree()
	if not tree:
		return null
	return tree.get_first_node_in_group("dungeon_world")
