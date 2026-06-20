extends Node
class_name DungeonManager

enum RoomType { MONSTER, TREASURE, REST, EVENT, SHOP, BOSS, MINIBOSS, SECRET }

var floor_number: int = 1
var room_number: int = 0
var rooms_since_boss: int = 0
var escape_shards_collected: int = 0
var can_escape: bool = false
var boss_count: int = 0

var floor_theme: String = ""
var floor_rooms: Array = []
var current_room_index: int = 0
var current_room_type: int = RoomType.MONSTER

var room_themes = ["Dark Caverns", "Ancient Ruins", "Crystal Caves", "Lava Tunnels", "Frozen Depths", "Abyssal Vaults"]

func generate_floor(floor_num: int):
	floor_number = floor_num
	room_number = 0
	rooms_since_boss = 0
	floor_rooms = []
	floor_theme = room_themes[floor_num % room_themes.size()]
	var rng = RandomNumberGenerator.new()
	rng.randomize()

	var is_boss_floor = floor_num % 5 == 0

	var rooms_this_floor = rng.randi_range(4, 7)
	if is_boss_floor:
		rooms_this_floor = rng.randi_range(3, 5)

	for i in range(rooms_this_floor):
		var type = RoomType.MONSTER
		var roll = rng.randf()
		if is_boss_floor and i == rooms_this_floor - 1:
			type = RoomType.BOSS
		elif floor_num > 0 and i == 0:
			type = RoomType.REST
		else:
			if roll < 0.45:
				type = RoomType.MONSTER
			elif roll < 0.65:
				type = RoomType.TREASURE
			elif roll < 0.80:
				type = RoomType.REST
			elif roll < 0.92:
				type = RoomType.EVENT
			else:
				type = RoomType.SECRET
		floor_rooms.append(type)

	current_room_index = 0
	if floor_rooms.size() > 0:
		current_room_type = floor_rooms[0]

func get_current_room_type() -> int:
	return current_room_type

func get_room_label(type: int) -> String:
	match type:
		RoomType.MONSTER: return "Monster Den"
		RoomType.TREASURE: return "Treasure Hoard"
		RoomType.REST: return "Rest Site"
		RoomType.EVENT: return "Mysterious Chamber"
		RoomType.SHOP: return "Wandering Merchant"
		RoomType.BOSS: return "Boss Lair"
		RoomType.MINIBOSS: return "Elite Chamber"
		RoomType.SECRET: return "Hidden Vault"
	return "Unknown"

func get_room_description(type: int) -> String:
	match type:
		RoomType.MONSTER:
			return "You hear growling ahead. Something lurks in the shadows..."
		RoomType.TREASURE:
			return "Glittering light reflects off piles of gold and trinkets."
		RoomType.REST:
			return "A warm glow emanates from an ancient brazier. The air is calm."
		RoomType.EVENT:
			return "Strange symbols cover the walls. The air hums with energy."
		RoomType.SHOP:
			return "A hooded figure tends a stall of curious wares."
		RoomType.BOSS:
			return "The air grows heavy. A massive presence awaits..."
		RoomType.SECRET:
			return "The wall seems... wrong. You feel a hidden space beyond."
	return ""

func get_choices_for_room(type: int, player: PlayerData) -> Array:
	var choices = []
	match type:
		RoomType.MONSTER:
			choices.append({ "id": "fight", "label": "Enter the den", "desc": "Face the monsters within", "icon": "⚔️" })
			if player.has_survival_item("phantom_cloak"):
				choices.append({ "id": "cloak", "label": "Use Phantom Cloak", "desc": "Sneak past unseen", "icon": "👻" })
			choices.append({ "id": "skip", "label": "Take another path", "desc": "Avoid this room", "icon": "🚪" })
		RoomType.TREASURE:
			choices.append({ "id": "loot", "label": "Search the hoard", "desc": "Claim the treasure", "icon": "💰" })
			choices.append({ "id": "investigate", "label": "Investigate carefully", "desc": "Check for traps first", "icon": "🔍" })
		RoomType.REST:
			choices.append({ "id": "rest", "label": "Rest by the fire", "desc": "Heal " + str(floor(player.max_hp * 0.3)) + " HP", "icon": "🔥" })
			choices.append({ "id": "meditate", "label": "Meditate", "desc": "Clear status effects", "icon": "🧘" })
			if escape_shards_collected >= 3 and not can_escape:
				choices.append({ "id": "escape", "label": "Craft Portal Stone", "desc": "Use your 3 shards to escape!", "icon": "✨" })
		RoomType.EVENT:
			choices.append({ "id": "touch", "label": "Touch the sigil", "desc": "???", "icon": "👆" })
			choices.append({ "id": "read", "label": "Read the inscriptions", "desc": "Learn ancient knowledge", "icon": "📖" })
			choices.append({ "id": "leave", "label": "Leave it alone", "desc": "Press on carefully", "icon": "🚶" })
		RoomType.SHOP:
			choices.append({ "id": "browse", "label": "Browse wares", "desc": "See what's for sale", "icon": "🛒" })
			choices.append({ "id": "leave", "label": "Decline and move on", "desc": "Continue deeper", "icon": "🚶" })
		RoomType.BOSS:
			choices.append({ "id": "fight_boss", "label": "Face the boss", "desc": "No turning back now", "icon": "👑" })
		RoomType.SECRET:
			choices.append({ "id": "search_secret", "label": "Search the vault", "desc": "Find rare treasures", "icon": "💎" })
			choices.append({ "id": "leave", "label": "Move on", "desc": "Leave the strange space", "icon": "🚶" })
	choices.append({ "id": "inventory", "label": "Check inventory", "desc": "View items and equipment", "icon": "🎒" })
	return choices

func advance_room() -> bool:
	room_number += 1
	rooms_since_boss += 1
	current_room_index += 1
	if current_room_index >= floor_rooms.size():
		return false
	current_room_type = floor_rooms[current_room_index]
	return true

func is_last_room() -> bool:
	return current_room_index >= floor_rooms.size() - 1

func is_boss_room() -> bool:
	return current_room_type == RoomType.BOSS

func is_shop_room() -> bool:
	return current_room_type == RoomType.SHOP

func get_monster_encounter_size(tier: int) -> int:
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var max_count = 1
	if tier == 1:
		max_count = rng.randi_range(2, 4)
	elif tier == 2:
		max_count = rng.randi_range(1, 3)
	elif tier == 3:
		max_count = rng.randi_range(1, 2)
	else:
		max_count = 1
	return max_count

func collect_escape_shard():
	escape_shards_collected += 1

func can_craft_portal() -> bool:
	return escape_shards_collected >= 3 and not can_escape

func craft_portal():
	if escape_shards_collected >= 3:
		can_escape = true

func get_total_rooms() -> int:
	return floor_rooms.size()

func get_narration_for_room(type: int, theme: String) -> String:
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	match type:
		RoomType.MONSTER:
			var lines = [
				"You hear guttural growls ahead. Something hungry waits in the dark.",
				"The stench of blood and fur fills the air. Lair ahead.",
				"Shadows shift and move. You are not alone in this chamber.",
				"Eyes gleam from the darkness. Teeth drip with anticipation.",
				"The floor is strewn with bones. The inhabitants are near."
			]
			return lines[rng.randi() % lines.size()]
		RoomType.TREASURE:
			var lines = [
				"A glittering pile catches the torchlight. Riches beyond measure.",
				"Gold coins spill from ancient chests. A dragon's hoard, long forgotten.",
				"The room glows with a warm golden hue. Treasure awaits.",
				"Jewels and gemstones crunch underfoot. This place is a vault.",
				"Ancient coins bear the marks of a long-dead kingdom."
			]
			return lines[rng.randi() % lines.size()]
		RoomType.REST:
			var lines = [
				"A crackling fire casts dancing shadows. The air is safe and warm.",
				"Ancient runes on the walls pulse with a gentle light. Peace at last.",
				"Stone benches surround a dying ember. A moment to catch your breath.",
				"The quiet is almost unsettling after the horrors above.",
				"Fresh water trickles down the wall. A small mercy in this dark place."
			]
			return lines[rng.randi() % lines.size()]
		RoomType.EVENT:
			var lines = [
				"The air hums with arcane energy. Strange symbols cover every surface.",
				"A pedestal stands in the center, pulsing with an inner light.",
				"The walls are covered in murals depicting a great battle.",
				"You feel a presence watching from beyond the veil.",
				"Ghostly whispers echo through the chamber, speaking in forgotten tongues."
			]
			return lines[rng.randi() % lines.size()]
		RoomType.SHOP:
			var lines = [
				"A hooded figure tends a stall of oddities in the middle of nowhere.",
				"The merchant's eyes gleam with knowing. \"Looking for something special?\"",
				"Strange bottles and weapons line the shelves. A traveling merchant's cart.",
				"\"Not many make it this far, friend. Take a look.\"",
				"The merchant's wares glow with an unnatural light. Curiosity pulls you closer."
			]
			return lines[rng.randi() % lines.size()]
		RoomType.BOSS:
			var lines = [
				"The air grows heavy and cold. A malevolent presence stirs ahead.",
				"This is the lair of something ancient and terrible. You feel it watching.",
				"The walls pulse with a dark heartbeat. The boss awaits its challenger.",
				"Pressure builds in your chest. The very dungeon groans in anticipation.",
				"Deep, rhythmic breathing echoes through the chamber. You have arrived."
			]
			return lines[rng.randi() % lines.size()]
		RoomType.MINIBOSS:
			var lines = [
				"A powerful aura radiates from beyond the door. An elite guardian stands ready.",
				"The floor trembles slightly. Something big patrols these halls.",
				"Challenger marks are scratched into the stone. A warrior's room.",
				"You hear the sharpening of steel. A deadly foe prepares."
			]
			return lines[rng.randi() % lines.size()]
		RoomType.SECRET:
			var lines = [
				"The wall sounds hollow. Your fingers find a hidden catch.",
				"A draft whispers through a hairline crack. There's more here than meets the eye.",
				"You notice the mortar is newer here. Something was sealed away.",
				"Your torch flickers as a hidden passage is revealed behind the tapestry."
			]
			return lines[rng.randi() % lines.size()]
	return ""

func get_floor_entry_narration(floor: int, theme: String) -> String:
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	if floor == 1:
		var lines = [
			"You descend into the darkness. The entrance collapses behind you. There is no turning back.",
			"The stench of damp stone and ancient death greets you. The dungeon begins.",
			"Your torch flares to life, illuminating a long corridor. You take your first step into the abyss."
		]
		return lines[rng.randi() % lines.size()]
	var lines = [
		"You descend deeper into the " + theme + ". The temperature drops. The air thickens.",
		"The " + theme + " stretch before you, ancient and waiting. Floor " + str(floor) + ".",
		"Another level of the dungeon reveals itself. The " + theme + " hold new terrors.",
		"You climb down a spiral staircase. The " + theme + " unfold beneath you."
	]
	return lines[rng.randi() % lines.size()]

func get_action_narration(action_id: String, enemy_name: String = "") -> String:
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	match action_id:
		"attack":
			var lines = [
				"You lunge forward, weapon aimed at " + enemy_name + "!",
				"Steeling yourself, you strike at " + enemy_name + " with all your might.",
				"Your weapon cuts through the air toward " + enemy_name + "!",
				"You feint then drive your attack home against " + enemy_name + "."
			]
			return lines[rng.randi() % lines.size()]
		"power_attack":
			var lines = [
				"You wind up for a devastating overhead strike!",
				"Focusing your strength, you unleash a crushing blow!",
				"You roar as you swing with all your power!",
				"The weight of your weapon becomes a hammer of destruction!"
			]
			return lines[rng.randi() % lines.size()]
		"defend":
			var lines = [
				"You brace yourself behind your guard, watching for an opening.",
				"Raising your weapon defensively, you steady your breathing.",
				"You shift into a defensive stance, letting the enemy come to you.",
				"Your focus narrows. You will not be caught off guard."
			]
			return lines[rng.randi() % lines.size()]
		"called_shot":
			var lines = [
				"You line up a precise strike at " + enemy_name + "'s weak point.",
				"Squinting through the gloom, you aim for a vital spot on " + enemy_name + ".",
				"You take careful aim. One shot, one opportunity.",
				"Your eyes lock onto a gap in " + enemy_name + "'s defenses."
			]
			return lines[rng.randi() % lines.size()]
		"flee":
			var lines = [
				"You shove " + enemy_name + " back and bolt for the exit!",
				"Discretion over valor. You turn and run!",
				"You throw sand and retreat into the shadows!",
				"Survive to fight another day. You flee!"
			]
			return lines[rng.randi() % lines.size()]
		"use_ability":
			var lines = [
				"You tap into your inner power. A surge of energy courses through you!",
				"Ancient techniques flow through your muscles. Time to end this.",
				"You call upon your training. Your class ability awakens!",
				"With practiced ease, you execute a signature move!"
			]
			return lines[rng.randi() % lines.size()]
	return ""

func get_enemy_narration(enemy_name: String, attack_hit: bool) -> String:
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	if attack_hit:
		var lines = [
			"The " + enemy_name + " lunges wildly, claws and fangs aiming for your flesh!",
			"The " + enemy_name + " attacks with savage fury!",
			"The " + enemy_name + " strikes with frightening speed!",
			"A guttural roar escapes the " + enemy_name + " as it attacks!"
		]
		return lines[rng.randi() % lines.size()]
	else:
		var lines = [
			"The " + enemy_name + "'s attack goes wide, crashing into the wall!",
			"You sidestep as the " + enemy_name + "'s strike cleaves empty air.",
			"The " + enemy_name + " overextends and misses entirely!",
			"You duck under the " + enemy_name + "'s wild swing."
		]
		return lines[rng.randi() % lines.size()]

func get_event_narration(event_id: String) -> String:
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	match event_id:
		"touch":
			var lines = [
				"You reach out and touch the glowing sigil. Energy surges through your arm!",
				"Your fingers brush the ancient symbol. The world spins.",
				"The sigil burns cold as you make contact. Visions flash before your eyes.",
				"You press your palm against the rune. It pulses once, then..."  
			]
			return lines[rng.randi() % lines.size()]
		"read":
			var lines = [
				"You trace the ancient inscriptions. Knowledge floods your mind.",
				"The text tells of a great hero who fell in these very halls.",
				"Words of power reveal themselves. You learn a fragment of forgotten lore.",
				"The murals tell a story of betrayal and fire. History echoes.",
				"Runes of an elder tongue. You understand just enough to be useful."
			]
			return lines[rng.randi() % lines.size()]
		"rest":
			var lines = [
				"You sit by the crackling fire. The warmth seeps into your tired bones.",
				"Closing your eyes, you let the calm wash over you. For now, you are safe.",
				"The fire pops and hisses. You feel your strength returning.",
				"You tend to your wounds by the firelight. The rest is well earned."
			]
			return lines[rng.randi() % lines.size()]
		"meditate":
			var lines = [
				"You sit cross-legged and clear your mind. The negative energy lifts.",
				"Breathing deeply, you visualize the darkness leaving your body.",
				"Your mind quiets. The status effects fade like morning mist.",
				"Meditation brings clarity. You feel renewed and focused."
			]
			return lines[rng.randi() % lines.size()]
	return ""
