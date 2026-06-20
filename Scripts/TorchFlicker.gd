extends StaticBody3D

var flicker_time: float = 0.0
var light_node: OmniLight3D
var base_energy: float = 1.0

func _ready():
	for child in get_children():
		if child is OmniLight3D:
			light_node = child
			base_energy = light_node.light_energy
			break

func _process(delta):
	if not light_node:
		return
	flicker_time += delta
	var f = 0.85 + 0.15 * sin(flicker_time * 5.0)
	f *= 0.9 + 0.1 * sin(flicker_time * 7.3 + 1.2)
	f *= 0.95 + 0.05 * sin(flicker_time * 11.0 + 3.7)
	light_node.light_energy = base_energy * f
