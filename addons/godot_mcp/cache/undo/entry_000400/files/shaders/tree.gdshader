shader_type canvas_item;

uniform vec2 size = vec2(64.0, 70.0);
uniform float seed = 0.0;
uniform vec4 leaf_light : source_color = vec4(0.3, 0.43, 0.17, 1.0);
uniform vec4 leaf_mid : source_color = vec4(0.19, 0.3, 0.12, 1.0);
uniform vec4 leaf_dark : source_color = vec4(0.1, 0.17, 0.08, 1.0);
uniform vec4 sick_tint : source_color = vec4(0.62, 0.58, 0.25, 1.0);
uniform vec4 bark_light : source_color = vec4(0.36, 0.26, 0.17, 1.0);
uniform vec4 bark_dark : source_color = vec4(0.2, 0.14, 0.09, 1.0);
uniform vec4 outline_color : source_color = vec4(0.05, 0.06, 0.04, 1.0);
uniform vec4 shadow_color : source_color = vec4(0.0, 0.0, 0.0, 0.35);
uniform float sickly = 0.35;
uniform float crown_height = 1.3;

float rnd(float n) {
	return fract(sin(n * 12.9898 + seed * 78.233) * 43758.5453);
}

float pix(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7)) + seed) * 43758.5453);
}

void fragment() {
	vec2 px = floor(UV * size) + 0.5;
	float R = size.x / 2.5;
	vec2 base = vec2(size.x * 0.5, size.y * 0.94);
	vec2 p = (px - base) / R;
	vec4 col = vec4(0.0);
	vec2 s = (p - vec2(0.25, 0.0)) / vec2(1.0, 0.32);
	if (length(s) < 1.0) {
		col = shadow_color;
	}
	float trunk_top = crown_height - 0.2;
	float t = clamp(-p.y / trunk_top, 0.0, 1.0);
	float tx = p.x - (rnd(1.0) - 0.5) * 0.3 * t;
	float tw = mix(0.22, 0.13, t);
	if (p.y < 0.06 && p.y > -trunk_top && abs(tx) < tw) {
		vec3 bark = tx < -tw * 0.2 ? bark_light.rgb : bark_dark.rgb;
		if (pix(vec2(px.x, floor(px.y / 3.0))) > 0.8) {
			bark *= 0.8;
		}
		col = vec4(bark, 1.0);
		if ((tw - abs(tx)) * R < 1.0 || p.y > 0.0) {
			col = outline_color;
		}
	}
	vec2 crown = vec2((rnd(1.0) - 0.5) * 0.3, -crown_height);
	float front = -1000.0;
	vec2 best_c = vec2(0.0);
	float best_r = 1.0;
	float best_d = 2.0;
	float best_i = 0.0;
	float union_d = 10.0;
	for (int i = 0; i < 7; i++) {
		float fi = float(i);
		vec2 c = crown;
		float cr = 0.62;
		if (i > 0) {
			float a = fi / 6.0 * TAU + rnd(fi + 2.0) * 0.6;
			c = crown + vec2(cos(a), sin(a) * 0.75) * (0.45 + rnd(fi + 9.0) * 0.12);
			cr = 0.38 + rnd(fi + 15.0) * 0.14;
		}
		float dist = length(p - c);
		union_d = min(union_d, dist - cr);
		if (dist < cr && c.y > front) {
			front = c.y;
			best_c = c;
			best_r = cr;
			best_d = dist / cr;
			best_i = fi;
		}
	}
	if (union_d < 0.0) {
		vec2 n = (p - best_c) / best_r;
		float light = 0.5 + 0.35 * dot(n, vec2(-0.6, -0.8)) + 0.15 * (1.0 - length(n)) + (pix(px) - 0.5) * 0.25;
		vec3 leaf = light > 0.62 ? leaf_light.rgb : (light > 0.38 ? leaf_mid.rgb : leaf_dark.rgb);
		float sick = step(1.0 - sickly, rnd(best_i + 40.0));
		leaf = mix(leaf, leaf * sick_tint.rgb * 2.0, sick * 0.5);
		col = vec4(leaf, 1.0);
		if ((1.0 - best_d) * best_r * R < 1.0) {
			col = vec4(leaf_dark.rgb * 0.7, 1.0);
		}
		if (-union_d * R < 1.2) {
			col = outline_color;
		}
	}
	COLOR = col;
}
