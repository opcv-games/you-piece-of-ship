extends Node
## Rudder damage (DESIGN.md section 13). A hard impact (above half speed) damages the rudder
## instead of the hull, so one impact starts at most one new failure. Warning first: the wheel
## shudders for 5 s. Then steering response halves and the wheel pulls to one side, even with
## nobody at the helm. Fix: carry the heavy rudder pin to the helm and press Use.
## Turning still scales with speed, so the throttle stays a (clumsy) way to steer.

signal warning_started
signal damaged
signal repaired

@export_range(0.0, 1.0) var damage_speed := 0.5 ## impacts faster than this share of top speed hit the rudder
@export var warning_seconds := 5.0
@export_range(0.0, 1.0) var damaged_response := 0.5
@export_range(0.0, 1.0) var pull := 0.35 ## how hard the broken rudder pulls the wheel

var state := 0 ## 0 = intact, 1 = shuddering (warning), 2 = damaged
var pull_side := 1.0

var _warning_left := 0.0
var _time := 0.0
var _handling: Node
var _helm: Node3D
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	var ship := get_parent()
	_handling = ship.get_node("ShipHandling")
	_helm = ship.get_node("Helm")
	_rng.seed = 11


func is_damaged() -> bool:
	return state != 0


## Called by the hull when the ship hits something. Returns true if the rudder took this impact.
func try_damage(speed_fraction: float) -> bool:
	if state != 0 or speed_fraction <= damage_speed:
		return false
	state = 1
	_warning_left = warning_seconds
	pull_side = 1.0 if _rng.randf() < 0.5 else -1.0
	warning_started.emit()
	return true


func repair() -> void:
	state = 0
	_handling.turn_limits.erase("rudder")
	_handling.rudder_offset = 0.0
	_wheel_wobble(0.0)
	repaired.emit()


func _physics_process(delta: float) -> void:
	_time += delta
	if state == 1:
		_warning_left -= delta
		_wheel_wobble(sin(_time * 40.0) * 0.25)
		if _warning_left <= 0.0:
			state = 2
			damaged.emit()
	elif state == 2:
		_handling.turn_limits["rudder"] = damaged_response
		_handling.rudder_offset = pull * pull_side
		_wheel_wobble(sin(_time * 3.0) * 0.15 + pull_side * 0.4)
	_helm.status_text = _status()


func _status() -> String:
	var throttle := "throttle %d%%" % roundi(_handling.throttle * 100.0)
	match state:
		1:
			return "WHEEL SHUDDERS! %d\n%s" % [ceili(_warning_left), throttle]
		2:
			return "RUDDER BROKEN: bring the pin\n%s" % throttle
	return throttle


func _wheel_wobble(angle: float) -> void:
	var wheel := _helm.get_node_or_null("Wheel") as Node3D
	if wheel:
		wheel.rotation.x = angle
