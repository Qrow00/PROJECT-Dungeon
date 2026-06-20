class_name State
extends Node

var enemy
var state_machine: StateMachine

func _ready():
	await owner.ready
	enemy = owner
	state_machine = enemy.get_node("StateMachine")

func enter():
	pass

func exit():
	pass

func update(_delta: float):
	pass
