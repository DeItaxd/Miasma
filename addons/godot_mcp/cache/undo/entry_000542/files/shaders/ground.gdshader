shader_type canvas_item;

uniform sampler2D noise_tex : repeat_enable, filter_linear;
uniform sampler2D shape_tex : repeat_enable, filter_linear;
uniform vec4 dirt_color : source_color = vec4(0.235, 0.2, 0.135, 1.0);
uniform vec4 dirt_shade : source_color = vec4(0.18, 0.152, 0.1, 1.0);
uniform vec4 dirt_ink : source_color = vec4(0.085, 0.07, 0.045, 1.0);
uniform vec4 grass_color : source_color = vec4(0.2, 0.28, 0.12, 1.0);
uniform vec4 grass_shade : source_color = vec4(0.145, 0.21, 0.09, 1.0);
uniform vec4 grass_ink : source_color = vec4(0.055, 0.09, 0.035, 1.0);
uniform vec4 mud_color : source_color = vec4(0.13, 0.105, 0.07, 1.0);
uniform vec4 puddle_color : source_color = vec4(0.14, 0.155, 0.13, 1.0);
uniform vec4 puddle_shine : source_color = vec4(0.42, 0.46, 0.4, 1.0);
uniform vec4 ink_color : source_color = vec4(0.05, 0.04, 0.03, 1.0);
uniform vec4 stone_color : source_color = vec4(0.45, 0.42, 0.37, 1.0);
uniform vec4 stone_shade : source_color = vec4(0.31, 0.29, 0.26, 1.0);
uniform vec4 twig_color : source_color = vec4(0.34, 0.25, 0.16, 1.0);
uniform vec4 bone_color : source_color = vec4(0.64, 0.6, 0.52, 1.0);
uniform vec4 wall_color : source_color = vec4(0.14, 0.13, 0.11, 1.0);
uniform float patch_line = 0.42;
uniform float detail_line = 0.3;
uniform float sketchiness = 0.8;
uniform float roughness = 0.07;
uniform float wobble = 3.5;
uniform float grass_level = 0.47;
uniform float mud_level = 0.66;
uniform float puddle_level = 0.77;
uniform float shade_level = 0.55;
uniform float hatch_spacing = 3.0;
uniform float hatch_strength = 0.45;
uniform float grime = 0.4;
uniform float stain_strength = 0.3;
uniform float speck_cell = 5.0;
uniform float speck_chance = 0.07;
uniform float debris_cell = 24.0;
uniform float pebble_chance = 0.15;
uniform float twig_chance = 0.1;
uniform float bone_chance = 0.025;
uniform float tuft_chance = 0.3;

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

vec3 debris(vec2 p, vec3 col, float grass, float px) {
	vec2 cell = floor(p / debris_cell);
	vec2 local = p - cell * debris_cell;
	float pick = hash(cell + 0.13);
	if (pick < pebble_chance) {
		float r = 1.6 + 2.4 * hash(cell + 3.3);
		vec2 c = vec2(hash(cell + 1.7), hash(cell + 2.9)) * (debris_cell - 2.0 * r - 6.0) + r + 3.0;
		vec2 q = (local - c) / vec2(1.0, 0.78);
		float d = length(q) - r;
		float sh = length((local - c - vec2(0.9, 1.2)) / vec2(1.0, 0.78)) - r;
		col = mix(col, col * 0.6, fill(sh, px) * 0.7);
		vec3 rock = mix(stone_shade.rgb, stone_color.rgb, smoothstep(px, -px, q.y + q.x * 0.35 + r * 0.1));
		rock *= 0.85 + 0.3 * hash(cell + 4.4);
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
		col = mix(col, col * 0.6, fill(sh, px) * 0.6);
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
		col = mix(col, col * 0.6, fill(sh, px) * 0.6);
		col = mix(col, bone_color.rgb, fill(d, px));
		return mix(col, ink_color.rgb, ink(d, detail_line * 0.85, px));
	}
	pick -= bone_chance;
	if (pick < tuft_chance) {
		if (grass < 0.5 && hash(cell + 18.2) > 0.35) {
			return col;
		}
		float s = 0.9 + 0.6 * hash(cell + 13.5);
		vec2 base = vec2(hash(cell + 14.6), hash(cell + 15.7)) * (debris_cell - 14.0) + vec2(7.0, 10.0);
		float bend = (hash(cell + 17.1) - 0.5) * 1.6;
		float d = blade(local, base, base + vec2(-3.0 + bend, -4.5) * s, 0.38, 0.04);
		d = min(d, blade(local, base, base + vec2(bend * 1.3, -6.5) * s, 0.38, 0.04));
		d = min(d, blade(local, base, base + vec2(3.0 + bend, -4.5) * s, 0.38, 0.04));
		return mix(col, mix(dirt_ink.rgb, grass_ink.rgb, grass), fill(d, px));
	}
	return col;
}

void fragment() {
	vec2 p = world_pos;
	float px = max(length(vec2(dFdx(p.x), dFdy(p.x))), 1e-4);
	vec2 warp = vec2(texture(shape_tex, p / 45.0 + vec2(0.13, 0.57)).r, texture(shape_tex, p / 45.0 + vec2(0.71, 0.29)).r) - 0.5;
	vec2 w = p + warp * wobble * 2.0;
	float fine = texture(noise_tex, p / 40.0 + vec2(0.63, 0.12)).r;
	float fine2 = texture(noise_tex, p / 17.0 + vec2(0.27, 0.48)).r;
	float rough = (fine - 0.5) * 0.7 + (fine2 - 0.5) * 0.3;
	float big = texture(shape_tex, w / 650.0).r;
	float mid = texture(shape_tex, w / 200.0 + vec2(0.31, 0.77)).r;
	float wet = big * 0.7 + mid * 0.3 + rough * roughness * 0.7;
	float growth = texture(shape_tex, w / 300.0 + vec2(0.71, 0.43)).r * 0.75 + texture(shape_tex, w / 110.0 + vec2(0.17, 0.83)).r * 0.25 + rough * roughness;
	float shade_f = texture(shape_tex, w / 150.0 + vec2(0.53, 0.21)).r + rough * roughness * 1.6;
	float mottle = texture(noise_tex, p / 30.0 + vec2(0.11, 0.66)).r;
	float stain = smoothstep(0.52, 0.85, texture(noise_tex, p / 130.0 + vec2(0.81, 0.35)).r);
	float stroke = texture(noise_tex, p / 24.0 + vec2(0.37, 0.91)).r;
	float vary = mix(1.0, smoothstep(0.28, 0.6, stroke) * 1.45, sketchiness);
	float g_wet = grad(wet);
	float g_growth = grad(growth);
	float g_shade = grad(shade_f);
	float wall_tone = texture(noise_tex, p / 60.0 + vec2(0.4, 0.2)).r;
	float g_wall = grad(wall_tone);
	float mud = smoothstep(mud_level - g_wet, mud_level + g_wet, wet);
	float puddle = smoothstep(puddle_level - g_wet, puddle_level + g_wet, wet);
	float grass = smoothstep(grass_level - g_growth, grass_level + g_growth, growth) * (1.0 - mud);
	float shade = smoothstep(shade_level - g_shade, shade_level + g_shade, shade_f);
	float grass_edge = iso_ink(growth, grass_level, g_growth, patch_line * vary, px) * (1.0 - mud);
	float mud_edge = iso_ink(wet, mud_level, g_wet, patch_line * vary, px);
	float puddle_edge = iso_ink(wet, puddle_level, g_wet, patch_line * 1.15 * mix(1.0, vary, 0.5), px);
	float shine = iso_ink(wet, puddle_level + 0.035, g_wet, detail_line * 0.8, px) * smoothstep(0.58, 0.68, stroke) * puddle;
	float hatch_a = hatch(p, vec2(0.7071, -0.7071), px);
	float hatch_b = hatch(p + vec2(17.0, 5.0), vec2(0.7071, 0.7071), px);
	vec2 speck = specks(p, px);
	if (UV.x >= 0.6667) {
		float split = smoothstep(0.5 - g_wall, 0.5 + g_wall, wall_tone);
		vec3 wall = wall_color.rgb * mix(0.85, 1.12, split) * (0.85 + 0.3 * mottle);
		wall = mix(wall, ink_color.rgb, max(hatch_a, hatch_b * (1.0 - split)) * 0.65);
		COLOR = vec4(wall, 1.0);
	} else {
		vec3 col = mix(dirt_color.rgb, dirt_shade.rgb, shade);
		vec3 turf = mix(grass_color.rgb, grass_shade.rgb, shade);
		col = mix(col, turf, grass);
		col = mix(col, mud_color.rgb, mud);
		col *= mix(1.0, 0.76 + 0.48 * mottle, grime);
		col *= 1.0 - stain * stain_strength;
		float halo = smoothstep(mud_level - 0.1, mud_level, wet) * (1.0 - mud);
		col *= 1.0 - halo * 0.3;
		col = mix(col, puddle_color.rgb * (0.85 + 0.3 * mottle), puddle);
		vec3 hatch_ink = mix(dirt_ink.rgb, grass_ink.rgb, grass);
		col = mix(col, hatch_ink, hatch_a * max(shade, stain) * (1.0 - puddle) * hatch_strength);
		col = mix(col, dirt_ink.rgb, hatch_b * max(mud, halo) * (1.0 - puddle) * hatch_strength * 0.8);
		col = mix(col, grass_ink.rgb, grass_edge);
		col = mix(col, dirt_ink.rgb, mud_edge * (1.0 - puddle));
		col = mix(col, ink_color.rgb, puddle_edge);
		col = mix(col, puddle_shine.rgb, shine);
		vec3 speck_col = mix(hatch_ink, dirt_color.rgb * 1.45, speck.y);
		col = mix(col, speck_col, speck.x * (1.0 - puddle) * 0.85);
		if (puddle < 0.5 && mud < 0.5) {
			col = debris(p, col, grass, px);
		}
		COLOR = vec4(col, 1.0);
	}
}
