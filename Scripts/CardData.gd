extends Resource
class_name CardData

enum Suit { HEARTS, DIAMONDS, CLUBS, SPADES, SHIELDS }

var suit: int
var rank: String
var value: int

func _init(p_suit: int = Suit.HEARTS, p_rank: String = "A", p_value: int = 1):
	suit = p_suit
	rank = p_rank
	value = p_value

func is_red() -> bool:
	return suit == Suit.HEARTS or suit == Suit.DIAMONDS

func is_black() -> bool:
	return not is_red()

func is_face_card() -> bool:
	return rank in ["J", "Q", "K"]

func is_ace() -> bool:
	return rank == "A"

func is_monster() -> bool:
	return false

func is_shield() -> bool:
	return false

func get_suit_name() -> String:
	match suit:
		Suit.HEARTS: return "hearts"
		Suit.DIAMONDS: return "diamonds"
		Suit.CLUBS: return "clubs"
		Suit.SPADES: return "spades"
		Suit.SHIELDS: return "shields"
	return ""

func get_suit_symbol() -> String:
	match suit:
		Suit.HEARTS: return "♥"
		Suit.DIAMONDS: return "♦"
		Suit.CLUBS: return "♣"
		Suit.SPADES: return "♠"
		Suit.SHIELDS: return "🛡"
	return ""

func to_dict() -> Dictionary:
	return {
		"suit": suit,
		"rank": rank,
		"value": value,
		"suit_name": get_suit_name(),
		"suit_symbol": get_suit_symbol()
	}

static func from_dict(d: Dictionary) -> CardData:
	var card = CardData.new(d.get("suit", 0), d.get("rank", "A"), d.get("value", 1))
	return card

func clone() -> CardData:
	return CardData.new(suit, rank, value)
