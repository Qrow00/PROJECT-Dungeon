class_name StateMachine
extends Node

signal state_changed(state_name: String)

@export var initial_state: String = "idle"

var current_state
var states: Dictionary = {}

func _ready():
	for child in get_children():
		if child.has_method("enter"):
			states[child.name.to_lower()] = child
			child.state_machine = self
	if initial_state:
		change_state(initial_state)

func change_state(state_name: String):
	var new_state = states.get(state_name.to_lower())
	if not new_state:
		return
	if current_state:
		current_state.exit()
	current_state = new_state
	current_state.enter()
	state_changed.emit(state_name)

func _physics_process(delta):
	if current_state:
		current_state.update(delta)
