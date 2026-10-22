extends Node
## Rocks its parent like a ship on a swell: roll (side to side), pitch (bow up and down)
## and heave (the whole ship rising and falling).
## The pose is pure maths from time, so it is predictable for players and, later,
## identical on every networked screen. Serves Comedy (stumbles) without being a physics sim.

@export_range(0.0, 3.0, 0.05) var intensity := 1.0 ## 0 = flat calm, 1 = normal swell
@export_range(0.0, 30.0, 0.5) var roll_degrees := 8.0
@export var roll_period := 6.0 ## seconds for one full side-to-side rock
@export_range(0.0, 15.0, 0.5) var pitch_degrees := 3.0
@export var pitch_period := 4.3
@export var heave_metres := 0.3
@export var heave_period := 5.1

var _time := 0.0
var _rest_position := Vector3.ZERO
var _parent: Node3D


func _ready() -> void:
	_parent = get_parent() as Node3D
	if _parent:
		_rest_position = _parent.position


func _physics_process(delta: float) -> void:
	if _parent == null:
		return
	_time += delta
	var pose := sample(_time)
	# The bow points along +X, so roll turns around X and pitch around Z.
	_parent.rotation = Vector3(pose.roll, _parent.rotation.y, pose.pitch)
	_parent.position = _rest_position + Vector3(0.0, pose.heave, 0.0)


## Returns {roll, pitch} in radians and {heave} in metres at time t (seconds).
func sample(t: float) -> Dictionary:
	return {
		"roll": deg_to_rad(roll_degrees) * intensity * sin(TAU * t / roll_period),
		"pitch": deg_to_rad(pitch_degrees) * intensity * sin(TAU * t / pitch_period + 1.0),
		"heave": heave_metres * intensity * sin(TAU * t / heave_period + 2.0),
	}
