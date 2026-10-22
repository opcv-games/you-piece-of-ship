extends Control
## The title on a wooden sign, cartoon style: a ship's wheel behind, an anchor and a wave in front.
## Drawn with shapes (no image), so it stays crisp at any resolution. It sways a little.
## The title stays in English in every language.

const WOOD := Color(0.47, 0.27, 0.13)
const WOOD_DARK := Color(0.3, 0.16, 0.07)
const OUTLINE := Color(0.12, 0.06, 0.03)
const GOLD := Color(1.0, 0.78, 0.18)
const STEEL := Color(0.35, 0.6, 0.85)

var _time := 0.0
var _font: Font


func _ready() -> void:
	_font = UI.display_font()
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	_time += delta
	pivot_offset = size * 0.5
	rotation = deg_to_rad(-2.0 + sin(_time * 1.3) * 1.2)
	queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	_draw_wheel(Vector2(w * 0.5, h * 0.2), h * 0.24)
	var sign_rect := Rect2(w * 0.04, h * 0.2, w * 0.92, h * 0.68)
	_draw_sign(sign_rect)
	_outlined("YOU PIECE OF", Vector2(sign_rect.position.x, sign_rect.position.y + h * 0.2), sign_rect.size.x, h * 0.15, Color(1, 0.97, 0.9))
	_outlined("SHIP", Vector2(sign_rect.position.x, sign_rect.position.y + h * 0.6), sign_rect.size.x, h * 0.34, GOLD, true)
	_draw_anchor(Vector2(w * 0.1, h * 0.8), h * 0.14)
	_draw_wave(Vector2(w * 0.9, h * 0.9), h * 0.12)


func _outlined(text: String, at: Vector2, width: float, font_size: float, color: Color, shadow := false) -> void:
	var size_px := int(font_size)
	if shadow:
		draw_string_outline(_font, at + Vector2(4, 5), text, HORIZONTAL_ALIGNMENT_CENTER, width, size_px, 14, Color(0.75, 0.35, 0.05))
		draw_string(_font, at + Vector2(4, 5), text, HORIZONTAL_ALIGNMENT_CENTER, width, size_px, Color(0.75, 0.35, 0.05))
	draw_string_outline(_font, at, text, HORIZONTAL_ALIGNMENT_CENTER, width, size_px, 12, OUTLINE)
	draw_string(_font, at, text, HORIZONTAL_ALIGNMENT_CENTER, width, size_px, color)


func _draw_sign(r: Rect2) -> void:
	var points := PackedVector2Array([r.position + Vector2(10, 6), Vector2(r.end.x - 4, r.position.y),
			r.end + Vector2(-12, 0), Vector2(r.position.x, r.end.y - 8)])
	draw_colored_polygon(_grow(points, 7), OUTLINE)
	draw_colored_polygon(points, WOOD)
	for i in range(1, 4): # planks
		var y := r.position.y + r.size.y * i / 4.0
		draw_line(Vector2(r.position.x + 6, y), Vector2(r.end.x - 8, y - 3), WOOD_DARK, 3.0)
	for corner in [r.position + Vector2(22, 20), Vector2(r.end.x - 22, r.position.y + 16),
			r.end - Vector2(26, 20), Vector2(r.position.x + 18, r.end.y - 24)]:
		draw_circle(corner, 5, Color(0.75, 0.75, 0.7))
		draw_circle(corner, 2.5, Color(0.4, 0.4, 0.4))


func _grow(points: PackedVector2Array, by: float) -> PackedVector2Array:
	var center := Vector2.ZERO
	for p in points:
		center += p
	center /= points.size()
	var grown := PackedVector2Array()
	for p in points:
		grown.append(p + (p - center).normalized() * by)
	return grown


func _draw_wheel(c: Vector2, r: float) -> void:
	var angle := _time * 0.3
	for i in 8:
		var a := angle + i * TAU / 8.0
		var dir := Vector2(cos(a), sin(a))
		draw_line(c, c + dir * r * 1.25, OUTLINE, 14.0)
		draw_line(c, c + dir * r * 1.25, WOOD, 9.0)
		draw_circle(c + dir * r * 1.3, r * 0.11, OUTLINE)
		draw_circle(c + dir * r * 1.3, r * 0.08, WOOD)
	draw_arc(c, r, 0, TAU, 48, OUTLINE, r * 0.3)
	draw_arc(c, r, 0, TAU, 48, WOOD, r * 0.2)
	draw_circle(c, r * 0.22, OUTLINE)
	draw_circle(c, r * 0.16, GOLD)


func _draw_anchor(c: Vector2, s: float) -> void:
	for pass_color in [[OUTLINE, 9.0], [STEEL, 5.0]]:
		var color: Color = pass_color[0]
		var width: float = pass_color[1]
		draw_line(c + Vector2(0, -s), c + Vector2(0, s * 0.9), color, width)
		draw_line(c + Vector2(-s * 0.5, -s * 0.5), c + Vector2(s * 0.5, -s * 0.5), color, width)
		draw_arc(c + Vector2(0, s * 0.2), s * 0.7, PI * 0.1, PI * 0.9, 16, color, width)
		draw_arc(c + Vector2(0, -s * 1.15), s * 0.18, 0, TAU, 12, color, width * 0.7)


func _draw_wave(c: Vector2, s: float) -> void:
	var phase := sin(_time * 2.0) * 0.15
	for pass_color in [[OUTLINE, 12.0], [STEEL, 8.0], [Color(0.85, 0.95, 1.0), 3.0]]:
		draw_arc(c, s, PI * (0.9 + phase), PI * 2.1, 24, pass_color[0], pass_color[1])
		draw_arc(c + Vector2(s * 0.9, -s * 0.2), s * 0.5, PI * 1.0, PI * 2.2, 16, pass_color[0], pass_color[1] * 0.8)
