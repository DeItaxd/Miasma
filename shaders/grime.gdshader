shader_type canvas_item;

uniform vec2 frames = vec2(1.0, 1.0);
uniform float scale = 1.0;
uniform float desaturate : hint_range(0.0, 1.0) = 0.35;
uniform vec3 tint : source_color = vec3(0.9, 0.86, 0.74);
uniform float grime : hint_range(0.0, 1.0) = 0.45;
uniform vec3 grime_color : source_color = vec3(0.6, 0.48, 0.32);
uniform float mud : hint_range(0.0, 1.0) = 0.45;
uniform float mud_height : hint_range(0.0, 1.0) = 0.35;
uniform vec3 mud_color : source_color = vec3(0.45, 0.34, 0.22);
uniform float stains : hint_range(0.0, 1.0) = 0.6;
uniform float stain_level : hint_range(0.0, 1.0) = 0.56;
uniform vec3 stain_color : source_color = vec3(0.78, 0.62, 0.38);
uniform float specks : hint_range(0.0, 1.0) = 0.45;
uniform float speck_density = 45.0;
uniform float speck_amount : hint_range(0.0, 1.0) = 0.25;
uniform float soot : hint_range(0.0, 1.0) = 0.35;
uniform float soot_width = 6.0;
uniform float hatching : hint_range(0.0, 1.0) = 0.25;
uniform float hatch_spacing = 0.05;

instance uniform float seed = 0.0;

varying vec4 tint_in;

void vertex() {
	tint_in = COLOR;
}

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p, int octaves) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < octaves; i++) {
		v += a * noise(p);
		p = p * 2.03 + 17.1;
		a *= 0.5;
	}
	return v;
}

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	vec2 cell = 1.0 / (TEXTURE_PIXEL_SIZE * frames);
	vec2 local = mod(UV / TEXTURE_PIXEL_SIZE, cell);
	vec2 f = local / cell.y * scale;
	vec2 s = f + fract(seed * vec2(0.713, 0.371)) * 10.0;
	float height = local.y / cell.y;

	vec2 sp = s * speck_density;
	float speck_soft = max(fwidth(sp.x), 0.1);
	float hc = (f.x * 0.6 + f.y) / hatch_spacing;
	float hw = max(fwidth(hc), 0.001);

	vec3 c = tex.rgb;
	float lum = dot(c, vec3(0.299, 0.587, 0.114));
	c = mix(c, vec3(lum), desaturate) * tint;

	float g = smoothstep(0.38, 0.72, fbm(s * 5.0, 4)) * grime;
	c = mix(c, c * grime_color, g);

	float ragged = (fbm(s * 9.0 + 3.0, 3) - 0.5) * 0.3;
	float m = smoothstep(1.0 - mud_height, 1.0 - mud_height * 0.25, height + ragged) * mud;
	c = mix(c, c * mud_color, m);

	float st = fbm(s * 3.0 + 40.0, 4);
	float stain = smoothstep(stain_level, stain_level + 0.04, st) * stains;
	float ring = smoothstep(stain_level - 0.01, stain_level + 0.015, st) * (1.0 - smoothstep(stain_level + 0.015, stain_level + 0.05, st));
	c = mix(c, c * stain_color, stain);
	c *= 1.0 - ring * stains * 0.5;

	vec2 sc = floor(sp);
	vec2 off = vec2(hash(sc + 1.3), hash(sc + 9.1)) * 0.6 + 0.2;
	float blot = 1.0 - smoothstep(0.2 - speck_soft, 0.2 + speck_soft, length(sp - sc - off));
	blot *= clamp(0.2 / speck_soft, 0.0, 1.0);
	float speck = step(1.0 - speck_amount, hash(sc + 3.7)) * blot * specks;
	c *= 1.0 - speck * 0.65;

	float around = 0.0;
	for (int i = 0; i < 8; i++) {
		float ang = float(i) * TAU / 8.0;
		around += texture(TEXTURE, UV + vec2(cos(ang), sin(ang)) * soot_width * TEXTURE_PIXEL_SIZE).a;
	}
	float rim = (1.0 - around / 8.0) * soot;
	c *= 1.0 - rim * 0.7 * (0.5 + noise(s * 8.0));

	float shade = clamp(g + m + rim, 0.0, 1.0);
	float dd = abs(fract(hc + 0.5) - 0.5);
	float line = 1.0 - smoothstep(0.12, 0.12 + max(hw, 0.13), dd);
	line *= clamp((1.0 / hw - 1.5) / 3.0, 0.0, 1.0);
	float brk = smoothstep(0.35, 0.55, noise(s * vec2(30.0, 6.0)));
	c *= 1.0 - line * brk * shade * hatching * 0.5;

	COLOR = vec4(c, tex.a) * tint_in;
}
