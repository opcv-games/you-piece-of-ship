extends GutTest
## features/obstacles.feature — wrecks, whales, sirens and atolls behave as described.

const LevelScene = preload("res://scenes/levels/voyage.tscn")
const ContractLibrary = preload("res://scripts/contracts/contract_library.gd")

var _level: Node3D
var _ship: Node3D


func before_each() -> void:
	_level = LevelScene.instantiate()
	_level.contract = ContractLibrary.maiden_voyage()
	add_child_autofree(_level)
	_ship = _level.get_node("Ship")
	for player in _level.get_tree().get_nodes_in_group("crew"):
		player.get_node("PlayerInput").enabled = false
	await wait_physics_frames(2)


func test_a_diving_whale_is_not_solid() -> void:
	var whale: Node3D = _level._spawn_ahead("whale")
	assert_true(whale.is_solid())
	whale._dive_clock = whale.surfaced_seconds + 0.1
	await wait_physics_frames(2)
	assert_false(whale.is_solid(), "under the keel")


func test_the_whale_swims_across_the_channel() -> void:
	var whale: Node3D = _level._spawn_ahead("whale")
	var start: float = whale.position.z
	await wait_seconds(2.0)
	assert_ne(whale.position.z, start)
	assert_almost_eq(whale.position.x, whale.home.x, 0.01, "it crosses, it doesn't follow the ship")


func test_the_siren_pulls_the_wheel_toward_her() -> void:
	var siren: Node3D = _level._spawn_ahead("siren")
	siren.position = _ship.global_position + Vector3(20, 0, 12) # ahead, to starboard
	siren.position.y = 0.0
	await wait_physics_frames(3)
	var handling := _ship.get_node("ShipHandling")
	var pull: float = handling.lures[siren.get_instance_id()]
	assert_lt(pull, 0.0, "the wheel is pulled to starboard, toward her")
	siren.position = _ship.global_position + Vector3(200, 0, 12)
	await wait_physics_frames(3)
	assert_eq(handling.lures[siren.get_instance_id()], 0.0, "far away: no pull")


func test_every_kind_has_a_model_and_a_call_name() -> void:
	for kind in ["rock", "wreck", "whale", "siren", "atoll"]:
		var thing: Node3D = _level._spawn_ahead(kind)
		assert_not_null(thing.get_node_or_null("Model"), kind)
		assert_ne(thing.call_name(), "")


func test_the_navigator_names_what_it_sees() -> void:
	var ai: Node = _level.add_ai(3, "navigator")
	var wreck: Node3D = _level._spawn_ahead("wreck")
	wreck.position = _ship.global_position + Vector3(40, 0, 0)
	wreck.position.y = 0.0
	assert_string_contains(ai.callout(), "Wreck")
