# DEPRECATED for turn-based 3D. Real-time interaction replaced by choice UI.
class_name InteractionSystem
extends Area3D

signal interacted(interactable: Node3D)

@export var interaction_range: float = 2.5
@export var prompt_text: String = "Press E to interact"

var nearby_interactables: Array[Node3D] = []

func _ready():
	collision_layer = 0
	collision_mask = 64
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)

func _process(_delta):
	if nearby_interactables.is_empty():
		return

	if Input.is_action_just_pressed("interact"):
		var closest = _get_closest_interactable()
		if closest:
			interacted.emit(closest)

func _on_body_entered(body: Node):
	if body.has_method("on_interact"):
		nearby_interactables.append(body)
		_show_prompt(body)

func _on_body_exited(body: Node):
	nearby_interactables.erase(body)
	_hide_prompt()

func _on_area_entered(area: Area3D):
	if area.has_method("on_interact"):
		nearby_interactables.append(area)
		_show_prompt(area)

func _on_area_exited(area: Area3D):
	nearby_interactables.erase(area)
	_hide_prompt()

func _get_closest_interactable() -> Node3D:
	var closest: Node3D = null
	var closest_dist: float = INF
	for n in nearby_interactables:
		if not is_instance_valid(n):
			continue
		var d = global_position.distance_to(n.global_position)
		if d < closest_dist:
			closest_dist = d
			closest = n
	return closest

func _show_prompt(_target: Node3D):
	var prompt = _get_prompt_label()
	if prompt:
		prompt.text = prompt_text
		prompt.show()

func _hide_prompt():
	var prompt = _get_prompt_label()
	if prompt:
		prompt.hide()

func _get_prompt_label() -> Label:
	var parent = get_parent()
	while parent:
		if parent has_method("get_node"):
			var label = parent.get_node_or_null("UILayer/InteractionPrompt")
			if label:
				return label
		parent = parent.get_parent()
	return null
