extends Control

@onready var title_label: Label = $StonePanel/VBoxContainer/TitleLabel
@onready var stats_label: Label = $StonePanel/VBoxContainer/StatsLabel
@onready var achievement_label: Label = $StonePanel/VBoxContainer/AchievementLabel
@onready var unlock_label: Label = $StonePanel/VBoxContainer/UnlockLabel
@onready var retry_button: Button = $StonePanel/VBoxContainer/ButtonRow/RetryButton
@onready var menu_button: Button = $StonePanel/VBoxContainer/ButtonRow/MenuButton
@onready var panel: Panel = $StonePanel
@onready var bg: ColorRect = $Background
@onready var blood_overlay: ColorRect = $BloodOverlay
var torch_time: float = 0.0
var blood_particles: GPUParticles2D = null

func _ready():
	var is_victory = GameManager.game_state == GameManager.GameState.VICTORY

	var result = {}
	if is_victory:
		result = GameManager.victory()
		title_label.text = "YOU ESCAPED"
	else:
		result = GameManager.end_run()
		title_label.text = "YOU HAVE FALLEN"

	var depth = result.get("depth", result.get("floor", 0))
	stats_label.text = "Depth: Floor " + str(depth) + "\nLevel: " + str(result.get("level", GameManager.player.level)) + "\nMonsters Slain: " + str(result.get("monsters_killed", 0)) + "\nGold Earned: " + str(result.get("gold_earned", 0))

	if is_victory:
		var shards = result.get("shards", 0)
		stats_label.text += "\nEscape Shards: " + str(shards) + "/3"

	if result.achievement and result.achievement != "":
		achievement_label.text = result.achievement
		achievement_label.show()
	else:
		achievement_label.hide()

	var unlock_text = ""
	var reqs = result.get("unlocks", {})
	for class_id in reqs:
		var req = reqs[class_id]
		if req.condition:
			unlock_text += class_id.capitalize() + ": " + req.description + " ✓\n"
		else:
			unlock_text += class_id.capitalize() + ": " + req.description + "\n"

	if unlock_text != "":
		unlock_label.text = "Unlocks:\n" + unlock_text
	else:
		unlock_label.text = ""

	retry_button.pressed.connect(_on_retry_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	_apply_dungeon_style()
	if not is_victory:
		TTS.speak_line("death", GameManager.player.character_class.get("id", ""))
		_create_blood_particles()

func _process(delta):
	torch_time += delta
	var f = 1.0 + sin(torch_time * 2.5) * 0.06
	f *= 1.0 + sin(torch_time * 3.7 + 1.2) * 0.03
	var is_victory = GameManager.game_state == GameManager.GameState.VICTORY
	if bg:
		if is_victory:
			bg.modulate = Color(f * 0.5, f * 0.7, f * 0.5, 1.0)
		else:
			bg.modulate = Color(f * 0.8, f * 0.3, f * 0.3, 1.0)
	if blood_overlay:
		if is_victory:
			blood_overlay.modulate = Color(0, 0, 0, 0)
		else:
			var pulse = 0.3 + sin(torch_time * 1.5) * 0.08
			blood_overlay.modulate = Color(0.15, 0.0, 0.0, pulse)

func _create_blood_particles():
	blood_particles = GPUParticles2D.new()
	blood_particles.amount = 8
	blood_particles.lifetime = 3.0
	blood_particles.one_shot = false
	blood_particles.emitting = true
	blood_particles.explosiveness = 0.0
	blood_particles.randomness = 0.5
	var mat = ParticleProcessMaterial.new()
	mat.lifetime_randomness = 0.2
	mat.gravity = Vector3(0, 15, 0)
	mat.angle_min = 0.0
	mat.angle_max = 360.0
	mat.scale_min = 0.5
	mat.scale_max = 2.0
	mat.color = Color(0.5, 0.05, 0.02, 0.3)
	mat.initial_velocity_min = 5.0
	mat.initial_velocity_max = 25.0
	blood_particles.process_material = mat
	blood_particles.position = Vector2(960, 0)
	add_child(blood_particles)

func _style_button(btn: Button):
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
	btn.add_theme_font_size_override("font_size", 18)
	var f = load("res://Assets/Fonts/Cinzel.ttf") as FontFile
	if f:
		btn.add_theme_font_override("font", f)

func _apply_dungeon_style():
	_style_button(retry_button)
	_style_button(menu_button)

	var ps = StyleBoxFlat.new()
	ps.bg_color = Color("#0d0805")
	ps.border_color = Color("#5c3a3a") if GameManager.game_state != GameManager.GameState.VICTORY else Color("#3a5c3a")
	ps.border_width_left = 3
	ps.border_width_right = 3
	ps.border_width_top = 3
	ps.border_width_bottom = 3
	ps.corner_radius_top_left = 12
	ps.corner_radius_top_right = 12
	ps.corner_radius_bottom_left = 12
	ps.corner_radius_bottom_right = 12
	panel.add_theme_stylebox_override("panel", ps)

	var f = load("res://Assets/Fonts/Cinzel.ttf") as FontFile
	if f and title_label:
		title_label.add_theme_font_override("font", f)

func _on_retry_pressed():
	get_tree().change_scene_to_file("res://Scenes/ClassSelect.tscn")

func _on_menu_pressed():
	get_tree().change_scene_to_file("res://Scenes/TitleScreen.tscn")

func _exit_tree():
	if blood_particles:
		blood_particles.emitting = false
