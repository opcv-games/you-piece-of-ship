extends MeshInstance3D
## The painted sea (assets/shaders/sea.gdshader): a finely divided plane that follows the ship,
## snapped to a 2 m grid so the waves don't swim. Also rolls the big swell for big waves.

const SEA_SHADER = preload("res://assets/shaders/sea.gdshader")

@export var size := 360.0
@export var subdivisions := 220 ## 220 x 220: plenty of wave detail, still light
@export var follow: Node3D
@export_range(0.0, 1.5) var wave_height := 0.32
@export_range(0.0, 3.0) var wave_speed := 1.0
@export_range(0.0, 2.0) var glints := 1.0

var _material: ShaderMaterial
var _swell_age := 100.0


func _ready() -> void:
	var plane := PlaneMesh.new()
	plane.size = Vector2(size, size)
	plane.subdivide_width = subdivisions
	plane.subdivide_depth = subdivisions
	_material = ShaderMaterial.new()
	_material.shader = SEA_SHADER
	plane.material = _material
	mesh = plane
	material_override = null
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_to_group("dev_tunable")
	set_meta("dev_group", "Sea")
	var sun := get_tree().get_first_node_in_group("sun") as DirectionalLight3D
	if sun:
		_material.set_shader_parameter("sun_direction", sun.global_basis.z)


func _process(delta: float) -> void:
	_swell_age += delta
	_material.set_shader_parameter("swell_age", _swell_age)
	_material.set_shader_parameter("wave_height", wave_height)
	_material.set_shader_parameter("wave_speed", wave_speed)
	_material.set_shader_parameter("glints", glints)
	if follow:
		var at := follow.global_position
		global_position = Vector3(snappedf(at.x, 2.0), 0.0, snappedf(at.z, 2.0))


## A big swell rolls in from one side toward a point (the ship), for the big-wave hazard.
func swell(toward: Vector3, from_side: Vector3, height := 1.6) -> void:
	var origin := toward - from_side.normalized() * 45.0
	_material.set_shader_parameter("swell_origin", Vector2(origin.x, origin.z))
	_material.set_shader_parameter("swell_direction", Vector2(from_side.x, from_side.z))
	_swell_age = 0.0
	_material.set_shader_parameter("swell_height", height)
