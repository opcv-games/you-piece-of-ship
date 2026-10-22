extends Node
## Arcade sailing: the throttle sets speed, the wheel turns the bow. Moves its parent ship
## along the sea (yaw and travel only; WaveMotion owns roll, pitch and heave).
## Only the crew member at the helm can drive it: the captain's job (Social, Thrill of danger).

signal rock_hit(rock: Node3D)

@export var helm: Node3D ## the station the captain uses
@export var max_speed := 6.0 ## metres per second at full throttle
@export var acceleration := 1.2 ## metres per second gained each second
@export var turn_rate_degrees := 14.0 ## degrees per second at full wheel and full speed
@export var min_turn_factor := 0.35 ## a slow ship still turns a little, so you can steer off a rock
@export var throttle_rate := 0.5 ## throttle change per second while holding up or down
@export var hull_half_length := 9.0
@export var hull_half_width := 3.5
@export var impact_pushback := 2.5 ## metres the ship bounces back off a rock
@export var impact_cooldown := 1.5 ## seconds before the next rock can hit

var throttle := 0.0 ## 0..1
var rudder := 0.0 ## -1 = full starboard (right), +1 = full port (left)
var speed := 0.0

var _ship: Node3D
var _cooldown := 0.0


func _ready() -> void:
	_ship = get_parent() as Node3D


func _physics_process(delta: float) -> void:
	_read_helm(delta)
	step(delta)
	_update_helm_label()


func _read_helm(delta: float) -> void:
	var captain: Node3D = helm.occupant if helm else null
	if captain == null:
		rudder = 0.0 # nobody at the wheel: it springs back, but the engine keeps going
		return
	rudder = -captain.move_input.x
	throttle = clampf(throttle - captain.move_input.y * throttle_rate * delta, 0.0, 1.0)


func _update_helm_label() -> void:
	if helm:
		helm.status_text = "throttle %d%%" % roundi(throttle * 100.0)


## Direction the bow points, flat on the sea.
func forward() -> Vector3:
	var yaw := _ship.rotation.y
	return Vector3(cos(yaw), 0.0, -sin(yaw))


func step(delta: float) -> void:
	speed = move_toward(speed, throttle * max_speed, acceleration * delta)
	if speed > 0.05:
		var turn_factor := maxf(speed / max_speed, min_turn_factor)
		_ship.rotation.y += deg_to_rad(turn_rate_degrees) * rudder * turn_factor * delta
	_ship.position += forward() * speed * delta
	_cooldown = maxf(0.0, _cooldown - delta)
	if _cooldown == 0.0:
		_check_rocks()


func _check_rocks() -> void:
	var fwd := forward()
	var right := Vector3(-fwd.z, 0.0, fwd.x)
	for rock in get_tree().get_nodes_in_group("rocks"):
		var offset: Vector3 = rock.global_position - _ship.global_position
		var along := offset.dot(fwd)
		var across := offset.dot(right)
		# Closest point of the (rectangular) hull to the rock, in the ship's flat frame.
		var closest := Vector2(clampf(along, -hull_half_length, hull_half_length),
				clampf(across, -hull_half_width, hull_half_width))
		if Vector2(along, across).distance_to(closest) < rock.radius:
			_hit(rock)
			return


func _hit(rock: Node3D) -> void:
	speed = 0.0
	_ship.position -= forward() * impact_pushback
	_cooldown = impact_cooldown
	rock.reveal()
	rock_hit.emit(rock)
