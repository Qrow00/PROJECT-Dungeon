shader_type canvas_item;

uniform float time : hint_range(0.0, 100.0) = 0.0;
uniform float speed : hint_range(0.0, 5.0) = 0.8;
uniform float intensity : hint_range(0.0, 1.0) = 0.3;

void fragment() {
	vec4 base = COLOR;
	vec2 uv = UV;

	float sweep = sin((uv.x + uv.y * 0.3) * 8.0 + time * speed) * 0.5 + 0.5;
	sweep *= sin((uv.x * 0.7 - uv.y) * 6.0 + time * speed * 0.6) * 0.5 + 0.5;
	sweep = pow(sweep, 3.0) * intensity;
	vec4 gleam = vec4(0.788, 0.659, 0.298, 1.0) * sweep;
	vec4 result = base + gleam;
	result.a = base.a;
	COLOR = result;
}
