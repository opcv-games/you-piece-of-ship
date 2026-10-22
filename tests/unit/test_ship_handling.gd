extends GutTest
## features/station_information.feature — helm handling and hitting a hidden rock

const ShipHandling = preload("res://scripts/components/ship_handling.gd")
const RockScene = preload("res://scenes/greybox/rock.tscn")

var _ship: Node3D
var _handling: Node


func before_each() -> void:
	_ship = Node3D.new()
	_handling = ShipHandling.new()
	_ship.add_child(_handling)
	add_child_autofree(_ship)
	_handling.set_physics_process(false) # drive it by hand with step()


func _sail(seconds: float) -> void:
	for i in int(seconds * 60.0):
		_handling.step(1.0 / 60.0)


func test_given_full_throttle_when_time_passes_then_ship_sails_toward_bow() -> void:
	_handling.throttle = 1.0
	_sail(5.0)
	assert_gt(_ship.position.x, 5.0, "moved forward (bow is +X)")
	assert_almost_eq(_ship.position.z, 0.0, 0.01, "straight ahead")


func test_given_wheel_to_port_when_sailing_then_bow_turns_port() -> void:
	_handling.throttle = 1.0
	_sail(3.0)
	_handling.rudder = 1.0
	_sail(3.0)
	assert_gt(_ship.rotation.y, 0.1, "yawed to port")
	assert_lt(_ship.position.z, -0.5, "drifting to port side (-Z)")


func test_given_ship_stopped_when_wheel_turned_then_ship_does_not_spin() -> void:
	_handling.rudder = 1.0
	_sail(2.0)
	assert_almost_eq(_ship.rotation.y, 0.0, 0.0001)


func test_given_rock_ahead_when_hull_reaches_it_then_ship_stops_and_rock_revealed() -> void:
	var rock: Node3D = RockScene.instantiate()
	rock.position = Vector3(25, 0, 0)
	add_child_autofree(rock)
	watch_signals(_handling)
	_handling.throttle = 1.0
	_sail(8.0)
	assert_signal_emitted(_handling, "rock_hit")
	assert_true(rock.revealed, "rock revealed after the hit")
	assert_lt(_ship.position.x, 25.0 - rock.radius - _handling.hull_half_length + 0.5, "the hull did not sail through the rock")


func test_given_rock_to_the_side_when_sailing_past_then_no_hit() -> void:
	var rock: Node3D = RockScene.instantiate()
	rock.position = Vector3(25, 0, 9)
	add_child_autofree(rock)
	watch_signals(_handling)
	_handling.throttle = 1.0
	_sail(8.0)
	assert_signal_not_emitted(_handling, "rock_hit")
	assert_false(rock.revealed)


func test_given_rock_dead_ahead_when_hit_then_ship_glances_off_and_gets_past() -> void:
	var rock: Node3D = RockScene.instantiate()
	rock.position = Vector3(25, 0, 0.3)
	add_child_autofree(rock)
	_handling.throttle = 1.0
	_sail(40.0)
	assert_gt(_ship.position.x, 30.0, "a straight course doesn't stay stuck on the rock")


func test_given_throttle_pulled_below_zero_then_ship_backs_off() -> void:
	_handling.throttle = -_handling.max_reverse
	_sail(5.0)
	assert_lt(_ship.position.x, -2.0, "going astern")
	assert_lt(_handling.speed, 0.0)
