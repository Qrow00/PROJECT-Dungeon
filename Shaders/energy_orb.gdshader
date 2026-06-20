shader_type canvas_item;

uniform float time : hint_range(0.0, 100.0) = 0.0;
uniform float pulse_speed : hint_range(0.0, 5.0) = 2.0;
uniform vec3 orb_color : source_color = vec3(0.549, 0.110, 0.659);

void fragment() {
	vec2 uv = UV - 0.5;
	float dist = length(uv);
	float pulse = sin(time * pulse_speed) * 0.5 + 0.5;

	float glow = exp(-dist * 4.0) * (0.6 + pulse * 0.4);
	float core = exp(-dist * 12.0) * 0.8;

	vec3 col = orb_color * (glow + core);
	float alpha = clamp(glow + core, 0.0, 1.0);

	vec4 base = COLOR;
	vec3 result = mix(base.rgb, col, alpha * 0.8);
	COLOR = vec4(result, base.a);
}
