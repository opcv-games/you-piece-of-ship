extends GutTest
## features/carry_and_drop.feature

const LevelScene = preload("res://scenes/levels/rocking_deck.tscn")

var _level: Node3D
var _ship: Node3D
var _waves: Node
var _crew: Array[Node] = []


func before_each() -> void:
	_level = LevelScene.instantiate()
	add_child_autofree(_level)
	_ship = _level.get_node("Ship")
	_waves = _ship.get_node("WaveMotion")
	_waves.intensity = 0.0 # calm sea unless a test tilts it
	_crew = _level.get_tree().get_nodes_in_group("crew")
	for player in _crew:
		player.get_node("PlayerInput").enabled = false
	await wait_physics_frames(3)


func _place(player: Node3D, local: Vector3) -> void:
	player.global_position = _ship.to_global(local + Vector3(0, 0.05, 0))
	player.velocity = Vector3.ZERO
	await wait_physics_frames(3)


func _use(player: Node3D) -> void:
	player.use_requested = true
	await wait_physics_frames(2)


func _take_plank(player: Node3D) -> Node3D:
	var box := _ship.get_node("PlankBox")
	await _place(player, box.position)
	await _use(player)
	return player.carried


func test_given_player_at_plank_box_when_use_then_carries_plank() -> void:
	var box := _ship.get_node("PlankBox")
	var stock: int = box.stock
	var plank := await _take_plank(_crew[0])
	assert_not_null(plank, "carrying something")
	assert_eq(plank.kind, "plank")
	assert_eq(box.stock, stock - 1)
	assert_gt(plank.global_position.y, _crew[0].global_position.y + 1.2, "held above the head")


func test_given_carrying_plank_when_use_in_open_deck_then_plank_on_deck() -> void:
	var player: Node3D = _crew[0]
	var plank := await _take_plank(player)
	await _place(player, Vector3(-3, 0, 1.5))
	await _use(player)
	assert_null(player.carried)
	assert_null(plank.carrier)
	var feet: Vector3 = _ship.to_local(player.global_position)
	assert_almost_eq(Vector2(plank.position.x, plank.position.z).distance_to(Vector2(feet.x, feet.z)), 0.0, 0.3, "at their feet")


func test_given_carrier_on_listing_deck_when_wave_knocks_down_then_plank_slides_low_side() -> void:
	var player: Node3D = _crew[0]
	var plank := await _take_plank(player)
	await _place(player, Vector3(-3, 0, 0.5))
	_waves.list_roll = deg_to_rad(-10.0) # starboard up, port (-z) low
	_waves.wave_warning_seconds = 0.2
	_waves.big_wave(1.0)
	await wait_seconds(1.5)
	assert_gt(player.knocked, -0.01, "knock happened")
	assert_null(player.carried, "plank dropped")
	await wait_seconds(1.5)
	assert_lt(plank.position.z, -1.5, "plank slid toward the low (port) side")


func test_given_player_at_helm_when_wave_hits_then_stays_up() -> void:
	var player: Node3D = _crew[0]
	await _place(player, _ship.get_node("Helm").position)
	await _use(player)
	assert_eq(player.station, _ship.get_node("Helm"))
	_waves.wave_warning_seconds = 0.1
	_waves.big_wave(1.0)
	await wait_seconds(1.5)
	assert_eq(player.knocked, 0.0, "braced at the helm")
	var walker: Node3D = _crew[3]
	assert_true(walker.knocked > 0.0 or walker.get_node("Visual").rotation.x == 0.0, "sanity")


func test_given_wave_when_it_hits_then_free_crew_fall() -> void:
	watch_signals(_crew[1])
	_waves.wave_warning_seconds = 0.1
	_waves.big_wave(-1.0)
	await wait_seconds(1.0)
	assert_signal_emitted(_crew[1], "knocked_down")


func test_given_carrying_pin_then_walks_about_half_speed() -> void:
	var player: Node3D = _crew[0]
	await _place(player, Vector3(-6, 0, 1.5))
	player.move_input = Vector2.RIGHT
	var start: Vector3 = _ship.to_local(player.global_position)
	await wait_seconds(1.0)
	var free_distance: float = _ship.to_local(player.global_position).x - start.x
	player.move_input = Vector2.ZERO
	await _place(player, _ship.get_node("PinBox").position)
	await _use(player)
	assert_eq(player.carried.kind, "pin")
	await _place(player, Vector3(-6, 0, 1.5))
	player.move_input = Vector2.RIGHT
	start = _ship.to_local(player.global_position)
	await wait_seconds(1.0)
	var pin_distance: float = _ship.to_local(player.global_position).x - start.x
	assert_almost_eq(pin_distance / free_distance, 0.5, 0.12)


func test_given_lashed_cargo_on_tilted_deck_then_stays_and_relashes_on_free_spot() -> void:
	var crates := _level.get_tree().get_nodes_in_group("cargo")
	assert_eq(crates.size(), 6, "six crates of cargo")
	_waves.list_roll = deg_to_rad(15.0)
	var before: Vector3 = crates[0].position
	await wait_seconds(1.0)
	assert_eq(crates[0].position, before, "lashed crates don't slide")
	var player: Node3D = _crew[0]
	await _place(player, crates[0].position + Vector3(-0.9, 0, 0))
	await _use(player)
	assert_eq(player.carried, crates[0], "picked up the nearest crate")
	assert_false(crates[0].lashed)
	await _use(player)
	assert_null(player.carried)
	assert_true(crates[0].lashed, "put back on a free spot and lashed")


func test_given_loose_crate_sliding_fast_when_reaching_player_then_knocks_down() -> void:
	var crates := _level.get_tree().get_nodes_in_group("cargo")
	var crate: Node3D = crates[0]
	var bay := _ship.get_node("CargoBay")
	bay.unlash(crate)
	crate.position = Vector3(-4, 0, 1.5)
	var player: Node3D = _crew[0]
	await _place(player, Vector3(-4, 0, -1.0))
	watch_signals(player)
	crate.velocity = Vector2(0, -6)
	await wait_seconds(1.0)
	assert_signal_emitted(player, "knocked_down")
