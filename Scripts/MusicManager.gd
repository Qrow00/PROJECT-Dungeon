extends Node
class_name MusicManager

const MUSIC_DIR: String = "res://Audio/Music/"
const EXT: String = ".ogg"

var music_player: AudioStreamPlayer
var current_track: String = ""


func _ready():
	music_player = AudioStreamPlayer.new()
	music_player.volume_db = -12.0
	add_child(music_player)


func play(track_name: String):
	if track_name == current_track and music_player.playing:
		return
	var path = MUSIC_DIR + track_name + EXT
	var data = FileAccess.get_file_as_bytes(path)
	if data.is_empty():
		return
	var stream = AudioStreamOggVorbis.load_from_buffer(data)
	if stream == null:
		return
	stream.set_loop(true)
	current_track = track_name
	music_player.stream = stream
	music_player.play()


func stop():
	music_player.stop()
	current_track = ""


func set_volume_db(value: float):
	music_player.volume_db = value
