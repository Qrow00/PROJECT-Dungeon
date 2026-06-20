shader_type spatial;
render_mode blend_mix, unshaded, cull_disabled;

uniform vec4 core_color : source_color = vec4(1.0, 0.85, 0.4, 1.0);
uniform vec4 mid_color : source_color = vec4(1.0, 0.55, 0.1, 1.0);
uniform vec4 edge_color : source_color = vec4(0.7, 0.15, 0.02, 1.0);
uniform float flicker_speed = 4.0;

void fragment() {
	vec2 center = UV - vec2(0.5);
	float dist = length(center);
	float edge = 1.0 - smoothstep(0.0, 0.5, dist);

	float flicker = 0.75 + 0.25 * sin(TIME * flicker_speed + UV.y * 20.0);
	flicker *= 0.85 + 0.15 * sin(TIME * flicker_speed * 1.7 + UV.x * 15.0 + 1.3);

	float height_fade = 1.0 - UV.y;
	height_fade = clamp(height_fade * 2.0, 0.0, 1.0);

	vec3 col = mix(edge_color.rgb, mid_color.rgb, edge);
	col = mix(col, core_color.rgb, height_fade);
	col *= flicker;

	ALBEDO = col;
	EMISSION = col * 1.5;
	ALPHA = edge * 0.9;
}
