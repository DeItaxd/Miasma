shader_type canvas_item;

uniform vec2 size = vec2(56.0, 56.0);
uniform float seed = 0.0;
uniform vec4 stone_light : source_color = vec4(0.56, 0.53, 0.47, 1.0);
uniform vec4 stone_mid : source_color = vec4(0.39, 0.37, 0.33, 1.0);
uniform vec4 stone_dark : source_color = vec4(0.22, 0.2, 0.18, 1.0);
uniform vec4 outline_color : source_color = vec4(0.07, 0.065, 0.055, 1.0);
uniform vec4 moss_light : source_color = vec4(0.27, 0.39, 0.15, 1.0);
uniform vec4 moss_dark : source_color = vec4(0.16, 0.25, 0.1, 1.0);
uniform vec4 shadow_color : source_color = vec4(0.0, 0.0, 0.0, 0.35);
uniform float moss_amount = 0.55;

float rnd(float n) {
	return fract(sin(n * 12.9898 + seed * 78.233) * 43758.5453);
}

float pix(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7)) + seed) * 43758.5453);
}

float seg_dist(vec2 p, vec2 a, vec2 b) {
	vec2 pa = p - a;
	vec2 ba = b - a;
	float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
	return length(pa - ba * h);
}

void fragment() {
	vec2 px = floor(UV * size) + 0.5;
	float r = size.x / 2.8;
	vec2 base = vec2(size.x * 0.5, size.y * 0.72);
	vec2 p = (px - base) / r;
	vec2 e = (p - vec2(0.0, -0.5)) / vec2(1.05, 0.85);
	float ang = atan(e.y, e.x);
	float bump = 1.0 + 0.1 * sin(ang * 3.0 + rnd(1.0) * TAU) + 0.07 * sin(ang * 5.0 + rnd(2.0) * TAU) + 0.04 * sin(ang * 8.0 + rnd(3.0) * TAU);
	float rad = length(e) / bump;
	vec4 col = vec4(0.0);
	vec2 s = (p - vec2(0.3, 0.1)) / vec2(1.2, 0.42);
	if (length(s) < 1.0) {
		col = shadow_color;
	}
	if (rad < 1.0) {
		vec2 n = e / max(length(e), 0.001);
		float facets = 6.0 + floor(rnd(4.0) * 3.0);
		float f = floor((ang / TAU + 0.5) * facets + rnd(5.0));
		float light = 0.5 + 0.32 * dot(n, vec2(-0.6, -0.8)) * rad + 0.22 * (1.0 - rad) + (rnd(10.0 + f) - 0.5) * 0.3;
		vec3 stone = light > 0.62 ? stone_light.rgb : (light > 0.4 ? stone_mid.rgb : stone_dark.rgb);
		float grain = pix(px);
		if (grain > 0.93) {
			stone *= 1.12;
		} else if (grain < 0.06) {
			stone *= 0.85;
		}
		vec2 c1 = vec2(rnd(20.0) - 0.5, -0.6 + rnd(21.0) * 0.5);
		vec2 c2 = c1 + vec2(rnd(22.0) - 0.5, rnd(23.0) * 0.5 + 0.2) * 0.8;
		vec2 c3 = c2 + vec2(rnd(24.0) - 0.5, rnd(25.0) * 0.4) * 0.6;
		float crack = min(seg_dist(p, c1, c2), seg_dist(p, c2, c3)) * r;
		if (crack < 0.6 && rad < 0.85) {
			stone = stone_dark.rgb * 0.85;
		}
		float top = -n.y * rad;
		float moss = top - (1.0 - moss_amount) + (rnd(30.0 + f) - 0.5) * 0.4;
		if (moss > 0.0 && grain > 0.15) {
			stone = light > 0.62 ? moss_light.rgb : moss_dark.rgb;
		}
		col = vec4(stone, 1.0);
		if ((1.0 - rad) * r * 0.9 < 1.2) {
			col = outline_color;
		}
	}
	COLOR = col;
}
