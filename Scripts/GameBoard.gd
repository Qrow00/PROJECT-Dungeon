extends Control

const EnemyFactory = preload("res://Scripts/enemies/EnemyFactory.gd")
const DungeonWorld = preload("res://Scripts/dungeon/DungeonWorld.gd")

enum BoardMode { EXPLORE, COMBAT, BOSS, LOOT }

var mode: int = BoardMode.EXPLORE
var torch_time: float = 0.0
var combat_enemies: Array = []
var selected_enemy_index: int = -1
var current_loot: Dictionary = {}
var boss_active: bool = false
var prev_hp: int = 0
var pending_flavor: String = ""

var narration

@onready var bg: ColorRect = $Background
@onready var game_world = $GameWorldContainer/SubViewport/GameWorld
@onready var theme_overlay: ColorRect = $ThemeOverlay
@onready var transition_overlay: ColorRect = $TransitionOverlay
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var explore_panel: Control = $ExplorePanel
@onready var room_label: Label = $ExplorePanel/RoomLabel
@onready var floor_label: Label = $ExplorePanel/FloorLabel
@onready var desc_label: Label = $ExplorePanel/DescLabel
@onready var choices_container: VBoxContainer = $ExplorePanel/ChoicesContainer
@onready var combat_panel: Control = $CombatPanel
@onready var enemy_container: HBoxContainer = $CombatPanel/EnemyContainer
@onready var combat_narration: Label = $CombatPanel/CombatNarration
@onready var combat_log: VBoxContainer = $CombatPanel/CombatLog/ScrollContainer/VBox
@onready var action_container: HBoxContainer = $CombatPanel/ActionContainer
@onready var loot_panel: Control = $LootPanel
@onready var loot_label: Label = $LootPanel/LootLabel
@onready var loot_items_container: VBoxContainer = $LootPanel/LootItemsContainer
@onready var hp_bar_fill: ColorRect = $StatusBar/HPBar/HPBarFill
@onready var hp_label: Label = $StatusBar/HPBar/HPLabel
@onready var xp_bar_fill: ColorRect = $StatusBar/XPBar/XPBarFill
@onready var xp_label: Label = $StatusBar/XPBar/XPLabel
@onready var floor_info: Label = $StatusBar/FloorInfo
@onready var weapon_label: Label = $StatusBar/WeaponInfo
@onready var gold_label: Label = $StatusBar/GoldInfo
@onready var class_label: Label = $StatusBar/ClassInfo
@onready var shard_label: Label = $StatusBar/ShardInfo
@onready var status_icons: HBoxContainer = $StatusBar/StatusIcons
@onready var combat_scroll: ScrollContainer = $CombatPanel/CombatLog/ScrollContainer

func _ready():
	Music.play("dungeon")
	var NM = preload("res://Scripts/NarrationManager.gd")
	narration = NM.new()
	add_child(narration)
	GameManager.combat.combat_log.connect(_on_combat_message)
	GameManager.player.status_changed.connect(_on_status_changed)
	hide_all_panels()
	if GameManager.game_state == GameManager.GameState.EXPLORING:
		show_explore()
	elif GameManager.game_state == GameManager.GameState.COMBAT:
		show_combat()
	elif GameManager.game_state == GameManager.GameState.BOSS:
		show_boss()
	elif GameManager.game_state == GameManager.GameState.LOOT:
		show_loot(GameManager.current_loot_result)

func _on_combat_message(msg: Dictionary):
	var color = Color("#c9b99a")
	match msg.get("type", ""):
		"initiative":
			color = Color("#66aaff")
		"heal":
			color = Color("#44cc88")
		"hit":
			color = Color("#cc6644")
		"miss":
			color = Color("#888888")
		"crit":
			color = Color("#ffd700")
		"damage":
			color = Color("#ff4444")
		"victory":
			color = Color("#44cc88")
		"defeat":
			color = Color("#ff2222")
		"class_ability":
			color = Color("#aa66ff")
	add_combat_log(msg.get("text", ""), color)
	var flavor = msg.get("flavor", "")
	if flavor != "":
		combat_narration.text = flavor

func _on_status_changed():
	if is_inside_tree():
		refresh_status_icons()

func _process(delta):
	torch_time += delta
	var f = 1.0 + sin(torch_time * 2.5) * 0.06
	f *= 1.0 + sin(torch_time * 3.7 + 1.2) * 0.03
	if bg:
		bg.modulate = Color(f, f, f, 1.0)

func hide_all_panels():
	explore_panel.hide()
	combat_panel.hide()
	loot_panel.hide()

func apply_theme():
	var theme_name = GameManager.dungeon.floor_theme
	var FTC = preload("res://Scripts/FloorThemeConfig.gd")
	var cfg = FTC.get_config(theme_name)
	theme_overlay.color = cfg.base_color

func apply_room_accent():
	var room_type = GameManager.dungeon.get_current_room_type()
	var FTC = preload("res://Scripts/FloorThemeConfig.gd")
	var accent = FTC.get_room_accent(room_type)
	theme_overlay.color = accent

func _fade_transition(callback: Callable):
	if anim_player.has_animation("fade_out"):
		anim_player.play("fade_out")
	else:
		var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		tween.tween_property(transition_overlay, "color", Color(0, 0, 0, 1), 0.15)
		tween.tween_callback(callback)
		tween.tween_property(transition_overlay, "color", Color(0, 0, 0, 0), 0.15)
		return
	await anim_player.animation_finished
	callback.call()
	anim_player.play("fade_in")
	await anim_player.animation_finished

func update_status():
	var p = GameManager.player
	if prev_hp > p.hp:
		TTS.speak_line("combat_hit", p.character_class.get("id", ""))
	prev_hp = p.hp
	hp_bar_fill.anchor_right = float(p.hp) / max(p.max_hp, 1)
	hp_label.text = str(p.hp) + "/" + str(p.max_hp)
	xp_bar_fill.anchor_right = float(p.xp) / max(p.xp_to_next, 1)
	xp_label.text = "Lv." + str(p.level) + " (" + str(p.xp) + "/" + str(p.xp_to_next) + ")"
	floor_info.text = "F" + str(GameManager.dungeon.floor_number)
	if p.weapon:
		weapon_label.text = p.weapon.get_suit_symbol() + " " + p.weapon.rank + "(" + str(p.get_weapon_damage_roll()) + ")"
	else:
		weapon_label.text = "Fists (1d2)"
	gold_label.text = str(p.gold) + "g"
	class_label.text = p.character_class.get("name", "Adventurer")
	shard_label.text = "Shards: " + str(GameManager.dungeon.escape_shards_collected) + "/3"
	refresh_status_icons()

func refresh_status_icons():
	for child in status_icons.get_children():
		child.queue_free()
	var p = GameManager.player
	for e in p.status_effects:
		var icon = Label.new()
		var icon_map = { "poison": "☠", "burn": "🔥", "armor": "🛡", "shield": "✦", "weakness": "▼", "stun": "✕", "regeneration": "♥", "frost_armor": "❄", "frozen_weapon": "🧊" }
		var color_map = { "poison": Color("#66bb33"), "burn": Color("#ff6622"), "armor": Color("#708090"), "shield": Color("#4fc3f7"), "weakness": Color("#9e9e9e"), "stun": Color("#ffd700"), "regeneration": Color("#4caf50"), "frost_armor": Color("#88ccff"), "frozen_weapon": Color("#88ccff") }
		icon.text = icon_map.get(e.id, "?")
		icon.add_theme_color_override("font_color", color_map.get(e.id, Color("#aaaaaa")))
		icon.add_theme_font_size_override("font_size", 16)
		icon.tooltip_text = e.get("name", e.id) + " (" + str(e.duration) + " turns)"
		status_icons.add_child(icon)

func show_explore():
	mode = BoardMode.EXPLORE
	hide_all_panels()
	apply_theme()
	apply_room_accent()
	if is_instance_valid(game_world):
		game_world.show_room(GameManager.dungeon.get_current_room_type(), GameManager.dungeon.floor_theme)
	_clear_3d_enemies()
	explore_panel.show()
	var ctx = GameManager.get_exploration_context()
	room_label.text = ctx.room_label
	floor_label.text = "Floor " + str(ctx.floor) + " - " + ctx.floor_theme
	var desc = ctx.room_description
	var flavor = GameManager.dungeon.get_narration_for_room(ctx.room_type, ctx.floor_theme)
	desc_label.text = ""
	narration.narrate(desc_label, desc + "\n\n" + flavor, 0.025)
	TTS.speak(desc)
	TTS.speak(flavor)
	TTS.speak_line("move")
	if ctx.room_type == GameManager.dungeon.RoomType.SECRET:
		TTS.speak_line("secret")
	elif ctx.room_type == GameManager.dungeon.RoomType.REST:
		TTS.speak_line("rest")
	clear_choices()
	for choice in ctx.choices:
		add_choice_button(choice)
	update_status()

func clear_choices():
	for child in choices_container.get_children():
		child.queue_free()

func add_choice_button(choice: Dictionary):
	var btn = Button.new()
	btn.text = choice.label + " — " + choice.desc
	btn.add_theme_color_override("font_color", Color("#c9b99a"))
	btn.add_theme_font_size_override("font_size", 14)
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
	btn.pressed.connect(_on_explore_choice.bind(choice.id))
	choices_container.add_child(btn)

func _on_explore_choice(choice_id: String):
	var result = GameManager.process_exploration_choice(choice_id)
	if not result.get("success", false):
		narration.narrate_instant(desc_label, result.get("error", "Cannot do that!"))
		return

	var cid_lower = choice_id.to_lower()
	var wants_turn = cid_lower.contains("left") or cid_lower.contains("right") or cid_lower.contains("turn")
	var wants_walk = cid_lower.contains("forward") or cid_lower.contains("ahead") or cid_lower.contains("enter") or cid_lower.contains("go") or cid_lower.contains("walk")

	if wants_turn and is_instance_valid(game_world):
		var dir = "left" if cid_lower.contains("left") else "right"
		game_world.play_turn_animation(dir)
		await get_tree().create_timer(0.7).timeout

	if wants_walk and result.get("action", "") != "combat" and is_instance_valid(game_world):
		game_world.play_walk_animation()
		await get_tree().create_timer(0.8).timeout

	match result.get("action", ""):
		"combat":
			combat_enemies = result.get("enemies", [])
			selected_enemy_index = 0 if combat_enemies.size() > 0 else -1
			show_combat()
		"boss":
			show_boss()
		"loot":
			current_loot = result.get("loot", {})
			show_loot(current_loot)
		"rest", "event":
			var msgs = result.get("messages", [])
			if msgs.size() > 0:
				var event_flavor = GameManager.dungeon.get_event_narration(choice_id)
				var combined = ""
				for m in msgs:
					combined += m.get("text", "") + "\n"
				narration.narrate_instant(desc_label, event_flavor + "\n\n" + combined.strip_edges())
				TTS.speak(event_flavor)
				if choice_id in ["rest", "meditate"]:
					TTS.speak_line("rest")
				else:
					TTS.speak_line("cta")
			await get_tree().create_timer(1.0).timeout
			if GameManager.player.hp <= 0:
				GameManager.end_run()
				get_tree().change_scene_to_file("res://Scenes/GameOver.tscn")
				return
			advance_room()
		"skip":
			advance_room()
		"escape":
			get_tree().change_scene_to_file("res://Scenes/GameOver.tscn")
		"shop":
			TTS.speak_line("shop")
			get_tree().change_scene_to_file("res://Scenes/Shop.tscn")
		"inventory":
			narration.narrate_instant(desc_label, "Inventory: " + str(GameManager.player.survival_items.size()) + " items, " + str(GameManager.player.consumables.size()) + " consumables.")
		_:
			narration.narrate_instant(desc_label, "Nothing happens.")

func advance_room():
	if is_instance_valid(game_world):
		game_world.play_walk_animation()
		await get_tree().create_timer(0.8).timeout
	var has_next = GameManager.advance_room()
	if GameManager.game_state == GameManager.GameState.GAME_OVER:
		get_tree().change_scene_to_file("res://Scenes/GameOver.tscn")
		return
	elif GameManager.game_state == GameManager.GameState.VICTORY:
		get_tree().change_scene_to_file("res://Scenes/GameOver.tscn")
		return
	show_explore()

func show_combat():
	mode = BoardMode.COMBAT
	hide_all_panels()
	if is_instance_valid(game_world):
		game_world.show_room(GameManager.dungeon.RoomType.MONSTER, GameManager.dungeon.floor_theme, true, false)
	_spawn_3d_enemies()
	combat_panel.show()
	combat_narration.text = ""
	refresh_enemy_display()
	clear_combat_log()
	var intro = GameManager.dungeon.get_narration_for_room(GameManager.dungeon.RoomType.MONSTER, GameManager.dungeon.floor_theme)
	add_combat_log(intro, Color("#c9b99a"))
	add_combat_log("Combat begins! " + str(combat_enemies.size()) + " enemy(ies).")
	TTS.speak(intro)
	TTS.speak_line("cta")
	update_status()
	refresh_action_buttons()

func refresh_enemy_display():
	var live_enemies = GameManager.combat.get_alive_enemies() if GameManager.combat else []
	combat_enemies = live_enemies
	for child in enemy_container.get_children():
		child.queue_free()
	for i in range(combat_enemies.size()):
		var enemy = combat_enemies[i]
		if not enemy.is_alive():
			continue
		var btn = Button.new()
		var hp_pct = float(enemy.hp) / max(enemy.max_hp, 1)
		var hp_text = str(enemy.hp) + "/" + str(enemy.max_hp)
		btn.text = enemy.monster_name + "\nHP: " + hp_text + "  AC: " + str(enemy.ac)
		btn.add_theme_color_override("font_color", Color("#e8d5c0"))
		btn.add_theme_font_size_override("font_size", 12)
		var s = StyleBoxFlat.new()
		s.bg_color = Color("#1a0a08")
		s.border_color = Color("#8c3a2a")
		s.border_width_left = 1
		s.border_width_right = 1
		s.border_width_top = 1
		s.border_width_bottom = 1
		s.corner_radius_top_left = 6
		s.corner_radius_top_right = 6
		s.corner_radius_bottom_left = 6
		s.corner_radius_bottom_right = 6
		if i == selected_enemy_index:
			s.border_color = Color("#c9a84c")
			s.bg_color = Color("#2c1810")
		btn.add_theme_stylebox_override("normal", s)
		var sh = s.duplicate()
		sh.border_color = Color("#c9a84c")
		sh.bg_color = Color("#3c2210")
		btn.add_theme_stylebox_override("hover", sh)
		btn.pressed.connect(_select_enemy.bind(i))
		var size_v = Vector2(180, 120)
		btn.custom_minimum_size = size_v
		enemy_container.add_child(btn)

func _select_enemy(index: int):
	selected_enemy_index = index
	refresh_enemy_display()

func clear_combat_log():
	for child in combat_log.get_children():
		child.queue_free()

func add_combat_log(text: String, color: Color = Color("#c9b99a")):
	if text == "":
		return
	var entry = Label.new()
	entry.text = text
	entry.add_theme_color_override("font_color", color)
	entry.add_theme_font_size_override("font_size", 11)
	entry.autowrap_mode = TextServer.AUTOWRAP_WORD
	combat_log.add_child(entry)
	await get_tree().process_frame
	combat_scroll.scroll_vertical = int(combat_scroll.get_v_scroll_bar().max_value)

var _spawned_3d_enemies: Array[Node] = []

func _spawn_3d_enemies():
	_clear_3d_enemies()
	if not combat_enemies or combat_enemies.is_empty():
		return
	if not is_instance_valid(game_world) or not game_world.room_node:
		return
	var room = game_world.room_node
	var factory = EnemyFactory.new()
	add_child(factory)
	var spawns = []
	for child in room.find_children("*EnemySpawn*", "Marker3D"):
		spawns.append(child)
	for i in combat_enemies.size():
		var md = combat_enemies[i]
		if not md is MonsterData:
			continue
		var pos = room.global_position
		if i < spawns.size():
			pos = spawns[i].global_position
		else:
			pos += Vector3(i * 2 - 2, 0, -1)
		var enemy = factory.spawn_enemy(md, pos, room)
		if enemy:
			_spawned_3d_enemies.append(enemy)
	factory.queue_free()

func _clear_3d_enemies():
	for e in _spawned_3d_enemies:
		if is_instance_valid(e):
			e.queue_free()
	_spawned_3d_enemies.clear()

func refresh_action_buttons():
	for child in action_container.get_children():
		child.queue_free()
	var actions = ["Attack", "Power Attack", "Defend", "Called Shot", "Flee"]
	var ids = ["attack", "power_attack", "defend", "called_shot", "flee"]
	if GameManager.player.level_abilities.size() > 0:
		actions.append("Ability")
		ids.append("use_ability")
	for i in range(actions.size()):
		var btn = Button.new()
		btn.text = actions[i]
		btn.add_theme_color_override("font_color", Color("#c9b99a"))
		btn.add_theme_font_size_override("font_size", 13)
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
		btn.pressed.connect(_on_combat_action.bind(ids[i]))
		action_container.add_child(btn)

func _on_combat_action(action_id: String):
	if combat_enemies.is_empty():
		add_combat_log("No enemies to fight!", Color("#ff4444"))
		return
	if GameManager.combat.get_state() != 0:
		add_combat_log("Wait for your turn!", Color("#ff4444"))
		return

	var target_index = selected_enemy_index
	if target_index < 0 or target_index >= combat_enemies.size():
		target_index = 0

	var result = GameManager.combat.process_player_action(action_id, target_index)
	if not result.get("success", false):
		for msg in result.get("messages", []):
			add_combat_log(msg.get("text", ""), Color("#ff4444"))
		return

	TTS.speak_line("combat_action", GameManager.player.character_class.get("id", ""))

	if result.get("fled", false):
		add_combat_log("You escaped combat!", Color("#44cc88"))
		TTS.speak_line("flee", GameManager.player.character_class.get("id", ""))
		await get_tree().create_timer(0.5).timeout
		GameManager.start_exploration()
		show_explore()
		return

	if GameManager.combat.get_state() == 4:
		add_combat_log("You were defeated!", Color("#ff2222"))
		await get_tree().create_timer(0.8).timeout
		if GameManager.player.hp <= 0:
			GameManager.end_run()
			get_tree().change_scene_to_file("res://Scenes/GameOver.tscn")
			return

	if GameManager.combat.get_state() == 3:
		_finish_combat_victory()
		return

	refresh_enemy_display()
	update_status()

	await get_tree().create_timer(0.8).timeout

	var enemy_messages = GameManager.combat.process_enemy_turn()
	for msg in enemy_messages:
		add_combat_log(msg.get("text", ""), Color("#cc6644"))

	if GameManager.combat.get_state() == 4:
		add_combat_log("You were defeated!", Color("#ff2222"))
		await get_tree().create_timer(0.8).timeout
		if GameManager.player.hp <= 0:
			GameManager.end_run()
			get_tree().change_scene_to_file("res://Scenes/GameOver.tscn")
			return

	if GameManager.combat.get_state() == 3:
		_finish_combat_victory()
		return

	refresh_enemy_display()
	update_status()

func _finish_combat_victory():
	add_combat_log("Victory!", Color("#ffd700"))
	await get_tree().create_timer(0.5).timeout
	var xp_msg = GameManager.player.add_xp(GameManager.combat.end_combat().get("xp", 0))
	for msg in xp_msg:
		if msg.type == "level_up":
			add_combat_log("Level " + str(msg.level) + "! +" + str(msg.hp_gain) + " Max HP!", Color("#ffd700"))
			TTS.speak_line("level_up", GameManager.player.character_class.get("id", ""))
	var gold = 0
	for e in combat_enemies:
		if not e.is_alive():
			gold += randi_range(2, 6) + GameManager.dungeon.floor_number
	GameManager.player.gold += gold
	add_combat_log("+" + str(gold) + " gold found.", Color("#c9a84c"))

	var loot = GameManager.loot_system.generate_treasure_loot(GameManager.dungeon.floor_number)
	current_loot = loot
	show_loot(current_loot)

func show_boss():
	mode = BoardMode.BOSS
	hide_all_panels()
	combat_panel.show()
	boss_active = true
	var boss_state = GameManager.get_boss_state()
	var boss = boss_state.boss
	clear_combat_log()
	var intro = GameManager.dungeon.get_narration_for_room(GameManager.dungeon.RoomType.BOSS, GameManager.dungeon.floor_theme)
	add_combat_log(intro, Color("#c9b99a"))
	add_combat_log("BOSS: " + boss.get("name", "Unknown") + " appears!", Color("#c9a84c"))
	add_combat_log(boss.get("flavor", ""), Color("#7a6b5a"))
	TTS.speak(intro)
	TTS.speak(boss.get("flavor", ""))
	TTS.speak_line("boss")
	update_status()
	refresh_boss_buttons()

func refresh_boss_buttons():
	for child in action_container.get_children():
		child.queue_free()
	var btn = Button.new()
	btn.text = "HIT BOSS"
	btn.add_theme_color_override("font_color", Color("#c9b99a"))
	btn.add_theme_font_size_override("font_size", 16)
	var s = StyleBoxFlat.new()
	s.bg_color = Color("#1a0f0a")
	s.border_color = Color("#8c3a2a")
	s.border_width_left = 2
	s.border_width_right = 2
	s.border_width_top = 2
	s.border_width_bottom = 2
	btn.add_theme_stylebox_override("normal", s)
	var sh = s.duplicate()
	sh.bg_color = Color("#2c1810")
	sh.border_color = Color("#c9a84c")
	btn.add_theme_stylebox_override("hover", sh)
	btn.custom_minimum_size = Vector2(200, 50)
	btn.pressed.connect(_on_boss_hit)
	action_container.add_child(btn)

func _on_boss_hit():
	if not boss_active:
		return
	var result = GameManager.process_boss_hit()
	for msg in result.get("messages", []):
		add_combat_log(msg.text, Color("#ff8844"))
	update_status()

	if result.get("boss_defeated", false):
		add_combat_log("BOSS DEFEATED!", Color("#ffd700"))
		boss_active = false
		var final = GameManager.finalize_boss_defeat()
		for msg in final.get("messages", []):
			add_combat_log(msg.get("text", ""), Color("#c9a84c"))
		for item in final.get("items", []):
			add_combat_log("Item: " + item.get("name", "?"), Color("#4488ff"))
		await get_tree().create_timer(1.0).timeout
		current_loot = { "gold": final.gold_reward, "items": final.get("items", []), "cards": [] }
		show_loot(current_loot)
	elif GameManager.player.hp <= 0:
		add_combat_log("You have been defeated!", Color("#ff2222"))
		await get_tree().create_timer(0.5).timeout
		GameManager.end_run()
		get_tree().change_scene_to_file("res://Scenes/GameOver.tscn")

func show_loot(loot: Dictionary):
	mode = BoardMode.LOOT
	hide_all_panels()
	loot_panel.show()
	TTS.speak_line("loot")
	current_loot = loot
	var msgs = []
	if loot.has("gold") and loot.gold > 0:
		msgs.append("+" + str(loot.gold) + " gold")
	if loot.has("items"):
		for item in loot.items:
			msgs.append(item.get("name", "?") + " - " + item.get("description", ""))
	if loot.has("cards"):
		for card in loot.cards:
			msgs.append(card.get_suit_symbol() + " " + card.rank)
	if msgs.is_empty():
		msgs.append("Nothing of value.")
	loot_label.text = "\n".join(msgs)
	for child in loot_items_container.get_children():
		child.queue_free()
	var collect_btn = Button.new()
	collect_btn.text = "Collect Loot"
	collect_btn.add_theme_color_override("font_color", Color("#c9a84c"))
	collect_btn.add_theme_font_size_override("font_size", 18)
	var s = StyleBoxFlat.new()
	s.bg_color = Color("#1a0f0a")
	s.border_color = Color("#c9a84c")
	s.border_width_left = 1
	s.border_width_right = 1
	s.border_width_top = 1
	s.border_width_bottom = 1
	collect_btn.add_theme_stylebox_override("normal", s)
	var sh = s.duplicate()
	sh.bg_color = Color("#2c1810")
	collect_btn.add_theme_stylebox_override("hover", sh)
	collect_btn.custom_minimum_size = Vector2(200, 40)
	collect_btn.pressed.connect(_collect_loot)
	loot_items_container.add_child(collect_btn)
	update_status()

func _collect_loot():
	var result = GameManager.collect_loot()
	if result.get("success", false):
		for msg in result.get("messages", []):
			loot_label.text = msg.get("text", "")
	update_status()
	await get_tree().create_timer(0.5).timeout
	advance_room()

func _on_item_use(index: int):
	var p = GameManager.player
	if index < 0 or index >= p.survival_items.size():
		return
	var item = p.survival_items[index]
	if item.get("effect") == "auto_flee":
		p.use_survival_item_charge(item.id)
		GameManager.start_exploration()
		show_explore()

func _exit_tree():
	pass
