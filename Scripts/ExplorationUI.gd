extends Control

@onready var room_label: Label = $RoomPanel/RoomLabel
@onready var floor_label: Label = $RoomPanel/FloorLabel
@onready var description_label: Label = $DescriptionPanel/DescriptionLabel
@onready var choices_container: VBoxContainer = $ChoicesPanel/ChoicesContainer
@onready var status_bar: Control = $StatusBar
@onready var hp_bar_fill: ColorRect = $StatusBar/HPBar/HPBarFill
@onready var hp_label: Label = $StatusBar/HPBar/HPLabel
@onready var xp_label: Label = $StatusBar/XPBar/XPLabel
@onready var xp_bar_fill: ColorRect = $StatusBar/XPBar/XPBarFill
@onready var weapon_label: Label = $StatusBar/WeaponLabel
@onready var gold_label: Label = $StatusBar/GoldLabel
@onready var shard_label: Label = $StatusBar/ShardLabel
@onready var bg: ColorRect = $Background

var torch_time: float = 0.0

func _ready():
	refresh()

func _process(delta):
	torch_time += delta
	var f = 1.0 + sin(torch_time * 2.5) * 0.06
	f *= 1.0 + sin(torch_time * 3.7 + 1.2) * 0.03
	if bg:
		bg.modulate = Color(f * 0.95, f * 0.9, f * 0.85, 1.0)

func refresh():
	var ctx = GameManager.get_exploration_context()
	room_label.text = ctx.room_label
	floor_label.text = "Floor " + str(ctx.floor) + " - " + ctx.floor_theme
	description_label.text = ctx.room_description
	update_status()
	clear_choices()
	for choice in ctx.choices:
		add_choice(choice)

func update_status():
	var p = GameManager.player
	hp_bar_fill.anchor_right = float(p.hp) / max(p.max_hp, 1)
	hp_label.text = str(p.hp) + "/" + str(p.max_hp)
	var xp_ratio = float(p.xp) / max(p.xp_to_next, 1)
	xp_bar_fill.anchor_right = xp_ratio
	xp_label.text = "Lv." + str(p.level) + " (" + str(p.xp) + "/" + str(p.xp_to_next) + " XP)"
	if p.weapon:
		weapon_label.text = p.weapon.get_suit_symbol() + " " + p.weapon.rank + " (" + str(p.get_weapon_damage_roll()) + ")"
	else:
		weapon_label.text = "No weapon"
	gold_label.text = str(p.gold) + "g"
	var ctx = GameManager.get_exploration_context()
	shard_label.text = "Shards: " + str(ctx.escape_shards) + "/3"

func clear_choices():
	for child in choices_container.get_children():
		child.queue_free()

func add_choice(choice: Dictionary):
	var btn = Button.new()
	btn.text = choice.label + " — " + choice.desc
	btn.add_theme_color_override("font_color", Color("#c9b99a"))
	btn.add_theme_font_size_override("font_size", 16)
	var s = StyleBoxFlat.new()
	s.bg_color = Color("#1a0f0a")
	s.border_color = Color("#5c4a3a")
	s.border_width_left = 1
	s.border_width_right = 1
	s.border_width_top = 1
	s.border_width_bottom = 1
	s.corner_radius_top_left = 4
	s.corner_radius_top_right = 4
	s.corner_radius_bottom_left = 4
	s.corner_radius_bottom_right = 4
	btn.add_theme_stylebox_override("normal", s)
	var sh = s.duplicate()
	sh.bg_color = Color("#2c1810")
	sh.border_color = Color("#c9a84c")
	btn.add_theme_stylebox_override("hover", sh)
	btn.pressed.connect(_on_choice.bind(choice.id))
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	choices_container.add_child(btn)

func _on_choice(choice_id: String):
	var result = GameManager.process_exploration_choice(choice_id)
	if not result.get("success", false):
		description_label.text = result.get("error", "Cannot do that!")
		return
	match result.get("action", ""):
		"combat":
			get_tree().change_scene_to_file("res://Scenes/GameBoard.tscn")
		"boss":
			get_tree().change_scene_to_file("res://Scenes/GameBoard.tscn")
		"loot":
			get_tree().change_scene_to_file("res://Scenes/GameBoard.tscn")
		"rest", "event":
			var msgs = result.get("messages", [])
			if msgs.size() > 0:
				description_label.text = msgs[0].get("text", "Nothing happens.")
			await get_tree().create_timer(0.8).timeout
			if GameManager.player.hp <= 0:
				get_tree().change_scene_to_file("res://Scenes/GameOver.tscn")
				return
			advance()
		"skip":
			advance()
		"escape":
			get_tree().change_scene_to_file("res://Scenes/GameOver.tscn")
		"shop":
			get_tree().change_scene_to_file("res://Scenes/Shop.tscn")
		"inventory":
			description_label.text = "Checking inventory... (equip/use items here)"
		_:
			description_label.text = "Nothing happens."

func advance():
	var has_next = GameManager.advance_room()
	if not has_next:
		refresh()
		return
	if GameManager.game_state == GameManager.GameState.GAME_OVER:
		get_tree().change_scene_to_file("res://Scenes/GameOver.tscn")
		return
	if GameManager.game_state == GameManager.GameState.VICTORY:
		get_tree().change_scene_to_file("res://Scenes/GameOver.tscn")
		return
	refresh()
