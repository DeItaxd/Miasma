shader_type canvas_item;

uniform vec2 center = vec2(0.0);
uniform float radius = 288.0;
uniform float edge = 4.0;
uniform vec4 tint : source_color = vec4(0.55, 0.48, 0.16, 0.42);
uniform vec4 ring_color : source_color = vec4(1.0, 0.78, 0.38, 0.85);
uniform float ring_width = 3.0;

varying vec2 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	float d = distance(world_pos, center);
	float outside = smoothstep(radius - edge, radius, d);
	float ring = (1.0 - smoothstep(ring_width * 0.5, ring_width * 0.5 + 1.0, abs(d - radius))) * step(1.0, radius);
	COLOR = mix(vec4(tint.rgb, tint.a * outside), ring_color, ring);
}
