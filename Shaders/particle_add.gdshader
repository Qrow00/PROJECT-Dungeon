shader_type spatial;
render_mode blend_add, unshaded, cull_disabled;

void fragment() {
	ALBEDO = COLOR.rgb;
	EMISSION = COLOR.rgb * 2.0;
	ALPHA = COLOR.a;
}
