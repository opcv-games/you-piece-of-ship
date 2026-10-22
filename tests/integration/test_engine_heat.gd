extends GutTest
## features/engine_heat.feature

const LevelScene = preload("res://scenes/levels/reef_run.tscn")

var _level: Node3D
var _ship: Node3D
var _engine: Node
var _handling: Node
var _crew: Array[Node] = []


func before_each() -> void:
	_level = LevelScene.instantiate()
	add_child_autofree(_level)
	_ship = _level.get_node("Ship")
	_ship.get_node("WaveMotion").intensity = 0.0
	_engine = _ship.get_node("EngineSystem")
	_handling = _ship.get_node("ShipHandling")
	_crew = _level.get_tree().get_nodes_in_group("crew")
	for player in _crew:
		player.get_node("PlayerInput").enabled = false
	await wait_physics_frames(3)
	_engine.set_physics_process(false)


func _run(seconds: float) -> void:
	for i in int(seconds * 60.0):
		_engine.step(1.0 / 60.0)


func _place(player: Node3D, local: Vector3) -> void:
	player.global_position = _ship.to_global(local + Vector3(0, 0.05, 0))
	await wait_physics_frames(3)


func _use(player: Node3D) -> void:
	player.use_requested = true
	await wait_physics_frames(2)


func test_given_full_throttle_when_heat_passes_80_then_top_speed_capped() -> void:
	_handling.throttle = 1.0
	_run(10.0)
	assert_almost_eq(_handling.top_speed(), _handling.max_speed, 0.01, "not capped while cool")
	_run(10.0)
	assert_gt(_engine.heat, 0.8)
	assert_almost_eq(_handling.top_speed(), _handling.max_speed * _engine.heat_cap_speed, 0.01, "capped")


func test_given_heat_100_when_warning_ends_then_stalls_20_s_and_pipe_bursts() -> void:
	_handling.throttle = 1.0
	_engine.heat = 1.0
	_run(0.1)
	assert_true(_engine.is_warning(), "warning first")
	assert_false(_engine.is_stalled())
	_run(5.1)
	assert_true(_engine.is_stalled(), "stalled after the warning")
	assert_eq(_handling.top_speed(), 0.0)
	assert_true(_engine.is_pipe_burst(), "pipe burst")
	_run(20.5)
	assert_false(_engine.is_stalled(), "running again after 20 s")


func test_given_heat_100_when_engineer_vents_then_cools_and_bystander_knocked() -> void:
	await _place(_crew[3], _ship.get_node("Engine").position)
	await _use(_crew[3])
	assert_eq(_ship.get_node("Engine").occupant, _crew[3])
	await _place(_crew[1], _ship.get_node("Engine").position + Vector3(1.5, 0, -0.5))
	watch_signals(_crew[1])
	_handling.throttle = 1.0
	_engine.heat = 1.0
	_run(0.1)
	assert_true(_engine.is_warning())
	_crew[3].jump_requested = true # Jump at the engine = vent
	await wait_physics_frames(2)
	assert_lt(_engine.heat, 0.6, "vented")
	_run(6.0)
	assert_false(_engine.is_stalled(), "stall avoided")
	assert_signal_emitted(_crew[1], "knocked_down")
	assert_eq(_crew[3].knocked, 0.0, "the engineer holds on")


func test_given_no_coal_then_limps_and_shovelling_refills() -> void:
	_engine.fuel = 0.0
	_handling.throttle = 1.0
	_run(0.2)
	assert_almost_eq(_handling.top_speed(), _handling.max_speed * _engine.no_fuel_speed, 0.01)
	await _place(_crew[3], _ship.get_node("Engine").position)
	await _use(_crew[3])
	_crew[3].move_input = Vector2(0, -1)
	_engine.set_physics_process(true)
	await wait_seconds(2.0)
	assert_gt(_engine.fuel, 0.2, "coal shovelled in")


func test_given_water_in_hull_then_engine_heats_faster() -> void:
	_handling.throttle = 1.0
	_run(5.0)
	var dry: float = _engine.heat
	_engine.heat = 0.0
	_ship.get_node("HullSystem").water = 0.8
	_run(5.0)
	assert_gt(_engine.heat, dry * 1.4)


func test_given_burst_pipe_when_two_crew_fix_4_s_then_fixed() -> void:
	var pipe := _ship.get_node("CoolingPipe")
	pipe.break_it()
	await _place(_crew[0], pipe.position)
	await _use(_crew[0])
	await _place(_crew[1], pipe.position)
	await _use(_crew[1])
	assert_eq(pipe.occupants.size(), 2)
	await wait_seconds(4.3)
	assert_false(pipe.broken)


func test_given_nobody_at_engine_then_gauge_hidden_and_engineer_sees_it() -> void:
	var gauge: Control = _level.get_node("HUD/EngineGauge")
	await wait_physics_frames(2)
	assert_false(gauge.visible)
	await _place(_crew[3], _ship.get_node("Engine").position)
	await _use(_crew[3])
	await wait_physics_frames(2)
	assert_true(gauge.visible)
