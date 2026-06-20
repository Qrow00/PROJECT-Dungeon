extends Node
class_name DeckManager

var full_deck: Array = []
var draw_pile: Array = []
var discard_pile: Array = []
var monsters_data: Array = []

const SUITS = [CardData.Suit.HEARTS, CardData.Suit.DIAMONDS, CardData.Suit.CLUBS, CardData.Suit.SPADES]
const SHIELD_VALUES = [2, 3, 4, 5, 6, 7, 8]
const RANKS_VALUES = {
	"2": 2, "3": 3, "4": 4, "5": 5, "6": 6, "7": 7, "8": 8, "9": 9, "10": 10,
	"J": 11, "Q": 12, "K": 13, "A": 1
}

func load_monsters_data():
	var file = FileAccess.open("res://Data/Monsters.json", FileAccess.READ)
	if file:
		var text = file.get_as_text()
		var json = JSON.parse_string(text)
		if json is Array:
			monsters_data = json

func build_standard_deck():
	full_deck.clear()
	load_monsters_data()
	for entry in monsters_data:
		var monster = MonsterData.new(
			entry.get("name", "Monster"),
			entry.get("type", "beast"),
			entry.get("value", 3),
			entry.get("hp", 6),
			entry.get("ac", 12),
			entry.get("attack_bonus", 3),
			entry.get("damage_dice", "1d6"),
			entry.get("ability_id", ""),
			entry.get("ability_desc", ""),
			entry.get("description", ""),
			entry.get("tier", 1),
			entry.get("xp", 15),
			entry.get("behavior", "aggressive"),
			entry.get("min_encounter", 1),
			entry.get("max_encounter", 3)
		)
		full_deck.append(monster)
	for val in SHIELD_VALUES:
		full_deck.append(ShieldData.new(val))

func shuffle():
	draw_pile = full_deck.duplicate()
	draw_pile.shuffle()

func prepare_deck_for_floor(floor: int):
	draw_pile.clear()
	var max_tier = clampi(floor, 1, 4)
	for card in full_deck:
		if card is ShieldData or (card is MonsterData and card.tier <= max_tier):
			draw_pile.append(card)
	if draw_pile.is_empty():
		draw_pile = full_deck.duplicate()
	draw_pile.shuffle()

func draw_card() -> CardData:
	if draw_pile.is_empty():
		if discard_pile.is_empty():
			return null
		draw_pile = discard_pile.duplicate()
		discard_pile.clear()
		draw_pile.shuffle()
	return draw_pile.pop_back()

func draw_room() -> Array:
	var room = []
	for i in range(4):
		var card = draw_card()
		if card:
			room.append(card)
		else:
			break
	return room

func remaining() -> int:
	return draw_pile.size()

func total_cards() -> int:
	return full_deck.size()

func cards_left_in_deck() -> int:
	return draw_pile.size()
