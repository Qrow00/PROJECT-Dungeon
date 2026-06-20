extends State

func enter():
	if not enemy:
		return
	if enemy.anim_tree:
		enemy.anim_tree.set("parameters/state/transition_request", "death")
	enemy.set_collision_layer_value(3, false)
	enemy.set_collision_mask_value(1, false)
	enemy.set_collision_mask_value(2, false)
	if enemy.destroy_timer:
		enemy.destroy_timer.start()

func update(delta):
	pass
