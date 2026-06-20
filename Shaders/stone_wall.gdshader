shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled;

uniform sampler2D albedo_texture : source_color;
uniform vec4 stone_color : source_color = vec4(0.5, 0.38, 0.28, 1.0);
uniform vec2 texture_scale = vec2(1.0);
uniform float rows = 20.0;
uniform float columns = 6.0;

void fragment() {
	vec2 uv = UV * vec2(rows, columns);
	vec4 tex = texture(albedo_texture, uv);
	float lum = dot(tex.rgb, vec3(0.299, 0.587, 0.114));
	ALBEDO = stone_color.rgb * lum * 2.0;
	ROUGHNESS = 1.0;
}
