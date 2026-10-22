extends Node3D
## Makes the engine's heat obvious to everyone, not just whoever reads the gauge (Olivier,
## 2026-10-22): the firebox door glows dull red → orange → red → white-hot, a light flickers on the
## deck, the chimney smoke thickens and darkens, the air shimmers above it, a big dial on the front
## shows the needle climbing into the red, and past 70% the whole engine rattles.
## A child of the Engine station; builds its own meshes so it survives art changes.

const SHIMMER = preload("res://assets/shaders/heat_shimmer.gdshader")
const STAGES := [
	[0.0, Color(0.35, 0.12, 0.05)], # cold: dull embers
	[0.45, Color(1.0, 0.45, 0.08)], # working: orange
	[0.8, Color(1.0, 0.12, 0.05)], # hot: red (top speed capped)
	[1.0, Color(1.0, 0.95, 0.85)], # white-hot: about to blow
]

@export var front := Vector3(0.0, 0.0, -0.42) ## the engine's deck-facing side, from its body centre
@export var body_centre := Vector3(0.0, 0.6, 0.85)
@export var chimney_top := Vector3(-0.4, 2.65, 0.85)

var heat := 0.0 ## shown value (follows the engine's heat smoothly)

var _engine: Node
var _door_material: StandardMaterial3D
var _light: OmniLight3D
var _smoke: CPUParticles3D
var _smoke_material: StandardMaterial3D
var _shimmer_material: ShaderMaterial
var _needle: Node3D
var _rattle_targets: Array[Node3D] = []
var _rattle_rest := {}
var _time := 0.0


func _ready() -> void:
	name = "HeatVisual"
	var station := get_parent()
	_engine = station.get_parent().get_node_or_null("EngineSystem")
	for child in station.get_children():
		# The engine's visible body (grey box or painted model) rattles when hot.
		if child is Node3D and child.visible and not (child is Label3D or child is CPUParticles3D):
			_rattle_targets.append(child)
			_rattle_rest[child] = child.position
	_build_door()
	_build_gauge()
	_build_light()
	_build_smoke()
	_build_shimmer()


func _build_door() -> void:
	var door := MeshInstance3D.new()
	door.name = "FireboxDoor"
	var quad := QuadMesh.new()
	quad.size = Vector2(0.62, 0.42)
	_door_material = StandardMaterial3D.new()
	_door_material.emission_enabled = true
	_door_material.albedo_color = Color(0.1, 0.05, 0.03)
	quad.material = _door_material
	door.mesh = quad
	door.position = body_centre + front + Vector3(0.32, -0.15, -0.005)
	door.rotation.y = PI # face the deck (-z)
	add_child(door)
	# A dark iron frame around the glowing door.
	var frame := MeshInstance3D.new()
	var frame_quad := QuadMesh.new()
	frame_quad.size = Vector2(0.76, 0.56)
	var iron := StandardMaterial3D.new()
	iron.albedo_color = Color(0.12, 0.11, 0.12)
	frame_quad.material = iron
	frame.mesh = frame_quad
	frame.position = door.position + Vector3(0, 0, 0.004)
	frame.rotation.y = PI
	add_child(frame)


func _build_gauge() -> void:
	var dial := MeshInstance3D.new()
	dial.name = "HeatDial"
	var disc := CylinderMesh.new()
	disc.top_radius = 0.24
	disc.bottom_radius = 0.24
	disc.height = 0.04
	var face := StandardMaterial3D.new()
	face.albedo_texture = _dial_texture()
	face.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	disc.material = face
	dial.mesh = disc
	dial.position = body_centre + front + Vector3(-0.38, 0.22, -0.02)
	dial.rotation = Vector3(-PI / 2.0, 0.0, 0.0) # flat face towards the deck
	add_child(dial)
	_needle = Node3D.new()
	_needle.name = "Needle"
	_needle.position = dial.position + Vector3(0, 0, -0.03)
	add_child(_needle)
	var stick := MeshInstance3D.new()
	var bar := BoxMesh.new()
	bar.size = Vector3(0.025, 0.2, 0.01)
	var black := StandardMaterial3D.new()
	black.albedo_color = Color(0.08, 0.06, 0.05)
	black.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bar.material = black
	stick.mesh = bar
	stick.position = Vector3(0, 0.09, 0)
	_needle.add_child(stick)


## A painted dial face: green, yellow and a red zone across the top arc.
func _dial_texture() -> ImageTexture:
	var size := 128
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var centre := Vector2(size, size) * 0.5
	for y in size:
		for x in size:
			var offset := Vector2(x, y) - centre
			var r := offset.length() / (size * 0.5)
			var color := Color(0, 0, 0, 0)
			if r <= 1.0:
				color = Color(0.98, 0.94, 0.84)
				if r > 0.88:
					color = Color(0.2, 0.14, 0.1)
				elif r > 0.62 and offset.y < size * 0.1:
					# The arc from -120° (cold) to +120° (hot), measured from straight up.
					var angle := rad_to_deg(atan2(offset.x, -offset.y))
					if absf(angle) <= 120.0:
						var t := (angle + 120.0) / 240.0
						color = Color(0.3, 0.75, 0.35) if t < 0.55 else (Color(1.0, 0.8, 0.2) if t < 0.8 else Color(0.9, 0.15, 0.1))
			image.set_pixel(x, y, color)
	return ImageTexture.create_from_image(image)


func _build_light() -> void:
	_light = OmniLight3D.new()
	_light.name = "FireLight"
	_light.position = body_centre + front * 2.5
	_light.omni_range = 2.6
	_light.light_energy = 0.0
	_light.shadow_enabled = false
	add_child(_light)


func _build_smoke() -> void:
	_smoke = CPUParticles3D.new()
	_smoke.name = "Smoke"
	_smoke.position = chimney_top
	_smoke.amount = 24
	_smoke.lifetime = 2.2
	_smoke.local_coords = false # the smoke trails behind the moving ship
	var puff := SphereMesh.new()
	puff.radius = 0.22
	puff.height = 0.44
	puff.radial_segments = 8
	puff.rings = 4
	_smoke_material = StandardMaterial3D.new()
	_smoke_material.albedo_color = Color(0.75, 0.75, 0.75, 0.7)
	_smoke_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_smoke_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	puff.material = _smoke_material
	_smoke.mesh = puff
	_smoke.direction = Vector3(0, 1, 0)
	_smoke.spread = 12.0
	_smoke.gravity = Vector3(0, 0.6, 0)
	_smoke.initial_velocity_min = 1.0
	_smoke.initial_velocity_max = 1.6
	var grow := Curve.new()
	grow.add_point(Vector2(0, 0.5))
	grow.add_point(Vector2(1, 2.2))
	_smoke.scale_amount_curve = grow
	add_child(_smoke)


func _build_shimmer() -> void:
	var haze := MeshInstance3D.new()
	haze.name = "Shimmer"
	var quad := QuadMesh.new()
	quad.size = Vector2(1.2, 1.8)
	_shimmer_material = ShaderMaterial.new()
	_shimmer_material.shader = SHIMMER
	quad.material = _shimmer_material
	haze.mesh = quad
	haze.position = chimney_top + Vector3(0, 0.9, 0)
	haze.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(haze) # the shader turns it to face the camera


## Glow colour for a heat level, blended between the stages.
static func glow_color(value: float) -> Color:
	for i in range(1, STAGES.size()):
		if value <= STAGES[i][0]:
			var t: float = (value - STAGES[i - 1][0]) / (STAGES[i][0] - STAGES[i - 1][0])
			return (STAGES[i - 1][1] as Color).lerp(STAGES[i][1], t)
	return STAGES[-1][1]


func _process(delta: float) -> void:
	if _engine == null:
		return
	_time += delta
	heat = move_toward(heat, _engine.heat, delta * 1.5)
	var stalled: bool = _engine.is_stalled()
	var glow := glow_color(heat)
	var flicker := 0.85 + 0.15 * sin(_time * 23.0) * sin(_time * 7.3)
	var burning := 0.0 if stalled else clampf(0.25 + _engine.fuel, 0.0, 1.0)
	_door_material.emission = glow
	_door_material.emission_energy_multiplier = (0.5 + heat * 1.6) * flicker * burning
	_light.light_color = glow
	_light.light_energy = (0.2 + heat * 1.1) * flicker * burning
	# Needle: -120° cold to +120° hot; shivers when hot.
	var shiver := sin(_time * 40.0) * 0.06 * maxf(0.0, heat - 0.75) * 4.0
	_needle.rotation.z = -deg_to_rad(-120.0 + 240.0 * heat) + shiver
	# Smoke: thin and pale when cool, thick and dark when hot; none while stalled.
	_smoke.emitting = not stalled and _engine.fuel > 0.02
	_smoke.speed_scale = 0.7 + heat * 0.9
	_smoke.scale_amount_min = 0.6 + heat * 0.8
	_smoke.scale_amount_max = _smoke.scale_amount_min * 1.3
	_smoke_material.albedo_color = Color(0.85, 0.85, 0.85, 0.55).lerp(Color(0.18, 0.16, 0.16, 0.85), heat)
	_shimmer_material.set_shader_parameter("strength", clampf((heat - 0.35) * 1.6, 0.0, 1.0))
	# Rattle: past 70% heat the engine shakes, harder as it nears the top.
	var shake := maxf(0.0, heat - 0.7) / 0.3 * 0.045
	for mesh in _rattle_targets:
		var rest: Vector3 = _rattle_rest[mesh]
		mesh.position = rest + Vector3(sin(_time * 53.0 + rest.x) * shake, absf(sin(_time * 41.0)) * shake,
				cos(_time * 47.0) * shake * 0.5)
