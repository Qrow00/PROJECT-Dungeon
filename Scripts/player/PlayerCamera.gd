# DEPRECATED for turn-based 3D. Free-camera WASD movement not used.
class_name PlayerCamera
extends Node

@export var target: Node3D
@export var mouse_sensitivity: float = 0.003
@export var zoom_min: float = 2.0
@export var zoom_max: float = 10.0
@export var zoom_speed: float = 0.5
@export var spring_arm: SpringArm3D

var current_zoom: float = 5.0
var first_person: bool = false

func _ready():
	if not spring_arm:
		spring_arm = target.get_node("SpringArm3D") as SpringArm3D
	if spring_arm:
		spring_arm.spring_length = current_zoom

func _input(event):
	if event is InputEventMouseMotion:
		target.rotate_y(-event.relative.x * mouse_sensitivity)
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			current_zoom = max(zoom_min, current_zoom - zoom_speed)
			if spring_arm:
				spring_arm.spring_length = current_zoom
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			current_zoom = min(zoom_max, current_zoom + zoom_speed)
			if spring_arm:
				spring_arm.spring_length = current_zoom
