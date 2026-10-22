shader_type spatial;
// The sea (Olivier, 2026-10-22: "high fidelity, there are very lightweight ways to do it").
// One subdivided plane that follows the ship; everything else happens here:
//  - four Gerstner waves (rolling crests, computed normals) plus a travelling swell for big waves
//  - colour from deep blue to turquoise by viewing angle (fresnel) and wave height
//  - foam on the crests and wherever the water meets something (hull, rocks, whales): it reads the
//    depth of what is behind the water, so every object gets a foam ring for free
//  - two scrolling ripple layers for detail, and twinkling sun glints
// Painted look: colours are gently banded, foam has soft cartoon edges.
render_mode blend_mix, depth_draw_always, cull_back, specular_disabled;

uniform sampler2D depth_texture : hint_depth_texture, filter_linear_mipmap;
uniform vec4 deep_color : source_color = vec4(0.07, 0.33, 0.62, 1.0);
uniform vec4 shallow_color : source_color = vec4(0.2, 0.72, 0.82, 1.0);
uniform vec4 horizon_color : source_color = vec4(0.62, 0.86, 0.96, 1.0);
uniform vec4 foam_color : source_color = vec4(0.97, 1.0, 1.0, 1.0);
uniform float wave_height = 0.32;
uniform float wave_speed = 1.0;
uniform vec2 wind = vec2(1.0, 0.35);
uniform float shore_foam = 0.9; // metres of foam where water touches objects
uniform float crest_foam = 0.35;
uniform float glints = 1.0;
uniform vec3 sun_direction = vec3(-0.45, 0.75, 0.48);
// A big wave (swell) rolling in: origin and direction in world xz, start time, height.
uniform vec2 swell_origin = vec2(0.0);
uniform vec2 swell_direction = vec2(0.0, 1.0);
uniform float swell_age = 100.0; // seconds since the swell started
uniform float swell_height = 0.0;

varying vec3 world_pos;
varying float crest;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}

// One Gerstner wave: adds to position offset and to the normal's tangent/binormal.
void gerstner(vec2 dir, float wavelength, float steep, float amp, vec2 p, float t,
		inout vec3 offset, inout vec3 tangent, inout vec3 binormal) {
	float k = 6.28318 / wavelength;
	float c = sqrt(9.8 / k);
	vec2 d = normalize(dir);
	float f = k * (dot(d, p) - c * t);
	float a = amp;
	offset += vec3(d.x * steep * a * cos(f), a * sin(f), d.y * steep * a * cos(f));
	tangent += vec3(-d.x * d.x * steep * a * k * sin(f), d.x * a * k * cos(f), -d.x * d.y * steep * a * k * sin(f));
	binormal += vec3(-d.x * d.y * steep * a * k * sin(f), d.y * a * k * cos(f), -d.y * d.y * steep * a * k * sin(f));
}

void vertex() {
	vec3 p = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float t = TIME * wave_speed;
	vec3 offset = vec3(0.0);
	vec3 tangent = vec3(1.0, 0.0, 0.0);
	vec3 binormal = vec3(0.0, 0.0, 1.0);
	vec2 w = normalize(wind);
	gerstner(w, 28.0, 0.5, wave_height * 1.0, p.xz, t, offset, tangent, binormal);
	gerstner(vec2(w.x * 0.8 - w.y * 0.6, w.y * 0.8 + w.x * 0.6), 15.0, 0.55, wave_height * 0.55, p.xz, t, offset, tangent, binormal);
	gerstner(vec2(w.x * 0.6 + w.y * 0.8, w.y * 0.6 - w.x * 0.8), 9.0, 0.5, wave_height * 0.3, p.xz, t, offset, tangent, binormal);
	gerstner(vec2(-w.y, w.x), 5.5, 0.4, wave_height * 0.15, p.xz, t, offset, tangent, binormal);
	// The swell: one long wave packet travelling from its origin.
	if (swell_height > 0.0) {
		float age = swell_age;
		float along = dot(p.xz - swell_origin, normalize(swell_direction)) - age * 9.0;
		float envelope = exp(-along * along / 60.0) * clamp(1.0 - age / 9.0, 0.0, 1.0);
		offset.y += swell_height * envelope;
	}
	VERTEX += (inverse(MODEL_MATRIX) * vec4(offset, 0.0)).xyz;
	NORMAL = normalize(cross(binormal, tangent));
	world_pos = p + offset;
	crest = offset.y / max(wave_height * 2.0, 0.001);
}

void fragment() {
	vec3 view_world = normalize((INV_VIEW_MATRIX * vec4(VIEW, 0.0)).xyz);
	vec3 n = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	// Ripples: two scrolling noise layers tilt the normal a little.
	vec2 r1 = world_pos.xz * 0.35 + TIME * vec2(0.12, 0.05);
	vec2 r2 = world_pos.xz * 0.9 - TIME * vec2(0.05, 0.14);
	float e = 0.15;
	float h1 = noise(r1) + noise(r2) * 0.5;
	float hx = noise(r1 + vec2(e, 0.0)) + noise(r2 + vec2(e, 0.0)) * 0.5;
	float hz = noise(r1 + vec2(0.0, e)) + noise(r2 + vec2(0.0, e)) * 0.5;
	n = normalize(n + vec3(h1 - hx, 0.0, h1 - hz) * 0.9);
	float fresnel = pow(1.0 - clamp(dot(n, view_world), 0.0, 1.0), 4.0);
	vec3 water = mix(deep_color.rgb, shallow_color.rgb, clamp(crest * 0.35 + 0.35, 0.0, 1.0));
	water = mix(water, horizon_color.rgb, fresnel * 0.85);
	// Gentle banding for the painted look.
	water = floor(water * 18.0 + 0.5) / 18.0;
	// Foam where the water touches something: compare the water's depth with what's behind it.
	float scene_depth = texture(depth_texture, SCREEN_UV).r;
	vec4 behind = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, scene_depth, 1.0);
	behind.xyz /= behind.w;
	float gap = length(behind.xyz) - length(VERTEX);
	float foam_noise = noise(world_pos.xz * 1.6 + TIME * 0.4) * 0.6 + noise(world_pos.xz * 4.0 - TIME * 0.3) * 0.4;
	float touch = 1.0 - clamp(gap / shore_foam, 0.0, 1.0);
	float edge_foam = smoothstep(0.45, 0.55, touch * (0.65 + foam_noise * 0.7));
	water = mix(water, shallow_color.rgb * 1.15, clamp(touch * 1.4, 0.0, 1.0) * 0.6); // turquoise near things
	float crest_mask = smoothstep(0.78, 0.84, crest * 0.45 + foam_noise * crest_foam + 0.2);
	float foam = max(edge_foam, crest_mask * 0.9);
	// Sun glints: sparkles where the ripples reflect the sun straight at the camera.
	vec3 reflected = reflect(-view_world, n);
	float sun = max(dot(reflected, normalize(sun_direction)), 0.0);
	float sparkle = step(0.985, sun) * step(0.72, noise(world_pos.xz * 6.0 + TIME * 1.5)) * glints;
	ALBEDO = mix(water, foam_color.rgb, foam) + vec3(sparkle);
	EMISSION = vec3(sparkle) * 0.8 + foam * 0.12;
	ROUGHNESS = 0.6;
	ALPHA = 1.0;
}
