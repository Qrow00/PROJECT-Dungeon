extends State

func enter():
	if not enemy:
		return
	if enemy.anim_tree:
		enemy.anim_tree.set("parameters/state/transition_request", "run")
	enemy.aggro = true

func update(delta):
	if not enemy or not enemy.nav_agent:
		return
	var target_body = _find_target()
	if not target_body:
		state_machine.change_state("return")
		return
	enemy.nav_agent.target_position = target_body.global_position
	var dist = enemy.global_position.distance_to(target_body.global_position)
	if dist < enemy.attack_range:
		state_machine.change_state("attack")

func _find_target():
	if not enemy or not enemy.detection_zone:
		return null
	var bodies = enemy.detection_zone.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("player"):
			return body
	return null
