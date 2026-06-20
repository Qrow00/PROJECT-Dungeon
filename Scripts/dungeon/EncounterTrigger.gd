# DEPRECATED for turn-based 3D. Encounters triggered by UI choices, not collision.
class_name EncounterTrigger
extends Area3D

signal encounter_started(room_node)

@export var room: Node3D

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node):
	if not room or room.cleared:
		return
	if body.is_in_group("player"):
		room.on_encounter_started()
		encounter_started.emit(room)
		set_deferred("monitoring", false)
