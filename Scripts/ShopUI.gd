extends Control

@onready var item_container: VBoxContainer = $Panel/VBoxContainer/ItemsContainer
@onready var gold_label: Label = $Panel/VBoxContainer/GoldLabel
@onready var message_label: Label = $Panel/VBoxContainer/MessageLabel
@onready var leave_button: Button = $Panel/VBoxContainer/LeaveButton
@onready var title_label: Label = $Panel/VBoxContainer/TitleLabel
@onready var panel: Panel = $Panel
@onready var bg: ColorRect = $Background

var available_items: Array = []
var torch_time: float = 0.0
var gold_particles: GPUParticles2D = null

func _ready():
	leave_button.pressed.connect(_on_leave_pressed)
	_apply_dungeon_style()
	refresh_shop()
	_create_gold_particles()

func _process(delta):
	torch_time += delta
	var f = 1.0 + sin(torch_time * 2.5) * 0.06
	f *= 1.0 + sin(torch_time * 3.7 + 1.2) * 0.03
	if bg:
		bg.modulate = Color(f * 0.95, f * 0.9, f * 0.85, 1.0)

func _create_gold_particles():
	gold_particles = GPUParticles2D.new()
	gold_particles.amount = 12
	gold_particles.lifetime = 4.0
	gold_particles.one_shot = false
	gold_particles.emitting = true
	gold_particles.explosiveness = 0.0
	gold_particles.randomness = 0.4
	var mat = ParticleProcessMaterial.new()
	mat.lifetime_randomness = 0.3
	mat.gravity = Vector3(0, -10, 0)
	mat.angle_min = 0.0
	mat.angle_max = 360.0
	mat.scale_min = 0.3
	mat.scale_max = 1.0
	mat.color = Color(0.788, 0.659, 0.298, 0.4)
	mat.initial_velocity_min = 5.0
	mat.initial_velocity_max = 20.0
	gold_particles.process_material = mat
	gold_particles.position = Vector2(960, 1080)
	add_child(gold_particles)

func _apply_dungeon_style():
	var ps = StyleBoxFlat.new()
	ps.bg_color = Color("#0d0805")
	ps.border_color = Color("#3a2818")
	ps.border_width_left = 2
	ps.border_width_right = 2
	ps.border_width_top = 2
	ps.border_width_bottom = 2
	ps.corner_radius_top_left = 8
	ps.corner_radius_top_right = 8
	ps.corner_radius_bottom_left = 8
	ps.corner_radius_bottom_right = 8
	panel.add_theme_stylebox_override("panel", ps)
	
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
	leave_button.add_theme_stylebox_override("normal", s)
	var sh = s.duplicate()
	sh.bg_color = Color("#2c1810")
	sh.border_color = Color("#c9a84c")
	leave_button.add_theme_stylebox_override("hover", sh)
	leave_button.add_theme_color_override("font_color", Color("#c9a84c"))
	leave_button.add_theme_font_size_override("font_size", 18)

func refresh_shop():
	available_items = GameManager.shop_manager.get_available_items(GameManager.player.floor)
	gold_label.text = "Gold: " + str(GameManager.player.gold) + "g"
	message_label.text = ""
	
	for child in item_container.get_children():
		item_container.remove_child(child)
		child.queue_free()
	
	var item_idx = 0
	for item in available_items:
		var hbox = HBoxContainer.new()
		
		var name_label = Label.new()
		name_label.text = item.name + " — " + str(item.cost) + "g"
		name_label.custom_minimum_size = Vector2(260, 35)
		name_label.add_theme_font_size_override("font_size", 18)
		name_label.add_theme_color_override("font_color", Color("#c9b99a"))
		
		var desc_label = Label.new()
		desc_label.text = item.description
		desc_label.add_theme_color_override("font_color", Color("#7a6b5a"))
		desc_label.add_theme_font_size_override("font_size", 14)
		desc_label.custom_minimum_size = Vector2(300, 35)
		
		var buy_btn = Button.new()
		buy_btn.text = "BUY"
		buy_btn.custom_minimum_size = Vector2(80, 35)
		var bs = StyleBoxFlat.new()
		bs.bg_color = Color("#1a0f0a")
		bs.border_color = Color("#5c4a3a")
		bs.border_width_left = 1
		bs.border_width_right = 1
		bs.border_width_top = 1
		bs.border_width_bottom = 1
		bs.corner_radius_top_left = 4
		bs.corner_radius_top_right = 4
		bs.corner_radius_bottom_left = 4
		bs.corner_radius_bottom_right = 4
		buy_btn.add_theme_stylebox_override("normal", bs)
		var bsh = bs.duplicate()
		bsh.border_color = Color("#c9a84c")
		bsh.bg_color = Color("#2c1810")
		buy_btn.add_theme_stylebox_override("hover", bsh)
		buy_btn.add_theme_color_override("font_color", Color("#c9a84c"))
		buy_btn.add_theme_font_size_override("font_size", 16)
		
		var current_idx = item_idx
		buy_btn.pressed.connect(func(): purchase_item(current_idx))
		
		hbox.add_child(name_label)
		hbox.add_child(desc_label)
		hbox.add_child(buy_btn)
		item_container.add_child(hbox)
		item_idx += 1

func purchase_item(index: int):
	if index < 0 or index >= available_items.size():
		return
	
	var item = available_items[index]
	var result = GameManager.shop_manager.purchase(item, GameManager.player)
	message_label.text = result.message
	if result.success:
		gold_label.text = "Gold: " + str(GameManager.player.gold) + "g"
		refresh_shop()

func _exit_tree():
	if gold_particles:
		gold_particles.emitting = false

func _on_leave_pressed():
	GameManager.leave_shop()
	refresh_shop()
	get_tree().change_scene_to_file("res://Scenes/GameBoard.tscn")
