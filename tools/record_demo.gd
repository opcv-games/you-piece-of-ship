extends SceneTree
## A 45-second showreel for You Piece of Ship, recorded frame by frame with Godot's Movie Maker
## (tools/record_demo.sh). It plays the real game with the all-AI crew and uses the developer
## events to pack the highlights in: menu, world map, whale, leak and pump, hot engine, a pirate
## battle with loot, the siren, fishing, the Kraken's Gate storm, the stars, a title card.
## Nothing here changes normal play.

const MENU := "res://scenes/ui/main_menu.tscn"
const MAP := "res://scenes/ui/world_map.tscn"
const VOYAGE := "res://scenes/levels/voyage.tscn"
const ContractLibrary = preload("res://scripts/contracts/contract_library.gd")

var session: Node
var scene: Node


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await create_timer(0.2).timeout
	root.gui_disable_input = true # nothing may press a button during the recording
	session = root.get_node("Session")
	session.persist = false
	session.stars = {"0": 3, "4": 3, "1": 2, "5": 2, "2": 1}
	session.seen_oceans = [0, 1, 2]
	session.joined_players = [] as Array[int]
	session.ai_crew = {}
	session.fill_crew_with_ai()
	# 0-3 s: the main menu.
	await _show(load(MENU).instantiate())
	await _wait(3.2)
	# 3-7 s: the world map.
	await _show(load(MAP).instantiate())
	await _wait(1.5)
	scene.select(1)
	await _wait(2.3)
	# 7-31 s: Reef Run with the all-AI crew.
	session.contract_index = 1
	var voyage: Node3D = load(VOYAGE).instantiate()
	voyage.contract = ContractLibrary.reef_run()
	await _show(voyage)
	voyage._apply_crew([] as Array[int])
	voyage.get_node("HUD/Controls").visible = false
	await _wait(1.5)
	voyage.dev_event("spawn_whale")
	await _wait(3.0)
	voyage.dev_event("crash")
	await _wait(1.5)
	voyage.dev_event("flood")
	voyage.dev_event("overheat")
	await _wait(3.0)
	_fish(voyage)
	var pirates: Node3D = voyage.spawn_enemy(1.0)
	var ship: Node3D = voyage.get_node("Ship")
	pirates.global_position = ship.global_position + ship.global_basis.z * 22.0 - ship.global_basis.x * 4.0
	pirates.global_position.y = 0.0
	pirates.reload_left = 1.0
	await _wait(2.0)
	_fire_all(voyage, pirates)
	await _wait(1.6)
	pirates.take_hit(pirates.global_position)
	_fire_all(voyage, pirates)
	await _wait(1.6)
	pirates.take_hit(pirates.global_position)
	pirates.take_hit(pirates.global_position)
	await _wait(0.5)
	for loot in voyage.get_tree().get_nodes_in_group("loot"):
		loot.global_position = ship.global_position + ship.global_basis.x * randf_range(16.0, 26.0) + ship.global_basis.z * randf_range(-3.0, 3.0)
		loot.global_position.y = 0.0
	await _wait(2.5)
	voyage.dev_event("spawn_siren")
	await _wait(4.5)
	# 31-39 s: Kraken's Gate in the storm.
	session.contract_index = 8
	var storm: Node3D = load(VOYAGE).instantiate()
	storm.contract = ContractLibrary.krakens_gate()
	await _show(storm)
	storm._apply_crew([] as Array[int])
	storm.get_node("HUD/Controls").visible = false
	storm.get_node("HUD/Hint").visible = false
	await _wait(1.0)
	storm.dev_event("wave_port")
	await _wait(1.5)
	storm._lightning()
	await _wait(2.5)
	storm._lightning()
	await _wait(2.0)
	# 39-43 s: port reached, three stars pop in.
	var rules := storm.get_node("StarRules")
	rules.star_2 = 2
	rules.star_3 = 3
	storm.dev_event("reach_port")
	await _wait(3.6)
	# 43-45 s: the title card.
	_title_card()
	await _wait(3.0)
	quit()


func _wait(seconds: float) -> void:
	await create_timer(seconds).timeout


func _show(next: Node) -> void:
	# Only one screen at a time: the old one is gone before the new one starts.
	if scene and is_instance_valid(scene):
		scene.queue_free()
		await process_frame
		await process_frame
	scene = next
	root.add_child(next)
	current_scene = next


## Puts an AI sailor on a fishing spot and lands a catch, so the fish flies onto the deck.
func _fish(voyage: Node3D) -> void:
	var spot: Node3D = voyage.get_node("Ship/FishingSpot1")
	for player in voyage.get_tree().get_nodes_in_group("crew"):
		if player.player_index == 3:
			if player.station:
				player.station.release(player)
			player.position = spot.position
			spot.occupy(player)
			spot.phase = spot.Phase.BITE
			spot.bite_left = 0.8
			create_timer(0.6).timeout.connect(func(): spot.strike(player))


## Loads every cannon on the pirates' side and fires.
func _fire_all(voyage: Node3D, pirates: Node3D) -> void:
	for cannon in voyage.get_tree().get_nodes_in_group("cannons"):
		if cannon.side > 0.0:
			cannon.loaded = true
			cannon.aim = 0.0
			cannon.fire()


func _title_card() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 200
	root.add_child(layer)
	var panel := ColorRect.new()
	panel.color = Color(0.09, 0.15, 0.27)
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(panel)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	layer.add_child(box)
	for line in [["YOU PIECE OF SHIP", 86, Color(1.0, 0.78, 0.2)], ["Couch co-op chaos for 1 to 4 sailors", 34, Color(1, 0.96, 0.86)],
			["Steer · Shovel · Patch · Pump · Fire · Fish", 26, Color(1, 1, 1, 0.8)]]:
		var label := Label.new()
		label.text = line[0]
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", line[1])
		label.add_theme_color_override("font_color", line[2])
		label.add_theme_constant_override("outline_size", 12)
		box.add_child(label)
