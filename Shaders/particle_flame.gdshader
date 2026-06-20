shader_type spatial;
render_mode blend_add, unshaded, cull_disabled;

uniform float flame_taper = 2.0;

void fragment() {
	float u = UV.x;
	float v = 1.0 - UV.y;
	float d = abs(u - 0.5) * 2.0;
	float taper = 1.0 - pow(v, flame_taper);
	float flame_mask = 1.0 - smoothstep(taper * 0.7, 0.5 + taper * 0.5, d);
	float wave = sin(v * 12.0 + TIME * 5.0) * 0.08 + sin(v * 20.0 + TIME * 3.0 + u * 8.0) * 0.04;
	float edge_jitter = v * (0.12 + 0.08 * sin(TIME * 4.0 + v * 15.0));
	flame_mask -= smoothstep(taper * 0.4 - edge_jitter, taper * 0.4 + edge_jitter + 0.3, d + wave);
	flame_mask = clamp(flame_mask, 0.0, 1.0);
	float core = 1.0 - smoothstep(0.0, 0.25 + v * 0.4, d);
	vec3 core_col = vec3(1.0, 0.9, 0.5);
	vec3 mid_col = vec3(1.0, 0.6, 0.15);
	vec3 edge_col = vec3(0.5, 0.08, 0.0);
	vec3 col = mix(edge_col, mid_col, core);
	col = mix(col, core_col, core * (1.0 - v));
	float pop = step(0.97, sin(u * 40.0 + v * 25.0 + TIME * 15.0)) * v * 0.4;
	col += pop;
	ALBEDO = col;
	EMISSION = col * 3.0;
	ALPHA = flame_mask * 0.85;
	ALPHA *= 0.85 + 0.15 * sin(TIME * 6.0 + v * 12.0);
}
