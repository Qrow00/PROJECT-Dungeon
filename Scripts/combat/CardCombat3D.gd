extends Control

signal combat_resolved(result: Dictionary)

var combat_system
var enemies_3d: Array = []
var combat_manager
var selected_enemy_index: int = 0

@onready var combat_log: VBoxContainer = $CombatLog/ScrollContainer/VBox
@onready var action_container: HBoxContainer = $ActionContainer
@onready var enemy_container: HBoxContainer = $EnemyContainer
@onready var narration_label: Label = $NarrationLabel
@onready var combat_scroll: ScrollContainer = $CombatLog/ScrollContainer

func setup(combat, enemies: Array, mgr):
	combat_system = combat
	enemies_3d = enemies
	combat_manager = mgr
	add_combat_log("Combat begins!", Color("#c9b99a"))
	for e in enemies_3d:
		if is_instance_valid(e):
			var name_str = e.enemy_data.monster_name if e.enemy_data else "Enemy"
			add_combat_log("%s (%d HP)" % [name_str, e.hp], Color("#cc6644"))
	refresh_enemy_display()
	refresh_action_buttons()

func refresh_enemy_display():
	for child in enemy_container.get_children():
		child.queue_free()
	for i in enemies_3d.size():
		var e = enemies_3d[i]
		if not is_instance_valid(e):
			continue
		var name_str = e.enemy_data.monster_name if e.enemy_data else "Enemy"
		var btn = Button.new()
		btn.text = "%s\nHP: %d" % [name_str, e.hp]
		btn.add_theme_color_override("font_color", Color("#e8d5c0"))
		btn.custom_minimum_size = Vector2(150, 80)
		var style = StyleBoxFlat.new()
		style.bg_color = Color("#1a0a08")
		style.border_color = Color("#8c3a2a") if i != selected_enemy_index else Color("#c9a84c")
		style.border_width_left = 1
		style.border_width_right = 1
		style.border_width_top = 1
		style.border_width_bottom = 1
		btn.add_theme_stylebox_override("normal", style)
		btn.pressed.connect(_select_enemy.bind(i))
		enemy_container.add_child(btn)

func refresh_action_buttons():
	for child in action_container.get_children():
		child.queue_free()
	var actions = [
		{ "label": "Attack", "id": "attack" },
		{ "label": "Power Attack", "id": "power_attack" },
		{ "label": "Defend", "id": "defend" },
		{ "label": "Called Shot", "id": "called_shot" },
		{ "label": "Flee", "id": "flee" },
	]
	if GameManager.player.level_abilities.size() > 0:
		actions.append({ "label": "Ability", "id": "use_ability" })
	for action in actions:
		var btn = Button.new()
		btn.text = action.label
		btn.add_theme_color_override("font_color", Color("#c9b99a"))
		var style = StyleBoxFlat.new()
		style.bg_color = Color("#1a0f0a")
		style.border_color = Color("#5c4a3a")
		style.border_width_left = 1
		style.border_width_right = 1
		style.border_width_top = 1
		style.border_width_bottom = 1
		btn.add_theme_stylebox_override("normal", style)
		btn.pressed.connect(_on_action.bind(action.id))
		action_container.add_child(btn)

func _select_enemy(index: int):
	selected_enemy_index = index
	refresh_enemy_display()

func _on_action(action_id: String):
	if not combat_system:
		return
	if combat_system.get_state() != 0:
		add_combat_log("Not your turn!", Color("#ff4444"))
		return
	var result = combat_system.process_player_action(action_id, selected_enemy_index)
	if not result.get("success", false):
		return
	for msg in result.get("messages", []):
		add_combat_log(msg.get("text", ""), _msg_color(msg.get("type", "")))
	if result.get("fled", false):
		combat_resolved.emit({ "fled": true })
		if combat_manager: combat_manager.flee_combat()
		return
	if combat_system.get_state() >= 3:
		_handle_end()
		return
	refresh_enemy_display()
	await get_tree().create_timer(0.6).timeout
	var enemy_msgs = combat_system.process_enemy_turn()
	for msg in enemy_msgs:
		add_combat_log(msg.get("text", ""), _msg_color(msg.get("type", "")))
	if combat_system.get_state() >= 3:
		_handle_end()
		return
	refresh_enemy_display()

func _handle_end():
	var state = combat_system.get_state()
	if state == 3:
		add_combat_log("Victory!", Color("#ffd700"))
		var result = combat_system.end_combat()
		var xp_msgs = GameManager.player.add_xp(result.get("xp", 0))
		for m in xp_msgs:
			if m.type == "level_up":
				add_combat_log("Level %d!" % m.level, Color("#ffd700"))
		combat_resolved.emit({ "victory": true })
		if combat_manager: combat_manager.end_combat_victory()
	elif state == 4:
		add_combat_log("Defeated!", Color("#ff2222"))
		combat_resolved.emit({ "defeat": true })
		if combat_manager: combat_manager.end_combat_defeat()

func _msg_color(type: String) -> Color:
	match type:
		"initiative": return Color("#66aaff")
		"heal": return Color("#44cc88")
		"hit","crit": return Color("#cc6644")
		"miss": return Color("#888888")
		"damage": return Color("#ff4444")
		"victory": return Color("#44cc88")
		"defeat": return Color("#ff2222")
		"class_ability": return Color("#aa66ff")
	return Color("#c9b99a")

func add_combat_log(text: String, color: Color = Color("#c9b99a")):
	if text == "": return
	var entry = Label.new()
	entry.text = text
	entry.add_theme_color_override("font_color", color)
	entry.add_theme_font_size_override("font_size", 11)
	entry.autowrap_mode = TextServer.AUTOWRAP_WORD
	combat_log.add_child(entry)
	await get_tree().process_frame
	combat_scroll.scroll_vertical = int(combat_scroll.get_v_scroll_bar().max_value)
