extends GutTest
## features/ai_crew.feature

const LevelScene = preload("res://scenes/levels/voyage.tscn")
const ContractLibrary = preload("res://scripts/contracts/contract_library.gd")
const RockScene = preload("res://scenes/greybox/rock.tscn")

var _level: Node3D
var _ship: Node3D
var _crew := {}


func before_each() -> void:
	_level = LevelScene.instantiate()
	_level.contract = ContractLibrary.reef_run()
	add_child_autofree(_level)
	_ship = _level.get_node("Ship")
	_ship.get_node("WaveMotion").intensity = 0.0
	_crew.clear()
	for player in _level.get_tree().get_nodes_in_group("crew"):
		player.get_node("PlayerInput").enabled = false
		_crew[player.player_index] = player
	await wait_physics_frames(2)


## A human (P1) takes the helm, so the AIs under test aren't pulled away to steer.
func _human_at_helm() -> void:
	await _place(_crew[1], _ship.get_node("Helm").position)
	_crew[1].use_requested = true
	await wait_physics_frames(3)


func _ai(index: int, primary: String, secondary := "") -> Node:
	return _level.add_ai(index, primary, secondary)


func _place(player: Node3D, local: Vector3) -> void:
	player.global_position = _ship.to_global(local + Vector3(0, 0.05, 0))
	await wait_physics_frames(3)


func test_given_human_at_helm_then_ai_with_helm_primary_does_its_secondary() -> void:
	await _place(_crew[1], _ship.get_node("Helm").position)
	_crew[1].use_requested = true
	await wait_physics_frames(3)
	_ai(2, "helm", "pump")
	_ship.get_node("HullSystem").water = 0.4
	await wait_seconds(1.0)
	assert_eq(_level.get_node("CrewBrain").job_of(_crew[2]), "pump")
	assert_eq(_ship.get_node("Helm").occupant, _crew[1], "the human keeps the helm")


func test_given_ai_at_engine_when_human_takes_it_then_ai_steps_aside() -> void:
	await _human_at_helm()
	_ai(4, "engine")
	await wait_seconds(4.0)
	assert_eq(_ship.get_node("Engine").occupant, _crew[4], "AI went to the engine")
	await _place(_crew[2], _ship.get_node("Engine").position + Vector3(0.6, 0, -0.4))
	_crew[2].use_requested = true
	await wait_physics_frames(3)
	assert_eq(_ship.get_node("Engine").occupant, _crew[2], "the human takes over")
	assert_null(_crew[4].station, "the AI let go")


func test_given_ai_engineer_then_shovels_low_coal_and_vents_hot_engine() -> void:
	await _human_at_helm()
	_ai(4, "engine")
	await wait_seconds(4.0)
	var engine := _ship.get_node("EngineSystem")
	engine.fuel = 0.3
	await wait_seconds(1.5)
	assert_gt(engine.fuel, 0.4, "shovelling")
	engine.heat = 0.95
	await wait_seconds(0.5)
	assert_lt(engine.heat, 0.6, "vented")


func test_given_leak_then_ai_carpenter_patches_it() -> void:
	await _human_at_helm()
	_ai(3, "carpenter")
	var hull := _ship.get_node("HullSystem")
	var breach: Node3D = hull.add_breach(Vector3(3, 0, 3))
	breach._warning_left = 0.0
	await wait_seconds(20.0)
	assert_eq(breach.state, 0, "patched")


func test_given_navigator_and_rock_ahead_then_calls_it_out() -> void:
	await _human_at_helm()
	var ai: Node = _ai(3, "navigator")
	var rock: Node3D = RockScene.instantiate()
	_level.add_child(rock)
	rock.global_position = _ship.to_global(Vector3(45, 0, 12))
	rock.global_position.y = 0.0
	await wait_seconds(6.0)
	var bubble: Label3D = _crew[3].get_node("Bubble")
	assert_string_contains(bubble.text, "o'clock")
	assert_true(_ship.get_node("MapTable").is_active(), "standing at the chart")


func test_given_navigator_with_carpenter_secondary_when_clear_sea_and_leak_then_patches() -> void:
	await _human_at_helm()
	_ai(3, "navigator", "carpenter")
	var breach: Node3D = _ship.get_node("HullSystem").add_breach(Vector3(3, 0, 3))
	breach._warning_left = 0.0
	await wait_seconds(1.0)
	assert_eq(_level.get_node("CrewBrain").job_of(_crew[3]), "carpenter", "no rocks near: fix the leak")


func test_given_ai_helm_then_ship_gets_under_way() -> void:
	_ai(2, "helm")
	await wait_seconds(8.0)
	assert_eq(_ship.get_node("Helm").occupant, _crew[2])
	assert_gt(_ship.get_node("ShipHandling").speed, 1.0)


func test_given_nobody_steering_then_any_ai_takes_the_helm() -> void:
	_ai(4, "engine")
	await wait_seconds(1.0)
	assert_eq(_level.get_node("CrewBrain").job_of(_crew[4]), "helm", "someone must always steer")


func test_given_ai_navigator_then_chart_stays_off_screen_and_rocks_are_called_out() -> void:
	await _human_at_helm()
	_ai(3, "navigator")
	await wait_seconds(5.0)
	assert_true(_ship.get_node("MapTable").is_active(), "the AI reads the chart")
	assert_false(_level.get_node("HUD/MapChart").visible, "but only a human reader puts it on screen")
