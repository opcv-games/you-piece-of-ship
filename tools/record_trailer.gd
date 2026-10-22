extends SceneTree
## The Steam trailer (45 s), recorded with Godot's Movie Maker by tools/record_trailer.sh.
## Gameplay from the first frame, big captions readable with the sound off, close-ups and wide
## shots, a pirate battle, whales and sirens, the storm, three stars, then the end card.
## It drives the real game with the all-AI crew (standing in for P1-P4) and developer events.

const VOYAGE := "res://scenes/levels/voyage.tscn"
const ContractLibrary = preload("res://scripts/contracts/contract_library.gd")

var scene: Node3D
var _caption: Label
var _layer: CanvasLayer


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await create_timer(0.2).timeout
	root.gui_disable_input = true
	var session := root.get_node("Session")
	session.persist = false
	session.joined_players = [] as Array[int]
	session.ai_crew = {}
	session.fill_crew_with_ai()
	_build_caption()
	# --- Reef Run: chaos from the first second ----------------------------------------------
	session.contract_index = 1
	scene = await _voyage(ContractLibrary.reef_run())
	var ship: Node3D = scene.get_node("Ship")
	ship.get_node("ShipHandling").speed = 6.0
	await _wait(0.4)
	scene.dev_event("crash")
	caption("4 TERRIBLE SAILORS")
	await _wait(2.4)
	caption("1 SHIP")
	_wide(true)
	await _wait(2.0)
	caption("")
	_close([_crew(2), _crew(4)])
	await _wait(2.4)
	caption("EVERY MISTAKE\nMAKES IT WORSE")
	_wide(false)
	scene.dev_event("flood")
	scene.dev_event("overheat")
	await _wait(1.2)
	scene.dev_event("wave_port")
	scene.dev_event("loose_cargo")
	await _wait(2.4)
	caption("")
	_close([ship.get_node("Pump"), ship.get_node("Engine")])
	await _wait(2.4)
	# --- Pirates --------------------------------------------------------------------------------
	_wide(false)
	var pirates: Node3D = scene.spawn_enemy(1.0)
	pirates.global_position = ship.global_position + ship.global_basis.z * 21.0 - ship.global_basis.x * 2.0
	pirates.global_position.y = 0.0
	pirates.reload_left = 0.6
	scene.get_node("HUD/Hint").visible = false
	caption("FIGHT PIRATES")
	await _wait(1.2)
	_fire(true)
	await _wait(1.2)
	pirates.take_hit(pirates.global_position)
	_fire(true)
	await _wait(1.2)
	pirates.take_hit(pirates.global_position)
	pirates.take_hit(pirates.global_position)
	caption("SINK THEM.\nGRAB THE LOOT.")
	await _wait(0.4)
	for loot in scene.get_tree().get_nodes_in_group("loot"):
		loot.global_position = ship.global_position + ship.global_basis.x * randf_range(17.0, 26.0) + ship.global_basis.z * randf_range(-2.5, 2.5)
		loot.global_position.y = 0.0
	await _wait(2.0)
	# --- Whales, sirens, fishing ----------------------------------------------------------------
	scene.dev_event("spawn_whale")
	scene.dev_event("spawn_siren")
	caption("DODGE WHALES\n& SIRENS")
	await _wait(3.6)
	_fish()
	_close([ship.get_node("FishingSpot1")])
	caption("GO FISHING")
	await _wait(2.4)
	# --- The storm ------------------------------------------------------------------------------
	caption("")
	session.contract_index = 8
	scene = await _voyage(ContractLibrary.krakens_gate())
	ship = scene.get_node("Ship")
	ship.get_node("ShipHandling").speed = 6.0
	caption("SURVIVE THE STORM")
	await _wait(0.8)
	scene._lightning()
	scene.dev_event("wave_starboard")
	await _wait(1.8)
	scene._lightning()
	scene.dev_event("flood")
	await _wait(1.6)
	caption("")
	_close([_crew(1), _crew(3)])
	await _wait(1.4)
	_wide(false)
	scene.dev_event("crash")
	await _wait(1.2)
	# --- Delivered, three stars -----------------------------------------------------------------
	caption("")
	var rules := scene.get_node("StarRules")
	rules.star_2 = 2
	rules.star_3 = 3
	scene.get_node("HUD").visible = true
	for hide in ["Status", "MapChart", "EngineGauge", "Hint", "Controls"]:
		scene.get_node("HUD/" + hide).visible = false
	scene.dev_event("reach_port")
	await _wait(3.6)
	# --- End card -------------------------------------------------------------------------------
	_end_card()
	await _wait(7.6)
	quit()


func _wait(seconds: float) -> void:
	await create_timer(seconds).timeout


## Starts a voyage with a clean screen: no timer, chart, hints or station labels; P1-P4 tags.
func _voyage(contract: Resource) -> Node3D:
	if scene and is_instance_valid(scene):
		scene.queue_free()
		await process_frame
		await process_frame
	var voyage: Node3D = load(VOYAGE).instantiate()
	voyage.contract = contract
	root.add_child(voyage)
	current_scene = voyage
	voyage._apply_crew([] as Array[int])
	for hide in ["Status", "MapChart", "EngineGauge", "Hint", "Controls"]:
		voyage.get_node("HUD/" + hide).visible = false
	voyage.get_node("HUD/Hint").modulate.a = 0.0 # hints would pop back up: keep them invisible
	var camera := voyage.get_node("SharedCamera")
	camera.reserve_right = 0.0
	await process_frame
	for label in voyage.get_node("Ship").find_children("Label", "Label3D", true, false):
		if not label.get_parent().is_in_group("crew"):
			label.visible = false
			label.set_process(false)
	for station in voyage.get_tree().get_nodes_in_group("stations"):
		station.set_process(false) # keeps their labels hidden
	for player in voyage.get_tree().get_nodes_in_group("crew"):
		player.get_node("Label").text = "P%d" % player.player_index
	return voyage


func _crew(index: int) -> Node3D:
	for player in scene.get_tree().get_nodes_in_group("crew"):
		if player.player_index == index:
			return player
	return null


## Close-up on a few things (crew, stations).
func _close(targets: Array) -> void:
	var camera := scene.get_node("SharedCamera")
	for node in scene.get_tree().get_nodes_in_group("trailer_focus"):
		node.remove_from_group("trailer_focus")
	for target in targets:
		if target:
			target.add_to_group("trailer_focus")
	camera.target_group = "trailer_focus"
	camera.min_distance = 7.0
	camera.look_ahead = 0.0
	camera.margin = 3.0


## Back to the whole ship (and, far, lots of sea).
func _wide(far: bool) -> void:
	var camera := scene.get_node("SharedCamera")
	camera.target_group = "camera_focus"
	camera.min_distance = 26.0 if far else 12.0
	camera.look_ahead = 14.0
	camera.margin = 2.5


func _fire(starboard: bool) -> void:
	for cannon in scene.get_tree().get_nodes_in_group("cannons"):
		if (cannon.side > 0.0) == starboard:
			cannon.loaded = true
			cannon.aim = 0.0
			cannon.fire()


func _fish() -> void:
	var spot: Node3D = scene.get_node("Ship/FishingSpot1")
	var fisher := _crew(3)
	if fisher.station:
		fisher.station.release(fisher)
	if fisher.carried:
		fisher.carried.drop()
	fisher.position = spot.position
	spot.occupy(fisher)
	spot.phase = spot.Phase.BITE
	spot.bite_left = 1.0
	create_timer(0.7).timeout.connect(func(): spot.strike(fisher))


# --- Captions and the end card ------------------------------------------------------------------

func _build_caption() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 150
	root.add_child(_layer)
	_caption = Label.new()
	_caption.set_anchors_preset(Control.PRESET_FULL_RECT)
	_caption.offset_top = 330
	_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_caption.add_theme_font_override("font", root.get_node("UI").display_font())
	_caption.add_theme_font_size_override("font_size", 72)
	_caption.add_theme_color_override("font_color", Color(1.0, 0.82, 0.25))
	_caption.add_theme_color_override("font_outline_color", Color(0.08, 0.06, 0.12))
	_caption.add_theme_constant_override("outline_size", 26)
	_caption.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
	_caption.add_theme_constant_override("shadow_offset_y", 8)
	_layer.add_child(_caption)


## Shows a caption with a punchy pop (empty text hides it).
func caption(text: String) -> void:
	_caption.text = text
	_caption.visible = text != ""
	if text == "":
		return
	_caption.pivot_offset = Vector2(_caption.size.x * 0.5, _caption.size.y * 0.5 + 165)
	_caption.scale = Vector2(1.6, 1.6)
	_caption.rotation = deg_to_rad(-4)
	var tween := _caption.create_tween().set_parallel()
	tween.tween_property(_caption, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_caption, "rotation", 0.0, 0.25)


func _end_card() -> void:
	caption("")
	var card := CanvasLayer.new()
	card.layer = 210
	root.add_child(card)
	var painting := TextureRect.new()
	painting.texture = load("res://assets/art/export/ui/menu_background.png")
	painting.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	painting.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	painting.set_anchors_preset(Control.PRESET_FULL_RECT)
	card.add_child(painting)
	var shade := ColorRect.new()
	shade.color = Color(0.05, 0.08, 0.16, 0.45)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	card.add_child(shade)
	# The title on a wooden sign (drawn here: the menu's sign needs the running game's UI).
	var logo := PanelContainer.new()
	var wood := StyleBoxFlat.new()
	wood.bg_color = Color(0.45, 0.26, 0.13)
	wood.border_color = Color(0.18, 0.1, 0.06)
	wood.set_border_width_all(8)
	wood.set_corner_radius_all(22)
	wood.content_margin_left = 60
	wood.content_margin_right = 60
	wood.content_margin_top = 16
	wood.content_margin_bottom = 22
	wood.shadow_color = Color(0, 0, 0, 0.45)
	wood.shadow_size = 18
	wood.shadow_offset = Vector2(0, 10)
	logo.add_theme_stylebox_override("panel", wood)
	logo.position = Vector2(286, 70)
	logo.custom_minimum_size = Vector2(580, 0)
	logo.rotation = deg_to_rad(-2)
	card.add_child(logo)
	var title := VBoxContainer.new()
	title.add_theme_constant_override("separation", -18)
	logo.add_child(title)
	for part in [["YOU PIECE OF", 64, Color(1, 0.96, 0.86)], ["SHIP", 150, Color(1.0, 0.78, 0.2)]]:
		var word := Label.new()
		word.text = part[0]
		word.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		word.add_theme_font_override("font", root.get_node("UI").display_font())
		word.add_theme_font_size_override("font_size", part[1])
		word.add_theme_color_override("font_color", part[2])
		word.add_theme_color_override("font_outline_color", Color(0.2, 0.1, 0.05))
		word.add_theme_constant_override("outline_size", 22)
		title.add_child(word)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_top = 420
	card.add_child(box)
	for line in [["Couch & online co-op  ·  1–4 players", 34, Color(1, 0.96, 0.86)],
			["Coming soon to Steam", 40, Color(1.0, 0.82, 0.25)]]:
		var label := Label.new()
		label.text = line[0]
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_override("font", root.get_node("UI").display_font())
		label.add_theme_font_size_override("font_size", line[1])
		label.add_theme_color_override("font_color", line[2])
		label.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.1))
		label.add_theme_constant_override("outline_size", 14)
		box.add_child(label)
	logo.modulate.a = 0.0
	logo.create_tween().tween_property(logo, "modulate:a", 1.0, 0.4)
