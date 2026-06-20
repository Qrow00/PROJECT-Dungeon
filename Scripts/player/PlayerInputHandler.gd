# DEPRECATED for turn-based 3D. Real-time attack/ability input not used.
class_name PlayerInputHandler
extends Node

var is_attacking: bool = false

func _input(event):
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	if event.is_action_pressed("attack"):
		var player = get_tree().get_first_node_in_group("player") as PlayerController
		if player and not player.movement_locked:
			is_attacking = true
			_play_attack(player)
	if event.is_action_pressed("ability"):
		var player = get_tree().get_first_node_in_group("player") as PlayerController
		if player and not player.movement_locked:
			_use_ability(player)

func _play_attack(player: PlayerController):
	var anim_tree = player.get_node_or_null("AnimationTree") as AnimationTree
	if anim_tree:
		anim_tree.set("parameters/state/transition_request", "attack")
		await player.get_tree().create_timer(0.5).timeout
	is_attacking = False

func _use_ability(player: PlayerController):
	pass
