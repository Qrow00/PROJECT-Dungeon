extends CardData
class_name ShieldData

func _init(p_value: int = 3):
	super(CardData.Suit.SHIELDS, "S", p_value)

func is_shield() -> bool:
	return true

func get_suit_symbol() -> String:
	return "🛡"

func to_dict() -> Dictionary:
	var d = super.to_dict()
	d["is_shield"] = true
	return d

static func from_dict(d: Dictionary) -> ShieldData:
	return ShieldData.new(d.get("value", 3))

func clone() -> ShieldData:
	return ShieldData.new(value)
