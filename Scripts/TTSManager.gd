extends Node
class_name TTSManager

signal tts_finished

const HASH_DIR: String = "res://Audio/Narration/hash/"
const VOICE_DIR: String = "res://Audio/Narration/voice/"
const EXT: String = ".ogg"

var queue: Array = []
var busy: bool = false
var rng: RandomNumberGenerator


func _ready():
	rng = RandomNumberGenerator.new()


func speak(text: String):
	if text.is_empty():
		return
	var hash = text.strip_edges().md5_text()
	var path = HASH_DIR + hash + EXT
	if not FileAccess.file_exists(path):
		return
	queue.push_back(path)
	if not busy:
		_process_queue()


func speak_line(category: String, class_id: String = ""):
	if class_id == "" and GameManager.player != null:
		class_id = GameManager.player.character_class.get("id", "")
	var base_dir = VOICE_DIR
	if class_id != "":
		var class_dir = DirAccess.open(base_dir.path_join(class_id))
		if class_dir:
			base_dir = base_dir.path_join(class_id) + "/"
	var dir = DirAccess.open(base_dir)
	if dir == null:
		return
	var files: Array = []
	dir.list_dir_begin()
	var f = dir.get_next()
	while f != "":
		if f.begins_with(category + "_") and f.ends_with(EXT):
			files.append(base_dir.path_join(f))
		f = dir.get_next()
	dir.list_dir_end()
	if files.is_empty():
		return
	var path = files[rng.randi() % files.size()]
	queue.push_back(path)
	if not busy:
		_process_queue()


func _process_queue():
	if queue.is_empty():
		if busy:
			busy = false
			tts_finished.emit()
		return
	if busy:
		return
	busy = true
	var path = queue.pop_front()
	var data = FileAccess.get_file_as_bytes(path)
	if data.is_empty():
		busy = false
		_process_queue()
		return
	var stream = AudioStreamOggVorbis.load_from_buffer(data)
	if stream == null:
		busy = false
		_process_queue()
		return
	var player = AudioStreamPlayer.new()
	add_child(player)
	player.stream = stream
	player.finished.connect(_on_player_finished.bind(player))
	player.play()


func _on_player_finished(player: AudioStreamPlayer):
	player.queue_free()
	busy = false
	_process_queue()
