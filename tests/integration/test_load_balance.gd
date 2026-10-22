extends GutTest
## features/load_and_balance.feature

const LevelScene = preload("res://scenes/levels/rocking_deck.tscn")

var _level: Node3D
var _ship: Node3D
var _load: Node
var _waves: Node
var _handling: Node
var _crew: Array[Node] = []


func before_each() -> void:
	_level = LevelScene.instantiate()
	add_child_autofree(_level)
	_ship = _level.get_node("Ship")
	_waves = _ship.get_node("WaveMotion")
	_waves.intensity = 0.0
	_load = _ship.get_node("LoadSystem")
	_handling = _ship.get_node("ShipHandling")
	_crew = _level.get_tree().get_nodes_in_group("crew")
	for player in _crew:
		player.get_node("PlayerInput").enabled = false
	await wait_physics_frames(3)


func test_given_balanced_cargo_then_level() -> void:
	assert_almost_eq(_waves.list_sources["load"], 0.0, 0.001)


func test_given_cargo_moved_to_starboard_then_lists_to_starboard() -> void:
	var bay := _ship.get_node("CargoBay")
	for crate in _load.crates().slice(0, 2):
		bay.unlash(crate)
		crate.position = Vector3(crate.position.x, 0, 2.8)
		crate.lashed = true # hold it there for the test
	await wait_physics_frames(2)
	assert_gt(_waves.list_sources["load"], deg_to_rad(2.0), "heels toward starboard (+Z down)")


func test_given_big_wave_coming_then_rope_frays_and_crate_breaks_loose() -> void:
	watch_signals(_load)
	_waves.wave_warning_seconds = 0.5
	_waves.big_wave(1.0)
	assert_signal_emitted(_load, "rope_fraying")
	var crate: Node3D = get_signal_parameters(_load, "rope_fraying")[0]
	await wait_physics_frames(2)
	assert_not_null(crate.get_node_or_null("FrayLabel"), "warning shown on the crate")
	await wait_seconds(1.5)
	assert_signal_emitted(_load, "crate_loose")
	assert_false(crate.lashed, "broke loose")


func test_given_crate_carried_to_rail_when_use_then_overboard() -> void:
	var before: int = _load.cargo_value()
	var speed_before: float = _handling.top_speed()
	var player: Node3D = _crew[0]
	var crate: Node3D = _load.crates()[0]
	player.global_position = _ship.to_global(crate.position + Vector3(-0.9, 0.05, 0))
	await wait_physics_frames(3)
	player.use_requested = true
	await wait_physics_frames(2)
	assert_eq(player.carried, crate)
	player.global_position = _ship.to_global(Vector3(-3.0, 0.05, 2.9))
	await wait_physics_frames(3)
	player.use_requested = true
	await wait_physics_frames(3)
	assert_null(player.carried)
	assert_eq(_load.crates().size(), 5)
	assert_eq(_load.cargo_value(), before - 100)
	assert_gt(_handling.top_speed(), speed_before, "lighter, a bit faster")
