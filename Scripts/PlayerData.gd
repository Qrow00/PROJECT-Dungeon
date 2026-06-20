extends Node
class_name PlayerData

signal status_changed

var character_class: Dictionary = {}
var hp: int = 20
var max_hp: int = 20
var gold: int = 0
var floor: int = 1
var room_count: int = 0

var level: int = 1
var xp: int = 0
var xp_to_next: int = 10

var ac: int = 10
var attack_bonus: int = 0
var strength: int = 0
var defense_bonus: int = 0

var weapon: CardData = null
var weapon_damage: int = 0
var armor: CardData = null
var armor_bonus: int = 0
var shield: CardData = null
var shield_block: int = 0

var permanent_weapon_bonus: int = 0
var status_effects: Array = []
var consumables: Array = []
var survival_items: Array = []
var upgrades: Dictionary = {}
var escape_shards: int = 0

var skirmish_used: bool = false
var total_monsters_killed: int = 0
var total_floors_cleared: int = 0
var max_hp_upgrades: int = 0
var weapon_upgrades: int = 0
var level_abilities: Array = []

var phantom_cloak_active: bool = false

func has_survival_item(item_id: String) -> bool:
	for item in survival_items:
		if item.id == item_id and item.current_charges > 0:
			return true
	return false

func use_survival_item_charge(item_id: String) -> bool:
	for i in range(survival_items.size()):
		if survival_items[i].id == item_id and survival_items[i].current_charges > 0:
			survival_items[i].current_charges -= 1
			if survival_items[i].current_charges <= 0:
				survival_items.remove_at(i)
			return true
	return false

func reset(p_class: Dictionary):
	character_class = p_class
	max_hp = p_class.get("max_hp", 20)
	max_hp += max_hp_upgrades * 5
	hp = max_hp
	gold = p_class.get("starting_gold", 5)
	floor = 1
	room_count = 0
	level = 1
	xp = 0
	xp_to_next = 10
	ac = 10 + p_class.get("base_ac", 0)
	attack_bonus = p_class.get("base_attack", 1)
	strength = p_class.get("base_strength", 0)
	defense_bonus = 0
	weapon = null
	weapon_damage = 0
	armor = null
	armor_bonus = 0
	shield = null
	shield_block = 0
	status_effects = []
	consumables = []
	survival_items = []
	escape_shards = 0
	skirmish_used = false
	phantom_cloak_active = false
	level_abilities = []

func get_total_ac() -> int:
	var total = ac
	if shield:
		total += shield_block
	if armor:
		total += armor_bonus
	for e in status_effects:
		if e.id == "armor":
			total += e.get("ac_bonus", 2)
	return total

func get_attack_roll() -> int:
	var bonus = attack_bonus
	if weapon:
		bonus += permanent_weapon_bonus
	if character_class.get("id") == "warrior":
		bonus += 1
	for e in status_effects:
		if e.id == "weakness":
			bonus -= e.get("weapon_penalty", 2)
	return bonus

func get_weapon_damage_roll() -> int:
	if not weapon:
		return strength
	var base = weapon.value + strength + permanent_weapon_bonus
	return max(1, base)

func take_damage(amount: int) -> int:
	var effective = amount
	if shield and shield_block > 0:
		var blocked = min(effective, shield_block)
		effective -= blocked
		shield_block -= blocked
		if shield_block <= 0:
			shield = null
	for effect in status_effects:
		if effect.id == "armor":
			effective = max(0, effective - effect.get("damage_reduction", 2))
	var survived = false
	for item in survival_items:
		if item.effect == "negate_fatal" and hp <= effective:
			item.current_charges -= 1
			effective = 0
			survived = true
			if item.current_charges <= 0:
				survival_items.erase(item)
			break
	hp -= effective
	if hp < 0:
		hp = 0
	return effective

func heal(amount: int) -> int:
	var old = hp
	hp = min(hp + amount, max_hp)
	return hp - old

func equip_weapon(card: CardData):
	weapon = card
	weapon_damage = card.value + permanent_weapon_bonus

func equip_armor(card: CardData):
	armor = card
	armor_bonus = card.value

func equip_shield(card: CardData):
	shield = card
	shield_block = card.value

func add_xp(amount: int) -> Array:
	var messages = []
	xp += amount
	while xp >= xp_to_next:
		xp -= xp_to_next
		level += 1
		xp_to_next = floor(xp_to_next * 1.5)
		var hp_gain = 4
		match character_class.get("id", ""):
			"warrior": hp_gain = 8
			"paladin": hp_gain = 6
			"rogue": hp_gain = 5
		max_hp += hp_gain
		hp = min(hp + hp_gain, max_hp)
		attack_bonus += 1
		messages.append({ "type": "level_up", "level": level, "hp_gain": hp_gain })
		if level in [1, 3, 5, 7]:
			var ability = get_class_ability_for_level(level)
			if ability:
				level_abilities.append(ability)
				messages.append({ "type": "new_ability", "ability": ability })
		check_and_unlock_achievements()
	return messages

func get_class_ability_for_level(lvl: int) -> Dictionary:
	var class_id = character_class.get("id", "")
	match class_id:
		"warrior":
			match lvl:
				1: return { "id": "cleave", "name": "Cleave", "desc": "Hit all enemies, -2 damage each" }
				3: return { "id": "battle_cry", "name": "Battle Cry", "desc": "+2 attack for 3 turns (1/rest)" }
				5: return { "id": "whirlwind", "name": "Whirlwind", "desc": "Full damage to all enemies (1/rest)" }
				7: return { "id": "berserker_rage", "name": "Berserker Rage", "desc": "Double damage, halve AC for 3 turns" }
		"rogue":
			match lvl:
				1: return { "id": "backstab", "name": "Backstab", "desc": "+2d6 damage if target distracted" }
				3: return { "id": "evasion", "name": "Evasion", "desc": "Dodge 1 attack (1/rest)" }
				5: return { "id": "shadowstep", "name": "Shadowstep", "desc": "Flee combat + auto-crit next (1/rest)" }
				7: return { "id": "assassinate", "name": "Assassinate", "desc": "Instantly kill non-boss enemy below 50% HP" }
		"mage":
			match lvl:
				1: return { "id": "firebolt", "name": "Firebolt", "desc": "1d10 ranged damage" }
				3: return { "id": "frost_armor", "name": "Frost Armor", "desc": "+3 AC for 3 turns, chills attacker" }
				5: return { "id": "chain_lightning", "name": "Chain Lightning", "desc": "3x 1d8 damage to random enemies" }
				7: return { "id": "meteor", "name": "Meteor", "desc": "3d6 damage to all enemies (1/rest)" }
		"paladin":
			match lvl:
				1: return { "id": "lay_on_hands", "name": "Lay on Hands", "desc": "Heal 50% HP (1/rest)" }
				3: return { "id": "smite", "name": "Smite", "desc": "+2d6 holy damage on next attack" }
				5: return { "id": "divine_shield", "name": "Divine Shield", "desc": "Immune to damage for 2 turns (1/rest)" }
				7: return { "id": "holy_aura", "name": "Holy Aura", "desc": "Heal 1 HP/turn to self, 2 dmg/turn to undead/demon" }
	return {}

func has_ability(ability_id: String) -> bool:
	for a in level_abilities:
		if a.id == ability_id:
			return true
	return false

func check_and_unlock_achievements():
	if level >= 3 and not "level_3" in upgrades:
		upgrades["level_3"] = true
	if level >= 5 and not "level_5" in upgrades:
		upgrades["level_5"] = true

func has_status(effect_id: String) -> bool:
	for e in status_effects:
		if e.id == effect_id:
			return true
	return false

func remove_status(effect_id: String):
	status_effects = status_effects.filter(func(e): return e.id != effect_id)
	status_changed.emit()

func tick_statuses() -> Array:
	var messages = []
	var expired = []
	for effect in status_effects:
		if effect.has("damage_per_turn"):
			hp -= effect.damage_per_turn
			messages.append({ "type": "status_damage", "effect": effect.id, "amount": effect.damage_per_turn })
		if effect.has("heal_per_turn"):
			heal(effect.heal_per_turn)
			messages.append({ "type": "status_heal", "effect": effect.id, "amount": effect.heal_per_turn })
		effect.duration -= 1
		if effect.duration <= 0:
			expired.append(effect)
	for e in expired:
		status_effects.erase(e)
		messages.append({ "type": "status_expire", "effect": e.id })
	if expired.size() > 0:
		status_changed.emit()
	if hp < 0:
		hp = 0
	return messages

func is_alive() -> bool:
	return hp > 0

func add_consumable(item: Dictionary):
	consumables.append(item)

func use_consumable(index: int) -> Dictionary:
	var item = consumables[index]
	consumables.remove_at(index)
	return item

func add_survival_item(item: Dictionary):
	var existing = null
	for i in survival_items:
		if i.id == item.id:
			existing = i
			break
	if existing:
		existing.current_charges = min(existing.current_charges + 1, existing.max_charges)
	else:
		var copy = item.duplicate()
		copy.current_charges = 1
		survival_items.append(copy)

func use_survival_item(index: int) -> Dictionary:
	var item = survival_items[index]
	survival_items.remove_at(index)
	return item

func to_save_data() -> Dictionary:
	return {
		"max_hp_upgrades": max_hp_upgrades,
		"weapon_upgrades": weapon_upgrades,
		"total_monsters_killed": total_monsters_killed,
		"total_floors_cleared": total_floors_cleared,
		"best_level": level
	}

func load_save_data(data: Dictionary):
	max_hp_upgrades = data.get("max_hp_upgrades", 0)
	weapon_upgrades = data.get("weapon_upgrades", 0)
	total_monsters_killed = data.get("total_monsters_killed", 0)
	total_floors_cleared = data.get("total_floors_cleared", 0)
