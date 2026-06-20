extends Control

@onready var class_container: VBoxContainer = $Panel/VBoxContainer/ClassList
@onready var description_label: Label = $Panel/VBoxContainer/DescriptionLabel
@onready var start_button: Button = $Panel/VBoxContainer/ButtonRow/StartButton
@onready var back_button: Button = $Panel/VBoxContainer/ButtonRow/BackButton
@onready var panel: Panel = $Panel
@onready var title_label: Label = $Panel/VBoxContainer/TitleLabel
@onready var bg: ColorRect = $Background
@onready var hp_bar_fill: ColorRect = $Panel/VBoxContainer/StatBars/HPBar/HPBarFill
@onready var hp_stat_label: Label = $Panel/VBoxContainer/StatBars/HPBar/HPStatLabel
@onready var gold_bar_fill: ColorRect = $Panel/VBoxContainer/StatBars/GoldBar/GoldBarFill
@onready var gold_stat_label: Label = $Panel/VBoxContainer/StatBars/GoldBar/GoldStatLabel

var selected_class: Dictionary = {}
var class_buttons: Dictionary = {}
var torch_time: float = 0.0

func _ready():
	Music.play("menu")
	populate_classes()
	start_button.pressed.connect(_on_start_pressed)
	back_button.pressed.connect(_on_back_pressed)
	_apply_dungeon_style()

func _process(delta):
	torch_time += delta
	var f = 1.0 + sin(torch_time * 2.5) * 0.06
	f *= 1.0 + sin(torch_time * 3.7 + 1.2) * 0.03
	if bg:
		bg.modulate = Color(f * 0.95, f * 0.9, f * 0.85, 1.0)

func _apply_dungeon_style():
	var ps = StyleBoxFlat.new()
	ps.bg_color = Color("#0d0805")
	ps.border_color = Color("#2c1f14")
	ps.border_width_left = 2
	ps.border_width_right = 2
	ps.border_width_top = 2
	ps.border_width_bottom = 2
	ps.corner_radius_top_left = 8
	ps.corner_radius_top_right = 8
	ps.corner_radius_bottom_left = 8
	ps.corner_radius_bottom_right = 8
	panel.add_theme_stylebox_override("panel", ps)

	for btn in [start_button, back_button]:
		var s = StyleBoxFlat.new()
		s.bg_color = Color("#1a0f0a")
		s.border_color = Color("#5c4a3a")
		s.border_width_left = 2
		s.border_width_right = 2
		s.border_width_top = 2
		s.border_width_bottom = 2
		s.corner_radius_top_left = 4
		s.corner_radius_top_right = 4
		s.corner_radius_bottom_left = 4
		s.corner_radius_bottom_right = 4
		btn.add_theme_stylebox_override("normal", s)
		var sh = s.duplicate()
		sh.bg_color = Color("#2c1810")
		sh.border_color = Color("#c9a84c")
		btn.add_theme_stylebox_override("hover", sh)
		btn.add_theme_color_override("font_color", Color("#c9a84c"))
		btn.add_theme_font_size_override("font_size", 20)

	var f = load("res://Assets/Fonts/Cinzel.ttf") as FontFile
	if f and title_label:
		title_label.add_theme_font_override("font", f)

func populate_classes():
	var classes = GameManager.get_classes()
	for i in class_container.get_children():
		class_container.remove_child(i)
		i.queue_free()

	class_buttons.clear()

	for c in classes:
		var is_locked = not GameManager.is_class_unlocked(c.id)
		var hbox = HBoxContainer.new()

		var icon = Label.new()
		var icons = { "warrior": "⚔", "rogue": "🗡", "mage": "🔮", "paladin": "🛡" }
		icon.text = icons.get(c.id, "?") + " "
		icon.add_theme_font_size_override("font_size", 22)
		icon.custom_minimum_size = Vector2(36, 45)

		var btn = Button.new()
		btn.text = c.name
		if is_locked:
			btn.text += " [LOCKED]"
			btn.disabled = true
		btn.custom_minimum_size = Vector2(200, 45)
		btn.add_theme_font_size_override("font_size", 22)

		var style = StyleBoxFlat.new()
		style.bg_color = Color("#1a0f0a")
		style.border_color = Color("#5c4a3a")
		style.border_width_left = 2
		style.border_width_right = 2
		style.border_width_top = 2
		style.border_width_bottom = 2
		style.corner_radius_top_left = 4
		style.corner_radius_top_right = 4
		style.corner_radius_bottom_left = 4
		style.corner_radius_bottom_right = 4
		btn.add_theme_stylebox_override("normal", style)

		var sh = style.duplicate()
		sh.border_color = Color("#c9a84c")
		btn.add_theme_stylebox_override("hover", sh)
		btn.add_theme_color_override("font_color", Color("#c9a84c"))

		if not is_locked:
			var class_id = c.id
			btn.pressed.connect(func():
				select_class(class_id)
			)

		class_buttons[c.id] = btn
		hbox.add_child(icon)
		hbox.add_child(btn)
		class_container.add_child(hbox)

func select_class(class_id: String):
	var classes = GameManager.get_classes()
	for c in classes:
		if c.id == class_id:
			selected_class = c
			var hp = c.get("max_hp", 20)
			var gold = c.get("starting_gold", 5)
			description_label.text = c.name + "\n" + c.description + "\n" + c.get("ability_desc", "")

			hp_bar_fill.anchor_right = clamp(hp / 30.0, 0.0, 1.0)
			hp_stat_label.text = "♥ " + str(hp)
			gold_bar_fill.anchor_right = clamp(gold / 20.0, 0.0, 1.0)
			gold_stat_label.text = "✦ " + str(gold)

			for btn_id in class_buttons:
				var style = StyleBoxFlat.new()
				style.bg_color = Color("#1a0f0a")
				style.border_color = Color("#5c4a3a")
				style.border_width_left = 2
				style.border_width_right = 2
				style.border_width_top = 2
				style.border_width_bottom = 2
				style.corner_radius_top_left = 4
				style.corner_radius_top_right = 4
				style.corner_radius_bottom_left = 4
				style.corner_radius_bottom_right = 4
				class_buttons[btn_id].add_theme_stylebox_override("normal", style)

			var selected_style = StyleBoxFlat.new()
			selected_style.bg_color = Color("#2c1810")
			selected_style.border_color = Color("#ffd700")
			selected_style.border_width_left = 3
			selected_style.border_width_right = 3
			selected_style.border_width_top = 3
			selected_style.border_width_bottom = 3
			selected_style.corner_radius_top_left = 4
			selected_style.corner_radius_top_right = 4
			selected_style.corner_radius_bottom_left = 4
			selected_style.corner_radius_bottom_right = 4
			class_buttons[class_id].add_theme_stylebox_override("normal", selected_style)
			break

func _on_start_pressed():
	if selected_class.is_empty():
		return
	GameManager.start_game(selected_class.id)
	get_tree().change_scene_to_file("res://Scenes/GameBoard.tscn")

func _on_back_pressed():
	get_tree().change_scene_to_file("res://Scenes/TitleScreen.tscn")
