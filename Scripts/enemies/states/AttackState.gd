extends State

var attack_cooldown: float = 0.0

func enter():
	if not enemy:
		return
	if enemy.anim_tree:
		enemy.anim_tree.set("parameters/state/transition_request", "attack")
	attack_cooldown = enemy.attack_speed

func update(delta):
	attack_cooldown -= delta
	if attack_cooldown <= 0:
		if enemy:
			enemy.deal_damage.emit(enemy.damage)
		var target_body = _find_target()
		if target_body and enemy and enemy.global_position.distance_to(target_body.global_position) < enemy.attack_range:
			attack_cooldown = enemy.attack_speed
		else:
			state_machine.change_state("return")

func _find_target():
	if not enemy or not enemy.detection_zone:
		return null
	var bodies = enemy.detection_zone.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("player"):
			return body
	return null
