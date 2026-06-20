extends Control
class_name CardUI

var card_data: CardData = null
var is_face_down: bool = false
var is_hovered: bool = false
var is_selected: bool = false
var is_disabled: bool = false
var card_index: int = -1
var is_boss: bool = false
var boss_hp: int = 0
var boss_max_hp: int = 0
var glow_time: float = 0.0
var card_type: int = 0

@onready var card_shadow: ColorRect = $CardShadow
@onready var card_border: TextureRect = $CardBorderOuter
@onready var card_face: ColorRect = $CardFace
@onready var center_art: TextureRect = $CenterArt

@onready var monster_name_label: Label = $MonsterNameLabel

@onready var card_back: TextureRect = $CardBack
@onready var glow_overlay: ColorRect = $GlowOverlay
@onready var hover_glow: ColorRect = $HoverGlow
@onready var cost_label: Label = $CardCostLabel
@onready var type_banner: Label = $CardTypeBanner

signal card_clicked(index, card_data)
signal card_hovered(index, card_data)

const INK_COLOR = Color("#1a0f0a")
const PARCHMENT = Color("#d4c5a9")
const PARCHMENT_LIGHT = Color("#e8dcc8")
const RED_ACCENT = Color("#b91c1c")
const MONSTER_COLOR = Color("#2a1010")
const BOSS_COLOR = Color("#1a0a1a")
const GOLD_ACCENT = Color("#c9a84c")
const GOLD_BRIGHT = Color("#ffd700")
const WEAPON_COLOR = Color("#1a1a2e")
const SHIELD_COLOR = Color("#1a2a3a")
const CARD_CORNER_RADIUS = 8.0

enum CardTheme {
	ATTACK,
	SKILL,
	DEFENSE,
	MAGIC,
	LEGENDARY,
	MONSTER,
	BOSS,
}

var hover_tween: Tween = null
var select_tween: Tween = null
var flip_tween: Tween = null
var deal_tween: Tween = null
var is_flipped: bool = false

const NATIVE_HEIGHT = 375.0

var monster_textures: Dictionary = {}
var card_face_textures: Array = []
var card_face_aspects: Array = []
var monster_aspects: Dictionary = {}

var bow_texture: Texture2D
var bow_aspect: float
var warhammer_texture: Texture2D
var warhammer_aspect: float

var cinzel_font: Font = load("res://Assets/Fonts/Cinzel.ttf")

func _ready():
	mouse_entered.connect(_on_mouse_enter)
	mouse_exited.connect(_on_mouse_exit)
	if cinzel_font:
		var fv = FontVariation.new()
		fv.base_font = cinzel_font
		fv.set_variation_opentype({"wght": 600})
		var th = Theme.new()
		th.default_font = fv
		theme = th
	monster_name_label.add_theme_font_size_override("font_size", 14)
	type_banner.add_theme_font_size_override("font_size", 10)

	card_face_textures = []
	card_face_aspects = []
	var weapon_paths = [
		"res://Assets/Art/cards/bow.png",
		"res://Assets/Art/cards/healing_potion.png",
		"res://Assets/Art/cards/iron_sword.png",
		"res://Assets/Art/cards/shield.png",
		"res://Assets/Art/cards/warhammer.png",
	]
	for path in weapon_paths:
		var tex = _load_texture(path)
		if tex:
			card_face_textures.append(tex)
			var s = tex.get_size()
			card_face_aspects.append(s.x / s.y)
		else:
			var fallback = PlaceholderTexture2D.new()
			fallback.size = Vector2(48, 64)
			card_face_textures.append(fallback)
			card_face_aspects.append(0.75)
	bow_texture = card_face_textures[0]
	bow_aspect = card_face_aspects[0]
	warhammer_texture = card_face_textures[4]
	warhammer_aspect = card_face_aspects[4]

	var monster_types = ["beast", "construct", "cultist", "demon", "dragon", "elemental", "giant", "goblin", "slime", "undead"]
	for t in monster_types:
		var path = "res://Assets/Art/cards/" + t + ".png"
		if t == "cultist":
			path = "res://Assets/Art/cards/culltist.png"
		var tex = _load_texture(path)
		if tex:
			monster_textures[t] = tex
			var s = tex.get_size()
			monster_aspects[t] = s.x / s.y
	monster_aspects["goblin"] = 0.746

func _load_texture(path: String) -> Texture2D:
	var tex = load(path)
	if tex:
		return tex
	return null

func _get_card_art_aspect(card: CardData) -> float:
	if card is MonsterData:
		var m = card as MonsterData
		var a = monster_aspects.get(m.monster_type)
		if a:
			return a
	return 0.6

static func get_card_aspect(card: CardData) -> float:
	if card is MonsterData:
		var m = card as MonsterData
		var monster_aspects = {
			"beast": 0.747, "construct": 0.729, "cultist": 0.741,
			"demon": 0.731, "dragon": 0.796, "elemental": 0.744,
			"giant": 0.795, "goblin": 0.746, "slime": 0.745, "undead": 0.737,
		}
		var a = monster_aspects.get(m.monster_type)
		if a:
			return a
	return 0.6

static func get_card_native_height(card: CardData) -> float:
	return 375.0

static func get_card_native_width(card: CardData) -> float:
	return get_card_native_height(card) * get_card_aspect(card)

func _update_shader_size():
	if center_art and center_art.material is ShaderMaterial:
		(center_art.material as ShaderMaterial).set_shader_parameter("node_size", size)

func _sync_minimum_size():
	custom_minimum_size = size
	if center_art and center_art.material is ShaderMaterial:
		(center_art.material as ShaderMaterial).set_shader_parameter("node_size", size)

func setup(card: CardData, index: int, face_down: bool = false, card_w: float = 160.0, card_h: float = 228.0):
	card_data = card
	card_index = index
	is_face_down = face_down
	is_boss = false
	is_hovered = false
	is_selected = false
	is_disabled = false
	if card:
		card_h = card_w / _get_card_art_aspect(card)
		card_type = _get_card_theme(card)
	size = Vector2(card_w, card_h)
	_sync_minimum_size()
	mouse_filter = Control.MOUSE_FILTER_STOP
	update_visuals()

func setup_boss(card: CardData, index: int, hp: int = 0, max_hp: int = 0, card_w: float = 160.0, card_h: float = 228.0):
	card_data = card
	card_index = index
	is_face_down = false
	is_boss = true
	boss_hp = hp
	boss_max_hp = max_hp
	is_hovered = false
	is_selected = false
	is_disabled = false
	if card:
		card_h = card_w / _get_card_art_aspect(card)
		card_type = _get_card_theme(card)
	size = Vector2(card_w, card_h)
	_sync_minimum_size()
	mouse_filter = Control.MOUSE_FILTER_STOP
	is_disabled = false
	update_visuals()

func _get_card_theme(card: CardData) -> int:
	if card is MonsterData:
		if is_boss:
			return CardTheme.BOSS
		return CardTheme.MONSTER
	if card.is_red():
		return CardTheme.MAGIC
	if card.is_shield():
		return CardTheme.DEFENSE
	if card.rank == "A" and card.suit == CardData.Suit.SPADES:
		return CardTheme.LEGENDARY
	return CardTheme.ATTACK

func update_visuals():
	if not card_data:
		return
	if is_face_down:
		_hide_art()
		update_face_down()
		return
	if card_data is MonsterData:
		_render_monster(card_data as MonsterData)
	else:
		_render_playing_card()

func update_face_down():
	_size_art()
	if card_face:
		card_face.color = Color(0.3, 0.2, 0.15, 1)
	if center_art:
		center_art.hide()

func _hide_art():
	if center_art:
		center_art.hide()
	if card_face:
		card_face.hide()
	if card_border:
		card_border.hide()

func _render_playing_card():
	if card_face:
		card_face.show()
		card_face.color = get_card_color()

	if center_art:
		center_art.show()
		center_art.stretch_mode = TextureRect.STRETCH_SCALE

	if card_border:
		card_border.show()

	if cost_label:
		cost_label.text = str(card_data.value)

	if monster_name_label:
		monster_name_label.hide()

	if card_data.suit == CardData.Suit.CLUBS:
		_render_weapon()
	elif card_data.suit == CardData.Suit.DIAMONDS or card_data.is_red():
		_render_default()
	else:
		if not center_art or not center_art.texture:
			_render_default()

func _render_monster(m: MonsterData):
	if center_art:
		center_art.show()
		center_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		center_art.size = size
		center_art.position = Vector2(0, 0)
		var tex = monster_textures.get(m.monster_type)
		if not tex:
			var idx = m.value % card_face_textures.size()
			tex = card_face_textures[idx]
		center_art.texture = tex

	if monster_name_label:
		monster_name_label.hide()

	var has_ability = not m.ability_id.is_empty()
	if glow_overlay:
		if has_ability:
			glow_overlay.show()
			glow_overlay.color = Color(0.3, 0.0, 0.0, 0.3)
		else:
			glow_overlay.color = Color(0, 0, 0, 0)
	_size_art()

func _render_weapon():
	if center_art:
		var weapon_idx = card_data.value % card_face_textures.size()
		center_art.texture = card_face_textures[weapon_idx]
		_size_art()
	if type_banner:
		type_banner.text = str(card_data.value)
		type_banner.show()

func _render_default():
	if center_art:
		var idx = card_data.value % card_face_textures.size()
		center_art.texture = card_face_textures[idx]
		_size_art()

func _size_art():
	pass

func get_card_color() -> Color:
	return Color(0.3, 0.15, 0.1, 1)

func _gui_input(event):
	if is_disabled or not card_data:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			card_clicked.emit(card_index, card_data)
			accept_event()

func _on_mouse_enter():
	if not is_disabled:
		is_hovered = true
		card_hovered.emit(card_index, card_data)
		_play_hover_animation()

func _on_mouse_exit():
	is_hovered = false
	_play_unhover_animation()

func _play_hover_animation():
	if hover_tween and hover_tween.is_valid():
		hover_tween.kill()
	hover_tween = create_tween()
	hover_tween.set_parallel(true)
	hover_tween.tween_property(self, "scale", Vector2(1.05, 1.05), 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	hover_tween.tween_property(self, "position", position - Vector2(0, 20), 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)

func _play_unhover_animation():
	if hover_tween and hover_tween.is_valid():
		hover_tween.kill()
	hover_tween = create_tween()
	hover_tween.set_parallel(true)
	hover_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	hover_tween.tween_property(self, "position", position + Vector2(0, 20), 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)

func _play_select_animation():
	if select_tween and select_tween.is_valid():
		select_tween.kill()
	select_tween = create_tween()
	select_tween.set_parallel(true)
	select_tween.tween_property(self, "scale", Vector2(1.15, 1.15), 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	select_tween.tween_property(self, "position", position - Vector2(0, 40), 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func _play_deselect_animation():
	if select_tween and select_tween.is_valid():
		select_tween.kill()
	select_tween = create_tween()
	select_tween.set_parallel(true)
	select_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	select_tween.tween_property(self, "position", position + Vector2(0, 40), 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func play_flip_deal_animation(target_pos: Vector2, from_pos: Vector2, delay: float = 0.0):
	if deal_tween and deal_tween.is_valid():
		deal_tween.kill()
	position = target_pos
	modulate = Color(1, 1, 1, 0)
	scale = Vector2(0.5, 1.0)
	deal_tween = create_tween()
	deal_tween.set_parallel(false)
	deal_tween.tween_interval(delay)
	deal_tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	deal_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	if is_face_down:
		deal_tween.tween_callback(_flip_face_up)
	deal_tween.parallel().tween_property(self, "scale", Vector2(1.0, 1.0), 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)

func _flip_face_up():
	is_face_down = false
	update_visuals()

func select():
	is_selected = true
	_play_select_animation()

func deselect():
	is_selected = false
	_play_deselect_animation()

func disable():
	is_disabled = true
	modulate = Color(0.6, 0.6, 0.6, 1)

func enable():
	is_disabled = false
	modulate = Color(1, 1, 1, 1)

func play_victory_animation():
	if deal_tween and deal_tween.is_valid():
		deal_tween.kill()
	deal_tween = create_tween()
	deal_tween.tween_property(self, "modulate", Color(1, 1, 1, 0), 0.3).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)

func play_heal_animation():
	pass

func play_charge_animation():
	pass

func play_kill_shot_animation():
	if select_tween and select_tween.is_valid():
		select_tween.kill()
	select_tween = create_tween()
	select_tween.set_parallel(true)
	select_tween.tween_property(self, "scale", Vector2(1.3, 1.3), 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	select_tween.tween_property(self, "modulate", Color(1, 0.3, 0.3, 1), 0.1)
	select_tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.2)

func play_deal_animation(target_pos: Vector2, delay: float = 0.0):
	if deal_tween and deal_tween.is_valid():
		deal_tween.kill()
	position = target_pos
	modulate = Color(1, 1, 1, 0)
	scale = Vector2(0.5, 1.0)
	deal_tween = create_tween()
	deal_tween.set_parallel(false)
	deal_tween.tween_interval(delay)
	deal_tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	deal_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func play_boss_defeat_animation():
	if deal_tween and deal_tween.is_valid():
		deal_tween.kill()
	deal_tween = create_tween()
	deal_tween.set_parallel(true)
	deal_tween.tween_property(self, "modulate", Color(1, 0.5, 0.5, 0), 0.5)
	deal_tween.tween_property(self, "scale", Vector2(0.1, 0.1), 0.5).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)

func play_death_charge_animation():
	if select_tween and select_tween.is_valid():
		select_tween.kill()
	select_tween = create_tween()
	select_tween.set_parallel(true)
	select_tween.tween_property(self, "modulate", Color(3, 0.2, 0.2, 1), 0.3)
	select_tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	select_tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.2).set_delay(0.3)
