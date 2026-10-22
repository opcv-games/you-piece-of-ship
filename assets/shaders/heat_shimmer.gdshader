shader_type spatial;
// Heat haze above the engine's chimney: wobbles whatever is behind it. Strength 0 = invisible.
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float strength : hint_range(0.0, 1.0) = 0.0;

void vertex() {
	// Billboard: always face the camera.
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
}

void fragment() {
	vec2 centred = UV - vec2(0.5);
	float fade = smoothstep(0.5, 0.15, length(centred * vec2(1.4, 1.0))) * (1.0 - UV.y * 0.3);
	float wave = sin(UV.y * 22.0 - TIME * 9.0) + sin(UV.y * 13.0 + UV.x * 7.0 - TIME * 6.0) * 0.6;
	vec2 offset = vec2(wave * 0.004, wave * 0.002) * strength * fade;
	ALBEDO = texture(screen_texture, SCREEN_UV + offset).rgb;
	ALPHA = clamp(fade * strength * 4.0, 0.0, 1.0);
}
