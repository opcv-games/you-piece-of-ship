extends GutTest
## features/rudder.feature

const LevelScene = preload("res://scenes/levels/rocking_deck.tscn")
const RockScene = preload("res://scenes/greybox/rock.tscn")

var _level: Node3D
var _ship: Node3D
var _rudder: Node
var _hull: Node
var _handling: Node
var _crew: Array[Node] = []


func before_each() -> void:
	_level = LevelScene.instantiate()
	add_child_autofree(_level)
	_ship = _level.get_node("Ship")
	_ship.get_node("WaveMotion").intensity = 0.0
	_rudder = _ship.get_node("RudderSystem")
	_hull = _ship.get_node("HullSystem")
	_handling = _ship.get_node("ShipHandling")
	_crew = _level.get_tree().get_nodes_in_group("crew")
	for player in _crew:
		player.get_node("PlayerInput").enabled = false
	await wait_physics_frames(3)


func _hit(speed_fraction: float) -> void:
	var rock: Node3D = RockScene.instantiate()
	_level.add_child(rock)
	rock.global_position = _ship.to_global(Vector3(12, 0, 0))
	_handling.impact_speed = _handling.max_speed * speed_fraction
	_handling.rock_hit.emit(rock)


func test_given_hard_hit_then_wheel_shudders_then_rudder_damaged() -> void:
	_hit(0.9)
	assert_eq(_rudder.state, 1, "shuddering")
	assert_eq(_hull.open_breach_count(), 0, "hull not cracked by this impact")
	assert_false(_handling.turn_limits.has("rudder"), "steering still fine during the warning")
	await wait_seconds(5.3)
	assert_eq(_rudder.state, 2)
	assert_almost_eq(_handling.turn_factor(), 0.5, 0.01)
	assert_ne(_handling.rudder_offset, 0.0, "pulls to one side")


func test_given_slow_hit_then_hull_cracks_and_rudder_fine() -> void:
	_hit(0.3)
	assert_eq(_rudder.state, 0)
	assert_eq(_hull.open_breach_count(), 1)


func test_given_rudder_already_damaged_when_hard_hit_then_hull_cracks() -> void:
	_hit(0.9)
	_hull._last_rock = ""
	_hit(0.9)
	assert_eq(_hull.open_breach_count(), 1)


func test_given_damaged_rudder_when_pin_brought_to_helm_then_repaired() -> void:
	_rudder.try_damage(1.0)
	_rudder._warning_left = 0.0
	await wait_physics_frames(2)
	assert_eq(_rudder.state, 2)
	var player: Node3D = _crew[0]
	player.global_position = _ship.to_global(_ship.get_node("PinBox").position + Vector3(0, 0.05, 0))
	await wait_physics_frames(3)
	player.use_requested = true
	await wait_physics_frames(2)
	assert_eq(player.carried.kind, "pin")
	player.global_position = _ship.to_global(_ship.get_node("Helm").position + Vector3(0.3, 0.05, 0))
	await wait_physics_frames(3)
	player.use_requested = true
	await wait_physics_frames(2)
	assert_eq(_rudder.state, 0, "repaired")
	assert_null(player.carried, "pin used")
	assert_almost_eq(_handling.turn_factor(), 1.0, 0.01)
	assert_eq(_handling.rudder_offset, 0.0)


func test_given_damaged_rudder_and_nobody_steering_then_drifts_off_course() -> void:
	_rudder.try_damage(1.0)
	_rudder._warning_left = 0.0
	_handling.throttle = 1.0
	await wait_seconds(4.0)
	assert_gt(absf(_ship.rotation.y), 0.05)
