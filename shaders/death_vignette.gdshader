shader_type canvas_item;

uniform vec2 center = vec2(0.5, 0.5);
uniform float radius = 2.0;
uniform float softness = 0.35;
uniform float aspect = 1.7778;
uniform float raggedness = 0.08;
uniform float grain = 0.04;
uniform vec4 tint : source_color = vec4(0.0, 0.0, 0.0, 1.0);

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

void fragment() {
	vec2 p = (UV - center) * vec2(aspect, 1.0);
	float d = length(p);
	vec2 dir = p / max(d, 0.0001);
	float edge = noise(dir * 2.5 + vec2(d * 3.0 - TIME * 0.25, TIME * 0.1)) * 0.7 + noise(dir * 9.0 + d * 5.0) * 0.3;
	float speck = noise(UV * vec2(aspect, 1.0) * 220.0);
	d += (edge - 0.5) * raggedness * 2.0 + (speck - 0.5) * grain;
	float a = smoothstep(radius - softness, radius, d);
	COLOR = vec4(tint.rgb, tint.a * a);
}
