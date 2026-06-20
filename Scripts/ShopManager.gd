extends Node
class_name ShopManager

var shop_items: Array = []
var items_purchased: Array = []

func _ready():
	load_shop_data()

func load_shop_data():
	var file = FileAccess.open("res://Data/ShopItems.json", FileAccess.READ)
	if file:
		var text = file.get_as_text()
		var json = JSON.parse_string(text)
		if json is Array:
			shop_items = json

func get_available_items(floor: int) -> Array:
	var available = []
	for item in shop_items:
		available.append({
			"id": item.id,
			"name": item.name,
			"description": item.description,
			"type": item.type,
			"effect": item.effect,
			"effect_value": item.effect_value,
			"cost": item.cost,
			"icon": item.icon
		})
	return available

func purchase(item: Dictionary, player: PlayerData) -> Dictionary:
	var result = { "success": false, "message": "" }
	
	if player.gold < item.cost:
		result.message = "Not enough gold! Need " + str(item.cost) + " gold."
		return result
	
	player.gold -= item.cost
	
	match item.effect:
		"heal":
			var healed = player.heal(item.effect_value)
			result.message = "Healed " + str(healed) + " HP!"
		"shield":
			player.status_effects.append({ "id": "shield", "blocks": 1, "duration": 99 })
			result.message = "Barrier activated!"
		"strength":
			player.status_effects.append({ "id": "strength", "weapon_bonus": item.effect_value, "duration": 2 })
			result.message = "Strength oil applied!"
		"weapon_upgrade":
			player.permanent_weapon_bonus += item.effect_value
			player.weapon_upgrades += 1
			result.message = "Weapon permanently upgraded!"
		"max_hp":
			player.max_hp += item.effect_value
			player.hp = min(player.hp + item.effect_value, player.max_hp)
			player.max_hp_upgrades += 1
			result.message = "Max HP increased by " + str(item.effect_value) + "!"
		"cure":
			player.remove_status("poison")
			player.remove_status("burn")
			result.message = "Cured of all ailments!"
		"scry":
			result.message = "You sense the next room... (revealed on next draw)"
			result.scry = true
	
	result.success = true
	return result
