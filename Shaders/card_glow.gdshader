shader_type canvas_item;

uniform int card_type : hint_range(0, 5) = 0;
uniform float glow_intensity : hint_range(0.0, 1.0) = 0.4;
uniform float shimmer_speed : hint_range(0.0, 5.0) = 1.2;
uniform float time : hint_range(0.0, 100.0) = 0.0;
uniform float parchment_roughness : hint_range(0.0, 0.15) = 0.04;
uniform float burn_darkness : hint_range(0.0, 0.3) = 0.08;

const vec4 ATTACK  = vec4(0.725, 0.110, 0.110, 1.0);
const vec4 SKILL   = vec4(0.110, 0.659, 0.298, 1.0);
const vec4 DEFENSE = vec4(0.110, 0.298, 0.659, 1.0);
const vec4 MAGIC   = vec4(0.549, 0.110, 0.659, 1.0);
const vec4 GOLD    = vec4(0.788, 0.659, 0.298, 1.0);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

vec4 get_theme_color() {
	if (card_type == 1) return SKILL;
	if (card_type == 2) return DEFENSE;
	if (card_type == 3) return MAGIC;
	if (card_type == 4) return GOLD;
	return ATTACK;
}

void fragment() {
	vec4 base = COLOR;
	vec2 uv = UV;
	vec4 theme = get_theme_color();

	float age = noise(uv * 120.0) * burn_darkness;
	vec4 parchment_tint = vec4(vec3(0.92, 0.88, 0.78) * (1.0 - age), 1.0);
	vec4 dark_edge = vec4(vec3(0.15, 0.08, 0.04), 1.0);

	float shimmer = sin(uv.y * 20.0 + uv.x * 10.0 + time * shimmer_speed) * 0.5 + 0.5;
	shimmer *= sin(uv.x * 15.0 - time * shimmer_speed * 0.7) * 0.5 + 0.5;
	shimmer = pow(shimmer, 2.0) * glow_intensity;
	vec4 glow = theme * shimmer;

	vec4 theme_tint = theme * 0.06 * glow_intensity;
	vec4 card_tint = base * parchment_tint + theme_tint;

	float edge_dist = min(min(uv.x, uv.y), min(1.0 - uv.x, 1.0 - uv.y));
	float edge_burn = smoothstep(0.01, 0.08, edge_dist);

	vec4 final_color = mix(dark_edge, card_tint, edge_burn) + glow;
	final_color.a = base.a;
	COLOR = final_color;
}
