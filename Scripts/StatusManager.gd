extends Node
class_name StatusManager

var status_effects_data: Dictionary = {}

func _ready():
	load_status_data()

func load_status_data():
	var file = FileAccess.open("res://Data/StatusEffects.json", FileAccess.READ)
	if file:
		var text = file.get_as_text()
		var json = JSON.parse_string(text)
		if json is Array:
			for entry in json:
				status_effects_data[entry.id] = entry

func get_status_data(effect_id: String) -> Dictionary:
	return status_effects_data.get(effect_id, {})

func apply_status(player: PlayerData, effect_id: String, duration: int = -1) -> Dictionary:
	var data = get_status_data(effect_id)
	if data.is_empty():
		return { "success": false, "message": "Unknown status: " + effect_id }
	
	var effect = data.duplicate()
	if duration > 0:
		effect.duration = duration
	
	player.status_effects.append(effect)
	return { "success": true, "message": effect.get("name", effect_id) + " applied for " + str(effect.duration) + " turns" }

func tick_all(player: PlayerData) -> Array:
	return player.tick_statuses()

func clear_all(player: PlayerData):
	player.status_effects.clear()
