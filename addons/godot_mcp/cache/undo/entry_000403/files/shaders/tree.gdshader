shader_type canvas_item;

uniform vec2 size = vec2(84.0, 73.0);
uniform float seed = 0.0;
uniform vec4 leaf_light : source_color = vec4(0.3, 0.43, 0.17, 1.0);
uniform vec4 leaf_mid : source_color = vec4(0.19, 0.3, 0.12, 1.0);
uniform vec4 leaf_dark : source_color = vec4(0.1, 0.17, 0.08, 1.0);
uniform vec4 sick_tint : source_color = vec4(0.62, 0.58, 0.25, 1.0);
uniform vec4 bark_light : source_color = vec4(0.36, 0.26, 0.17, 1.0);
uniform vec4 bark_dark : source_color = vec4(0.2, 0.14, 0.09, 1.0);
uniform vec4 outline_color : source_color = vec4(0.05, 0.06, 0.04, 1.0);
uniform vec4 shadow_color : source_color = vec4(0.0, 0.0, 0.0, 0.35);
uniform float sickly = 0.3;
uniform float crown_height = 1.1;
uniform float spread = 0.85;
uniform float scallop = 0.09;

float rnd(float n) {
	return fract(sin(n * 12.9898 + seed * 78.233) * 43758.5453);
}

float pix(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7)) + seed) * 43758.5453);
}

void fragment() {
	vec2 px = floor(UV * size) + 0.5;
	float R = size.x / 3.0;
	vec2 base = vec2(size.x * 0.5, size.y * 0.94);
	vec2 p = (px - base) / R;
	vec4 col = vec4(0.0);
	vec2 s = (p - vec2(0.2, 0.0)) / vec2(1.35, 0.38);
	if (length(s) < 1.0) {
		col = shadow_color;
	}
	float t = clamp(-p.y / crown_height, 0.0, 1.0);
	float tx = p.x - (rnd(1.0) - 0.5) * 0.25 * t;
	float tw = mix(0.24, 0.15, t);
	if (p.y < 0.06 && p.y > -crown_height && abs(tx) < tw) {
		vec3 bark = tx < -tw * 0.2 ? bark_light.rgb : bark_dark.rgb;
		if (pix(vec2(px.x, floor(px.y / 3.0))) > 0.8) {
			bark *= 0.8;
		}
		col = vec4(bark, 1.0);
		if ((tw - abs(tx)) * R < 1.0 || p.y > 0.0) {
			col = outline_color;
		}
	}
	vec2 crown = vec2((rnd(1.0) - 0.5) * 0.2, -crown_height);
	float front = -1000.0;
	vec2 best_c = vec2(0.0);
	float best_r = 1.0;
	float best_d = 2.0;
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
		float wobble = 1.0 + scallop * sin(atan(d.y, d.x) * 7.0 + rnd(fi + 30.0) * TAU);
		float edge = cr * wobble;
		float dist = length(d);
		union_d = min(union_d, dist - edge);
		if (dist < edge && c.y > front) {
			front = c.y;
			best_c = c;
			best_r = edge;
			best_d = dist / edge;
			best_i = fi;
		}
	}
	if (union_d < 0.0) {
		vec2 n = (p - best_c) / best_r;
		float depth = (best_c.y - crown.y) * 0.35;
		float light = 0.52 + 0.33 * dot(n, vec2(-0.6, -0.8)) + 0.12 * (1.0 - length(n)) - depth + (pix(px) - 0.5) * 0.25;
		vec3 leaf = light > 0.62 ? leaf_light.rgb : (light > 0.38 ? leaf_mid.rgb : leaf_dark.rgb);
		if (pix(px + 0.37) > 0.94 && light > 0.5) {
			leaf = leaf_light.rgb * 1.15;
		}
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
