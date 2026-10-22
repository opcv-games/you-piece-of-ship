extends Control
## The band's corner (bottom left): a tiny pirate musician and its comment on how the voyage is
## going. Breaks the fourth wall on purpose (Olivier, 2026-10-22). Hidden when captions are off.

const PixelArt = preload("res://scripts/systems/pixel_art.gd")

@export var music: Node
@export var show_seconds := 4.5

var _left := 0.0
var _portrait: TextureRect
var _text: Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	modulate.a = 0.0
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.1, 0.16, 0.85)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(8)
	style.border_color = Color(1, 0.85, 0.3, 0.8)
	style.set_border_width_all(2)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	panel.add_child(row)
	_portrait = TextureRect.new()
	var avatar := AtlasTexture.new()
	avatar.atlas = PixelArt.crew_texture(null)
	avatar.region = Rect2(304, 136, 24, 22) # the pirate portrait on the sheet
	_portrait.texture = avatar
	_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_portrait.custom_minimum_size = Vector2(48, 44)
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	row.add_child(_portrait)
	_text = Label.new()
	_text.add_theme_font_size_override("font_size", 15)
	_text.add_theme_color_override("font_color", Color(1, 0.95, 0.8))
	_text.custom_minimum_size = Vector2(300, 0)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(_text)
	if music:
		music.caption.connect(show_caption)


func show_caption(text: String) -> void:
	_text.text = "♪ " + text
	_left = show_seconds
	pivot_offset = Vector2(0, size.y)
	scale = Vector2(0.85, 0.85)
	create_tween().tween_property(self, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _process(delta: float) -> void:
	_left = maxf(0.0, _left - delta)
	var target := 1.0 if _left > 0.0 else 0.0
	modulate.a = move_toward(modulate.a, target, delta * 3.0)
	# The musician bobs to the beat while it talks.
	if _portrait and _left > 0.0:
		_portrait.position.y = -absf(sin(Time.get_ticks_msec() / 1000.0 * PI / 0.6)) * 4.0
