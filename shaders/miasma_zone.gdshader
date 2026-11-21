shader_type canvas_item;

uniform vec2 center = vec2(0.0);
uniform float radius = 288.0;
uniform float time = 0.0;
uniform float jag = 16.0;
uniform float blend = 16.0;
uniform float pixel_size = 0.0;
uniform vec4 tint : source_color = vec4(0.55, 0.48, 0.16, 0.42);
uniform sampler2D fog_noise : repeat_enable, filter_linear;
uniform float fog_size = 420.0;
uniform float fog_strength = 0.8;
uniform float edge_glow = 0.6;
uniform float edge_falloff = 18.0;
uniform float wind_angle = 0.3;
uniform float wind_sway = 0.35;
uniform float wind_speed = 40.0;
uniform vec4 line_color : source_color = vec4(1.0, 1.0, 1.0, 0.55);
uniform float line_speed = 140.0;
uniform float line_width = 2.0;
uniform float line_spacing = 70.0;
uniform float line_cell = 600.0;
uniform float line_density = 0.6;
uniform float line_wiggle = 7.0;
uniform float line_wavelength = 90.0;

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

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float wind_line(vec2 p, vec2 wind, vec2 side) {
	float along = dot(p, wind) - time * line_speed;
	float across = dot(p, side);
	float lane = floor(across / line_spacing);
	float cell = floor(along / line_cell);
	vec2 id = vec2(lane, cell);
	if (hash(id + 3.1) > line_density) {
		return 0.0;
	}
	float len = 70.0 + 90.0 * hash(id + 1.7);
	float start = cell * line_cell + (line_cell - 170.0) * hash(id);
	float period = 3.0 + 4.0 * hash(id + 5.3);
	float t = fract((time + hash(id + 7.9) * period) / period) / 0.35;
	if (t > 1.0) {
		return 0.0;
	}
	float head = start + len * smoothstep(0.0, 0.6, t);
	float tail = start + len * smoothstep(0.4, 1.0, t);
	if (along < tail || along > head) {
		return 0.0;
	}
	float mid = (lane + 0.5) * line_spacing;
	float snake = mid + line_wiggle * sin(along * TAU / line_wavelength + hash(id + 9.4) * TAU + time * 1.5);
	float core = 1.0 - smoothstep(line_width * 0.5, line_width * 0.5 + 0.75, abs(across - snake));
	float k = (along - tail) / max(head - tail, 0.001);
	float taper = smoothstep(0.0, 0.25, k) * (1.0 - smoothstep(0.6, 1.0, k));
	return core * taper;
}

void fragment() {
	vec2 p = world_pos;
	if (pixel_size > 0.0) {
		p = (floor(p / pixel_size) + 0.5) * pixel_size;
	}
	float angle = wind_angle + wind_sway * sin(time * 0.07);
	vec2 wind = vec2(cos(angle), sin(angle));
	vec2 side = vec2(-wind.y, wind.x);
	vec2 rel = p - center;
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
		haze = vec4(mix(tint.rgb * 0.7, tint.rgb * 1.2, fog), clamp(alpha, 0.0, 0.9));
	}
	float line = wind_line(p, wind, side) * line_color.a;
	vec3 line_rgb = mix(line_color.rgb, tint.rgb * 1.8, outside * 0.35);
	float a = line + haze.a * (1.0 - line);
	vec3 rgb = a > 0.0 ? (line_rgb * line + haze.rgb * haze.a * (1.0 - line)) / a : vec3(0.0);
	COLOR = vec4(rgb, a);
}
