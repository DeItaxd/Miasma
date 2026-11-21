shader_type canvas_item;

uniform sampler2D noise_tex : repeat_enable, filter_linear;
uniform float pixel_size = 1.0;
uniform vec4 dirt_dark : source_color = vec4(0.15, 0.135, 0.09, 1.0);
uniform vec4 dirt_light : source_color = vec4(0.24, 0.215, 0.14, 1.0);
uniform vec4 grass_dark : source_color = vec4(0.12, 0.19, 0.085, 1.0);
uniform vec4 grass_light : source_color = vec4(0.21, 0.31, 0.12, 1.0);
uniform vec4 mud_color : source_color = vec4(0.11, 0.09, 0.06, 1.0);
uniform vec4 puddle_color : source_color = vec4(0.12, 0.125, 0.115, 1.0);
uniform vec4 puddle_shine : source_color = vec4(0.26, 0.29, 0.27, 1.0);
uniform vec4 stone_color : source_color = vec4(0.34, 0.32, 0.27, 1.0);
uniform vec4 twig_color : source_color = vec4(0.33, 0.25, 0.16, 1.0);
uniform vec4 bone_color : source_color = vec4(0.52, 0.48, 0.42, 1.0);
uniform float grass_level = 0.47;
uniform float mud_level = 0.57;
uniform float puddle_level = 0.71;
uniform float debris_cell = 22.0;
uniform float pebble_chance = 0.16;
uniform float twig_chance = 0.1;
uniform float bone_chance = 0.02;
uniform float tuft_chance = 0.18;
uniform float wall_texture = 0.3;

varying vec2 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float seg_dist(vec2 p, vec2 a, vec2 b) {
	vec2 pa = p - a;
	vec2 ba = b - a;
	float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
	return length(pa - ba * h);
}

vec3 debris(vec2 p, vec3 col) {
	vec2 cell = floor(p / debris_cell);
	vec2 local = p - cell * debris_cell;
	float pick = hash(cell + 0.13);
	if (pick < pebble_chance) {
		float r = 1.5 + 2.0 * hash(cell + 3.3);
		vec2 c = vec2(hash(cell + 1.7), hash(cell + 2.9)) * (debris_cell - 2.0 * r - 4.0) + r + 2.0;
		vec2 q = local - c;
		if (length(q * vec2(1.0, 1.3)) < r) {
			float top = step(q.y, -r * 0.25);
			return stone_color.rgb * (0.8 + 0.35 * top) * (0.85 + 0.3 * hash(cell + 4.4));
		}
		if (length((q - vec2(0.6, 1.2)) * vec2(1.0, 1.3)) < r) {
			return col * 0.6;
		}
		return col;
	}
	pick -= pebble_chance;
	if (pick < twig_chance) {
		float len = 3.0 + 4.0 * hash(cell + 8.4);
		vec2 c = vec2(hash(cell + 5.1), hash(cell + 6.2)) * (debris_cell - 2.0 * len - 4.0) + len + 2.0;
		float ang = hash(cell + 7.3) * TAU;
		vec2 dir = vec2(cos(ang), sin(ang)) * len;
		if (seg_dist(local, c - dir, c + dir) < 0.7) {
			return twig_color.rgb * (0.8 + 0.4 * hash(floor(p)));
		}
		if (seg_dist(local - vec2(0.0, 1.0), c - dir, c + dir) < 0.7) {
			return col * 0.65;
		}
		return col;
	}
	pick -= twig_chance;
	if (pick < bone_chance) {
		float len = 2.5 + 1.5 * hash(cell + 9.1);
		vec2 c = vec2(hash(cell + 10.2), hash(cell + 11.3)) * (debris_cell - 12.0) + 6.0;
		float ang = hash(cell + 12.4) * TAU;
		vec2 dir = vec2(cos(ang), sin(ang)) * len;
		float shaft = seg_dist(local, c - dir, c + dir);
		float knobs = min(length(local - (c - dir)), length(local - (c + dir)));
		if (shaft < 0.7 || knobs < 1.3) {
			return bone_color.rgb;
		}
		if (seg_dist(local - vec2(0.0, 1.0), c - dir, c + dir) < 1.0) {
			return col * 0.65;
		}
		return col;
	}
	pick -= bone_chance;
	if (pick < tuft_chance) {
		float s = 0.8 + 0.6 * hash(cell + 13.5);
		vec2 base = vec2(hash(cell + 14.6), hash(cell + 15.7)) * (debris_cell - 12.0) + vec2(6.0, 9.0);
		float d = min(seg_dist(local, base, base + vec2(-2.5, -4.0) * s), min(seg_dist(local, base, base + vec2(0.0, -5.5) * s), seg_dist(local, base, base + vec2(2.5, -4.0) * s)));
		if (d < 0.6) {
			return grass_light.rgb * (1.0 + 0.25 * hash(cell + 16.8));
		}
	}
	return col;
}

void fragment() {
	vec2 p = world_pos;
	if (pixel_size > 0.0) {
		p = (floor(p / pixel_size) + 0.5) * pixel_size;
	}
	if (UV.x >= 0.6667) {
		float n = texture(noise_tex, p / 60.0 + vec2(0.4, 0.2)).r;
		COLOR.rgb *= 1.0 - wall_texture * 0.5 + wall_texture * n + 0.08 * (hash(p) - 0.5);
	} else {
		float big = texture(noise_tex, p / 700.0).r;
		float mid = texture(noise_tex, p / 180.0 + vec2(0.31, 0.77)).r;
		float fine = texture(noise_tex, p / 45.0 + vec2(0.63, 0.12)).r;
		float grain = hash(p);
		vec3 col = mix(dirt_dark.rgb, dirt_light.rgb, smoothstep(0.25, 0.75, mid * 0.7 + fine * 0.3));
		col *= 0.9 + 0.2 * grain;
		col = mix(col, dirt_light.rgb * 1.25, step(0.985, grain));
		col = mix(col, dirt_dark.rgb * 0.6, step(grain, 0.015));
		float wet = big * 0.75 + mid * 0.25;
		float mud = smoothstep(mud_level, mud_level + 0.06, wet);
		float growth = texture(noise_tex, p / 260.0 + vec2(0.71, 0.43)).r * 0.7 + fine * 0.3;
		float grass = smoothstep(grass_level, grass_level + 0.08, growth) * (1.0 - mud);
		float blade = hash(vec2(p.x, floor(p.y / 3.0)) + 0.5);
		vec3 turf = mix(grass_dark.rgb, grass_light.rgb, smoothstep(0.3, 0.8, mid)) * (0.85 + 0.3 * blade);
		turf = mix(turf, grass_light.rgb * 1.3, step(0.93, blade));
		col = mix(col, turf, grass);
		col = mix(col, mud_color.rgb * (0.9 + 0.2 * fine), mud);
		float puddle = step(puddle_level, wet);
		float rim = step(puddle_level - 0.015, wet) * (1.0 - puddle);
		col = mix(col, mud_color.rgb * 0.65, rim);
		if (puddle > 0.5) {
			float shine = smoothstep(0.45, 0.85, texture(noise_tex, p / 140.0 + vec2(0.2, 0.9)).r);
			col = mix(puddle_color.rgb, puddle_shine.rgb, shine * 0.35);
		} else {
			col = debris(p, col);
		}
		COLOR = vec4(col, 1.0);
	}
}
