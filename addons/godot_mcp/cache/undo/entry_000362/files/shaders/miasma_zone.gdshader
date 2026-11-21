shader_type canvas_item;

uniform vec2 center = vec2(0.0);
uniform float radius = 288.0;
uniform float time = 0.0;
uniform float jag = 16.0;
uniform float blend = 16.0;
uniform float pixel_size = 1.0;
uniform vec4 tint : source_color = vec4(0.55, 0.48, 0.16, 0.42);
uniform sampler2D fog_noise : repeat_enable, filter_linear;
uniform float fog_size = 420.0;
uniform float fog_strength = 0.8;
uniform float edge_glow = 0.6;
uniform float edge_falloff = 18.0;
uniform float wind_angle = 0.3;
uniform float wind_sway = 0.35;
uniform float wind_speed = 40.0;
uniform float smear = 28.0;
uniform float streak_length = 520.0;
uniform float streak_width = 36.0;
uniform float streak_shine = 0.3;

varying vec2 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

float tri(float x) {
	return 1.0 - 4.0 * abs(fract(x) - 0.5);
}

float jag_wave(float angle) {
	float u = angle / TAU;
	return 0.45 * tri(u * 11.0 + time * 0.04) + 0.35 * tri(u * 31.0 - time * 0.07) + 0.2 * tri(u * 67.0 + time * 0.11);
}

void fragment() {
	vec2 p = world_pos;
	if (pixel_size > 0.0) {
		p = (floor(p / pixel_size) + 0.5) * pixel_size;
	}
	float angle = wind_angle + wind_sway * sin(time * 0.07);
	vec2 wind = vec2(cos(angle), sin(angle));
	vec2 side = vec2(-wind.y, wind.x);
	float along = dot(p, wind);
	float across = dot(p, side);
	float s1 = texture(fog_noise, vec2((along - time * wind_speed) / streak_length, across / streak_width)).r;
	float s2 = texture(fog_noise, vec2((along - time * wind_speed * 1.6) / (streak_length * 0.5), across / (streak_width * 0.55) + 0.37)).r;
	float streak = smoothstep(0.25, 0.75, s1 * 0.65 + s2 * 0.35);
	vec2 q = p - wind * smear * (streak * 2.0 - 1.0);
	vec2 rel = q - center;
	float d = length(rel);
	float amount = min(jag, radius * 0.25);
	float r = radius + amount * jag_wave(atan(rel.y, rel.x));
	float lit = step(1.0, radius);
	float outside = mix(1.0, smoothstep(r - blend, r + blend, d), lit);
	vec4 haze = vec4(0.0);
	if (outside > 0.0) {
		float n = texture(fog_noise, (p - wind * time * wind_speed * 0.3) / fog_size).r;
		float n2 = texture(fog_noise, (p - wind * time * wind_speed * 0.5) / (fog_size * 0.6) + vec2(0.5)).r;
		float fog = (n + n2) * 0.5;
		float wall = 1.0 + edge_glow * exp(-max(d - r, 0.0) / edge_falloff) * lit;
		float alpha = tint.a * outside * mix(1.0, 0.4 + 1.2 * fog, fog_strength) * wall;
		vec3 color = mix(tint.rgb * 0.7, tint.rgb * 1.2, fog);
		color = mix(color, tint.rgb * 1.5, streak * streak_shine);
		haze = vec4(color, clamp(alpha, 0.0, 0.9));
	}
	COLOR = haze;
}
