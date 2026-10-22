extends Button
## A main-menu button: a little icon, a title and a subtitle (cartoon style, see the mockup).

@export var title := ""
@export var subtitle := ""
@export var compact := false ## half width (two to a row)
@export_enum("wheel", "people", "link", "crate", "gear", "door", "map") var glyph := "wheel"
@export var highlight := false ## the big yellow Quick Play

const INK := Color(0.07, 0.1, 0.18)


func _ready() -> void:
	text = ""
	custom_minimum_size = Vector2(187 if compact else 380, 64 if highlight else 52)
	if highlight:
		add_theme_stylebox_override("normal", _yellow(UI.YELLOW))
		add_theme_stylebox_override("hover", _yellow(UI.YELLOW.lightened(0.15)))
		add_theme_stylebox_override("focus", _yellow(Color(0, 0, 0, 0), true))
		add_theme_stylebox_override("pressed", _yellow(UI.YELLOW.darkened(0.15)))


func _yellow(fill: Color, border_only := false) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = Color.WHITE if border_only else Color(0.55, 0.32, 0.05)
	box.set_border_width_all(4)
	box.set_corner_radius_all(16)
	box.skew = Vector2(-0.06, 0)
	if not border_only: # a focus outline is drawn on top: a shadow there would darken the button
		box.shadow_color = Color(0, 0, 0, 0.4)
		box.shadow_size = 6
		box.shadow_offset = Vector2(0, 5)
	return box


func _draw() -> void:
	var font := get_theme_default_font()
	var ink := INK if highlight else UI.CREAM
	var h := size.y
	_draw_icon(Vector2(h * 0.6, h * 0.5), h * 0.26, ink)
	var x := h * 1.15
	if subtitle == "":
		draw_string(font, Vector2(x, h * 0.62), tr(title), HORIZONTAL_ALIGNMENT_LEFT, -1, 22, ink)
	else:
		draw_string(font, Vector2(x, h * 0.46), tr(title), HORIZONTAL_ALIGNMENT_LEFT, -1, 24 if highlight else 21, ink)
		draw_string(font, Vector2(x, h * 0.78), tr(subtitle), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(ink, 0.8))


func _draw_icon(c: Vector2, r: float, color: Color) -> void:
	match glyph:
		"wheel":
			draw_arc(c, r, 0, TAU, 24, color, 3.0)
			for i in 8:
				var d := Vector2.from_angle(i * TAU / 8.0)
				draw_line(c, c + d * r * 1.35, color, 3.0)
			draw_circle(c, r * 0.3, color)
		"people":
			for p in [Vector2(-r * 0.6, 0), Vector2(r * 0.6, 0), Vector2(0, -r * 0.15)]:
				draw_circle(c + p + Vector2(0, -r * 0.45), r * 0.28, color)
				draw_arc(c + p + Vector2(0, r * 0.45), r * 0.45, PI, TAU, 12, color, 4.0)
		"link":
			draw_arc(c + Vector2(-r * 0.4, r * 0.3), r * 0.45, 0, TAU, 16, color, 4.0)
			draw_arc(c + Vector2(r * 0.4, -r * 0.3), r * 0.45, 0, TAU, 16, color, 4.0)
		"crate":
			var box := Rect2(c - Vector2(r, r), Vector2(r, r) * 2)
			draw_rect(box, color, false, 3.0)
			draw_line(box.position, box.end, color, 3.0)
			draw_line(Vector2(box.end.x, box.position.y), Vector2(box.position.x, box.end.y), color, 3.0)
		"gear":
			for i in 8:
				var d := Vector2.from_angle(i * TAU / 8.0)
				draw_line(c + d * r * 0.7, c + d * r * 1.15, color, 6.0)
			draw_arc(c, r * 0.75, 0, TAU, 24, color, 5.0)
			draw_circle(c, r * 0.25, color)
		"map":
			var sheet := PackedVector2Array([c + Vector2(-r, -r * 0.8), c + Vector2(-r * 0.33, -r), c + Vector2(r * 0.33, -r * 0.8),
					c + Vector2(r, -r), c + Vector2(r, r * 0.8), c + Vector2(r * 0.33, r), c + Vector2(-r * 0.33, r * 0.8),
					c + Vector2(-r, r), c + Vector2(-r, -r * 0.8)])
			draw_polyline(sheet, color, 3.0)
			draw_line(c + Vector2(-r * 0.33, -r), c + Vector2(-r * 0.33, r * 0.8), color, 2.0)
			draw_line(c + Vector2(r * 0.33, -r * 0.8), c + Vector2(r * 0.33, r), color, 2.0)
			draw_line(c + Vector2(r * 0.4, -r * 0.2), c + Vector2(r * 0.75, r * 0.2), color, 3.0)
			draw_line(c + Vector2(r * 0.75, -r * 0.2), c + Vector2(r * 0.4, r * 0.2), color, 3.0)
		"door":
			draw_rect(Rect2(c - Vector2(r * 0.8, r), Vector2(r * 1.1, r * 2)), color, false, 3.0)
			draw_line(c + Vector2(0, 0), c + Vector2(r * 1.2, 0), color, 3.0)
			draw_line(c + Vector2(r * 0.85, -r * 0.35), c + Vector2(r * 1.2, 0), color, 3.0)
			draw_line(c + Vector2(r * 0.85, r * 0.35), c + Vector2(r * 1.2, 0), color, 3.0)
