extends GutTest
## features/contracts.feature

const LevelScene = preload("res://scenes/levels/voyage.tscn")
const ContractLibrary = preload("res://scripts/contracts/contract_library.gd")
const RockScene = preload("res://scenes/greybox/rock.tscn")

var _level: Node3D


func _load(contract: Resource) -> void:
	_level = LevelScene.instantiate()
	_level.contract = contract
	add_child_autofree(_level)
	for player in _level.get_tree().get_nodes_in_group("crew"):
		player.get_node("PlayerInput").enabled = false
	await wait_physics_frames(3)


func test_contracts_keep_their_save_slots_and_pay_rises_along_the_map() -> void:
	var titles := []
	for contract in ContractLibrary.all_contracts():
		titles.append(contract.title)
	assert_eq(titles.slice(0, 4), ["Maiden Voyage", "Reef Run", "The Narrows", "Fog Bank"], "old saves still match")
	var pay := []
	for ocean in load("res://scripts/systems/progress.gd").OCEANS:
		for index in ocean.routes:
			pay.append(ContractLibrary.by_index(index).pay_per_crate)
	for i in range(1, pay.size()):
		assert_gt(pay[i], pay[i - 1], "each route on the map pays more than the one before")


func test_given_maiden_voyage_then_lessons_happen_and_cannot_sink() -> void:
	await _load(ContractLibrary.maiden_voyage())
	var ship: Node3D = _level.get_node("Ship")
	var hint: Label = _level.get_node("HUD/Hint")
	await wait_physics_frames(2)
	assert_true(hint.visible, "welcome hint")
	ship.position.x = 365.0
	await wait_physics_frames(2)
	assert_eq(ship.get_node("HullSystem").open_breach_count(), 1, "leak lesson")
	assert_string_contains(hint.text, "PLANK")
	ship.position.x = 525.0
	await wait_physics_frames(2)
	assert_gte(ship.get_node("EngineSystem").heat, 0.8, "heat lesson")
	ship.position.x = 885.0
	await wait_physics_frames(2)
	assert_true(ship.get_node("RudderSystem").is_damaged(), "rudder lesson")
	var hull := ship.get_node("HullSystem")
	hull.elapsed += 1000.0
	hull.water = 1.0
	hull.step(0.1)
	assert_false(hull.sunk, "can't be lost")


func test_given_fog_bank_then_fog_short_chart_and_telescope() -> void:
	await _load(ContractLibrary.fog_bank())
	assert_true(_level.get_node("WorldEnvironment").environment.fog_enabled)
	assert_eq(_level.get_node("HUD/MapChart").range_metres, 30.0)
	var telescope := _level.get_node("Ship/Telescope")
	assert_true(telescope.enabled)
	assert_true(telescope.visible)


func test_given_crew_at_telescope_then_rocks_ahead_marked() -> void:
	await _load(ContractLibrary.fog_bank())
	var ship: Node3D = _level.get_node("Ship")
	var rock: Node3D = RockScene.instantiate()
	_level.add_child(rock)
	rock.global_position = ship.to_global(Vector3(60, 0, 3))
	rock.global_position.y = 0.0
	var behind: Node3D = RockScene.instantiate()
	_level.add_child(behind)
	behind.global_position = ship.to_global(Vector3(-40, 0, 0))
	var telescope := ship.get_node("Telescope")
	var player: Node3D = _level.get_tree().get_nodes_in_group("crew")[2]
	player.global_position = telescope.global_position
	await wait_physics_frames(3)
	player.use_requested = true
	await wait_seconds(0.8)
	assert_eq(telescope.occupant, player)
	var marker = rock.get_children().filter(func(c): return c.is_in_group("spot_markers"))
	assert_eq(marker.size(), 1, "rock ahead marked")
	assert_true(marker[0].visible)
	assert_eq(behind.get_children().filter(func(c): return c.is_in_group("spot_markers")).size(), 0, "not behind")


func test_given_reef_run_then_no_telescope() -> void:
	await _load(ContractLibrary.reef_run())
	assert_false(_level.get_node("Ship/Telescope").enabled)
	assert_false(_level.get_node("WorldEnvironment").environment.fog_enabled)


func test_given_maiden_voyage_then_crates_pay_its_rate() -> void:
	await _load(ContractLibrary.maiden_voyage())
	for crate in _level.get_tree().get_nodes_in_group("cargo"):
		assert_eq(crate.value, 60)


func test_given_maiden_voyage_then_never_runs_out_of_coal() -> void:
	await _load(ContractLibrary.maiden_voyage())
	var engine := _level.get_node("Ship/EngineSystem")
	engine.set_physics_process(false)
	_level.get_node("Ship/ShipHandling").throttle = 1.0
	engine.heat_rise = 0.0
	for i in 600 * 60:
		engine.step(1.0 / 60.0)
	assert_almost_eq(engine.fuel, 0.3, 0.001)
