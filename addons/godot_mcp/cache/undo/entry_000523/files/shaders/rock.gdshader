shader_type canvas_item;

uniform vec2 size = vec2(56.0, 56.0);
uniform float seed = 0.0;
uniform vec4 stone_light : source_color = vec4(0.62, 0.59, 0.52, 1.0);
uniform vec4 stone_mid : source_color = vec4(0.47, 0.45, 0.4, 1.0);
uniform vec4 stone_dark : source_color = vec4(0.31, 0.29, 0.26, 1.0);
uniform vec4 ink_color : source_color = vec4(0.06, 0.055, 0.05, 1.0);
uniform vec4 moss_light : source_color = vec4(0.33, 0.46, 0.18, 1.0);
uniform vec4 moss_dark : source_color = vec4(0.22, 0.33, 0.12, 1.0);
uniform vec4 moss_ink : source_color = vec4(0.09, 0.15, 0.06, 1.0);
uniform vec4 shadow_color : source_color = vec4(0.0, 0.0, 0.0, 0.3);
uniform float moss_amount = 0.55;
uniform float outline = 0.85;
uniform float inner_line = 0.42;

float rnd(float n) {
	return fract(sin(n * 12.9898 + seed * 78.233) * 43758.5453);
}

float seg(vec2 p, vec2 a, vec2 b) {
	vec2 pa = p - a;
	vec2 ba = b - a;
	float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
	return length(pa - ba * h);
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
	float r = size.x / 2.8;
	float aa = px / r;
	vec2 base = vec2(size.x * 0.5, size.y * 0.72);
	vec2 p = (q - base) / r;
	vec2 e = (p - vec2(0.0, -0.5)) / vec2(1.05, 0.85);
	float ang = atan(e.y, e.x);
	float bump = 1.0 + 0.1 * sin(ang * 3.0 + rnd(1.0) * TAU) + 0.07 * sin(ang * 5.0 + rnd(2.0) * TAU) + 0.04 * sin(ang * 8.0 + rnd(3.0) * TAU);
	float len = length(e);
	float rad = len / bump;
	float d = (len - bump) * 0.92;
	vec4 col = vec4(0.0);
	float sd = (length((p - vec2(0.3, 0.1)) / vec2(1.2, 0.42)) - 1.0) * 0.42;
	col = vec4(shadow_color.rgb, shadow_color.a * cover(sd, aa));
	vec2 n = e / max(len, 0.001);
	float facets = 6.0 + floor(rnd(4.0) * 3.0);
	float fpos = (ang / TAU + 0.5) * facets + rnd(5.0);
	float f = floor(fpos);
	float light = 0.5 + 0.32 * dot(n, vec2(-0.6, -0.8)) * rad + 0.22 * (1.0 - rad) + (rnd(10.0 + f) - 0.5) * 0.3;
	float gl = max(length(vec2(dFdx(light), dFdy(light))), 1e-5);
	vec3 stone = mix(stone_dark.rgb, stone_mid.rgb, smoothstep(0.4 - gl, 0.4 + gl, light));
	stone = mix(stone, stone_light.rgb, smoothstep(0.62 - gl, 0.62 + gl, light));
	float ridge = abs(fract(fpos) - 0.5);
	float ridge_d = (0.5 - ridge) / facets * TAU * len * 0.95;
	float ridge_on = step(0.35, rnd(f + 50.0)) * smoothstep(0.25, 0.4, rad) * (1.0 - smoothstep(0.75, 0.9, rad));
	stone = mix(stone, ink_color.rgb, ink(ridge_d, inner_line * 0.75 / r, aa) * ridge_on);
	vec2 c1 = vec2(rnd(20.0) - 0.5, -0.6 + rnd(21.0) * 0.5);
	vec2 c2 = c1 + vec2(rnd(22.0) - 0.5, rnd(23.0) * 0.5 + 0.2) * 0.8;
	vec2 c3 = c2 + vec2(rnd(24.0) - 0.5, rnd(25.0) * 0.4) * 0.6;
	float crack = min(seg(p, c1, c2), seg(p, c2, c3));
	float crack_taper = 1.0 - smoothstep(0.0, 0.9, length(p - c1));
	stone = mix(stone, ink_color.rgb, ink(crack, inner_line * (0.4 + 0.6 * crack_taper) / r, aa) * (1.0 - smoothstep(0.78, 0.88, rad)));
	float top = -n.y * rad;
	float moss = top - (1.0 - moss_amount) + 0.08 * sin(ang * 9.0 + rnd(31.0) * TAU) + 0.05 * sin(ang * 17.0 + rnd(32.0) * TAU);
	float gm = max(length(vec2(dFdx(moss), dFdy(moss))), 1e-5);
	float mossy = smoothstep(-gm, gm, moss);
	vec3 moss_col = mix(moss_dark.rgb, moss_light.rgb, smoothstep(0.55 - gl, 0.55 + gl, light));
	stone = mix(stone, moss_col, mossy);
	float moss_edge = 1.0 - smoothstep(inner_line / r - aa, inner_line / r + aa, abs(moss) / gm * aa);
	stone = mix(stone, moss_ink.rgb, moss_edge * (1.0 - smoothstep(0.85, 0.95, rad)));
	col = over(col, stone, cover(d, aa));
	float ow = outline * (0.85 + 0.3 * sin(ang * 3.0 + seed)) / r;
	col = over(col, ink_color.rgb, ink(d, ow, aa));
	COLOR = col;
}
