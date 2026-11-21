shader_type canvas_item;

uniform vec4 outline_color : source_color = vec4(1.0, 1.0, 1.0, 0.9);
uniform float width = 8.0;
uniform float pulse = 0.0;
uniform float pulse_speed = 7.0;

varying vec4 tint;

void vertex() {
	tint = COLOR;
	vec2 grow = 1.0 + 2.0 * width * TEXTURE_PIXEL_SIZE;
	VERTEX *= grow;
	UV = (UV - 0.5) * grow + 0.5;
}

float alpha_at(sampler2D tex, vec2 uv) {
	if (uv.x < 0.0 || uv.y < 0.0 || uv.x > 1.0 || uv.y > 1.0) {
		return 0.0;
	}
	return texture(tex, uv).a;
}

void fragment() {
	vec4 body = vec4(0.0);
	if (UV.x >= 0.0 && UV.y >= 0.0 && UV.x <= 1.0 && UV.y <= 1.0) {
		body = texture(TEXTURE, UV) * tint;
	}
	float around = 0.0;
	for (int i = 0; i < 12; i++) {
		vec2 dir = vec2(cos(float(i) * TAU / 12.0), sin(float(i) * TAU / 12.0));
		around = max(around, alpha_at(TEXTURE, UV + dir * width * TEXTURE_PIXEL_SIZE));
		around = max(around, alpha_at(TEXTURE, UV + dir * width * 0.5 * TEXTURE_PIXEL_SIZE));
	}
	float glow = mix(1.0, 0.5 + 0.5 * sin(TIME * pulse_speed), pulse);
	vec4 line = vec4(outline_color.rgb, outline_color.a * glow * around);
	COLOR = mix(line, body, body.a);
}
