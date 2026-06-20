# DEPRECATED for turn-based 3D. Kept as reference for third-person controller implementation.
class_name PlayerController
extends CharacterBody3D

signal movement_locked_changed(locked: bool)

@export var walk_speed: float = 4.0
@export var run_speed: float = 7.0
@export var sprint_speed: float = 10.0
@export var acceleration: float = 10.0
@export var gravity: float = 9.8
@export var jump_velocity: float = 4.5

var current_speed: float = 0.0
var is_sprinting: bool = false
var is_attacking: bool = false
var movement_locked: bool = false

@onready var spring_arm: SpringArm3D = $SpringArm3D
@onready var camera: Camera3D = $SpringArm3D/Camera3D

func _ready():
	add_to_group("player")
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func set_movement_locked(locked: bool):
	movement_locked = locked
	movement_locked_changed.emit(locked)

func _input(event):
	if movement_locked:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * 0.003)
		spring_arm.rotation.x -= event.relative.y * 0.003
		spring_arm.rotation.x = clamp(spring_arm.rotation.x, -0.5, 1.2)

func _physics_process(delta):
	if movement_locked:
		velocity.x = move_toward(velocity.x, 0, acceleration * delta)
		velocity.z = move_toward(velocity.z, 0, acceleration * delta)
		if not is_on_floor():
			velocity.y -= gravity * delta
		move_and_slide()
		return

	var move_input = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = (transform.basis * Vector3(move_input.x, 0, move_input.y)).normalized()

	if not is_on_floor():
		velocity.y -= gravity * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	is_sprinting = Input.is_action_pressed("sprint")
	var target_speed = sprint_speed if is_sprinting else (run_speed if move_input.length() > 0 else 0.0)

	if direction:
		velocity.x = move_toward(velocity.x, direction.x * target_speed, acceleration * delta)
		velocity.z = move_toward(velocity.z, direction.z * target_speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, acceleration * delta)
		velocity.z = move_toward(velocity.z, 0, acceleration * delta)

	move_and_slide()
