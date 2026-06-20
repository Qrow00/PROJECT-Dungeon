class_name EnemyFactory
extends Node

const ENEMY_SCENES = {
	"goblin": preload("res://Scenes/enemies/Goblin.tscn"),
	"undead": preload("res://Scenes/enemies/Skeleton.tscn"),
	"beast": preload("res://Scenes/enemies/Skeleton.tscn"),
	"slime": preload("res://Scenes/enemies/Slime.tscn"),
	"cultist": preload("res://Scenes/enemies/Cultist.tscn"),
	"demon": preload("res://Scenes/enemies/Demon.tscn"),
	"dragon": preload("res://Scenes/enemies/Dragon.tscn"),
	"elemental": preload("res://Scenes/enemies/Cultist.tscn"),
	"giant": preload("res://Scenes/enemies/Demon.tscn"),
	"construct": preload("res://Scenes/enemies/Demon.tscn"),
}

func spawn_enemy(monster_data: MonsterData, position: Vector3, parent: Node):
	var scene = ENEMY_SCENES.get(monster_data.monster_type, ENEMY_SCENES["goblin"])
	if not scene:
		return null
	var instance = scene.instantiate()
	if instance.has_method("set_enemy_data"):
		instance.set_enemy_data(monster_data)
	else:
		instance.enemy_data = monster_data
	instance.position = position
	parent.add_child(instance)
	return instance
