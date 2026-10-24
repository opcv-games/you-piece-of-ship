extends Node3D
## The wake (Olivier, 2026-10-24: "acceleration is not obvious enough"). Foam trails spread in a V
## from the stern quarters and the propeller wash, and spray curls off the bow. Three steps of
## foam switch on one after another as the ship speeds up, so every notch of throttle shows.
## Child of the ship; the foam is left behind on the water (world space).

@export var tiers := [0.05, 0.4, 0.75] ## share of top speed at which each step of foam starts
@export var stern_x := -10.6
@export var bow_x := 14.0
@export var waterline := -0.75 ## ship-local height for the foam: just above the wave crests

var ratio := 0.0
var _handling: Node
var _emitters: Array = [] ## [CPUParticles3D, tier index]


func _ready() -> void:
	name = "Wake"
	_handling = get_parent().get_node("ShipHandling")
	var foam := _foam_mesh()
	for tier in tiers.size():
		for side in [-1.0, 1.0]:
			# The V: foam peels off the stern quarters and drifts outward.
			_add(Vector3(stern_x + 0.4, waterline, side * 3.0), Vector3(-0.6, 0.0, side * 0.8), foam, tier, 2.6 + tier)
		_add(Vector3(stern_x, waterline, 0.0), Vector3(-1.0, 0.0, 0.0), foam, tier, 3.0) # propeller wash
		for side in [-1.0, 1.0]:
			_add(Vector3(bow_x - 1.5, waterline + 0.2, side * 0.9), Vector3(0.2, 0.25, side * 1.0), foam, tier, 0.9) # bow spray


func _add(at: Vector3, direction: Vector3, mesh: Mesh, tier: int, life: float) -> void:
	var p := CPUParticles3D.new()
	p.position = at
	p.local_coords = false # the foam stays on the water behind us
	p.emitting = false
	p.amount = 40
	p.lifetime = life
	p.mesh = mesh
	p.direction = direction.normalized()
	p.spread = 14.0
	p.gravity = Vector3.ZERO
	p.initial_velocity_min = 0.6
	p.initial_velocity_max = 1.6
	p.damping_min = 0.4
	p.damping_max = 0.8
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 0.6
	var grow := Curve.new()
	grow.add_point(Vector2(0, 0.6))
	grow.add_point(Vector2(1, 2.4))
	p.scale_amount_curve = grow
	var fade := Gradient.new()
	fade.set_color(0, Color(1, 1, 1, 0.95))
	fade.set_color(1, Color(1, 1, 1, 0.0))
	p.color_ramp = fade
	add_child(p)
	_emitters.append([p, tier])


static func _foam_mesh() -> Mesh:
	var quad := PlaneMesh.new()
	quad.size = Vector2(1.8, 1.3)
	var white := StandardMaterial3D.new()
	white.vertex_color_use_as_albedo = true
	white.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	white.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	white.cull_mode = BaseMaterial3D.CULL_DISABLED
	white.render_priority = 5
	# A soft round blob instead of a square.
	var blob := GradientTexture2D.new()
	blob.fill = GradientTexture2D.FILL_RADIAL
	blob.fill_from = Vector2(0.5, 0.5)
	blob.fill_to = Vector2(1.0, 0.5)
	var edge := Gradient.new()
	edge.set_color(0, Color(1, 1, 1, 1))
	edge.add_point(0.55, Color(1, 1, 1, 0.8))
	edge.set_color(edge.get_point_count() - 1, Color(1, 1, 1, 0))
	blob.gradient = edge
	white.albedo_texture = blob # drawn after the (see-through) sea, or the sea hides it
	quad.material = white
	return quad


func _physics_process(_delta: float) -> void:
	ratio = clampf(absf(_handling.speed) / _handling.max_speed, 0.0, 1.0)
	for entry in _emitters:
		var p: CPUParticles3D = entry[0]
		p.emitting = ratio > tiers[entry[1]]
		p.speed_scale = 0.7 + ratio * 0.8
		p.scale_amount_min = 0.6 + ratio * 0.8
		p.scale_amount_max = 1.0 + ratio * 1.2
