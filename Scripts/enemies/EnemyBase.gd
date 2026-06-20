class_name EnemyBase
extends CharacterBody3D

signal dealt_damage(amount: int)
signal died(enemy: EnemyBase)

@export var enemy_data: MonsterData
@export var walk_speed: float = 2.0
@export var run_speed: float = 4.0
@export var attack_range: float = 2.0
@export var attack_speed: float = 1.5
@export var damage: int = 5
@export var patrol_points: Array[Vector3] = []
@export var hp: int = 10
@export var max_hp: int = 10

var nav_agent: NavigationAgent3D
var anim_tree: AnimationTree
var anim_player: AnimationPlayer
var spawn_position: Vector3
var aggro: bool = false

@onready var detection_zone: Area3D = $DetectionZone
@onready var destroy_timer: Timer = $DestroyTimer

func _ready():
	add_to_group("enemy")
	spawn_position = global_position
	nav_agent = $NavigationAgent3D as NavigationAgent3D
	anim_tree = $AnimationTree as AnimationTree
	anim_player = $AnimationPlayer as AnimationPlayer
	if enemy_data:
		hp = enemy_data.hp
		max_hp = enemy_data.max_hp
		damage = enemy_data.roll_damage()

func _physics_process(delta):
	if not nav_agent or nav_agent.is_navigation_finished():
		velocity.x = move_toward(velocity.x, 0, 5.0 * delta)
		velocity.z = move_toward(velocity.z, 0, 5.0 * delta)
		move_and_slide()
		return
	var next_pos = nav_agent.get_next_path_position()
	var dir = (next_pos - global_position).normalized()
	var speed = run_speed if aggro else walk_speed
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	velocity.y -= 9.8 * delta
	if dir.length() > 0:
		look_at(global_position + dir, Vector3.UP, true)
	move_and_slide()

func take_damage(amount: int) -> int:
	hp -= amount
	if hp <= 0:
		die()
	return amount

func die():
	$StateMachine.change_state("death")
	died.emit(self)
	await destroy_timer.timeout
	queue_free()

func play_hit_reaction():
	if anim_tree:
		anim_tree.set("parameters/hit/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
