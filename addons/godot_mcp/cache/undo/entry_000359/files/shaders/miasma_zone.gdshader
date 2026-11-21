shader_type canvas_item;

uniform vec2 center = vec2(0.0);
uniform float radius = 288.0;
uniform float time = 0.0;
uniform float jag = 10.0;
uniform float edge = 1.0;
uniform float pixel_size = 1.0;
uniform vec4 tint : source_color = vec4(0.55, 0.48, 0.16, 0.42);
uniform vec4 ring_color : source_color = vec4(1.0, 0.78, 0.38, 0.85);
uniform float ring_width = 2.5;
uniform sampler2D fog_noise : repeat_enable, filter_linear;
uniform float fog_size = 420.0;
uniform float fog_strength = 0.8;
uniform float edge_glow = 0.6;
uniform float edge_falloff = 18.0;

varying vec2 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

float tri(float x) {
	return 1.0 - 4.0 * abs(fract(x) - 0.5);
}

float jag_wave(float angle) {
	float u = angle / TAU;
	return 0.55 * tri(u * 14.0 + time * 0.05) + 0.3 * tri(u * 23.0 - time * 0.08) + 0.15 * tri(u * 37.0 + time * 0.13);
}

void fragment() {
	vec2 p = world_pos;
	if (pixel_size > 0.0) {
		p = (floor(p / pixel_size) + 0.5) * pixel_size;
	}
	vec2 rel = p - center;
	float d = length(rel);
	float amount = min(jag, radius * 0.25);
	float r = radius + amount * jag_wave(atan(rel.y, rel.x));
	float outside = smoothstep(r - edge, r, d);
	float lit = step(1.0, radius);
	float ring = (1.0 - smoothstep(ring_width * 0.5, ring_width * 0.5 + 1.0, abs(d - r))) * lit;
	vec4 haze = vec4(0.0);
	if (outside > 0.0) {
		float n = texture(fog_noise, p / fog_size + vec2(time * 0.012, time * 0.007)).r;
		float n2 = texture(fog_noise, p / (fog_size * 0.6) - vec2(time * 0.009, -time * 0.015)).r;
		float fog = (n + n2) * 0.5;
		float wall = 1.0 + edge_glow * exp(-max(d - r, 0.0) / edge_falloff) * lit;
		float alpha = tint.a * outside * mix(1.0, 0.4 + 1.2 * fog, fog_strength) * wall;
		haze = vec4(mix(tint.rgb * 0.7, tint.rgb * 1.2, fog), clamp(alpha, 0.0, 0.9));
	}
	COLOR = mix(haze, ring_color, ring);
}
