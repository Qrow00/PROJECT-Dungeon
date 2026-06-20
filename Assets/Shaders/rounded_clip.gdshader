shader_type canvas_item;

uniform vec2 node_size = vec2(120.0, 170.0);
uniform float corner_radius : hint_range(0.0, 50.0) = 8.0;

void fragment() {
	vec2 coord = UV * node_size;
	vec2 half_node = node_size * 0.5;
	vec2 center = abs(coord - half_node);
	vec2 corner_max = half_node - corner_radius;
	vec2 corner_dist = max(center - corner_max, 0.0);
	float dist = length(corner_dist);
	COLOR.a *= 1.0 - smoothstep(corner_radius - 1.0, corner_radius, dist);
}
