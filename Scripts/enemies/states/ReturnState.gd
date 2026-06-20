extends State

func enter():
	if not enemy:
		return
	if enemy.anim_tree:
		enemy.anim_tree.set("parameters/state/transition_request", "walk")
	if enemy.nav_agent:
		enemy.nav_agent.target_position = enemy.spawn_position
	enemy.aggro = false

func update(delta):
	if not enemy:
		return
	if enemy.detection_zone:
		var bodies = enemy.detection_zone.get_overlapping_bodies()
		for body in bodies:
			if body.is_in_group("player"):
				state_machine.change_state("chase")
				return
	if enemy.nav_agent and enemy.nav_agent.is_navigation_finished():
		state_machine.change_state("idle")
