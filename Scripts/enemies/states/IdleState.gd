extends State

var idle_timer: float = 0.0

func enter():
	idle_timer = randf_range(2.0, 5.0)
	if enemy and enemy.anim_tree:
		enemy.anim_tree.set("parameters/state/transition_request", "idle")

func update(delta):
	idle_timer -= delta
	if idle_timer <= 0:
		state_machine.change_state("patrol")
		return
	if enemy and enemy.detection_zone:
		var bodies = enemy.detection_zone.get_overlapping_bodies()
		for body in bodies:
			if body.is_in_group("player"):
				state_machine.change_state("chase")
				return
