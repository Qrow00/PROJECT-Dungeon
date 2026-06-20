extends Node
class_name CombatSystem

signal combat_log(message: Dictionary)
signal combat_ended(result: Dictionary)

enum CombatState { PLAYER_TURN, ENEMY_TURN, ANIMATING, VICTORY, DEFEAT }

var player: PlayerData
var deck_manager: DeckManager
var enemies: Array = []
var state: int = CombatState.PLAYER_TURN
var turn_number: int = 0
var player_defending: bool = false
var player_evasion_charges: int = 0
var combat_messages: Array = []
var player_rest_cooldown: int = 0
var current_initiative: int = 0
var rng: RandomNumberGenerator

func _init(p_player: PlayerData, p_deck: DeckManager):
	player = p_player
	deck_manager = p_deck
	rng = RandomNumberGenerator.new()
	rng.randomize()

func start_combat(monsters: Array, loot_system) -> Dictionary:
	enemies = monsters.duplicate()
	state = CombatState.PLAYER_TURN
	turn_number = 0
	player_defending = false
	player_evasion_charges = 0
	combat_messages = []
	player_rest_cooldown = 0
	for e in enemies:
		e.reset_hp()
	combat_messages.append({ "type": "info", "text": "Combat begins! " + str(enemies.size()) + " enemy(ies)." })
	for e in enemies:
		combat_messages.append({ "type": "enemy_intro", "text": e.monster_name + " (" + str(e.hp) + " HP, AC " + str(e.ac) + ")" })
	return { "success": true, "messages": combat_messages }

func roll_initiative() -> int:
	current_initiative = rng.randi_range(1, 20) + player.get_attack_roll()
	return current_initiative

func process_player_action(action_id: String, target_index: int = -1) -> Dictionary:
	var result = { "success": false, "messages": [], "action": action_id }
	if state != CombatState.PLAYER_TURN:
		result.messages.append({ "type": "error", "text": "Not your turn!" })
		return result

	if enemies.is_empty():
		result.messages.append({ "type": "error", "text": "No enemies!" })
		return result

	player_defending = false
	roll_initiative()
	result.messages.append({ "type": "initiative", "text": "Initiative: d20+" + str(player.get_attack_roll()) + " = " + str(current_initiative) })

	match action_id:
		"attack": result = _do_attack(target_index)
		"power_attack": result = _do_power_attack(target_index)
		"defend": result = _do_defend()
		"called_shot": result = _do_called_shot(target_index)
		"use_ability": result = _do_class_ability(target_index)
		"use_item": result = _do_use_item(target_index)
		"flee": result = _do_flee()
		_:
			result.messages.append({ "type": "error", "text": "Unknown action!" })
			return result

	if not result.get("success", false):
		return result

	for msg in result.get("messages", []):
		combat_log.emit(msg)

	if result.get("fled", false):
		return result

	if result.get("target", null):
		_check_enemy_death(result.target)

	if _is_combat_over():
		return result

	state = CombatState.ENEMY_TURN

	return result

func _do_attack(target_index: int) -> Dictionary:
	var result = { "success": false, "messages": [], "action": "attack" }
	var target = _get_valid_target(target_index)
	if not target:
		result.messages.append({ "type": "error", "text": "Invalid target!" })
		return result

	var roll = current_initiative
	var msg = "Attack " + target.monster_name + "! d20+" + str(player.get_attack_roll()) + "=" + str(roll) + " vs AC " + str(target.ac)
	result.messages.append({ "type": "info", "text": msg, "flavor": GameManager.dungeon.get_action_narration("attack", target.monster_name) })

	if roll >= target.ac:
		var damage = player.get_weapon_damage_roll()
		if player.has_ability("backstab") and enemies.size() > 1:
			var extra = rng.randi_range(2, 12)
			damage += extra
			result.messages.append({ "type": "class_ability", "text": "Backstab! +" + str(extra) + " damage!" })
		target.take_damage(damage)
		result.messages.append({ "type": "hit", "text": "Hit! " + str(damage) + " damage." })
		result.damage_dealt = damage
		result.target = target
		if rng.randi_range(1, 20) == 20:
			var crit = damage
			target.take_damage(crit)
			result.messages.append({ "type": "crit", "text": "Critical! +" + str(crit) + " damage!" })
			result.damage_dealt += crit
	else:
		result.messages.append({ "type": "miss", "text": "Miss!" })

	result.success = true
	return result

func _do_power_attack(target_index: int) -> Dictionary:
	var result = { "success": false, "messages": [], "action": "power_attack" }
	var target = _get_valid_target(target_index)
	if not target:
		result.messages.append({ "type": "error", "text": "Invalid target!" })
		return result

	var roll = current_initiative - 3
	result.messages.append({ "type": "info", "text": "Power attack! d20+" + str(player.get_attack_roll() - 3) + "=" + str(roll) + " vs AC " + str(target.ac), "flavor": GameManager.dungeon.get_action_narration("power_attack") })

	if roll >= target.ac:
		var damage = player.get_weapon_damage_roll() * 2
		target.take_damage(damage)
		result.messages.append({ "type": "hit", "text": "Crushing blow! " + str(damage) + " damage!" })
		result.damage_dealt = damage
		result.target = target
	else:
		result.messages.append({ "type": "miss", "text": "Power attack misses!" })

	result.success = true
	return result

func _do_defend() -> Dictionary:
	var result = { "success": false, "messages": [], "action": "defend" }
	player_defending = true
	var heal_amt = floor(current_initiative / 3) + 1
	player.heal(heal_amt)
	result.messages.append({ "type": "info", "text": "Brace! +4 AC, +" + str(heal_amt) + " HP.", "flavor": GameManager.dungeon.get_action_narration("defend") })
	result.success = true
	return result

func _do_called_shot(target_index: int) -> Dictionary:
	var result = { "success": false, "messages": [], "action": "called_shot" }
	var target = _get_valid_target(target_index)
	if not target:
		result.messages.append({ "type": "error", "text": "Invalid target!" })
		return result

	var roll = current_initiative - 5
	result.messages.append({ "type": "info", "text": "Called shot! Roll " + str(roll) + " vs AC " + str(target.ac), "flavor": GameManager.dungeon.get_action_narration("called_shot", target.monster_name) })

	if roll >= target.ac:
		var damage = player.get_weapon_damage_roll()
		target.take_damage(damage)
		result.messages.append({ "type": "hit", "text": "Hit! " + str(damage) + " damage!" })
		result.damage_dealt = damage
		result.target = target
		var effects = ["stagger", "blind", "disarm"]
		var effect = effects[rng.randi() % effects.size()]
		match effect:
			"stagger":
				target.attack_bonus = max(0, target.attack_bonus - 2)
				result.messages.append({ "type": "ability", "text": "Staggered! -2 attack." })
			"blind":
				target.ac = max(target.ac - 2, 10)
				result.messages.append({ "type": "ability", "text": "Blinded! -2 AC." })
			"disarm":
				result.messages.append({ "type": "ability", "text": "Disarmed! Halved damage." })
	else:
		result.messages.append({ "type": "miss", "text": "Called shot misses!" })

	result.success = true
	return result

func _do_class_ability(target_index: int) -> Dictionary:
	var result = { "success": false, "messages": [], "action": "class_ability" }
	result.messages.append({ "type": "info", "text": "", "flavor": GameManager.dungeon.get_action_narration("use_ability") })
	var class_id = player.character_class.get("id", "")

	match class_id:
		"warrior":
			if player.has_ability("cleave"):
				var msgs = []
				for e in enemies:
					var dmg = max(1, floor(current_initiative / 3))
					e.take_damage(dmg)
					msgs.append({ "type": "hit", "text": "Cleave hits " + e.monster_name + " for " + str(dmg) + "!" })
				result.messages = msgs
				result.success = true
				return result
		"rogue":
			if player.has_ability("evasion") and player_evasion_charges < 1:
				player_evasion_charges = 1
				result.messages = [{ "type": "class_ability", "text": "Evasion ready!" }]
				result.success = true
				return result
			if player.has_ability("shadowstep"):
				result.messages = [{ "type": "class_ability", "text": "Shadowstep! Vanish and reposition." }]
				result.success = true
				return result
		"mage":
			if player.has_ability("firebolt"):
				var target = _get_valid_target(target_index)
				if not target:
					result.messages = [{ "type": "error", "text": "Invalid target!" }]
					return result
				var damage = floor(current_initiative / 2)
				target.take_damage(damage)
				result.messages = [{ "type": "class_ability", "text": "Firebolt! " + str(damage) + " damage to " + target.monster_name + "!" }]
				result.damage_dealt = damage
				result.target = target
				result.success = true
				return result
			if player.has_ability("frost_armor"):
				var existing = null
				for e in player.status_effects:
					if e.id == "frost_armor":
						existing = e
						break
				if not existing:
					player.status_effects.append({ "id": "frost_armor", "ac_bonus": 3, "duration": 3 })
					result.messages = [{ "type": "class_ability", "text": "Frost armor! +3 AC for 3 turns." }]
					result.success = true
					return result
		"paladin":
			if player.has_ability("smite"):
				var target = _get_valid_target(target_index)
				if not target:
					result.messages = [{ "type": "error", "text": "Invalid target!" }]
					return result
				if current_initiative >= target.ac:
					var damage = player.get_weapon_damage_roll() + floor(current_initiative / 3)
					target.take_damage(damage)
					result.messages = [{ "type": "class_ability", "text": "Smite! " + str(damage) + " holy damage!" }]
					result.damage_dealt = damage
					result.target = target
				else:
					result.messages = [{ "type": "miss", "text": "Smite misses!" }]
				result.success = true
				return result

	result.messages = [{ "type": "error", "text": "Ability not available!" }]
	return result

func _do_use_item(index: int) -> Dictionary:
	var result = { "success": false, "messages": [], "action": "use_item" }
	if index < 0 or index >= player.consumables.size():
		result.messages.append({ "type": "error", "text": "Invalid item!" })
		return result
	var item = player.use_consumable(index)
	var base_heal = item.get("value", 5)
	var bonus = floor(current_initiative / 4)
	var total = base_heal + bonus
	var actual = player.heal(total)
	result.messages.append({ "type": "heal", "text": item.get("name", "Potion") + "! +" + str(actual) + " HP (initiative bonus +" + str(bonus) + ")." })
	result.success = true
	return result

func _do_flee() -> Dictionary:
	var result = { "success": false, "messages": [], "action": "flee" }
	var dc = 10 + enemies.size() * 2
	var roll = current_initiative
	var enemy_name = enemies[0].monster_name if enemies.size() > 0 else "enemy"
	result.messages.append({ "type": "info", "text": "Flee! Roll " + str(roll) + " vs DC " + str(dc), "flavor": GameManager.dungeon.get_action_narration("flee", enemy_name) })
	if roll >= dc:
		result.messages.append({ "type": "victory", "text": "You escape!" })
		result.fled = true
	else:
		result.messages.append({ "type": "damage", "text": "Failed to escape!" })
		result.fled = false
	result.success = true
	return result

func process_enemy_turn() -> Array:
	var messages = []
	if _is_combat_over():
		return messages

	for enemy in enemies:
		if not enemy.is_alive():
			continue

		if player_evasion_charges > 0:
			messages.append({ "type": "info", "text": enemy.monster_name + " attacks but you evade!" })
			player_evasion_charges -= 1
			continue

		var ac_bonus = 4 if player_defending else 0
		var roll = rng.randi_range(1, 20) + enemy.attack_bonus
		var target_ac = player.get_total_ac() + ac_bonus
		var flavor = GameManager.dungeon.get_enemy_narration(enemy.monster_name, roll >= target_ac)
		var atk_msg = enemy.monster_name + " attacks! d20+" + str(enemy.attack_bonus) + "=" + str(roll) + " vs AC " + str(target_ac)
		messages.append({ "type": "info", "text": atk_msg, "flavor": flavor })

		if roll >= target_ac:
			var damage = enemy.roll_damage()
			_apply_enemy_ability(enemy, messages)
			var actual = player.take_damage(damage)
			messages.append({ "type": "damage", "text": enemy.monster_name + " hits for " + str(actual) + "!" })
		else:
			messages.append({ "type": "info", "text": enemy.monster_name + " misses!" })

		if not player.is_alive():
			_do_auto_revive(messages)
			if not player.is_alive():
				state = CombatState.DEFEAT
				messages.append({ "type": "defeat", "text": "You fall!" })
				end_combat()
				return messages

	for msg in messages:
		combat_log.emit(msg)
	state = CombatState.PLAYER_TURN
	turn_number += 1

	if _is_combat_over():
		end_combat()
		return messages

	var all_dead = true
	for e in enemies:
		if e.is_alive():
			all_dead = false
			break

	if all_dead:
		state = CombatState.VICTORY
		messages.append({ "type": "victory", "text": "All enemies defeated!" })
		end_combat()

	return messages

func _check_enemy_death(enemy: MonsterData):
	if not enemy.is_alive() and enemy in enemies:
		enemies.erase(enemy)
		if enemies.is_empty():
			state = CombatState.VICTORY
			end_combat()

func _apply_enemy_ability(enemy: MonsterData, messages: Array):
	var ability = enemy.ability_id
	if ability == "":
		return
	match ability:
		"burn":
			var dmg = 2 if enemy.tier >= 3 else 1
			player.status_effects.append({ "id": "burn", "damage_per_turn": dmg, "duration": 2 })
			messages.append({ "type": "status", "text": enemy.monster_name + " burns you!" })
		"curse":
			var penalty = 3 if enemy.tier >= 4 else 2
			player.status_effects.append({ "id": "weakness", "weapon_penalty": penalty, "duration": 2 })
			messages.append({ "type": "status", "text": enemy.monster_name + " curses your weapon!" })
		"poison":
			var dmg = 3 if enemy.tier >= 3 else 2
			player.status_effects.append({ "id": "poison", "damage_per_turn": dmg, "duration": 3 })
			messages.append({ "type": "status", "text": enemy.monster_name + " poisons you!" })
		"drain":
			if enemy.hp < enemy.max_hp:
				var drain = enemy.roll_damage()
				var heal = floor(drain / 2)
				player.take_damage(drain)
				enemy.hp = min(enemy.max_hp, enemy.hp + heal)
			messages.append({ "type": "ability", "text": enemy.monster_name + " drains your life!" })
		"corrode":
			if player.weapon:
				player.weapon_damage = max(1, player.weapon_damage - 2)
				messages.append({ "type": "ability", "text": enemy.monster_name + " corrodes your weapon!" })
		"freeze":
			if player.weapon:
				player.status_effects.append({ "id": "frozen_weapon", "weapon_penalty": 3, "duration": 1 })
				messages.append({ "type": "ability", "text": enemy.monster_name + " freezes your weapon!" })
		"summon":
			if enemies.size() < 6:
				var imp = MonsterData.new("Summoned Imp", "demon", 3, 4, 10, 2, "1d4", "", "", "A summoned minion", 1, 5)
				enemies.append(imp)
				messages.append({ "type": "ability", "text": enemy.monster_name + " summons a minion!" })
		"split":
			if enemy.hp <= enemy.max_hp * 0.5 and enemies.size() < 6:
				var copy = enemy.clone()
				copy.hp = floor(enemy.max_hp * 0.4)
				copy.max_hp = copy.hp
				enemies.append(copy)
				messages.append({ "type": "ability", "text": enemy.monster_name + " splits!" })
		"stomp":
			if enemies.size() > 1:
				messages.append({ "type": "ability", "text": enemy.monster_name + " stomps! Bonus from allies." })
		"pierce":
			messages.append({ "type": "ability", "text": enemy.monster_name + " pierces your armor!" })
		"fury":
			if player.hp < player.max_hp * 0.5:
				messages.append({ "type": "ability", "text": enemy.monster_name + " is enraged!" })
		"armor":
			messages.append({ "type": "info", "text": enemy.monster_name + " absorbs some damage." })

func _do_auto_revive(messages: Array):
	for item in player.survival_items:
		if item.effect == "auto_revive" and item.current_charges > 0:
			player.hp = floor(player.max_hp * 0.25)
			item.current_charges -= 1
			messages.append({ "type": "revive", "text": "Phoenix Feather revives you! (" + str(player.hp) + " HP)" })
			if item.current_charges <= 0:
				player.survival_items.erase(item)
			return

func _is_combat_over() -> bool:
	return state == CombatState.VICTORY or state == CombatState.DEFEAT

func _get_valid_target(index: int) -> MonsterData:
	if index >= 0 and index < enemies.size():
		return enemies[index]
	for e in enemies:
		if e.is_alive():
			return e
	return null

func get_alive_enemies() -> Array:
	return enemies.filter(func(e): return e.is_alive())

func end_combat() -> Dictionary:
	var result = { "xp": 0, "enemies_slain": 0, "victory": state == CombatState.VICTORY }
	if state == CombatState.VICTORY:
		for e in enemies:
			result.xp += e.xp
	return result

func get_state() -> int:
	return state
