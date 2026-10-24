extends CanvasLayer
## Interface toolkit (autoload "UI"): the cartoon theme, screen transitions, button juice and the
## little interface sounds. Couch-party style: chunky rounded shapes, warm wood and navy, bouncy.

const SOUNDS := ["hover", "click", "coin", "whoosh", "stamp", "error"]
const YELLOW := Color(1.0, 0.78, 0.2)
const NAVY := Color(0.09, 0.15, 0.27)
const NAVY_LIGHT := Color(0.16, 0.25, 0.42)
const WOOD := Color(0.42, 0.24, 0.12)
const CREAM := Color(1.0, 0.96, 0.86)

var theme: Theme
var _players := {}
var _curtain: ColorRect
var _busy := false


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	theme = build_theme()
	get_tree().root.theme = theme
	for sound in SOUNDS:
		var player := AudioStreamPlayer.new()
		player.stream = load("res://assets/audio/ui/%s.wav" % sound)
		add_child(player)
		_players[sound] = player
	_curtain = ColorRect.new()
	_curtain.color = NAVY
	_curtain.set_anchors_preset(Control.PRESET_FULL_RECT)
	_curtain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_curtain.modulate.a = 0.0
	add_child(_curtain)
	get_tree().node_added.connect(_on_node_added)


## A big rounded cartoon font: the Mac's Arial Rounded, Windows' Segoe UI Black, or the default.
func display_font() -> Font:
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Arial Rounded MT Bold", "Segoe UI Black", "Verdana"])
	font.font_weight = 800
	return font


func build_theme() -> Theme:
	var t := Theme.new()
	t.default_font = display_font()
	t.default_font_size = 18
	t.set_stylebox("normal", "Button", _box(NAVY, Color(0, 0, 0, 0.55), 3))
	t.set_stylebox("hover", "Button", _box(NAVY_LIGHT, YELLOW, 3))
	t.set_stylebox("pressed", "Button", _box(YELLOW.darkened(0.2), YELLOW, 3))
	var focus := _box(Color(0, 0, 0, 0), YELLOW, 3)
	focus.shadow_size = 0 # drawn on top of the button: no shadow
	t.set_stylebox("focus", "Button", focus)
	t.set_stylebox("disabled", "Button", _box(NAVY.darkened(0.3), Color(0, 0, 0, 0.3), 3))
	t.set_color("font_color", "Button", CREAM)
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_focus_color", "Button", Color.WHITE)
	t.set_color("font_pressed_color", "Button", NAVY)
	t.set_color("font_disabled_color", "Button", Color(1, 1, 1, 0.4))
	t.set_stylebox("normal", "LineEdit", _box(Color(0.05, 0.08, 0.14), NAVY_LIGHT, 2))
	t.set_stylebox("focus", "LineEdit", _box(Color(0.05, 0.08, 0.14), YELLOW, 2))
	t.set_stylebox("panel", "PanelContainer", _box(Color(NAVY, 0.94), Color(0, 0, 0, 0.6), 3, 18))
	t.set_stylebox("panel", "Panel", _box(Color(NAVY, 0.94), Color(0, 0, 0, 0.6), 3, 18))
	t.set_color("font_color", "Label", CREAM)
	t.set_color("font_outline_color", "Label", Color(0.03, 0.05, 0.1))
	t.set_constant("outline_size", "Label", 4)
	return t


func _box(fill: Color, border: Color, border_width: int, radius := 14) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(border_width)
	box.set_corner_radius_all(radius)
	box.set_content_margin_all(10)
	box.shadow_color = Color(0, 0, 0, 0.35)
	box.shadow_size = 4
	box.shadow_offset = Vector2(0, 4)
	return box


func play(sound: String) -> void:
	var player: AudioStreamPlayer = _players.get(sound)
	if player:
		player.pitch_scale = randf_range(0.95, 1.05)
		player.play()


# --- Juice ----------------------------------------------------------------------------------

## Every button anywhere gets the same bouncy feel: grow on hover/focus, squash on press, sounds.
func _on_node_added(node: Node) -> void:
	# In-world labels (station names, prompts, P1-P4) are drawn 1.7x bigger so they read from
	# the couch (Olivier, 2026-10-24: "the texts indicating what is what are too small").
	if node is Label3D and not node.has_meta("sized"):
		node.set_meta("sized", true)
		node.font_size = int(node.font_size * 1.7)
		node.outline_size = int(node.outline_size * 1.7)
	if node is BaseButton and not node.has_meta("juiced"):
		node.set_meta("juiced", true)
		node.mouse_entered.connect(_grow.bind(node))
		node.focus_entered.connect(_grow.bind(node))
		node.mouse_exited.connect(_shrink.bind(node))
		node.focus_exited.connect(_shrink.bind(node))
		node.pressed.connect(_squash.bind(node))
		node.resized.connect(func(): node.pivot_offset = node.size * 0.5)


func _grow(button: Control) -> void:
	if button.is_inside_tree() and not (button is BaseButton and button.disabled):
		play("hover")
		_tween(button, Vector2.ONE * 1.05, 0.12)


func _shrink(button: Control) -> void:
	if button.is_inside_tree() and not button.has_focus():
		_tween(button, Vector2.ONE, 0.12)


func _squash(button: Control) -> void:
	play("click")
	button.scale = Vector2(1.12, 0.88)
	_tween(button, Vector2.ONE * 1.05, 0.25)


func _tween(control: Control, to: Vector2, seconds: float) -> void:
	control.pivot_offset = control.size * 0.5
	var tween := control.create_tween()
	tween.tween_property(control, "scale", to, seconds).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Pops a control in (scale from small with a bounce), after an optional delay: menus cascade in.
func pop_in(control: Control, delay := 0.0) -> void:
	control.pivot_offset = control.size * 0.5
	control.scale = Vector2(0.6, 0.6)
	control.modulate.a = 0.0
	var tween := control.create_tween().set_parallel()
	tween.tween_property(control, "scale", Vector2.ONE, 0.35).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(control, "modulate:a", 1.0, 0.2).set_delay(delay)


## Counts a label up from 0 to a number (results, coins).
func roll_up(label: Label, to: int, seconds := 0.8, format := "%d") -> void:
	var tween := label.create_tween()
	tween.tween_method(func(v: float): label.text = format % roundi(v), 0.0, float(to), seconds) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


## A burst of little gold coins from a point on screen (purchases, earnings).
func coin_burst(at: Vector2, count := 18) -> void:
	play("coin")
	for i in count:
		var coin := Label.new()
		coin.text = "●"
		coin.add_theme_color_override("font_color", YELLOW)
		coin.add_theme_font_size_override("font_size", randi_range(14, 26))
		coin.position = at
		coin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(coin)
		var angle := randf_range(-PI, 0.0)
		var distance := randf_range(60.0, 180.0)
		var tween := coin.create_tween().set_parallel()
		tween.tween_property(coin, "position", at + Vector2(cos(angle), sin(angle)) * distance + Vector2(0, 80), 0.8) \
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(coin, "modulate:a", 0.0, 0.8).set_delay(0.3)
		tween.chain().tween_callback(coin.queue_free)


# --- Transitions -------------------------------------------------------------------------------

## Changes scene behind a quick navy curtain with a whoosh.
func go(scene_path: String) -> void:
	if _busy:
		return
	_busy = true
	play("whoosh")
	_curtain.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween := create_tween()
	tween.tween_property(_curtain, "modulate:a", 1.0, 0.22)
	await tween.finished
	get_tree().change_scene_to_file(scene_path)
	await get_tree().process_frame
	var back := create_tween()
	back.tween_property(_curtain, "modulate:a", 0.0, 0.3)
	await back.finished
	_curtain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_busy = false
