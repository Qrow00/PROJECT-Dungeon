# DEPRECATED for turn-based 3D. GameBoard manages state transitions.
class_name GameState
extends Node

enum State3D {
	EXPLORING,
	COMBAT,
	BOSS,
	LOOT,
	SHOP,
	PAUSED,
	GAME_OVER,
}

var current_state_3d: int = State3D.EXPLORING

func transition_to(state: int):
	current_state_3d = state
	match state:
		State3D.EXPLORING:
			GameManager.start_exploration()
		State3D.COMBAT:
			pass
		State3D.LOOT:
			pass
		State3D.SHOP:
			pass
		State3D.PAUSED:
			get_tree().paused = true
		State3D.GAME_OVER:
			get_tree().change_scene_to_file("res://Scenes/GameOver.tscn")
