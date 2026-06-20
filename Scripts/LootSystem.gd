extends Node
class_name LootSystem

var survival_items_data: Array = []
var monsters_data: Array = []

func _ready():
	load_survival_items()
	load_monsters_data()

func load_survival_items():
	var file = FileAccess.open("res://Data/SurvivalItems.json", FileAccess.READ)
	if file:
		var text = file.get_as_text()
		var json = JSON.parse_string(text)
		if json is Array:
			survival_items_data = json

func load_monsters_data():
	var file = FileAccess.open("res://Data/Monsters.json", FileAccess.READ)
	if file:
		var text = file.get_as_text()
		var json = JSON.parse_string(text)
		if json is Array:
			monsters_data = json

func generate_treasure_loot(floor: int) -> Dictionary:
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var result = { "gold": 0, "items": [], "cards": [] }
	var gold_roll = rng.randi_range(5, 15) + floor * rng.randi_range(1, 3)
	result.gold = gold_roll
	var item_count = rng.randi_range(0, 2)
	for i in range(item_count):
		var item = roll_random_item(floor)
		if item:
			result.items.append(item)
	var card_count = rng.randi_range(0, 1)
	for i in range(card_count):
		var card = roll_equipment_card(floor)
		if card:
			result.cards.append(card)
	return result

func generate_monster_loot(monster: MonsterData, floor: int) -> Dictionary:
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var result = { "gold": 0, "items": [], "xp": monster.xp }
	var gold_base = floor(rng.randi_range(2, 6) + floor * 0.5)
	result.gold = gold_base
	if rng.randf() < 0.15:
		var item = roll_random_item(floor)
		if item:
			result.items.append(item)
	return result

func generate_secret_loot(floor: int) -> Dictionary:
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var result = { "gold": 0, "items": [], "cards": [] }
	result.gold = rng.randi_range(20, 50) + floor * 5
	var item_count = rng.randi_range(1, 3)
	for i in range(item_count):
		var item = roll_random_item(floor)
		if item:
			result.items.append(item)
	if rng.randf() < 0.3:
		var card = roll_equipment_card(floor)
		if card:
			result.cards.append(card)
	if rng.randf() < 0.33 and floor >= 10:
		result.items.append(get_escape_shard())
	return result

func generate_boss_loot(boss: Dictionary, floor: int) -> Dictionary:
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var result = { "gold": 0, "items": [], "guaranteed_items": [] }
	result.gold = 10 + floor * 3
	var rarity_roll = rng.randf()
	if rarity_roll < 0.1 or floor >= 15:
		var feather = get_item_by_id("phoenix_feather")
		if feather:
			result.guaranteed_items.append(feather)
	elif rarity_roll < 0.25 or floor >= 10:
		var amulet = get_item_by_id("blessed_amulet")
		if amulet:
			result.guaranteed_items.append(amulet)
	var item_count = rng.randi_range(0, 1)
	for i in range(item_count):
		var item = roll_random_item(floor)
		if item:
			result.items.append(item)
	if floor >= 10 and rng.randf() < 0.5:
		result.items.append(get_escape_shard())
	elif floor >= 15:
		result.items.append(get_escape_shard())
	return result

func roll_random_item(floor: int) -> Dictionary:
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var available = []
	for item in survival_items_data:
		if item.id == "escape_shard":
			continue
		var chance = item.get("drop_chance", 0.0)
		if rng.randf() < chance:
			available.append(item)
	if available.is_empty():
		var common_items = ["escape_rope", "phantom_cloak", "heartstone"]
		var pick = common_items[rng.randi() % common_items.size()]
		for item in survival_items_data:
			if item.id == pick:
				return item.duplicate()
		return { "id": pick, "name": pick, "description": "", "effect": "none", "charges": 1 }
	return available[rng.randi() % available.size()].duplicate()

func get_item_by_id(id: String) -> Dictionary:
	for item in survival_items_data:
		if item.id == id:
			return item.duplicate()
	return {}

func get_escape_shard() -> Dictionary:
	for item in survival_items_data:
		if item.id == "escape_shard":
			return item.duplicate()
	return {}

func roll_equipment_card(floor: int) -> CardData:
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var is_weapon = rng.randf() < 0.6
	if is_weapon:
		var weapon_values = [4, 5, 6, 7, 8, 9, 10]
		var max_val = min(10, 4 + floor)
		var filtered = weapon_values.filter(func(v): return v <= max_val)
		var val = filtered[rng.randi() % filtered.size()]
		var ranks = { 4: "4", 5: "5", 6: "6", 7: "7", 8: "8", 9: "9", 10: "10" }
		return CardData.new(CardData.Suit.CLUBS, ranks.get(val, "6"), val)
	else:
		var shield_values = [2, 3, 4, 5, 6]
		var max_val = min(6, 2 + floor / 2)
		var filtered = shield_values.filter(func(v): return v <= max_val)
		var val = filtered[rng.randi() % filtered.size()]
		return ShieldData.new(val)
