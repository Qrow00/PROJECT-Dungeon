shader_type canvas_item;

uniform float flicker_speed : hint_range(0.0, 10.0) = 2.5;
uniform float flicker_strength : hint_range(0.0, 0.5) = 0.12;
uniform float time : hint_range(0.0, 100.0) = 0.0;
uniform vec4 warm_tint : source_color = vec4(0.95, 0.85, 0.7, 1.0);
uniform float tint_strength : hint_range(0.0, 1.0) = 0.15;

void fragment() {
	float flicker = 1.0 + sin(time * flicker_speed + UV.x * 50.0) * flicker_strength;
	flicker *= 1.0 + sin(time * flicker_speed * 1.3 + UV.y * 40.0) * flicker_strength * 0.5;
	flicker *= 1.0 + sin(time * flicker_speed * 2.1 + UV.x * 30.0 - UV.y * 20.0) * flicker_strength * 0.3;
	vec4 base = COLOR;
	vec4 tinted = mix(base, base * warm_tint, tint_strength);
	COLOR = tinted * vec4(vec3(flicker), 1.0);
}
