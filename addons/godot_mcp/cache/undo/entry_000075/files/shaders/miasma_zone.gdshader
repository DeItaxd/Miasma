shader_type canvas_item;

uniform vec2 center = vec2(0.0);
uniform float radius = 192.0;
uniform float edge = 4.0;
uniform vec4 tint : source_color = vec4(0.55, 0.48, 0.16, 0.42);

varying vec2 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	float outside = smoothstep(radius - edge, radius, distance(world_pos, center));
	COLOR = vec4(tint.rgb, tint.a * outside);
}
