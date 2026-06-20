extends CardData
class_name MonsterData

var monster_name: String
var monster_type: String
var ability_id: String
var ability_desc: String
var description: String
var tier: int
var hp: int
var max_hp: int
var ac: int
var attack_bonus: int
var damage_dice: String
var xp: int
var behavior: String
var min_encounter: int
var max_encounter: int

func _init(p_name: String = "", p_type: String = "beast", p_value: int = 3,
	p_hp: int = 6, p_ac: int = 12, p_attack_bonus: int = 3, p_damage_dice: String = "1d6",
	p_ability_id: String = "", p_ability_desc: String = "",
	p_desc: String = "", p_tier: int = 1, p_xp: int = 15,
	p_behavior: String = "aggressive", p_min: int = 1, p_max: int = 3):
	super(CardData.Suit.SPADES, "M", p_value)
	monster_name = p_name
	monster_type = p_type
	value = p_value
	hp = p_hp
	max_hp = p_hp
	ac = p_ac
	attack_bonus = p_attack_bonus
	damage_dice = p_damage_dice
	ability_id = p_ability_id
	ability_desc = p_ability_desc
	description = p_desc
	tier = p_tier
	xp = p_xp
	behavior = p_behavior
	min_encounter = p_min
	max_encounter = p_max

func is_monster() -> bool:
	return true

func get_art_path() -> String:
	return MonsterData.get_monster_art_path(monster_type)

static func get_monster_art_path(monster_type: String) -> String:
	match monster_type:
		"cultist": return "res://Assets/Art/cards/culltist.png"
	return "res://Assets/Art/cards/" + monster_type + ".png"

func get_type_icon() -> String:
	match monster_type:
		"goblin": return "👺"
		"undead": return "💀"
		"beast": return "🐺"
		"dragon": return "🐉"
		"demon": return "👹"
		"slime": return "🟢"
		"cultist": return "🔮"
		"elemental": return "🔥"
		"giant": return "🦶"
		"construct": return "⚙️"
	return "💀"

func get_type_label() -> String:
	return monster_type.capitalize()

func roll_damage() -> int:
	var parts = damage_dice.split("d")
	var count = int(parts[0])
	var sides = int(parts[1])
	var total = 0
	if "+" in parts[1]:
		var sub = parts[1].split("+")
		sides = int(sub[0])
		total = int(sub[1])
	for i in range(count):
		total += randi() % sides + 1
	return total

func take_damage(amount: int) -> int:
	hp -= amount
	if hp < 0:
		hp = 0
	return amount

func is_alive() -> bool:
	return hp > 0

func reset_hp():
	hp = max_hp

func to_dict() -> Dictionary:
	var d = super.to_dict()
	d["monster_name"] = monster_name
	d["monster_type"] = monster_type
	d["hp"] = hp
	d["max_hp"] = max_hp
	d["ac"] = ac
	d["attack_bonus"] = attack_bonus
	d["damage_dice"] = damage_dice
	d["ability_id"] = ability_id
	d["ability_desc"] = ability_desc
	d["description"] = description
	d["tier"] = tier
	d["xp"] = xp
	d["behavior"] = behavior
	d["min_encounter"] = min_encounter
	d["max_encounter"] = max_encounter
	d["is_monster"] = true
	return d

static func from_dict(d: Dictionary) -> MonsterData:
	var m = MonsterData.new(
		d.get("monster_name", ""),
		d.get("monster_type", "beast"),
		d.get("value", 3),
		d.get("hp", 6),
		d.get("ac", 12),
		d.get("attack_bonus", 3),
		d.get("damage_dice", "1d6"),
		d.get("ability_id", ""),
		d.get("ability_desc", ""),
		d.get("description", ""),
		d.get("tier", 1),
		d.get("xp", 15),
		d.get("behavior", "aggressive"),
		d.get("min_encounter", 1),
		d.get("max_encounter", 3)
	)
	return m

func clone() -> MonsterData:
	return MonsterData.new(monster_name, monster_type, value, hp, ac, attack_bonus, damage_dice, ability_id, ability_desc, description, tier, xp, behavior, min_encounter, max_encounter)
