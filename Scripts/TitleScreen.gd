extends Control

@onready var start_button: Button = $VBoxContainer/StartButton
@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var bg: ColorRect = $Background
@onready var vignette: ColorRect = $Vignette

var torch_time: float = 0.0
var particles: GPUParticles2D = null

func _ready():
	Music.play("title")
	start_button.pressed.connect(_on_start_pressed)
	start_button.grab_focus()
	_style_button(start_button)
	_style_title()
	_create_embers()

func _process(delta):
	torch_time += delta
	var f = 1.0 + sin(torch_time * 2.5) * 0.06
	f *= 1.0 + sin(torch_time * 3.7 + 1.2) * 0.03
	bg.modulate = Color(f * 0.95, f * 0.9, f * 0.85, 1.0)
	if title_label and title_label.material is ShaderMaterial:
		(title_label.material as ShaderMaterial).set_shader_parameter("time", torch_time)

func _create_embers():
	particles = GPUParticles2D.new()
	particles.amount = 20
	particles.lifetime = 5.0
	particles.one_shot = false
	particles.emitting = true
	particles.explosiveness = 0.0
	particles.randomness = 0.3
	var mat = ParticleProcessMaterial.new()
	mat.lifetime_randomness = 0.3
	mat.gravity = Vector3(0, -15, 0)
	mat.angle_min = 0.0
	mat.angle_max = 360.0
	mat.scale_min = 0.5
	mat.scale_max = 2.0
	mat.color = Color(0.788, 0.5, 0.2, 0.5)
	mat.initial_velocity_min = 10.0
	mat.initial_velocity_max = 30.0
	particles.process_material = mat
	particles.position = Vector2(960, 1080)
	add_child(particles)

func _style_title():
	var f = load("res://Assets/Fonts/Cinzel.ttf") as FontFile
	if f and title_label:
		title_label.add_theme_font_override("font", f)

func _style_button(btn: Button):
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color("#1a0f0a")
	style_normal.border_color = Color("#8b7d6b")
	style_normal.border_width_left = 2
	style_normal.border_width_right = 2
	style_normal.border_width_top = 2
	style_normal.border_width_bottom = 2
	style_normal.corner_radius_top_left = 4
	style_normal.corner_radius_top_right = 4
	style_normal.corner_radius_bottom_left = 4
	style_normal.corner_radius_bottom_right = 4

	var style_hover = style_normal.duplicate()
	style_hover.bg_color = Color("#2c1810")
	style_hover.border_color = Color("#c9a84c")

	btn.add_theme_stylebox_override("normal", style_normal)
	btn.add_theme_stylebox_override("hover", style_hover)
	btn.add_theme_color_override("font_color", Color("#c9a84c"))
	btn.add_theme_font_size_override("font_size", 24)

	var f = load("res://Assets/Fonts/Cinzel.ttf") as FontFile
	if f:
		btn.add_theme_font_override("font", f)

func _on_start_pressed():
	get_tree().change_scene_to_file("res://Scenes/ClassSelect.tscn")

func _exit_tree():
	if start_button.pressed.is_connected(_on_start_pressed):
		start_button.pressed.disconnect(_on_start_pressed)
