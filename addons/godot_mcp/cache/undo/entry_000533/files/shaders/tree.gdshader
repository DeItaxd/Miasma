shader_type canvas_item;

uniform vec2 size = vec2(90.0, 73.0);
uniform float seed = 0.0;
uniform vec4 leaf_light : source_color = vec4(0.37, 0.51, 0.2, 1.0);
uniform vec4 leaf_mid : source_color = vec4(0.26, 0.39, 0.15, 1.0);
uniform vec4 leaf_dark : source_color = vec4(0.17, 0.27, 0.1, 1.0);
uniform vec4 leaf_shine : source_color = vec4(0.62, 0.74, 0.4, 1.0);
uniform vec4 sick_tint : source_color = vec4(0.62, 0.58, 0.25, 1.0);
uniform vec4 bark_light : source_color = vec4(0.44, 0.32, 0.2, 1.0);
uniform vec4 bark_dark : source_color = vec4(0.28, 0.2, 0.12, 1.0);
uniform vec4 ink_color : source_color = vec4(0.05, 0.05, 0.04, 1.0);
uniform vec4 shadow_color : source_color = vec4(0.0, 0.0, 0.0, 0.3);
uniform float sickly = 0.3;
uniform float crown_height = 1.1;
uniform float spread = 0.85;
uniform float scallop = 0.09;
uniform float outline = 0.9;
uniform float inner_line = 0.5;

float rnd(float n) {
	return fract(sin(n * 12.9898 + seed * 78.233) * 43758.5453);
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

void fragment() {
	vec2 q = UV * size;
	float px = max(length(vec2(dFdx(q.x), dFdy(q.x))), 1e-4);
	float R = size.x / 3.2;
	float aa = px / R;
	vec2 base = vec2(size.x * 0.5, size.y * 0.94);
	vec2 p = (q - base) / R;
	vec4 col = vec4(0.0);
	float sd = (length((p - vec2(0.2, 0.0)) / vec2(1.35, 0.38)) - 1.0) * 0.38;
	col = vec4(shadow_color.rgb, shadow_color.a * cover(sd, aa));
	float t = clamp(-p.y / crown_height, 0.0, 1.0);
	float tx = p.x - (rnd(1.0) - 0.5) * 0.25 * t;
	float tw = mix(0.24, 0.15, t) + 0.07 * smoothstep(-0.2, 0.06, p.y);
	float trunk_d = max(abs(tx) - tw, max(p.y - 0.06, -p.y - crown_height));
	float side = smoothstep(-aa, aa, tx + tw * 0.2);
	vec3 bark = mix(bark_light.rgb, bark_dark.rgb, side);
	float groove = abs(tx - tw * 0.35 - 0.025 * sin(p.y * 17.0 + seed));
	bark = mix(bark, ink_color.rgb, ink(groove, inner_line * 0.6 / R, aa) * step(-crown_height * 0.8, p.y) * step(p.y, -0.08));
	col = over(col, bark, cover(trunk_d, aa));
	col = over(col, ink_color.rgb, ink(trunk_d, outline / R, aa) * step(-crown_height, p.y));
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
		float wobble = 1.0 + scallop * sin(atan(d.y, d.x) * 7.0 + rnd(fi + 30.0) * TAU);
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
	float light = 0.52 + 0.33 * dot(n, vec2(-0.6, -0.8)) + 0.12 * (1.0 - length(n)) - depth;
	float gl = max(length(vec2(dFdx(light), dFdy(light))), 1e-5);
	vec3 leaf = mix(leaf_dark.rgb, leaf_mid.rgb, smoothstep(0.38 - gl, 0.38 + gl, light));
	leaf = mix(leaf, leaf_light.rgb, smoothstep(0.62 - gl, 0.62 + gl, light));
	float sick = step(1.0 - sickly, rnd(best_i + 40.0));
	leaf = mix(leaf, leaf * sick_tint.rgb * 2.0, sick * 0.5);
	float shine_on = step(0.35, rnd(best_i + 50.0)) * step(best_c.y, crown.y + 0.25);
	float arc_ang = atan(n.y, n.x);
	float arc = abs(length(n) - 0.62) * best_r;
	float arc_span = step(-2.75, arc_ang) * step(arc_ang, -1.75);
	leaf = mix(leaf, leaf_shine.rgb, ink(arc, inner_line * 0.8 / R, aa) * arc_span * shine_on);
	float clump = (best_dist - best_r);
	float under = smoothstep(-0.3, 0.2, n.y) * step(0.0, -union_d - outline * 0.5 / R);
	leaf = mix(leaf, ink_color.rgb, ink(clump, inner_line / R, aa) * under);
	float crown_ang = atan(p.y - crown.y, p.x - crown.x);
	float ow = outline * (0.85 + 0.3 * sin(crown_ang * 4.0 + seed)) / R;
	col = over(col, leaf, cover(union_d, aa));
	col = over(col, ink_color.rgb, ink(union_d, ow, aa));
	COLOR = col;
}
