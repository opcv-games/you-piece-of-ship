// The painted-kawaii look (Olivier, 2026-10-22): soft two-step cartoon shading with warm lilac
// shadows instead of grey, a creamy rim light, a faint brush-stroke texture from world-space noise,
// and a soft highlight. Cheap: one light pass, no textures.

uniform vec4 albedo : source_color = vec4(1.0);
uniform vec4 shade_tint : source_color = vec4(0.64, 0.68, 0.9, 1.0); // shadows lean lilac
uniform float softness : hint_range(0.01, 0.5) = 0.12;
uniform float rim_strength : hint_range(0.0, 1.0) = 0.35;
uniform float paint_strength : hint_range(0.0, 0.3) = 0.07;
uniform float paint_scale = 2.2;
uniform float glossy : hint_range(0.0, 1.0) = 0.3;
uniform float emission_strength = 0.0;
uniform float alpha : hint_range(0.0, 1.0) = 1.0;

varying vec3 world_pos;

float hash(vec3 p) {
	p = fract(p * 0.3183099 + 0.1);
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

float noise(vec3 x) {
	vec3 i = floor(x);
	vec3 f = fract(x);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(hash(i), hash(i + vec3(1, 0, 0)), f.x), mix(hash(i + vec3(0, 1, 0)), hash(i + vec3(1, 1, 0)), f.x), f.y),
			mix(mix(hash(i + vec3(0, 0, 1)), hash(i + vec3(1, 0, 1)), f.x), mix(hash(i + vec3(0, 1, 1)), hash(i + vec3(1, 1, 1)), f.x), f.y), f.z);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	// Brush strokes: stretched noise, so the colour wavers like paint.
	float strokes = noise(world_pos * vec3(paint_scale, paint_scale * 3.0, paint_scale)) * 0.6
			+ noise(world_pos * paint_scale * 4.0) * 0.4;
	ALBEDO = albedo.rgb * (1.0 + (strokes - 0.5) * 2.0 * paint_strength);
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
	EMISSION = albedo.rgb * emission_strength;
#ifdef SEE_THROUGH
	ALPHA = alpha;
#endif
}

void light() {
	float ndl = dot(NORMAL, LIGHT);
	float wrapped = (ndl + 0.35) / 1.35;
	float shadow = smoothstep(0.2, 0.6, ATTENUATION);
	float lit = smoothstep(0.32 - softness, 0.32 + softness, wrapped) * shadow;
	vec3 tone = mix(shade_tint.rgb, vec3(1.0), lit);
	DIFFUSE_LIGHT += LIGHT_COLOR / PI * tone;
	// Rim: a creamy edge on the lit side.
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0) * smoothstep(-0.2, 0.4, ndl);
	DIFFUSE_LIGHT += LIGHT_COLOR / PI * rim * rim_strength * vec3(1.0, 0.95, 0.85);
	// A soft cartoon highlight.
	vec3 half_vector = normalize(LIGHT + VIEW);
	float spec = smoothstep(0.9, 0.95, dot(NORMAL, half_vector)) * glossy * shadow;
	SPECULAR_LIGHT += LIGHT_COLOR / PI * spec * 0.6;
}
