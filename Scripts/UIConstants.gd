extends Node

## ── Dungeon Card UI Constants ──
## Central source of truth for all visual design tokens.

## ── Palette ──
const BG_DARKEST     := Color("#050302")
const BG_DARK        := Color("#0a0706")
const BG_MID         := Color("#1a0f0a")
const BG_LIGHT       := Color("#2c1810")
const STONE_LIGHT    := Color("#5c4a3a")
const STONE_MED      := Color("#3d2e22")

const GOLD_ACCENT    := Color("#c9a84c")
const GOLD_BRIGHT    := Color("#ffd700")
const GOLD_DIM       := Color("#8a7030")

const PARCHMENT      := Color("#d4c5a9")
const PARCHMENT_LIT  := Color("#e8dcc8")
const INK            := Color("#1a0f0a")

const RED_CRIMSON    := Color("#b91c1c")
const RED_BLOOD      := Color("#8a1010")
const RED_GLOW       := Color("#ff3333")

const EMERALD        := Color("#1ca84c")
const SAPPHIRE       := Color("#1c4ca8")
const ARCANE         := Color("#8c1ca8")
const LEGENDARY      := Color("#c9a84c")

const HP_GREEN       := Color("#2ecc40")
const HP_RED         := Color("#cc4422")
const ARMOR_BLUE     := Color("#4488cc")
const XP_PURPLE      := Color("#8844cc")

const STATUS_POISON  := Color("#66bb33")
const STATUS_BURN    := Color("#ff6622")
const STATUS_SHIELD  := Color("#4488cc")
const STATUS_WEAK    := Color("#886644")
const STATUS_STUN    := Color("#cccc44")
const STATUS_REGEN   := Color("#44cc88")

## ── Font sizes ──
const TITLE_SIZE     := 48
const HEADING_SIZE   := 28
const BODY_SIZE      := 18
const SMALL_SIZE     := 14
const TINY_SIZE      := 11

## ── Spacing ──
const PAD_TINY       := 4
const PAD_SMALL      := 8
const PAD_MED        := 16
const PAD_LARGE      := 24
const PAD_XLARGE     := 40

## ── Card dimensions ──
const CARD_W         := 160.0
const CARD_H         := 228.0
const CARD_GAP       := 14.0
const CARD_FAN_LIFT  := 40.0
const CARD_HOVER_LIFT := 50.0
const CARD_SELECT_LIFT := 70.0
const CARD_HOVER_SCALE := 1.10
const CARD_SELECT_SCALE := 1.15

## ── Animation durations (seconds) ──
const ANIM_FAST      := 0.08
const ANIM_NORMAL    := 0.15
const ANIM_SLOW      := 0.30
const ANIM_DEAL      := 0.35
const ANIM_SHAKE     := 0.10
const ANIM_ROOM_CLEAR := 0.40

## ── Torch flicker ──
const TORCH_SPEED1   := 2.5
const TORCH_SPEED2   := 3.7
const TORCH_STRENGTH := 0.06
const TORCH_OFFSET   := 1.2

## ── Card type theme colors ──
enum CardTheme {
	ATTACK,     # crimson
	SKILL,      # emerald
	DEFENSE,    # sapphire
	MAGIC,      # arcane
	LEGENDARY,  # gold
	MONSTER     # blood dark
}

const CARD_THEME_COLORS := {
	CardTheme.ATTACK:    RED_CRIMSON,
	CardTheme.SKILL:     EMERALD,
	CardTheme.DEFENSE:   SAPPHIRE,
	CardTheme.MAGIC:     ARCANE,
	CardTheme.LEGENDARY: LEGENDARY,
	CardTheme.MONSTER:   Color("#2a1010"),
}

const CARD_THEME_NAMES := {
	CardTheme.ATTACK:    "Attack",
	CardTheme.SKILL:     "Skill",
	CardTheme.DEFENSE:   "Defense",
	CardTheme.MAGIC:     "Magic",
	CardTheme.LEGENDARY: "Legendary",
	CardTheme.MONSTER:   "Monster",
}

## ── Panel / button style helpers ──
static func panel_style(bg: Color = BG_DARK, border: Color = STONE_MED) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.border_width_left = 1
	s.border_width_right = 1
	s.border_width_top = 1
	s.border_width_bottom = 1
	s.corner_radius_top_left = 6
	s.corner_radius_top_right = 6
	s.corner_radius_bottom_left = 6
	s.corner_radius_bottom_right = 6
	return s

static func gold_button_style() -> Dictionary:
	var n := StyleBoxFlat.new()
	n.bg_color = BG_MID
	n.border_color = STONE_LIGHT
	n.border_width_left = 2
	n.border_width_right = 2
	n.border_width_top = 2
	n.border_width_bottom = 2
	n.corner_radius_top_left = 4
	n.corner_radius_top_right = 4
	n.corner_radius_bottom_left = 4
	n.corner_radius_bottom_right = 4

	var h := n.duplicate()
	h.bg_color = BG_LIGHT
	h.border_color = GOLD_ACCENT

	return { "normal": n, "hover": h }

static func style_button(btn: Button):
	var s = gold_button_style()
	btn.add_theme_stylebox_override("normal", s.normal)
	btn.add_theme_stylebox_override("hover", s.hover)
	btn.add_theme_color_override("font_color", GOLD_ACCENT)
	btn.add_theme_font_size_override("font_size", BODY_SIZE)

## ── Dungeon nav style ──
static func dungeon_panel(p: Panel):
	var s = panel_style()
	p.add_theme_stylebox_override("panel", s)
