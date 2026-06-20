# DEPRECATED for turn-based 3D. GameWorld.gd handles room display directly.
class_name RoomViewport3D
extends Node3D

signal transition_finished()

var current_room_node: Node3D = null
var camera: Camera3D
var camera_tween: Tween
var is_transitioning: bool = false

@export var transition_speed: float = 0.4

func _ready():
	camera = Camera3D.new()
	camera.current = true
	camera.fov = 75
	camera.near = 0.05
	camera.far = 100.0
	add_child(camera)

func show_room(room_type: int, theme_name: String, enemies: Array = [], treasure: bool = false):
	if is_transitioning:
		return

	if current_room_node:
		_animate_out()
		await transition_finished

	var room_scene = _get_room_scene(room_type)
	if not room_scene:
		return

	var instance = room_scene.instantiate()
	add_child(instance)
	current_room_node = instance

	_apply_theme(instance, theme_name)
	_place_camera_for_room(instance)
	_animate_in()

func _get_room_scene(room_type: int) -> PackedScene:
	var dm = GameManager.dungeon
	if not dm:
		return load("res://Scenes/environments/dungeon_room.tscn")

	var room_label = dm.get_room_label(room_type).to_lower().replace(" ", "_")
	var path = "res://Scenes/environments/%s.tscn" % room_label
	if ResourceLoader.exists(path):
		return load(path)
	return load("res://Scenes/environments/dungeon_room.tscn")

func _place_camera_for_room(room: Node3D):
	var cam_pos = room.get_node_or_null("CameraPosition")
	if cam_pos:
		camera.global_position = cam_pos.global_position
		if cam_pos.get_child_count() > 0 and cam_pos.get_child(0) is Marker3D:
			var look = cam_pos.get_child(0) as Marker3D
			camera.look_at(look.global_position)
		else:
			camera.look_at(room.global_position)
	else:
		camera.position = Vector3(0, 2.5, 8)
		camera.look_at(room.global_position)

func _animate_in():
	is_transitioning = true
	if camera_tween and camera_tween.is_valid():
		camera_tween.kill()
	camera_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	camera_tween.tween_property(camera, "position:z", camera.position.z + 2, transition_speed * 0.5).from(camera.position.z + 4)
	camera_tween.tween_callback(_on_transition_done)

func _animate_out():
	is_transitioning = true
	if camera_tween and camera_tween.is_valid():
		camera_tween.kill()
	camera_tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	camera_tween.tween_property(camera, "position:z", camera.position.z + 4, transition_speed * 0.3)
	camera_tween.tween_callback(_remove_current_room)
	camera_tween.tween_callback(_on_transition_done)

func _remove_current_room():
	if current_room_node:
		current_room_node.queue_free()
		current_room_node = null

func _on_transition_done():
	is_transitioning = false
	transition_finished.emit()

func play_walk_animation():
	if not current_room_node:
		return
	var walk_tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	walk_tween.tween_property(camera, "position:z", camera.position.z - 1.5, 0.25)
	walk_tween.tween_property(camera, "position:z", camera.position.z, 0.35)

func play_turn_animation(direction: String):
	var dir = 1 if direction == "left" else -1
	var turn_tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	turn_tween.tween_property(camera, "rotation:y", 0.5 * dir, 0.25)
	turn_tween.tween_property(camera, "rotation:y", 0.0, 0.25)

func _apply_theme(room: Node3D, theme_name: String):
	var theme_colors = {
		"Dark Caverns": Color("#2a1a0a"),
		"Ancient Ruins": Color("#3a2a18"),
		"Crystal Caves": Color("#1a2a3a"),
		"Lava Tunnels": Color("#3a1a0a"),
		"Frozen Depths": Color("#1a2a3a"),
		"Abyssal Vaults": Color("#0a001a"),
	}
	var color = theme_colors.get(theme_name, Color("#1a0f0a"))
	var env = get_node_or_null("/root/GameWorld/World3D/WorldEnvironment")
	if env and env.environment:
		env.environment.ambient_light_color = color
		env.environment.fog_light_color = color
