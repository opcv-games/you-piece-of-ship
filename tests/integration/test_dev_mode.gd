extends GutTest
## features/dev_mode.feature — Esc opens the pause menu; its Developer panel tunes and forces events.

const LevelScene = preload("res://scenes/levels/voyage.tscn")
const ContractLibrary = preload("res://scripts/contracts/contract_library.gd")

var _level: Node3D
var _menu: CanvasLayer


func before_each() -> void:
	_level = LevelScene.instantiate()
	_level.contract = ContractLibrary.reef_run()
	add_child_autofree(_level)
	_menu = _level.get_node("PauseMenu")
	_menu.presets_path = "user://test_dev_presets.json"
	for player in _level.get_tree().get_nodes_in_group("crew"):
		player.get_node("PlayerInput").enabled = false
	await wait_physics_frames(2)


func after_each() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://test_dev_presets.json"))


func test_esc_pauses_and_developer_keeps_the_game_running() -> void:
	_menu.toggle()
	assert_true(_menu.is_open())
	assert_true(get_tree().paused, "offline: the pause menu pauses")
	_menu.open_dev()
	assert_false(get_tree().paused, "the developer panel lets you watch changes live")
	_menu.toggle()
	assert_false(_menu.is_open())


func test_every_system_exposes_its_numbers() -> void:
	var groups: Dictionary = _menu.groups()
	for group in ["Ship handling", "Engine and coal", "Hull and leaks", "Waves", "Music", "Crew"]:
		assert_true(groups.has(group), group)
	var names: Array = _menu.tunable_properties(_level.get_node("Ship/EngineSystem")).map(func(p): return p.name)
	assert_has(names, "heat_rise")
	assert_has(names, "fuel_burn")


func test_slider_changes_apply_to_every_node_in_the_group() -> void:
	_menu.apply("Crew", "walk_speed", 9.0)
	for player in get_tree().get_nodes_in_group("crew"):
		assert_eq(player.walk_speed, 9.0)


func test_presets_save_and_load() -> void:
	_menu.open_dev()
	_menu.apply("Engine and coal", "heat_rise", 0.2)
	_menu.save_preset(1)
	_menu.apply("Engine and coal", "heat_rise", 0.01)
	assert_true(_menu.load_preset(1))
	assert_almost_eq(_level.get_node("Ship/EngineSystem").heat_rise, 0.2, 0.0001)
	assert_false(_menu.load_preset(3), "empty slot")


func test_forced_events() -> void:
	var ship := _level.get_node("Ship")
	assert_true(_level.dev_event("leak"))
	assert_eq(ship.get_node("HullSystem").open_breach_count() + _cracked(ship), 1, "a leak appeared")
	_level.dev_event("rudder")
	assert_true(ship.get_node("RudderSystem").is_damaged())
	_level.dev_event("overheat")
	assert_eq(ship.get_node("EngineSystem").heat, 1.0)
	watch_signals(_level)
	_level.dev_event("reach_port")
	await wait_physics_frames(3)
	assert_signal_emitted(_level, "port_reached")
	assert_false(_level.dev_event("nonsense"))


func test_god_mode_keeps_the_ship_dry() -> void:
	_level.dev_event("god_mode")
	_level.get_node("Ship/HullSystem").water = 0.7
	await wait_physics_frames(2)
	assert_eq(_level.get_node("Ship/HullSystem").water, 0.0)


func _cracked(ship: Node) -> int:
	var count := 0
	for breach in ship.get_node("HullSystem").breaches():
		if breach.state != 0:
			count += 1
	return count - ship.get_node("HullSystem").open_breach_count()
