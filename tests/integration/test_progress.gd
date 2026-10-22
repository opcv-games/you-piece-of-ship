extends GutTest
## features/progression.feature — oceans, routes, stars that open them, hats, new trouble.

const ContractLibrary = preload("res://scripts/contracts/contract_library.gd")
const Progress = preload("res://scripts/systems/progress.gd")
const MapScene = preload("res://scenes/ui/world_map.tscn")
const LevelScene = preload("res://scenes/levels/voyage.tscn")

var _saved := {}


func before_each() -> void:
	_saved = {"stars": Session.stars.duplicate(), "hats": Session.hats.duplicate(), "seen": Session.seen_oceans.duplicate(),
			"all": Session.unlock_everything}
	Session.stars = {}
	Session.hats = {}
	Session.seen_oceans = [0]
	Session.unlock_everything = false


func after_each() -> void:
	Session.stars = _saved.stars
	Session.hats = _saved.hats
	Session.seen_oceans = _saved.seen
	Session.unlock_everything = _saved.all


func test_three_oceans_of_three_routes_cover_every_contract() -> void:
	var seen := []
	for ocean in Progress.OCEANS:
		assert_eq(ocean.routes.size(), 3)
		seen.append_array(ocean.routes)
	seen.sort()
	assert_eq(seen, range(ContractLibrary.all_contracts().size()), "every contract is on the map once")


func test_stars_open_routes() -> void:
	assert_true(Session.is_open(0), "the Maiden Voyage is always open")
	assert_false(Session.is_open(4))
	Session.stars["0"] = 1
	assert_true(Session.is_open(4), "one star opens Coral Hop")
	assert_false(Session.is_open(5), "Whale Waters needs more stars")
	Session.stars = {"0": 3, "4": 2}
	assert_true(Session.is_open(5))
	Session.unlock_everything = true
	assert_true(Session.is_open(8))


func test_hats_unlock_with_stars() -> void:
	assert_false(Progress.hats_unlocked(0).has("captain"))
	assert_true(Progress.hats_unlocked(6).has("captain"))
	assert_true(Progress.hats_unlocked(15).has("crown"))
	assert_eq(Session.outfit_for(2), "bandana", "default hat")
	Session.hats["2"] = "crown"
	assert_eq(Session.outfit_for(2), "bandana", "a locked hat can't be worn")
	Session.stars = {"0": 3, "1": 3, "2": 3, "3": 3, "4": 3}
	assert_eq(Session.outfit_for(2), "crown")


func test_the_map_sails_only_to_open_routes_and_announces_a_new_ocean() -> void:
	Session.stars = {"0": 3, "4": 2}
	var map: Control = MapScene.instantiate()
	add_child_autofree(map)
	await wait_physics_frames(2)
	assert_true(map._popup.visible, "Whale Waters just opened: announce it")
	assert_has(Session.seen_oceans, 1)
	map.select(8)
	assert_false(map.set_sail(), "Kraken's Gate is still locked")
	map.select(5)
	assert_true(map.set_sail())
	assert_eq(Session.contract_index, 5)


func test_new_trouble_cargo_shift_no_sail_and_storm() -> void:
	var level: Node3D = LevelScene.instantiate()
	level.contract = ContractLibrary.krakens_gate()
	add_child_autofree(level)
	await wait_physics_frames(2)
	assert_not_null(level.get_node("Ship").get_node_or_null("Rain"), "a storm brings rain")
	level._shift_cargo()
	var loose := 0
	for crate in get_tree().get_nodes_in_group("cargo"):
		if not crate.lashed:
			loose += 1
	assert_gt(loose, 0, "the cargo shifted")
	var smugglers: Node3D = LevelScene.instantiate()
	smugglers.contract = ContractLibrary.smugglers_run()
	add_child_autofree(smugglers)
	await wait_physics_frames(2)
	assert_eq(smugglers.get_node("Ship/ShipHandling").sail_speed, 0.0, "no sail: no minimum speed")
