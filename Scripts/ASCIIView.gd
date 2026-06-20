extends Control

enum Anim { IDLE, TURNING, WALKING }

var room_type := 0
var theme_name := "Dark Caverns"
var has_enemies := false
var has_treasure := false
var variant := 0
var torch_time := 0.0

var frames: Array = []
var current_frame := 0
var frame_timer := 0.0
var frame_interval := 1.5

var anim_state := Anim.IDLE
var anim_frames: Array = []
var anim_index := 0
var anim_timer := 0.0
var anim_speed := 0.08
var anim_callback: Callable = Callable()

var label: RichTextLabel

const COLS := 78
const ROWS := 28
const PAD := 25

func _init():
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _ready():
	label = RichTextLabel.new()
	label.bbcode_enabled = true
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.fit_content = false
	label.scroll_active = false
	var sf = SystemFont.new()
	sf.font_names = ["Consolas", "Courier New", "Lucida Console", "monospace"]
	label.add_theme_font_override("normal_font", sf)
	label.add_theme_font_size_override("normal_font_size", 14)
	add_child(label)
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	generate_frames()

func set_room(type: int, theme: String, enemies: bool = false, treasure: bool = false):
	anim_state = Anim.IDLE
	anim_frames.clear()
	room_type = type
	theme_name = theme
	has_enemies = enemies
	has_treasure = treasure
	variant = randi() % 6
	current_frame = 0
	frame_timer = 0.0
	generate_frames()

func play_turn(direction: String, callback: Callable = Callable()):
	anim_state = Anim.TURNING
	anim_callback = callback
	anim_index = 0
	anim_timer = 0.0
	anim_speed = 0.08
	anim_frames.clear()
	var dir = 1 if direction == "left" else -1
	for i in range(8):
		var t = float(i) / 7.0
		var offset = sin(t * PI) * 10.0 * dir
		anim_frames.append(build(0, 1, offset, 0.0, 0.0))
	_render()

func play_walk(callback: Callable = Callable()):
	anim_state = Anim.WALKING
	anim_callback = callback
	anim_index = 0
	anim_timer = 0.0
	anim_speed = 0.07
	anim_frames.clear()
	for i in range(10):
		var t = float(i) / 9.0
		var depth = sin(t * PI) * 6.0
		var bob = sin(t * PI * 2.0) * 1.5
		anim_frames.append(build(0, 1, 0.0, depth, bob))
	_render()

func generate_frames():
	frames.clear()
	for i in range(8):
		frames.append(build(i, 8, 0.0, 0.0, 0.0))
	_render()

func build(idx: int, total: int, toff: float, walk: float, bob: float) -> String:
	var VW = COLS + PAD * 2
	var gc = VW / 2

	var gd: Array = []
	for y in range(ROWS):
		var row: Array = []
		for x in range(VW):
			row.append({ "c": " ", "col": "" })
		gd.append(row)

	var dv = int(idx * 1.7 + variant * 2.3)
	var wc = wall_col()
	var fc = floor_col()
	var cc = ceil_col()

	for y in range(ROWS):
		var t = float(y) / float(ROWS)
		var walk_factor = 0.1 + t * 0.5
		var bob_factor = 0.2 + t * 0.8
		var sy = y + int(bob * bob_factor)
		var hw = int(2.5 + float(y) * 0.9 + walk * walk_factor)
		if hw < 1: hw = 1
		var p_off = int(toff * (0.2 + t * 0.8))
		var cy = gc + p_off
		var l = cy - hw
		var r = cy + hw

		for x in range(VW):
			var ch = " "
			var col = ""

			if sy < 5:
				if x >= l + 1 and x <= r - 1:
					if hw < 5:
						ch = ["▀","░"][abs(x - int(cy)) % 2]; col = cc
					else:
						ch = ["░","▒"," "," "][(x + y * 2 + dv) % 4]
						ch = " " if ch == " " else ch
						col = cc if ch != " " else ""
				else:
					ch = "▓"; col = cc

			elif sy < 6:
				if abs(x - int(cy)) < 2:
					ch = "#"; col = wc
				elif abs(x - int(cy)) < 4:
					ch = "▓"; col = wc
				elif x >= l and x <= r:
					ch = "░"; col = wc
				else:
					ch = "#"; col = wc

			elif sy < 17:
				if x > l and x < r:
					ch = corr_floor(x, y, hw, dv, int(cy))
					col = fc
				elif x == l or x == r:
					ch = "║"; col = wc
				else:
					var wb = _brick(x, y, l, r, int(cy), dv, wc)
					ch = wb.c; col = wb.col

			else:
				if x > l + 1 and x < r - 1:
					var opening = r - l - 2
					var segs = max(4, opening / 4)
					var seg_w = float(opening) / segs
					var rel = float(x - l - 1)
					var seg = int(rel / seg_w)
					var in_seg = (rel / seg_w) - seg
					var edge_dist = min(in_seg, 1.0 - in_seg)
					if edge_dist < 0.06:
						ch = "░"; col = fc
					else:
						var tile = seg + y * 2 + dv
						if tile % 2 == 0:
							ch = "."; col = fc
						else:
							ch = ","; col = fc
				elif x >= l and x <= r:
					ch = "░"; col = wc
				elif x >= l - 2 and x <= r + 2:
					ch = "▒"; col = wc
				else:
					ch = "#"; col = wc

			gd[y][x] = { "c": ch, "col": col }

	if anim_state == Anim.IDLE:
		overlays(gd, idx, wc, fc, gc)

	return extract_window(gd, gc)

func extract_window(gd: Array, gc: int) -> String:
	var VW = COLS + PAD * 2
	var win = gc - COLS / 2

	var parts: Array = []
	for y in range(gd.size()):
		var line = ""
		var last_col = ""
		for x in range(COLS):
			var vx = win + x
			var cell = gd[y][vx]
			if cell.col == last_col:
				line += cell.c
			elif cell.col == "":
				line += "[/color]" if last_col != "" else ""
				line += cell.c
				last_col = ""
			elif last_col == "":
				line += "[color=" + cell.col + "]" + cell.c
				last_col = cell.col
			else:
				line += "[/color][color=" + cell.col + "]" + cell.c
				last_col = cell.col
		if last_col != "":
			line += "[/color]"
		parts.append(line)
	return "\n".join(parts)

func _brick(x: int, y: int, l: int, r: int, center: int, dv: int, wc: String) -> Dictionary:
	var wall_x: int
	if x <= l:
		wall_x = l - x
	else:
		wall_x = x - r

	var scale = 0.4 + float(y) / float(ROWS) * 0.8
	var bh = int(4.0 * scale)
	var bw = int(7.0 * scale)
	if bh < 2: bh = 2
	if bw < 3: bw = 3

	var row = y % (bh + 1)
	var brick_row = int(y / (bh + 1))
	var offset = (brick_row % 2) * int(bw / 2)
	var col = (wall_x + offset) % (bw + 1)

	if row == 0 or row == bh:
		return { "c": "░", "col": wc }
	if col == 0 or col == bw:
		return { "c": "░", "col": wc }

	var tex = (wall_x + y + dv) % 5
	if tex < 2:
		return { "c": "█", "col": wc }
	elif tex < 4:
		return { "c": "▓", "col": wc }
	else:
		return { "c": "▒", "col": wc }

func corr_floor(x: int, y: int, hw: int, dv: int, center: int) -> String:
	var cx = x - center
	if hw > 7:
		if abs(cx) < hw * 0.3:
			return "." if (x + y * 2 + dv) % 3 == 0 else ","
		return "." if (x + y + dv) % 2 == 0 else ","
	if hw > 4:
		return "." if (x + y + dv) % 2 == 0 else " "
	return " " if (x + y + dv) % 2 == 0 else " "

func overlays(gd: Array, idx: int, wc: String, fc: String, gc: int):
	var show_m = has_enemies and (idx % 2 == 0)
	if show_m:
		var spots = [[0, 11], [-2, 12], [3, 10], [-1, 13]]
		var si = idx % spots.size()
		var sp = spots[si]
		var cx = gc + sp[0]; var cy = sp[1]
		if cy < gd.size() and cx >= 0 and cx < gd[cy].size():
			var mc = ["M", "W", "G", "S"][(idx + variant) % 4]
			gd[cy][cx] = { "c": mc, "col": "#ee3333" }

	var show_t = has_treasure and (idx % 4 == 1)
	if show_t:
		var cy = 15
		if cy < gd.size():
			var cx = gc - 1
			if cx >= 0 and cx + 2 < gd[cy].size():
				gd[cy][cx] = { "c": "[", "col": wc }
				gd[cy][cx + 1] = { "c": "$", "col": "#ffcc00" }
				gd[cy][cx + 2] = { "c": "]", "col": wc }

	var is_boss = (room_type == 6) and (idx % 2 == 0)
	if is_boss:
		var cy = 10
		if cy < gd.size():
			var cx = gc - 1
			if cx >= 0 and cx + 1 < gd[cy].size():
				gd[cy][cx] = { "c": "Ω", "col": "#ee2222" }
				gd[cy][cx + 1] = { "c": "Ω", "col": "#ee2222" }

	var is_esc = (room_type == 7) and (idx % 3 == 0)
	if is_esc:
		for dy in range(4):
			var cy = 8 + dy
			if cy < gd.size():
				for dx in range(-3, 4):
					var cx = gc + dx
					if cx >= 0 and cx < gd[cy].size():
						var star = (abs(dx) + dy + idx) % 2 == 0
						gd[cy][cx] = { "c": "✦" if star else " ", "col": "#44bbff" if star else "" }

	var is_rest = (room_type == 5) and (idx % 4 == 0)
	if is_rest:
		var cy = 15
		if cy < gd.size():
			var cx = gc - 2
			if cx >= 0 and cx + 2 < gd[cy].size():
				gd[cy][cx] = { "c": "(", "col": wc }
				gd[cy][cx + 1] = { "c": "♥", "col": "#ee4466" }
				gd[cy][cx + 2] = { "c": ")", "col": wc }

func current() -> String:
	if anim_state != Anim.IDLE and anim_frames.size() > 0:
		return anim_frames[anim_index]
	if frames.size() > 0:
		return frames[current_frame]
	return ""

func _render():
	label.text = current()

func _process(delta):
	torch_time += delta
	var f = 0.82 + sin(torch_time * 1.6) * 0.10 + sin(torch_time * 2.9 + 1.7) * 0.05
	modulate = Color(f, f, f * 0.90, 1.0)

	if anim_state != Anim.IDLE and anim_frames.size() > 0:
		anim_timer += delta
		if anim_timer >= anim_speed:
			anim_timer = 0.0
			anim_index += 1
			if anim_index >= anim_frames.size():
				anim_state = Anim.IDLE
				anim_frames.clear()
				generate_frames()
				if anim_callback.is_valid():
					anim_callback.call()
			else:
				_render()
	else:
		frame_timer += delta
		if frame_timer >= frame_interval:
			frame_timer = 0.0
			current_frame = (current_frame + 1) % frames.size()
			_render()

func wall_col() -> String:
	match theme_name:
		"Dark Caverns": return "#7a5533"
		"Ancient Ruins": return "#8a6a44"
		"Crystal Caves": return "#557799"
		"Lava Tunnels": return "#994433"
		"Frozen Depths": return "#7788aa"
		"Abyssal Vaults": return "#553377"
		_: return "#7a5533"

func floor_col() -> String:
	match theme_name:
		"Dark Caverns": return "#aa8844"
		"Ancient Ruins": return "#9a7a44"
		"Crystal Caves": return "#557766"
		"Lava Tunnels": return "#996633"
		"Frozen Depths": return "#779988"
		"Abyssal Vaults": return "#665588"
		_: return "#aa8844"

func ceil_col() -> String:
	match theme_name:
		"Dark Caverns": return "#221111"
		"Ancient Ruins": return "#1a1110"
		"Crystal Caves": return "#112233"
		"Lava Tunnels": return "#1a0808"
		"Frozen Depths": return "#112244"
		"Abyssal Vaults": return "#0a001a"
		_: return "#221111"
