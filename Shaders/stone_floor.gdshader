shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled;

uniform sampler2D albedo_texture : source_color;
uniform vec4 floor_color : source_color = vec4(0.4, 0.32, 0.28, 1.0);
uniform vec2 texture_scale = vec2(1.0);
uniform float rows = 4.0;
uniform float columns = 8.0;

void fragment() {
	vec2 uv = UV * vec2(rows, columns);
	vec4 tex = texture(albedo_texture, uv);
	float lum = dot(tex.rgb, vec3(0.299, 0.587, 0.114));
	ALBEDO = floor_color.rgb * lum * 2.0;
	ROUGHNESS = 1.0;
}
