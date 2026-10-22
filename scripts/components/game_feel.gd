extends Node
## Game feel ("juice") for moments that already exist: the crash, speed, jumps and arriving in port.
## Every effect has its own switch and strength, so each one can be kept or cut after a playtest.
## Rule: any effect that hides information (rocks, the chart, a crew member) gets cut.

@export var ship: Node3D
@export var camera: Camera3D
@export var banner: Control

@export_group("Crash")
@export var shake_enabled := true
@export_range(0.0, 1.0) var shake_strength := 0.7
@export var hitstop_enabled := true
@export_range(0, 300) var hitstop_ms := 80 ## the game nearly freezes this long on impact
@export var debris_enabled := true
@export_range(0, 200) var debris_amount := 40
@export var crash_pop_enabled := true

@export_group("Wake")
@export var wake_enabled := true
@export_range(0.0, 2.0) var wake_strength := 1.0

@export_group("Jumps")
@export var squash_enabled := true
@export_range(0.0, 0.6) var squash_strength := 0.25

@export_group("Big waves")
@export var wave_warning_enabled := true ## a sign and growing spray on the side the wave comes from
@export var wave_splash_enabled := true

@export_group("Port")
@export var confetti_enabled := true
@export_range(0, 400) var confetti_amount := 160

const CREW_COLORS := [Color(0.9, 0.25, 0.2), Color(0.2, 0.45, 0.95), Color(0.95, 0.8, 0.15), Color(0.25, 0.75, 0.3)]

var wake_ratio := 0.0 ## 0 = no foam (stopped) .. 1 = full foam (full speed)

var _handling: Node
var _wakes: Array[CPUParticles3D] = []


func _ready() -> void:
	_handling = ship.get_node("ShipHandling")
	_handling.rock_hit.connect(_on_rock_hit)
	var level := get_parent()
	if level.has_signal("port_reached"):
		level.port_reached.connect(_on_port_reached)
	for player in get_tree().get_nodes_in_group("crew"):
		player.jumped.connect(_on_jumped.bind(player))
		player.landed.connect(_on_landed.bind(player))
	var half_length: float = ship.deck_length * 0.5
	_wakes.append(_make_wake("BowWake", Vector3(half_length + 0.3, -1.0, 0.0), 0.4))
	_wakes.append(_make_wake("SternWake", Vector3(-half_length - 0.2, -1.0, 0.0), ship.deck_width * 0.35))
	var waves: Node = ship.get_node("WaveMotion")
	waves.wave_warning.connect(_on_wave_warning)
	waves.wave_struck.connect(_on_wave_struck)


func _exit_tree() -> void:
	Engine.time_scale = 1.0 # never leave the game frozen (e.g. restarting mid hit-stop)


func _physics_process(_delta: float) -> void:
	wake_ratio = 0.0
	if wake_enabled:
		wake_ratio = clampf(absf(_handling.speed) / _handling.max_speed * wake_strength, 0.0, 1.0)
	for wake in _wakes:
		# Faster ship = bigger, faster-spreading foam.
		wake.emitting = wake_ratio > 0.05
		wake.scale_amount_min = lerpf(0.3, 1.0, wake_ratio)
		wake.scale_amount_max = lerpf(0.5, 1.6, wake_ratio)
		wake.speed_scale = lerpf(0.6, 1.4, wake_ratio)


# --- Crash ------------------------------------------------------------------

func _on_rock_hit(rock: Node3D) -> void:
	if shake_enabled:
		camera.add_trauma(shake_strength)
	if debris_enabled and debris_amount > 0:
		var toward_ship := ship.global_position - rock.global_position
		toward_ship.y = 0.0
		var contact: Vector3 = rock.global_position + toward_ship.normalized() * rock.radius + Vector3(0, 0.3, 0)
		var chunks := _burst(contact, debris_amount, _box(Vector3(0.35, 0.15, 0.15), Color(0.45, 0.32, 0.22)),
				4.0, 8.0, 60.0, 18.0, 1.4)
		chunks.angular_velocity_min = -540.0
		chunks.angular_velocity_max = 540.0
		_burst(contact, debris_amount, _box(Vector3(0.22, 0.22, 0.22), Color(0.92, 0.97, 1.0)),
				6.0, 11.0, 35.0, 14.0, 1.0)
	if crash_pop_enabled:
		_pop(banner)
	if hitstop_enabled and hitstop_ms > 0:
		Engine.time_scale = 0.05
		# The timer ignores time scale, so it ends after real milliseconds.
		get_tree().create_timer(hitstop_ms / 1000.0, true, false, true).timeout.connect(
				Engine.set.bind("time_scale", 1.0))


func _pop(control: Control) -> void:
	control.pivot_offset = control.size * 0.5
	control.scale = Vector2.ONE * 1.8
	control.rotation = deg_to_rad(-6.0)
	var tween := control.create_tween().set_parallel()
	tween.tween_property(control, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(control, "rotation", 0.0, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# --- Wake -------------------------------------------------------------------

func _make_wake(wake_name: String, local_position: Vector3, half_width: float) -> CPUParticles3D:
	var wake := CPUParticles3D.new()
	wake.name = wake_name
	wake.position = local_position
	wake.amount = 80
	wake.lifetime = 1.6
	wake.local_coords = false # foam stays on the water as the ship sails on
	wake.mesh = _box(Vector3(0.5, 0.05, 0.5), Color(0.92, 0.97, 1.0))
	wake.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	wake.emission_box_extents = Vector3(0.3, 0.0, half_width)
	wake.direction = Vector3(0, 0, 1)
	wake.spread = 180.0
	wake.flatness = 1.0 # spread flat across the water
	wake.gravity = Vector3.ZERO
	wake.initial_velocity_min = 1.0
	wake.initial_velocity_max = 2.5
	wake.damping_min = 0.5
	wake.damping_max = 1.0
	wake.scale_amount_curve = _shrink_curve()
	wake.emitting = false
	ship.add_child(wake)
	return wake


# --- Big waves ----------------------------------------------------------------

func _on_wave_warning(side: float) -> void:
	if not wave_warning_enabled:
		return
	var waves: Node = ship.get_node("WaveMotion")
	var sign := Label3D.new()
	sign.text = tr("BIG WAVE!\nGrab a station!")
	sign.font_size = 96
	sign.outline_size = 18
	sign.modulate = Color(1.0, 0.9, 0.3)
	sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sign.no_depth_test = true
	sign.position = Vector3(0.0, 2.8, side * (ship.deck_width * 0.5 + 1.5))
	ship.add_child(sign)
	var tween := sign.create_tween().set_loops(int(waves.wave_warning_seconds / 0.5))
	tween.tween_property(sign, "scale", Vector3.ONE * 1.15, 0.25)
	tween.tween_property(sign, "scale", Vector3.ONE, 0.25)
	get_tree().create_timer(waves.wave_warning_seconds + 0.3).timeout.connect(sign.queue_free)


func _on_wave_struck(side: float) -> void:
	if not wave_splash_enabled:
		return
	# Spray bursts just outside the rail, so it reads as a wave without covering the deck.
	var outside := ship.to_global(Vector3(0.0, 0.0, side * (ship.deck_width * 0.5 + 1.2)))
	for x in [-6.0, 0.0, 6.0]:
		_burst(outside + ship.global_basis.x * x, debris_amount / 2, _box(Vector3(0.3, 0.3, 0.3), Color(0.92, 0.97, 1.0)),
				5.0, 8.0, 15.0, 14.0, 1.0)
	if shake_enabled:
		camera.add_trauma(shake_strength * 0.6)


# --- Jumps ------------------------------------------------------------------

func _on_jumped(player: Node3D) -> void:
	if squash_enabled:
		var s := squash_strength
		_squash(player, Vector3(1.0 - s * 0.6, 1.0 + s, 1.0 - s * 0.6))


func _on_landed(player: Node3D) -> void:
	if squash_enabled:
		var s := squash_strength
		_squash(player, Vector3(1.0 + s, 1.0 - s * 0.8, 1.0 + s))


func _squash(player: Node3D, shape: Vector3) -> void:
	var visual: Node3D = player.get_node("Visual")
	visual.scale = shape
	visual.create_tween().tween_property(visual, "scale", Vector3.ONE, 0.3) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# --- Port -------------------------------------------------------------------

func _on_port_reached() -> void:
	if not confetti_enabled or confetti_amount <= 0:
		return
	_pop(banner)
	var colors := Gradient.new()
	colors.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	colors.offsets = PackedFloat32Array([0.0, 0.25, 0.5, 0.75])
	colors.colors = PackedColorArray(CREW_COLORS)
	for side in [-3.0, 3.0]:
		var burst := _burst(ship.global_position + Vector3(side, 4.0, 0.0), confetti_amount / 2,
				_box(Vector3(0.22, 0.03, 0.14), Color.WHITE, true), 7.0, 12.0, 55.0, 5.0, 3.0)
		burst.color_initial_ramp = colors
		burst.angular_velocity_min = -720.0
		burst.angular_velocity_max = 720.0


# --- Helpers ----------------------------------------------------------------

## One-shot particle burst placed in the level (world space), freed when done.
func _burst(where: Vector3, count: int, mesh: Mesh, speed_min: float, speed_max: float,
		spread: float, fall: float, life: float) -> CPUParticles3D:
	var burst := CPUParticles3D.new()
	burst.one_shot = true
	burst.explosiveness = 0.9
	burst.amount = maxi(count, 1)
	burst.lifetime = life
	burst.mesh = mesh
	burst.direction = Vector3.UP
	burst.spread = spread
	burst.gravity = Vector3(0.0, -fall, 0.0)
	burst.initial_velocity_min = speed_min
	burst.initial_velocity_max = speed_max
	burst.scale_amount_curve = _shrink_curve()
	get_parent().add_child(burst)
	burst.global_position = where
	burst.emitting = true
	get_tree().create_timer(life + 0.5).timeout.connect(burst.queue_free)
	return burst


func _box(size: Vector3, color: Color, use_particle_color := false) -> BoxMesh:
	var mesh := BoxMesh.new()
	mesh.size = size
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.vertex_color_use_as_albedo = use_particle_color
	mesh.material = material
	return mesh


func _shrink_curve() -> Curve:
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 1.0))
	curve.add_point(Vector2(0.7, 0.8))
	curve.add_point(Vector2(1.0, 0.0))
	return curve
