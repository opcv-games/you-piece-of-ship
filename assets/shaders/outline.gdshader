shader_type spatial;
// Soft cartoon outline: the back faces of the mesh, pushed out a little and drawn dark (inverted hull).
render_mode unshaded, cull_front, shadows_disabled;

uniform vec4 color : source_color = vec4(0.18, 0.11, 0.12, 1.0);
uniform float width = 0.025;

void vertex() {
	VERTEX += NORMAL * width;
}

void fragment() {
	ALBEDO = color.rgb;
}
