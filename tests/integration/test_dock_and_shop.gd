extends GutTest
## features/dock_and_shop.feature

const VoyageScene = preload("res://scenes/levels/voyage.tscn")
const DockScene = preload("res://scenes/levels/dock.tscn")
const ContractLibrary = preload("res://scripts/contracts/contract_library.gd")

var _saved := {}


func before_each() -> void:
	_saved = {"money": Session.money, "upgrades": Session.upgrades.duplicate(), "unlocked": Session.unlocked,
			"best": Session.best_scores.duplicate(), "persist": Session.persist}
	Session.persist = false
	Session.money = 0
	Session.upgrades = []
	Session.unlocked = 1
	Session.best_scores = {}


func after_each() -> void:
	Session.money = _saved.money
	Session.upgrades = _saved.upgrades
	Session.unlocked = _saved.unlocked
	Session.best_scores = _saved.best
	Session.persist = _saved.persist
	Session.joined_players.clear()
	Session.contract_index = 0


func _voyage_with(upgrades: Array) -> Node3D:
	Session.upgrades = upgrades
	var level := VoyageScene.instantiate()
	level.contract = ContractLibrary.reef_run()
	add_child_autofree(level)
	for player in level.get_tree().get_nodes_in_group("crew"):
		player.get_node("PlayerInput").enabled = false
	await wait_physics_frames(3)
	return level


func test_given_delivery_then_earn_and_unlock_but_sinking_earns_nothing() -> void:
	assert_eq(Session.record_voyage(0, true, 700), 700)
	assert_eq(Session.money, 700)
	assert_eq(Session.unlocked, 2)
	assert_eq(Session.record_voyage(1, false, 0), 0)
	assert_eq(Session.unlocked, 2, "sinking unlocks nothing")
	assert_eq(int(Session.best_scores["0"]), 700)


func test_given_500_coins_when_buying_pumps_then_150_left_and_owned() -> void:
	Session.money = 500
	assert_true(Session.buy("bigger_pumps"))
	assert_eq(Session.money, 150)
	assert_true(Session.upgrades.has("bigger_pumps"))
	assert_false(Session.buy("bigger_pumps"), "not twice")
	assert_false(Session.buy("reinforced_hull"), "not enough coins")


func test_overclocked_engine_faster_but_hotter() -> void:
	var plain := await _voyage_with([])
	var base_speed: float = plain.get_node("Ship/ShipHandling").max_speed
	var base_heat: float = plain.get_node("Ship/EngineSystem").heat_rise
	var level := await _voyage_with(["overclocked_engine"])
	assert_gt(level.get_node("Ship/ShipHandling").max_speed, base_speed)
	assert_gt(level.get_node("Ship/EngineSystem").heat_rise, base_heat)


func test_reinforced_hull_leaks_slower_but_heavier() -> void:
	var level := await _voyage_with(["reinforced_hull"])
	var handling := level.get_node("Ship/ShipHandling")
	assert_lt(level.get_node("Ship/HullSystem").flow_rate, 1.0 / 70.0)
	assert_gte(level.get_node("Ship/Leak1").warning_seconds, 8.0)
	assert_lt(handling.top_speed(), handling.max_speed)
	assert_lt(handling.turn_factor(), 1.0)


func test_bigger_pumps_pump_faster_but_burn_coal() -> void:
	var level := await _voyage_with(["bigger_pumps"])
	var engine := level.get_node("Ship/EngineSystem")
	assert_gt(level.get_node("Ship/HullSystem").pump_rate, 1.0 / 18.0)
	var player: Node3D = level.get_tree().get_nodes_in_group("crew")[1]
	player.global_position = level.get_node("Ship/Pump").global_position
	await wait_physics_frames(3)
	player.use_requested = true
	await wait_seconds(2.0)
	assert_lt(engine.fuel, 1.0, "pumping used coal")


func test_second_spares_crate_more_spares_less_cargo() -> void:
	var level := await _voyage_with(["second_spares_crate"])
	assert_eq(level.get_node("Ship/PlankBox").stock, 7)
	assert_eq(level.get_node("Ship/PinBox").stock, 2)
	assert_eq(level.get_tree().get_nodes_in_group("cargo").size(), 5)


func test_dock_needs_crew_then_starts_unlocked_contract() -> void:
	var dock: Control = DockScene.instantiate()
	add_child_autofree(dock)
	await wait_physics_frames(2)
	assert_false(dock.start_contract(0), "nobody aboard")
	dock.toggle_crew(1)
	dock.toggle_crew(3)
	assert_false(dock.start_contract(2), "locked")
	watch_signals(dock)
	assert_true(dock.start_contract(0))
	assert_signal_emitted(dock, "contract_started")
	assert_eq(Session.joined_players, [1, 3] as Array[int])
	assert_eq(Session.contract_index, 0)


func test_dock_shop_button_buys() -> void:
	Session.money = 400
	var dock: Control = DockScene.instantiate()
	add_child_autofree(dock)
	await wait_physics_frames(2)
	dock.shop_buttons["second_spares_crate"].emit_signal("pressed")
	assert_eq(Session.money, 100)
	assert_true(dock.shop_buttons["second_spares_crate"].disabled, "owned")


func test_dock_ai_slots_toggle_and_cycle_jobs() -> void:
	Session.ai_crew = {}
	var dock: Control = DockScene.instantiate()
	add_child_autofree(dock)
	await wait_physics_frames(2)
	dock.toggle_crew(1)
	dock.toggle_ai(1)
	assert_false(Session.ai_crew.has(1), "a human slot can't be AI")
	dock.toggle_ai(2)
	dock.toggle_ai(3)
	assert_true(Session.ai_crew.has(2))
	assert_ne(Session.ai_crew[2].primary, Session.ai_crew[3].primary, "different default jobs")
	var before: String = Session.ai_crew[2].primary
	dock.primary_buttons[1].emit_signal("pressed")
	assert_ne(Session.ai_crew[2].primary, before, "job cycled")
	dock.toggle_ai(2)
	assert_false(Session.ai_crew.has(2), "AI off again")
	Session.ai_crew = {}
