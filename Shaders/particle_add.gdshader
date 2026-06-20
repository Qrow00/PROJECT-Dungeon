shader_type spatial;
render_mode blend_add, unshaded, cull_disabled;

void fragment() {
	float dist = distance(UV, vec2(0.5, 0.5));
	float mask = smoothstep(0.5, 0.2, dist);
	ALBEDO = COLOR.rgb;
	EMISSION = COLOR.rgb * 2.0;
	ALPHA = COLOR.a * mask;
}
