extends Control

@onready var class_level_label: Label = $MainHBox/PlayerPanel/PlayerInfo/ClassLevelLabel
@onready var hp_bar_fill: ColorRect = $MainHBox/PlayerPanel/PlayerInfo/HPBar/HPBarFill
@onready var armor_bar_fill: ColorRect = $MainHBox/PlayerPanel/PlayerInfo/ArmorBar/ArmorBarFill
@onready var hp_label: Label = $MainHBox/PlayerPanel/PlayerInfo/HPLabel
@onready var gold_label: Label = $MainHBox/ResourcesPanel/GoldLabel

@onready var floor_label: Label = $MainHBox/NavPanel/FloorLabel
@onready var weapon_value: Label = $MainHBox/BottomRow/WeaponRow/WeaponValue
@onready var shield_value: Label = $MainHBox/BottomRow/ShieldRow/ShieldValue

const GOLD = Color("#c9a84c")
const RED = Color("#b91c1c")
const CREAM = Color("#c9b99a")
const MUTED = Color("#7a6b5a")

var last_hp: int = -1
var last_max_hp: int = -1
var last_armor: int = -1
var last_gold: int = -1
var last_floor: int = -1
var last_room: int = -1

func _ready():
	update_display()

func _process(_delta):
	update_display()

func update_display():
	var p = GameManager.player
	if not p:
		return

	class_level_label.text = p.character_class.get("name", "Adventurer") + "  Lv." + str(p.floor)

	if p.hp != last_hp or p.max_hp != last_max_hp:
		var ratio = float(p.hp) / max(p.max_hp, 1)
		hp_bar_fill.anchor_right = ratio
		var hp_color = UI.HP_GREEN if ratio > 0.5 else (Color("#cc8833") if ratio > 0.3 else UI.HP_RED)
		hp_bar_fill.color = hp_color
		hp_label.text = str(p.hp) + " / " + str(p.max_hp)
		last_hp = p.hp
		last_max_hp = p.max_hp

	var armor_val = p.shield_block if p.shield else 0
	if armor_val != last_armor:
		armor_bar_fill.anchor_right = clamp(armor_val / 10.0, 0.0, 1.0)
		last_armor = armor_val

	if p.gold != last_gold:
		gold_label.text = str(p.gold)
		last_gold = p.gold

	if p.floor != last_floor or p.room != last_room:
		floor_label.text = "F" + str(p.floor) + " - R" + str(p.room)
		last_floor = p.floor
		last_room = p.room

	if p.weapon:
		weapon_value.text = p.weapon.get_suit_symbol() + " " + p.weapon.rank + " (" + str(p.get_weapon_power()) + ")"
	else:
		weapon_value.text = "None"

	if p.shield:
		shield_value.text = p.shield.get_suit_symbol() + " (" + str(p.shield_block) + "/" + str(p.shield.value) + ")"
	else:
		shield_value.text = "None"
