shader_type canvas_item;

uniform vec2 size = vec2(90.0, 73.0);
uniform float seed = 0.0;
uniform sampler2D grime_tex : repeat_enable, filter_linear;
uniform vec4 leaf_light : source_color = vec4(0.3, 0.41, 0.16, 1.0);
uniform vec4 leaf_mid : source_color = vec4(0.21, 0.31, 0.11, 1.0);
uniform vec4 leaf_dark : source_color = vec4(0.13, 0.2, 0.075, 1.0);
uniform vec4 leaf_shine : source_color = vec4(0.45, 0.55, 0.29, 1.0);
uniform vec4 sick_tint : source_color = vec4(0.62, 0.58, 0.25, 1.0);
uniform vec4 bark_light : source_color = vec4(0.34, 0.25, 0.16, 1.0);
uniform vec4 bark_dark : source_color = vec4(0.21, 0.15, 0.1, 1.0);
uniform vec4 ink_color : source_color = vec4(0.04, 0.04, 0.03, 1.0);
uniform vec4 shadow_color : source_color = vec4(0.0, 0.0, 0.0, 0.35);
uniform float sickly = 0.3;
uniform float crown_height = 1.1;
uniform float spread = 0.85;
uniform float scallop = 0.09;
uniform float outline = 0.85;
uniform float inner_line = 0.45;
uniform vec4 blade_dark : source_color = vec4(0.135, 0.2, 0.078, 1.0);
uniform vec4 blade_light : source_color = vec4(0.285, 0.375, 0.145, 1.0);
uniform float grime = 0.6;
uniform float hatch_strength = 0.7;
uniform float weeds = 0.75;
uniform float ruggedness = 1.0;
uniform float leafiness = 0.07;
uniform float dry_brush = 0.45;

float rnd(float n) {
	return fract(sin(n * 12.9898 + seed * 78.233) * 43758.5453);
}

float cell_hash(vec2 c) {
	return fract(sin(dot(c, vec2(127.1, 311.7)) + seed * 3.7) * 43758.5453);
}

float ink(float d, float width, float aa) {
	return 1.0 - smoothstep(width - aa * 0.7, width + aa * 0.7, abs(d));
}

float cover(float d, float aa) {
	return 1.0 - smoothstep(-aa * 0.7, aa * 0.7, d);
}

vec4 over(vec4 under, vec3 rgb, float amount) {
	return vec4(mix(under.rgb, rgb, amount), mix(under.a, 1.0, amount));
}

float hatch(vec2 q, float px) {
	float u = (q.x + q.y) * 0.7071;
	float v = (q.x - q.y) * 0.7071;
	float lane = floor(u / 2.6);
	float local = u - (lane + 0.5) * 2.6;
	float on = step(0.3, cell_hash(vec2(lane, floor(v / 6.0))));
	return on * (1.0 - smoothstep(0.24 - px * 0.6, 0.24 + px * 0.6, abs(local)));
}

float blade(vec2 p, vec2 a, vec2 b, float w0, float w1) {
	vec2 pa = p - a;
	vec2 ba = b - a;
	float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
	return length(pa - ba * h) - mix(w0, w1, h);
}

float speck(vec2 q, float px) {
	vec2 cell = floor(q / 4.5);
	if (cell_hash(cell + 9.1) > 0.2) {
		return 0.0;
	}
	vec2 c = (cell + 0.25 + 0.5 * vec2(cell_hash(cell + 1.3), cell_hash(cell + 2.7))) * 4.5;
	float d = length(q - c) - (0.3 + 0.4 * cell_hash(cell + 4.1));
	return 1.0 - smoothstep(-px * 0.7, px * 0.7, d);
}

void fragment() {
	vec2 q = UV * size;
	float px = max(length(vec2(dFdx(q.x), dFdy(q.x))), 1e-4);
	float R = size.x / 3.2;
	float aa = px / R;
	vec2 base = vec2(size.x * 0.5, size.y * 0.86);
	vec2 p = (q - base) / R;
	float mottle = texture(grime_tex, q / 26.0 + vec2(seed * 0.137, seed * 0.071)).r;
	float stain = smoothstep(0.55, 0.8, texture(grime_tex, q / 70.0 + vec2(seed * 0.093, 0.4)).r);
	float edge_n = texture(grime_tex, q / 6.0 + vec2(seed * 0.31, 0.7)).r;
	float edge_n2 = texture(grime_tex, q / 2.2 + vec2(seed * 0.11, 0.2)).r;
	float ink_n = texture(grime_tex, q / 9.0 + vec2(seed * 0.17, 0.3)).r;
	float rough = ((edge_n - 0.5) * 0.09 + (edge_n2 - 0.5) * 0.04) * ruggedness;
	float dry = mix(1.0 - dry_brush, 1.0, smoothstep(0.3, 0.45, edge_n2));
	vec4 col = vec4(0.0);
	float sd = (length((p - vec2(0.2, 0.0)) / vec2(1.35, 0.38)) - 1.0) * 0.38;
	col = vec4(shadow_color.rgb, shadow_color.a * cover(sd, aa));
	float t = clamp(-p.y / crown_height, 0.0, 1.0);
	float tx = p.x - (rnd(1.0) - 0.5) * 0.25 * t;
	float tw = mix(0.24, 0.15, t) + 0.07 * smoothstep(-0.2, 0.06, p.y);
	float trunk_d = max(abs(tx) - tw, max(p.y - 0.06, -p.y - crown_height)) + rough * 0.7;
	float side = smoothstep(-aa, aa, tx + tw * 0.2);
	vec3 bark = mix(bark_light.rgb, bark_dark.rgb, side);
	bark *= mix(1.0, 0.7 + 0.6 * mottle, grime);
	float drip = texture(grime_tex, vec2(q.x / 3.0, q.y / 50.0) + vec2(seed * 0.21, seed * 0.05)).r;
	bark *= 1.0 - 0.4 * smoothstep(0.5, 0.75, drip);
	bark *= 1.0 - 0.3 * smoothstep(-0.5, 0.05, p.y);
	bark = mix(bark, ink_color.rgb, hatch(q, px) * side * hatch_strength);
	float groove = abs(tx - tw * 0.35 - 0.025 * sin(p.y * 17.0 + seed));
	bark = mix(bark, ink_color.rgb, ink(groove, inner_line * 0.6 / R, aa) * step(-crown_height * 0.8, p.y) * step(p.y, -0.08));
	col = over(col, bark, cover(trunk_d, aa));
	col = over(col, ink_color.rgb, ink(trunk_d, outline * (0.5 + 1.0 * ink_n) / R, aa) * step(-crown_height, p.y) * dry);
	vec2 crown = vec2((rnd(1.0) - 0.5) * 0.2, -crown_height);
	float front = -1000.0;
	vec2 best_c = vec2(0.0);
	float best_r = 1.0;
	float best_dist = 2.0;
	float best_i = 0.0;
	float union_d = 10.0;
	for (int i = 0; i < 13; i++) {
		float fi = float(i);
		vec2 c = crown + vec2(0.0, -0.1);
		float cr = 0.72;
		if (i > 0) {
			float a = fi / 12.0 * TAU + (rnd(fi + 2.0) - 0.5) * 0.5;
			float reach = 0.55 + rnd(fi + 9.0) * 0.4;
			c = crown + vec2(cos(a) * spread, sin(a) * 0.55) * reach;
			cr = 0.32 + rnd(fi + 15.0) * 0.22;
		}
		vec2 d = p - c;
		float ca = atan(d.y, d.x);
		float wobble = 1.0 + scallop * sin(ca * 7.0 + rnd(fi + 30.0) * TAU) + leafiness * (abs(sin(ca * 17.0 + rnd(fi + 33.0) * TAU)) - 0.6) * ruggedness;
		float edge = cr * wobble;
		float dist = length(d);
		union_d = min(union_d, dist - edge);
		if (dist < edge + aa && c.y > front) {
			front = c.y;
			best_c = c;
			best_r = edge;
			best_dist = dist;
			best_i = fi;
		}
	}
	vec2 n = (p - best_c) / best_r;
	float depth = (best_c.y - crown.y) * 0.35;
	float light = 0.52 + 0.33 * dot(n, vec2(-0.6, -0.8)) + 0.12 * (1.0 - length(n)) - depth + (mottle - 0.5) * 0.25;
	float gl = max(length(vec2(dFdx(light), dFdy(light))), 1e-5);
	vec3 leaf = mix(leaf_dark.rgb, leaf_mid.rgb, smoothstep(0.38 - gl, 0.38 + gl, light));
	leaf = mix(leaf, leaf_light.rgb, smoothstep(0.62 - gl, 0.62 + gl, light));
	float sick = step(1.0 - sickly, rnd(best_i + 40.0));
	leaf = mix(leaf, leaf * sick_tint.rgb * 2.0, sick * 0.5);
	leaf *= mix(1.0, 0.7 + 0.6 * mottle, grime);
	leaf *= 1.0 - stain * 0.35;
	leaf *= 1.0 - 0.25 * smoothstep(-0.1, 0.7, p.y - crown.y);
	float dark = 1.0 - smoothstep(0.4, 0.5, light);
	leaf = mix(leaf, ink_color.rgb, hatch(q, px) * dark * hatch_strength);
	float shine_on = step(0.35, rnd(best_i + 50.0)) * step(best_c.y, crown.y + 0.25);
	float arc_ang = atan(n.y, n.x);
	float arc = abs(length(n) - 0.62) * best_r;
	float arc_span = step(-2.75, arc_ang) * step(arc_ang, -1.75);
	leaf = mix(leaf, leaf_shine.rgb, ink(arc, inner_line * 0.7 / R, aa) * arc_span * shine_on * smoothstep(0.3, 0.55, mottle));
	float clump = best_dist - best_r;
	float under = smoothstep(-0.3, 0.2, n.y) * step(0.0, -union_d - outline * 0.5 / R);
	leaf = mix(leaf, ink_color.rgb, ink(clump, inner_line * (0.6 + 0.8 * mottle) / R, aa) * under);
	leaf = mix(leaf, ink_color.rgb, speck(q, px) * 0.8);
	float crown_ang = atan(p.y - crown.y, p.x - crown.x);
	float ow = outline * (0.75 + 0.5 * mottle) / R;
	col = over(col, leaf, cover(union_d, aa));
	col = over(col, ink_color.rgb, ink(union_d, ow, aa));
	float foot = base.y + 0.06 * R;
	float home = floor(q.x / 2.2);
	for (int i = -2; i <= 2; i++) {
		float cell = home + float(i);
		float h = cell_hash(vec2(cell, 77.0));
		if (h > weeds) {
			continue;
		}
		float rx = (cell + cell_hash(vec2(cell, 78.0))) * 2.2;
		if (abs(rx - base.x) > 0.55 * R) {
			continue;
		}
		vec2 root = vec2(rx, foot + 0.3 + 1.6 * cell_hash(vec2(cell, 79.0)));
		float len = 2.6 + 3.6 * cell_hash(vec2(cell, 80.0));
		float lean = (cell_hash(vec2(cell, 81.0)) - 0.5) * 1.4;
		vec2 bend = root + vec2(lean * 0.35, -0.55) * len;
		vec2 tip = root + vec2(lean, -1.0) * len;
		float bd = min(blade(q, root, bend, 0.42, 0.26), blade(q, bend, tip, 0.26, 0.04));
		float bt = clamp((root.y - q.y) / len, 0.0, 1.0);
		vec3 bcol = mix(blade_dark.rgb, blade_light.rgb, bt * 0.75 + 0.25 * h) * (0.75 + 0.5 * mottle);
		col = over(col, bcol, 1.0 - smoothstep(-px * 0.7, px * 0.7, bd));
	}
	COLOR = col;
}
