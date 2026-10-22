extends GutTest
## features/hull_breach.feature

const LevelScene = preload("res://scenes/levels/rocking_deck.tscn")
const RockScene = preload("res://scenes/greybox/rock.tscn")

var _level: Node3D
var _ship: Node3D
var _hull: Node
var _handling: Node
var _crew: Array[Node] = []


func before_each() -> void:
	_level = LevelScene.instantiate()
	add_child_autofree(_level)
	_ship = _level.get_node("Ship")
	_ship.get_node("WaveMotion").intensity = 0.0
	_hull = _ship.get_node("HullSystem")
	_handling = _ship.get_node("ShipHandling")
	_crew = _level.get_tree().get_nodes_in_group("crew")
	for player in _crew:
		player.get_node("PlayerInput").enabled = false
	await wait_physics_frames(3)


func _open_breach(local := Vector3(3, 0, 3)) -> Node3D:
	var breach: Node3D = _hull.add_breach(local)
	breach.warning_seconds = 0.0
	breach._warning_left = 0.0
	await wait_physics_frames(2)
	return breach


func _place(player: Node3D, local: Vector3) -> void:
	player.global_position = _ship.to_global(local + Vector3(0, 0.05, 0))
	await wait_physics_frames(3)


func _use(player: Node3D) -> void:
	player.use_requested = true
	await wait_physics_frames(2)


func test_given_rock_hit_then_nearest_leak_cracks_with_warning() -> void:
	var rock: Node3D = RockScene.instantiate()
	_level.add_child(rock)
	rock.global_position = _ship.to_global(Vector3(8, 0, 4))
	_handling.rock_hit.emit(rock)
	var breach: Node3D = _ship.get_node("Leak5") # bow starboard spot
	assert_eq(breach.state, 1, "cracking first")
	assert_eq(breach.flow(), 0.0, "no water during the warning")
	await wait_seconds(5.3)
	assert_eq(breach.state, 2, "open after the warning")
	assert_eq(breach.flow(), 1.0)


func test_given_open_breach_when_20_seconds_pass_then_water_rises_and_top_speed_drops() -> void:
	await _open_breach()
	var before: float = _handling.top_speed()
	_hull.set_physics_process(false)
	for i in 20 * 60:
		_hull.step(1.0 / 60.0)
	assert_gt(_hull.water, 0.2, "water rose")
	assert_lt(_handling.top_speed(), before * 0.92, "slower")


func test_given_patched_breach_and_flooded_ship_when_pumped_then_top_speed_recovers() -> void:
	var breach := await _open_breach()
	_hull.water = 0.6
	_hull.step(0.016)
	var flooded_speed: float = _handling.top_speed()
	breach._seal()
	await _place(_crew[0], _ship.get_node("Pump").position)
	await _use(_crew[0])
	assert_eq(_ship.get_node("Pump").occupant, _crew[0], "pumping")
	_hull.set_physics_process(false)
	for i in 15 * 60:
		_hull.step(1.0 / 60.0)
	assert_almost_eq(_hull.water, 0.0, 0.001, "pumped dry")
	assert_gt(_handling.top_speed(), flooded_speed)
	assert_almost_eq(_handling.top_speed(), _handling.max_speed, 0.01, "full speed again")


func test_given_plank_on_breach_when_two_crew_hammer_then_sealed_in_4_seconds() -> void:
	var breach := await _open_breach()
	var box := _ship.get_node("PlankBox")
	await _place(_crew[0], box.position)
	await _use(_crew[0])
	assert_eq(_crew[0].carried.kind, "plank")
	await _place(_crew[0], breach.position)
	await _use(_crew[0])
	assert_true(breach.has_plank, "plank placed")
	assert_eq(breach.occupants.size(), 1, "placing it starts hammering")
	await _place(_crew[1], breach.position)
	await _use(_crew[1])
	assert_eq(breach.occupants.size(), 2, "a second crew member joins")
	await wait_seconds(4.3)
	assert_eq(breach.state, 0, "sealed")
	assert_null(_crew[0].station, "hammerers are released")


func test_given_plank_on_breach_when_one_crew_hammers_4_seconds_then_not_yet_sealed() -> void:
	var breach := await _open_breach()
	breach.has_plank = true
	await _place(_crew[0], breach.position)
	await _use(_crew[0])
	await wait_seconds(4.3)
	assert_ne(breach.state, 0, "still leaking")
	assert_between(breach.progress, 0.3, 0.45, "about a third done")


func test_given_open_breach_when_crate_stuffed_in_then_flow_drops_and_cargo_lost() -> void:
	var breach := await _open_breach(Vector3(3, 0, 3))
	var crates := _level.get_tree().get_nodes_in_group("cargo")
	var crate: Node3D = crates[0]
	await _place(_crew[0], crate.position + Vector3(-0.9, 0, 0))
	await _use(_crew[0])
	assert_eq(_crew[0].carried, crate)
	await _place(_crew[0], breach.position)
	await _use(_crew[0])
	assert_true(breach.is_plugged)
	assert_almost_eq(breach.flow(), 0.3, 0.001)
	await wait_physics_frames(2)
	assert_eq(_level.get_tree().get_nodes_in_group("cargo").size(), 5, "that cargo is lost")


func test_given_recent_first_leak_then_cannot_sink_but_later_sinks() -> void:
	await _open_breach()
	watch_signals(_hull)
	_hull.set_physics_process(false)
	_hull.water = 0.99
	_hull.step(1.0)
	assert_false(_hull.sunk, "within 60 s of the first failure")
	assert_lte(_hull.water, 0.95)
	_hull.elapsed = _hull.first_failure_at + 61.0
	_hull.water = 0.99
	_hull.step(1.0)
	assert_true(_hull.sunk)
	assert_signal_emitted(_hull, "ship_sunk")


func test_given_starboard_leaks_when_water_comes_in_then_ship_heels_to_starboard() -> void:
	await _open_breach(Vector3(3, 0, 3))
	await _open_breach(Vector3(8, 0, 3))
	_hull.water = 0.6
	await wait_seconds(2.0)
	# Positive roll lowers starboard (+Z).
	assert_gt(_ship.get_node("WaveMotion").total_list(), 0.02)


func test_given_same_rock_bumped_twice_quickly_then_only_one_leak() -> void:
	var rock: Node3D = RockScene.instantiate()
	_level.add_child(rock)
	rock.global_position = _ship.to_global(Vector3(10, 0, 0))
	_handling.rock_hit.emit(rock)
	await wait_seconds(2.0)
	_handling.rock_hit.emit(rock)
	assert_eq(_hull.open_breach_count(), 1)
