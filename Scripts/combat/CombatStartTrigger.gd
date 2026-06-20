# DEPRECATED for turn-based 3D. Combat triggered by choice, not Area3D overlap.
class_name CombatStartTrigger
extends Node3D

@export var monster_type: String = "goblin"
@export var encounter_tier: int = 1
@export var monster_count: int = 2

func trigger_combat():
	var monsters = []
	for i in range(monster_count):
		var md = MonsterData.new(
			monster_type.capitalize() + " " + str(i + 1),
			monster_type,
			3 + encounter_tier,
			5 + encounter_tier * 2,
			10 + encounter_tier,
			2 + encounter_tier,
			"1d" + str(4 + encounter_tier * 2),
			"",
			"",
			"A " + monster_type + " enemy",
			encounter_tier,
			10 + encounter_tier * 5
		)
		monsters.append(md)

	var combat_mgr = CombatManager3D.find_instance(self)
	if combat_mgr:
		var room = _find_room()
		if room:
			combat_mgr.start_3d_combat(monsters, room)

func _find_room() -> Room:
	var p = get_parent()
	while p:
		if p is Room:
			return p
		p = p.get_parent()
	return null
