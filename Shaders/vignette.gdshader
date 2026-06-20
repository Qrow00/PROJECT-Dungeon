shader_type canvas_item;

uniform float intensity : hint_range(0.0, 1.0) = 0.6;
uniform float darkness : hint_range(0.0, 0.8) = 0.4;

void fragment() {
	vec2 center = UV - 0.5;
	float dist = length(center);
	float dark = smoothstep(0.15, 0.75, dist) * darkness * intensity;
	COLOR = vec4(0.0, 0.0, 0.0, dark);
}
