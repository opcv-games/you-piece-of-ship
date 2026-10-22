extends TextureRect
## Screen-edge flashes for alarms (juice): red on a crash, white-blue when a big wave is coming,
## orange when the engine stalls, a slow red pulse while the hold is more than half flooded.
## Only the edges light up, so the ship in the middle stays readable.

@export var ship: Node3D
@export var enabled := true

var _pulse := 0.0
var _color := Color.RED


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1, 1, 1, 0))
	gradient.set_color(1, Color(1, 1, 1, 1))
	gradient.set_offset(0, 0.55)
	var vignette := GradientTexture2D.new()
	vignette.gradient = gradient
	vignette.fill = GradientTexture2D.FILL_RADIAL
	vignette.fill_from = Vector2(0.5, 0.5)
	vignette.fill_to = Vector2(1.05, 1.05)
	texture = vignette
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_SCALE
	modulate.a = 0.0
	if ship:
		ship.get_node("ShipHandling").impact.connect(func(_r): flash(Color(1, 0.15, 0.1), 0.75))
		ship.get_node("WaveMotion").wave_warning.connect(func(_s): flash(Color(0.75, 0.9, 1.0), 0.5))
		ship.get_node("EngineSystem").stalled.connect(func(): flash(Color(1, 0.55, 0.1), 0.7))


func flash(color: Color, strength: float) -> void:
	if not enabled:
		return
	_color = color
	_pulse = maxf(_pulse, strength)


func _process(delta: float) -> void:
	_pulse = maxf(0.0, _pulse - delta * 1.4)
	var flooding := 0.0
	if ship and ship.get_node("HullSystem").water > 0.5:
		flooding = 0.25 + 0.15 * sin(Time.get_ticks_msec() / 1000.0 * TAU * 0.8)
		if _pulse <= 0.0:
			_color = Color(1, 0.15, 0.1)
	self_modulate = _color
	modulate.a = maxf(_pulse, flooding)
