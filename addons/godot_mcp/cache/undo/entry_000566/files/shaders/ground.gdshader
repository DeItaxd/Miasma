shader_type canvas_item;

uniform sampler2D noise_tex : repeat_enable, filter_linear;
uniform sampler2D shape_tex : repeat_enable, filter_linear;
uniform vec4 dirt_color : source_color = vec4(0.255, 0.215, 0.145, 1.0);
uniform vec4 dirt_shade : source_color = vec4(0.19, 0.16, 0.105, 1.0);
uniform vec4 dirt_ink : source_color = vec4(0.075, 0.06, 0.04, 1.0);
uniform vec4 grass_base : source_color = vec4(0.125, 0.175, 0.075, 1.0);
uniform vec4 blade_dark : source_color = vec4(0.135, 0.2, 0.078, 1.0);
uniform vec4 blade_light : source_color = vec4(0.285, 0.375, 0.145, 1.0);
uniform vec4 blade_dry : source_color = vec4(0.35, 0.32, 0.165, 1.0);
uniform vec4 grass_ink : source_color = vec4(0.045, 0.07, 0.028, 1.0);
uniform vec4 mud_color : source_color = vec4(0.125, 0.1, 0.068, 1.0);
uniform vec4 puddle_color : source_color = vec4(0.135, 0.15, 0.13, 1.0);
uniform vec4 puddle_shine : source_color = vec4(0.4, 0.44, 0.38, 1.0);
uniform vec4 ink_color : source_color = vec4(0.045, 0.035, 0.025, 1.0);
uniform vec4 stone_color : source_color = vec4(0.42, 0.39, 0.34, 1.0);
uniform vec4 stone_shade : source_color = vec4(0.28, 0.26, 0.23, 1.0);
uniform vec4 twig_color : source_color = vec4(0.3, 0.22, 0.14, 1.0);
uniform vec4 bone_color : source_color = vec4(0.58, 0.54, 0.46, 1.0);
uniform vec4 wall_color : source_color = vec4(0.13, 0.12, 0.1, 1.0);
uniform float detail_line = 0.3;
uniform float wobble = 5.0;
uniform float fray = 7.0;
uniform float grass_low = 0.38;
uniform float grass_high = 0.62;
uniform float mud_low = 0.56;
uniform float mud_high = 0.74;
uniform float puddle_level = 0.79;
uniform float blade_cell = 2.8;
uniform float blade_length = 4.2;
uniform float dry_amount = 0.22;
uniform float hatch_spacing = 3.0;
uniform float hatch_strength = 0.4;
uniform float grime = 0.55;
uniform float stain_strength = 0.32;
uniform float speck_cell = 5.0;
uniform float speck_chance = 0.1;
uniform float clod_chance = 0.4;
uniform float debris_cell = 24.0;
uniform float pebble_chance = 0.16;
uniform float twig_chance = 0.1;
uniform float bone_chance = 0.025;
uniform float weed_chance = 0.14;

varying vec2 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float seg(vec2 p, vec2 a, vec2 b) {
	vec2 pa = p - a;
	vec2 ba = b - a;
	float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
	return length(pa - ba * h);
}

float blade(vec2 p, vec2 a, vec2 b, float w0, float w1) {
	vec2 pa = p - a;
	vec2 ba = b - a;
	float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
	return length(pa - ba * h) - mix(w0, w1, h);
}

float grad(float f) {
	return max(length(vec2(dFdx(f), dFdy(f))), 1e-6);
}

float iso_ink(float f, float level, float g, float width, float px) {
	float dist = abs(f - level) / g * px;
	return 1.0 - smoothstep(width - px * 0.7, width + px * 0.7, dist);
}

float fill(float d, float px) {
	return 1.0 - smoothstep(-px * 0.7, px * 0.7, d);
}

float ink(float d, float width, float px) {
	return 1.0 - smoothstep(width - px * 0.7, width + px * 0.7, abs(d));
}

float hatch(vec2 p, vec2 dir, float px) {
	vec2 nrm = vec2(-dir.y, dir.x);
	float u = dot(p, nrm);
	float v = dot(p, dir);
	float lane = floor(u / hatch_spacing);
	float local = u - (lane + 0.5) * hatch_spacing;
	float shift = hash(vec2(lane, 1.3)) * 10.0;
	float cell = floor((v + shift) / 10.0);
	float along = fract((v + shift) / 10.0);
	float on = step(0.4, hash(vec2(lane, cell)));
	float taper = smoothstep(0.0, 0.2, along) * (1.0 - smoothstep(0.55, 0.85, along));
	float width = 0.26 * taper;
	return on * (1.0 - smoothstep(width - px * 0.6, width + px * 0.6, abs(local)));
}

vec2 specks(vec2 p, float px) {
	vec2 cell = floor(p / speck_cell);
	if (hash(cell + 21.7) > speck_chance) {
		return vec2(0.0);
	}
	vec2 c = (cell + 0.2 + 0.6 * vec2(hash(cell + 3.1), hash(cell + 5.9))) * speck_cell;
	float r = 0.3 + 0.5 * hash(cell + 8.3);
	float d = length((p - c) / vec2(1.0, 0.75 + 0.5 * hash(cell + 2.2))) - r;
	return vec2(fill(d, px), step(0.72, hash(cell + 6.6)));
}

vec3 clods(vec2 p, vec3 col, float amount, float px) {
	vec2 cell = floor(p / 6.0);
	if (hash(cell + 31.3) > clod_chance * amount) {
		return col;
	}
	vec2 c = (cell + 0.25 + 0.5 * vec2(hash(cell + 7.7), hash(cell + 8.8))) * 6.0;
	float r = 0.7 + 1.1 * hash(cell + 9.9);
	vec2 q = (p - c) / vec2(1.0, 0.72);
	float d = length(q) - r;
	float sh = length((p - c - vec2(0.45, 0.65)) / vec2(1.0, 0.72)) - r;
	vec3 lump = col * (1.08 + 0.3 * hash(cell + 3.3));
	lump = mix(lump, lump * 0.72, smoothstep(-px, px, q.y + 0.15 * r));
	col = mix(col, col * 0.62, fill(sh, px));
	return mix(col, lump, fill(d, px));
}

vec3 blades(vec2 p, vec3 col, float density, float tone, float px) {
	if (density < 0.02) {
		return col;
	}
	vec2 home = floor(p / blade_cell);
	for (int y = 0; y <= 2; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 cell = home + vec2(float(x), float(y));
			float h = hash(cell + 0.71);
			if (h > density) {
				continue;
			}
			vec2 root = (cell + vec2(hash(cell + 1.9), hash(cell + 2.3))) * blade_cell;
			float len = blade_length * (0.6 + 0.75 * hash(cell + 4.1));
			float lean = (hash(cell + 3.7) - 0.5) * 1.3;
			vec2 bend = root + vec2(lean * 0.35, -0.55) * len;
			vec2 tip = root + vec2(lean, -1.0) * len;
			float d = min(blade(p, root, bend, 0.42, 0.26), blade(p, bend, tip, 0.26, 0.04));
			if (d > 0.5) {
				continue;
			}
			float t = clamp((root.y - p.y) / len, 0.0, 1.0);
			vec3 bc = mix(blade_dark.rgb, blade_light.rgb, t * 0.75 + 0.25 * hash(cell + 5.3));
			bc = mix(bc, blade_dry.rgb, step(1.0 - dry_amount, hash(cell + 6.1)) * 0.75);
			bc *= 0.72 + 0.56 * tone;
			col = mix(col, col * 0.7, fill(d - 0.3, px));
			col = mix(col, bc, fill(d, px));
		}
	}
	return col;
}

vec3 debris(vec2 p, vec3 col, float density, float px) {
	vec2 cell = floor(p / debris_cell);
	vec2 local = p - cell * debris_cell;
	float pick = hash(cell + 0.13);
	if (pick < pebble_chance) {
		float r = 1.6 + 2.4 * hash(cell + 3.3);
		vec2 c = vec2(hash(cell + 1.7), hash(cell + 2.9)) * (debris_cell - 2.0 * r - 6.0) + r + 3.0;
		vec2 q = (local - c) / vec2(1.0, 0.78);
		float d = length(q) - r;
		float sh = length((local - c - vec2(0.9, 1.2)) / vec2(1.0, 0.78)) - r;
		col = mix(col, col * 0.55, fill(sh, px) * 0.75);
		vec3 rock = mix(stone_shade.rgb, stone_color.rgb, smoothstep(px, -px, q.y + q.x * 0.35 + r * 0.1));
		rock *= 0.8 + 0.35 * hash(cell + 4.4);
		col = mix(col, rock, fill(d, px));
		return mix(col, ink_color.rgb, ink(d, detail_line, px));
	}
	pick -= pebble_chance;
	if (pick < twig_chance) {
		float len = 4.0 + 4.0 * hash(cell + 8.4);
		vec2 c = vec2(hash(cell + 5.1), hash(cell + 6.2)) * (debris_cell - 2.0 * len - 6.0) + len + 3.0;
		float ang = hash(cell + 7.3) * TAU;
		vec2 dir = vec2(cos(ang), sin(ang)) * len;
		vec2 fork = c + dir * 0.3;
		vec2 fork_end = fork + vec2(cos(ang + 0.7), sin(ang + 0.7)) * len * 0.45;
		float d = min(seg(local, c - dir, c + dir) - 0.9, seg(local, fork, fork_end) - 0.6);
		float sh = seg(local - vec2(0.7, 1.1), c - dir, c + dir) - 0.9;
		col = mix(col, col * 0.55, fill(sh, px) * 0.6);
		col = mix(col, twig_color.rgb, fill(d, px));
		return mix(col, ink_color.rgb, ink(d, detail_line * 0.85, px));
	}
	pick -= twig_chance;
	if (pick < bone_chance) {
		float len = 3.2 + 1.5 * hash(cell + 9.1);
		vec2 c = vec2(hash(cell + 10.2), hash(cell + 11.3)) * (debris_cell - 16.0) + 8.0;
		float ang = hash(cell + 12.4) * TAU;
		vec2 dir = vec2(cos(ang), sin(ang)) * len;
		vec2 side = vec2(-sin(ang), cos(ang)) * 0.9;
		vec2 a = c - dir;
		vec2 b = c + dir;
		float d = seg(local, a, b) - 0.85;
		d = min(d, min(length(local - a - side), length(local - a + side)) - 1.05);
		d = min(d, min(length(local - b - side), length(local - b + side)) - 1.05);
		float sh = seg(local - vec2(0.7, 1.1), a, b) - 1.4;
		col = mix(col, col * 0.55, fill(sh, px) * 0.6);
		col = mix(col, bone_color.rgb, fill(d, px));
		return mix(col, ink_color.rgb, ink(d, detail_line * 0.85, px));
	}
	pick -= bone_chance;
	if (pick < weed_chance && density < 0.35) {
		float s = 0.9 + 0.6 * hash(cell + 13.5);
		vec2 base = vec2(hash(cell + 14.6), hash(cell + 15.7)) * (debris_cell - 14.0) + vec2(7.0, 10.0);
		float bend = (hash(cell + 17.1) - 0.5) * 1.6;
		float d = blade(local, base, base + vec2(-3.0 + bend, -4.5) * s, 0.38, 0.04);
		d = min(d, blade(local, base, base + vec2(bend * 1.3, -6.5) * s, 0.38, 0.04));
		d = min(d, blade(local, base, base + vec2(3.0 + bend, -4.5) * s, 0.38, 0.04));
		return mix(col, grass_ink.rgb, fill(d, px));
	}
	return col;
}

void fragment() {
	vec2 p = world_pos;
	float px = max(length(vec2(dFdx(p.x), dFdy(p.x))), 1e-4);
	vec2 warp = vec2(texture(shape_tex, p / 45.0 + vec2(0.13, 0.57)).r, texture(shape_tex, p / 45.0 + vec2(0.71, 0.29)).r) - 0.5;
	vec2 frayed = vec2(texture(noise_tex, p / 22.0 + vec2(0.41, 0.93)).r, texture(noise_tex, p / 22.0 + vec2(0.83, 0.17)).r) - 0.5;
	vec2 calm = p + warp * wobble * 2.0;
	vec2 w = calm + frayed * fray;
	float fine = texture(noise_tex, p / 40.0 + vec2(0.63, 0.12)).r;
	float fine2 = texture(noise_tex, p / 14.0 + vec2(0.27, 0.48)).r;
	float rough = (fine - 0.5) * 0.7 + (fine2 - 0.5) * 0.3;
	float big = texture(shape_tex, w / 650.0).r;
	float mid = texture(shape_tex, w / 200.0 + vec2(0.31, 0.77)).r;
	float wet = big * 0.7 + mid * 0.3 + rough * 0.05;
	float pool = texture(shape_tex, calm / 650.0).r * 0.7 + texture(shape_tex, calm / 200.0 + vec2(0.31, 0.77)).r * 0.3;
	float ripple = texture(noise_tex, p / 70.0 + vec2(0.52, 0.38)).r;
	float growth = texture(shape_tex, w / 300.0 + vec2(0.71, 0.43)).r * 0.75 + texture(shape_tex, w / 110.0 + vec2(0.17, 0.83)).r * 0.25 + rough * 0.14;
	float shade_f = texture(shape_tex, w / 150.0 + vec2(0.53, 0.21)).r + rough * 0.25;
	float mottle = texture(noise_tex, p / 30.0 + vec2(0.11, 0.66)).r;
	float stain = smoothstep(0.5, 0.85, texture(noise_tex, p / 130.0 + vec2(0.81, 0.35)).r);
	float g_pool = grad(pool);
	float wall_tone = texture(noise_tex, p / 60.0 + vec2(0.4, 0.2)).r;
	float g_wall = grad(wall_tone);
	float wetness = smoothstep(mud_low, mud_high, wet);
	float puddle = smoothstep(puddle_level - g_pool, puddle_level + g_pool, pool);
	float rim = smoothstep(puddle_level - 0.05, puddle_level, pool) * (1.0 - puddle);
	float density = smoothstep(grass_low, grass_high, growth) * (1.0 - wetness * 0.85);
	float shade = smoothstep(0.42, 0.68, shade_f);
	float shine = iso_ink(pool, puddle_level + 0.03, g_pool, detail_line * 0.8, px) * smoothstep(0.6, 0.68, ripple) * puddle;
	float water_edge = iso_ink(pool, puddle_level, g_pool, 0.22, px);
	float hatch_a = hatch(p, vec2(0.7071, -0.7071), px);
	float hatch_b = hatch(p + vec2(17.0, 5.0), vec2(0.7071, 0.7071), px);
	vec2 speck = specks(p, px);
	if (UV.x >= 0.6667) {
		float split = smoothstep(0.5 - g_wall, 0.5 + g_wall, wall_tone);
		vec3 wall = wall_color.rgb * mix(0.85, 1.12, split) * (0.8 + 0.4 * mottle);
		wall = mix(wall, ink_color.rgb, max(hatch_a, hatch_b * (1.0 - split)) * 0.65);
		COLOR = vec4(wall, 1.0);
	} else {
		vec3 soil = mix(dirt_color.rgb, dirt_shade.rgb, shade);
		soil = clods(p, soil, 1.0 - wetness, px);
		soil = mix(soil, mud_color.rgb * (0.8 + 0.4 * mottle), wetness);
		vec3 col = mix(soil, grass_base.rgb * (0.75 + 0.5 * mottle), smoothstep(0.5, 0.95, density));
		col *= 1.0 - rim * 0.45;
		vec3 water = puddle_color.rgb * (0.85 + 0.3 * ripple) * (1.0 - 0.3 * smoothstep(puddle_level, puddle_level + 0.08, pool));
		col = mix(col, water, puddle);
		col = mix(col, ink_color.rgb, water_edge * 0.6);
		col = mix(col, puddle_shine.rgb, shine);
		if (puddle < 0.5) {
			if (wetness < 0.6) {
				col = debris(p, col, density, px);
			}
			col = blades(p, col, density, mottle, px);
		}
		float bare = (1.0 - density) * (1.0 - puddle);
		col = mix(col, dirt_ink.rgb, hatch_a * max(shade, stain) * bare * hatch_strength);
		col = mix(col, dirt_ink.rgb, hatch_b * wetness * (1.0 - puddle) * hatch_strength * 0.8);
		col *= mix(1.0, 0.7 + 0.6 * mottle, grime);
		col *= 1.0 - stain * stain_strength;
		col *= 0.88 + 0.12 * big;
		vec3 speck_col = mix(mix(dirt_ink.rgb, grass_ink.rgb, density), mix(dirt_color.rgb * 1.4, puddle_shine.rgb, wetness), speck.y);
		col = mix(col, speck_col, speck.x * (1.0 - puddle) * 0.85);
		COLOR = vec4(col, 1.0);
	}
}
