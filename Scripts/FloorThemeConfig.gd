extends Node
class_name FloorThemeConfig

static func get_config(theme_name: String) -> Dictionary:
	match theme_name:
		"Dark Caverns":
			return {
				"base_color": Color("#0d0805"),
				"overlay_color": Color("#0a0604"),
				"accent_color": Color("#8c6b4a"),
				"tint": Color("#ffeedd"),
				"particle_color": Color("#ff884422")
			}
		"Ancient Ruins":
			return {
				"base_color": Color("#0a080d"),
				"overlay_color": Color("#08060a"),
				"accent_color": Color("#7a6b8c"),
				"tint": Color("#ddccff"),
				"particle_color": Color("#8866ff22")
			}
		"Crystal Caves":
			return {
				"base_color": Color("#080a0f"),
				"overlay_color": Color("#06080c"),
				"accent_color": Color("#4a8cbb"),
				"tint": Color("#ccddff"),
				"particle_color": Color("#4488ff22")
			}
		"Lava Tunnels":
			return {
				"base_color": Color("#0f0806"),
				"overlay_color": Color("#0c0604"),
				"accent_color": Color("#cc4a2a"),
				"tint": Color("#ffccaa"),
				"particle_color": Color("#ff442222")
			}
		"Frozen Depths":
			return {
				"base_color": Color("#080a0d"),
				"overlay_color": Color("#06080a"),
				"accent_color": Color("#6b8cbb"),
				"tint": Color("#ddeeff"),
				"particle_color": Color("#88bbff22")
			}
		"Abyssal Vaults":
			return {
				"base_color": Color("#0a060d"),
				"overlay_color": Color("#08040a"),
				"accent_color": Color("#7a4a8c"),
				"tint": Color("#eeccee"),
				"particle_color": Color("#aa44ff22")
			}
	return {
		"base_color": Color("#0d0805"),
		"overlay_color": Color("#0a0604"),
		"accent_color": Color("#8c6b4a"),
		"tint": Color("#ffeedd"),
		"particle_color": Color("#ff884422")
	}

static func get_room_accent(room_type: int) -> Color:
	match room_type:
		0: return Color("#5c2a1a66")
		1: return Color("#c9a84c44")
		2: return Color("#8c5a2a44")
		3: return Color("#8c5acc44")
		4: return Color("#5a7acc44")
		5: return Color("#cc224444")
		6: return Color("#cc664444")
		7: return Color("#c9a84c66")
	return Color("#00000000")
