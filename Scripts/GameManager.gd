extends Node

enum GameState { TITLE, CLASS_SELECT, EXPLORING, COMBAT, BOSS, LOOT, SHOP, GAME_OVER, VICTORY }

const _DungeonManager = preload("res://Scripts/DungeonManager.gd")
const _LootSystem = preload("res://Scripts/LootSystem.gd")
const _ShopManager = preload("res://Scripts/ShopManager.gd")
const _RoguelikeManager = preload("res://Scripts/RoguelikeManager.gd")

var game_state: int = GameState.TITLE
var player
var deck_manager
var combat
var dungeon
var loot_system
var shop_manager
var roguelike_manager

var use_3d: bool = false
var movement_locked_3d: bool = false
var classes_data: Array = []
var bosses_data: Array = []
var current_boss: Dictionary = {}
var current_boss_hp: int = 0
var current_boss_max_hp: int = 0
var gold_earned_this_run: int = 0
var current_loot_result: Dictionary = {}
var current_event_result: Dictionary = {}
var monster_save_data: Array = []
var exploration_rng: RandomNumberGenerator

func _ready():
	exploration_rng = RandomNumberGenerator.new()
	exploration_rng.randomize()
	player = PlayerData.new()
	deck_manager = DeckManager.new()
	deck_manager.build_standard_deck()
	dungeon = _DungeonManager.new()
	loot_system = _LootSystem.new()
	combat = CombatSystem.new(player, deck_manager)
	shop_manager = _ShopManager.new()
	roguelike_manager = _RoguelikeManager.new()
	add_child(deck_manager)
	add_child(combat)
	add_child(dungeon)
	add_child(loot_system)
	add_child(shop_manager)
	add_child(roguelike_manager)
	load_classes_data()
	load_bosses_data()

func load_classes_data():
	var file = FileAccess.open("res://Data/Classes.json", FileAccess.READ)
	if file:
		var text = file.get_as_text()
		var json = JSON.parse_string(text)
		if json is Array:
			classes_data = json

func load_bosses_data():
	var file = FileAccess.open("res://Data/Bosses.json", FileAccess.READ)
	if file:
		var text = file.get_as_text()
		var json = JSON.parse_string(text)
		if json is Array:
			bosses_data = json

func get_classes() -> Array:
	return classes_data

func get_bosses() -> Array:
	return bosses_data

func is_class_unlocked(class_id: String) -> bool:
	return roguelike_manager.is_class_unlocked(class_id)

func start_game(class_id: String) -> bool:
	for c in classes_data:
		if c.id == class_id:
			game_state = GameState.EXPLORING
			player.reset(c)
			gold_earned_this_run = 0
			dungeon.generate_floor(1)
			return true
	return false

func start_exploration():
	game_state = GameState.EXPLORING

func get_exploration_context() -> Dictionary:
	var room_type = dungeon.get_current_room_type()
	return {
		"floor": dungeon.floor_number,
		"floor_theme": dungeon.floor_theme,
		"room_type": room_type,
		"room_label": dungeon.get_room_label(room_type),
		"room_description": dungeon.get_room_description(room_type),
		"choices": dungeon.get_choices_for_room(room_type, player),
		"room_number": dungeon.room_number + 1,
		"total_rooms": dungeon.get_total_rooms(),
		"is_last_room": dungeon.is_last_room(),
		"is_boss": dungeon.is_boss_room(),
		"escape_shards": dungeon.escape_shards_collected,
		"can_craft_portal": dungeon.can_craft_portal()
	}

func roll_exploration_initiative() -> int:
	return exploration_rng.randi_range(1, 20) + player.get_attack_roll()

func process_exploration_choice(choice_id: String) -> Dictionary:
	match choice_id:
		"fight", "enter_den":
			var tier = clampi(dungeon.floor_number, 1, 4)
			var count = dungeon.get_monster_encounter_size(tier)
			var monsters = generate_encounter(tier, count)
			if monsters.is_empty():
				return { "success": false, "error": "No monsters to fight!" }
			start_combat(monsters)
			return { "success": true, "action": "combat", "enemies": monsters }

		"fight_boss":
			set_boss_for_floor()
			start_boss_combat()
			return { "success": true, "action": "boss" }

		"loot", "search_secret":
			var init = roll_exploration_initiative()
			var loot = {}
			if dungeon.get_current_room_type() == _DungeonManager.RoomType.SECRET:
				loot = loot_system.generate_secret_loot(dungeon.floor_number)
			else:
				loot = loot_system.generate_treasure_loot(dungeon.floor_number)
			loot.gold += floor(init / 3)
			current_loot_result = loot
			game_state = GameState.LOOT
			return { "success": true, "action": "loot", "loot": loot }

		"investigate":
			var init = roll_exploration_initiative()
			var loot = loot_system.generate_treasure_loot(dungeon.floor_number)
			loot.gold += 3 + floor(init / 4)
			current_loot_result = loot
			game_state = GameState.LOOT
			return { "success": true, "action": "loot", "loot": loot }

		"rest":
			var init = roll_exploration_initiative()
			var bonus_heal = floor(init / 4)
			var heal_amount = floor(player.max_hp * 0.3) + bonus_heal
			var actual = player.heal(heal_amount)
			var messages = [{ "type": "heal", "text": "You rest. Initiative d20+" + str(player.get_attack_roll()) + "=" + str(init) + ". Recover " + str(actual) + " HP." }]
			var xp_gain = 5 + floor(init / 5)
			player.add_xp(xp_gain)
			messages.append({ "type": "xp", "text": "+" + str(xp_gain) + " XP from meditation." })
			return { "success": true, "action": "rest", "messages": messages }

		"meditate":
			var init = roll_exploration_initiative()
			var to_clear = clampi(floor(init / 6), 1, 3)
			var cleared = 0
			while player.status_effects.size() > 0 and cleared < to_clear:
				player.status_effects.pop_front()
				cleared += 1
			var messages = [{ "type": "initiative", "text": "Initiative d20+" + str(player.get_attack_roll()) + "=" + str(init) }, { "type": "info", "text": "You meditate. Cleared " + str(cleared) + " status effect(s)." }]
			return { "success": true, "action": "rest", "messages": messages }

		"touch":
			var init = roll_exploration_initiative()
			var messages = [{ "type": "initiative", "text": "Initiative d20+" + str(player.get_attack_roll()) + "=" + str(init) }]
			if init < 12:
				var damage = exploration_rng.randi_range(3, 8)
				player.take_damage(damage)
				messages.append({ "type": "damage", "text": "The sigil burns you for " + str(damage) + " damage!" })
			elif init < 22:
				var gold = exploration_rng.randi_range(10, 25) + floor(init / 2)
				player.gold += gold
				messages.append({ "type": "gold", "text": "The sigil glows gold! +" + str(gold) + " gold." })
			else:
				messages.append({ "type": "info", "text": "Nothing happens. You feel watched." })
			return { "success": true, "action": "event", "messages": messages }

		"read":
			var init = roll_exploration_initiative()
			var xp_gain = 10 + floor(init / 2)
			player.add_xp(xp_gain)
			return { "success": true, "action": "event", "messages": [{ "type": "initiative", "text": "Initiative d20+" + str(player.get_attack_roll()) + "=" + str(init) }, { "type": "xp", "text": "Ancient knowledge floods your mind. +" + str(xp_gain) + " XP." }] }

		"cloak":
			if player.use_survival_item_charge("phantom_cloak"):
				return { "success": true, "action": "skip" }
			return { "success": false, "error": "No phantom cloak!" }

		"skip":
			return { "success": true, "action": "skip" }

		"escape":
			if dungeon.can_craft_portal():
				game_state = GameState.VICTORY
				return { "success": true, "action": "escape" }
			return { "success": false, "error": "You cannot escape yet!" }

		"browse":
			game_state = GameState.SHOP
			return { "success": true, "action": "shop" }

		"leave":
			return { "success": true, "action": "skip" }

		"inventory":
			return { "success": true, "action": "inventory" }

		_:
			return { "success": false, "error": "Unknown choice!" }

func generate_encounter(tier: int, count: int) -> Array:
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var available = []
	for entry in deck_manager.monsters_data:
		var entry_tier = entry.get("tier", 1)
		var min_e = entry.get("min_encounter", 1)
		var max_e = entry.get("max_encounter", 3)
		if entry_tier <= tier and count >= min_e and count <= max_e:
			available.append(entry)
	if available.is_empty():
		for entry in deck_manager.monsters_data:
			if entry.get("tier", 1) <= tier:
				available.append(entry)
	var result = []
	for i in range(count):
		if available.is_empty():
			break
		var entry = available[rng.randi() % available.size()]
		var monster = MonsterData.from_dict(entry)
		result.append(monster)
	return result

func start_combat(monsters: Array):
	game_state = GameState.COMBAT
	monster_save_data = []
	for m in monsters:
		monster_save_data.append(m.to_dict())
	combat.start_combat(monsters, loot_system)

func set_boss_for_floor():
	var floor = dungeon.floor_number
	var boss_idx = ((floor - 1) / 5) % bosses_data.size()
	if boss_idx >= bosses_data.size():
		boss_idx = 0
	current_boss = bosses_data[boss_idx].duplicate()
	var base_hp = current_boss.get("hp", 10)
	var extra = (dungeon.floor_number / 5) * 2
	current_boss_hp = base_hp + extra
	current_boss_max_hp = current_boss_hp

func start_boss_combat():
	game_state = GameState.BOSS

func process_boss_hit() -> Dictionary:
	var messages = []
	var init = exploration_rng.randi_range(1, 20) + player.get_attack_roll()
	messages.append({ "type": "initiative", "text": "Initiative d20+" + str(player.get_attack_roll()) + "=" + str(init) })
	var weapon_power = player.get_weapon_damage_roll() if player.weapon else 0
	var attack_roll = init
	var boss_ac = current_boss.get("ac", 14)
	var success = attack_roll >= boss_ac
	var damage_to_boss = 0
	if success:
		var damage_dice = "1d8"
		var parts = damage_dice.split("d")
		var count = int(parts[0])
		var sides = int(parts[1])
		damage_to_boss = 0
		for i in range(count):
			damage_to_boss += exploration_rng.randi() % sides + 1
		damage_to_boss += weapon_power
		current_boss_hp -= damage_to_boss
		if current_boss_hp < 0:
			current_boss_hp = 0
		messages.append({ "type": "hit", "text": "You hit the boss for " + str(damage_to_boss) + " damage!" })
	else:
		messages.append({ "type": "miss", "text": "Your attack misses!" })

	var boss_atk = current_boss.get("attack_bonus", 5)
	var boss_dmg_dice = current_boss.get("damage_dice", "1d10")
	var boss_roll = exploration_rng.randi_range(1, 20) + boss_atk
	var damage_to_player = 0
	if boss_roll >= player.get_total_ac():
		var parts = boss_dmg_dice.split("d")
		var count = int(parts[0])
		var sides = int(parts[1])
		damage_to_player = 0
		if "+" in parts[1]:
			var sub = parts[1].split("+")
			sides = int(sub[0])
			damage_to_player = int(sub[1])
		for i in range(count):
			damage_to_player += exploration_rng.randi() % sides + 1
		var actual = player.take_damage(damage_to_player)
		messages.append({ "type": "damage", "text": "Boss deals " + str(actual) + " damage!" })
	else:
		messages.append({ "type": "info", "text": "Boss attacks but misses!" })

	return {
		"success": true,
		"damage_to_boss": damage_to_boss,
		"damage_to_player": damage_to_player,
		"boss_defeated": current_boss_hp <= 0,
		"messages": messages
	}

func finalize_boss_defeat() -> Dictionary:
	var result = { "messages": [], "gold_reward": 0, "items": [] }
	var ability = current_boss.get("ability", "")
	match ability:
		"burn":
			player.status_effects.append({ "id": "burn", "damage_per_turn": 2, "duration": 2 })
			result.messages.append({ "type": "status", "text": "Boss's burn lingers!" })
		"curse":
			player.status_effects.append({ "id": "weakness", "weapon_penalty": 2, "duration": 2 })
			result.messages.append({ "type": "status", "text": "Boss's curse weakens you!" })
		"poison":
			player.status_effects.append({ "id": "poison", "damage_per_turn": 2, "duration": 2 })
			result.messages.append({ "type": "status", "text": "Boss has poisoned you!" })

	var gold_reward = 10 + dungeon.floor_number * 2
	player.gold += gold_reward
	result.gold_reward = gold_reward
	result.messages.append({ "type": "gold", "text": "Boss bounty: +" + str(gold_reward) + " gold!" })

	var loot = loot_system.generate_boss_loot(current_boss, dungeon.floor_number)
	result.gold_reward += loot.gold
	player.gold += loot.gold
	for item in loot.guaranteed_items:
		player.add_survival_item(item)
		result.messages.append({ "type": "item", "text": "Found: " + item.get("name", "?") })
	for item in loot.items:
		player.add_survival_item(item)
		result.items.append(item)

	if dungeon.floor_number >= 10:
		var shard = loot_system.get_escape_shard()
		if not shard.is_empty():
			dungeon.collect_escape_shard()
			result.messages.append({ "type": "item", "text": "Escape Shard found! (" + str(dungeon.escape_shards_collected) + "/3)" })

	var xp_gain = current_boss.get("xp", 100)
	player.add_xp(xp_gain)
	player.total_monsters_killed += 1
	return result

func set_movement_locked(locked: bool):
	movement_locked_3d = locked

func is_movement_locked() -> bool:
	return movement_locked_3d

func switch_to_3d():
	use_3d = true

func switch_to_2d():
	use_3d = false

func leave_shop():
	game_state = GameState.EXPLORING

func advance_to_next_floor():
	dungeon.floor_number += 1
	player.floor = dungeon.floor_number
	dungeon.generate_floor(dungeon.floor_number)
	game_state = GameState.EXPLORING

func collect_loot():
	if current_loot_result.is_empty():
		return { "success": false }
	var messages = []
	if current_loot_result.has("gold"):
		player.gold += current_loot_result.gold
		messages.append({ "type": "gold", "text": "+" + str(current_loot_result.gold) + " gold" })
	if current_loot_result.has("items"):
		for item in current_loot_result.items:
			if item.get("type") != "quest":
				player.add_survival_item(item)
				messages.append({ "type": "item", "text": "Found: " + item.get("name", "?") })
	current_loot_result = {}
	return { "success": true, "messages": messages }

func advance_room() -> bool:
	var has_next = dungeon.advance_room()
	if not has_next:
		advance_to_next_floor()
		return false
	return true

func end_run() -> Dictionary:
	roguelike_manager.record_run(dungeon.floor_number, player.total_monsters_killed, gold_earned_this_run)
	var achievement = roguelike_manager.check_achievements(dungeon.floor_number, player.total_monsters_killed)
	var reqs = roguelike_manager.get_unlock_requirements()
	game_state = GameState.GAME_OVER
	return {
		"floor": dungeon.floor_number,
		"depth": dungeon.floor_number,
		"monsters_killed": player.total_monsters_killed,
		"gold_earned": gold_earned_this_run,
		"level": player.level,
		"achievement": achievement,
		"unlocks": reqs
	}

func victory() -> Dictionary:
	roguelike_manager.record_run(dungeon.floor_number, player.total_monsters_killed, gold_earned_this_run)
	var achievement = roguelike_manager.check_achievements(dungeon.floor_number, player.total_monsters_killed)
	roguelike_manager.unlock_class("paladin")
	game_state = GameState.VICTORY
	return {
		"floor": dungeon.floor_number,
		"monsters_killed": player.total_monsters_killed,
		"gold_earned": gold_earned_this_run,
		"achievement": achievement,
		"shards": dungeon.escape_shards_collected
	}

func get_boss_state() -> Dictionary:
	return {
		"boss": current_boss,
		"hp": current_boss_hp,
		"max_hp": current_boss_max_hp
	}

func get_unlock_requirements() -> Dictionary:
	return roguelike_manager.get_unlock_requirements()
