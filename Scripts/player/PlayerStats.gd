# DEPRECATED for turn-based 3D. PlayerData in GameManager handles stats.
class_name PlayerStats
extends Node

signal hp_changed(hp: int, max_hp: int)
signal died()

var player_data: PlayerData:
	set(value):
		player_data = value

func get_hp() -> int:
	return player_data.hp if player_data else 0

func get_max_hp() -> int:
	return player_data.max_hp if player_data else 1

func take_damage(amount: int) -> int:
	if not player_data:
		return 0
	var actual = player_data.take_damage(amount)
	hp_changed.emit(player_data.hp, player_data.max_hp)
	if player_data.hp <= 0:
		died.emit()
	return actual

func heal(amount: int) -> int:
	if not player_data:
		return 0
	var actual = player_data.heal(amount)
	hp_changed.emit(player_data.hp, player_data.max_hp)
	return actual

func is_alive() -> bool:
	return player_data and player_data.hp > 0
