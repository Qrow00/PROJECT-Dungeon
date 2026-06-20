extends Node
class_name RoguelikeManager

var save_path: String = "user://dungeon_card_save.json"
var unlocks: Dictionary = {
	"classes_unlocked": ["warrior"],
	"highest_floor": 0,
	"total_runs": 0,
	"total_monsters_killed": 0,
	"total_gold_earned": 0,
	"achievements": []
}

func _ready():
	load_game()

func load_game():
	if FileAccess.file_exists(save_path):
		var file = FileAccess.open(save_path, FileAccess.READ)
		var text = file.get_as_text()
		var data = JSON.parse_string(text)
		if data is Dictionary:
			for key in unlocks.keys():
				if data.has(key):
					unlocks[key] = data[key]

func save_game():
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(unlocks))

func is_class_unlocked(class_id: String) -> bool:
	return class_id in unlocks.classes_unlocked

func unlock_class(class_id: String):
	if not is_class_unlocked(class_id):
		unlocks.classes_unlocked.append(class_id)
		save_game()

func get_unlock_requirements() -> Dictionary:
	return {
		"rogue": { "description": "Reach floor 3", "condition": unlocks.highest_floor >= 3 },
		"mage": { "description": "Reach floor 5", "condition": unlocks.highest_floor >= 5 },
		"paladin": { "description": "Win a run", "condition": false }
	}

func check_achievements(floor: int, monsters_killed: int):
	if floor >= 3 and not "reach_floor_3" in unlocks.achievements:
		unlocks.achievements.append("reach_floor_3")
		save_game()
		return "Achievement: Depth Seeker (Reach Floor 3)"
	if floor >= 5 and not "reach_floor_5" in unlocks.achievements:
		unlocks.achievements.append("reach_floor_5")
		if not is_class_unlocked("mage"):
			unlock_class("mage")
		save_game()
		return "Achievement: Dungeon Delver (Reach Floor 5) - Mage unlocked!"
	if monsters_killed >= 20 and not "kill_20" in unlocks.achievements:
		unlocks.achievements.append("kill_20")
		save_game()
		return "Achievement: Slayer (Kill 20 monsters)"
	return ""

func record_run(floor: int, monsters_killed: int, gold_earned: int):
	unlocks.total_runs += 1
	unlocks.total_monsters_killed += monsters_killed
	unlocks.total_gold_earned += gold_earned
	if floor > unlocks.highest_floor:
		unlocks.highest_floor = floor
	save_game()
