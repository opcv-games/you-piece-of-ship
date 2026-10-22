extends Node3D
## One voyage from the dock to port, built from a contract (rocks, cliffs, waves, deadline).
## The route's pacing is hand-made (DESIGN.md section 7); this script only lays it out and
## runs the clock.

signal port_reached
signal hint_shown(text: String)
signal voyage_over(delivered: bool)

const ContractLibrary = preload("res://scripts/contracts/contract_library.gd")
const RockScene = preload("res://scenes/greybox/rock.tscn")
const Upgrades = preload("res://scripts/systems/upgrades.gd")
const AICrew = preload("res://scripts/ai/ai_crew.gd")
const PlayerControls = preload("res://scripts/systems/player_controls.gd")
const PauseMenu = preload("res://scripts/ui/pause_menu.gd")
const DOCK_SCENE := "res://scenes/levels/dock.tscn"

@export var contract: Resource ## leave empty to use the session's chosen contract

var finish_x := 1300.0
var hits := 0
var started := false ## the clock runs once the crew has set sail
var finished := false
var delivered := false
var elapsed := 0.0
var _crash_flash := 0.0
var _show_help := false
var net_puppet := false ## online client: the host runs the game, this copy only shows it
var _next_event := 0
var _hint_left := 0.0
var god_mode := false ## developer mode: no flooding, no overheating, no running dry

@onready var _ship: Node3D = $Ship
@onready var _handling: Node = $Ship/ShipHandling
@onready var _water: Node3D = $Water
@onready var _status: Label = $HUD/Status
@onready var _banner: Label = $HUD/Banner


func _ready() -> void:
	if contract == null:
		contract = ContractLibrary.by_index(Session.contract_index)
	finish_x = contract.length
	_build_route()
	$HUD/MapChart.port_x = finish_x
	$Music.finish_x = finish_x
	$HazardDirector.setup(contract.waves)
	$HUD/MapChart.range_metres = contract.chart_range
	_apply_fog(contract.fog)
	for crate in get_tree().get_nodes_in_group("cargo"):
		crate.value = contract.pay_per_crate # each contract pays its own rate
	Upgrades.apply(_ship, Session.upgrades)
	if contract.tutorial:
		$Ship/HullSystem.sink_grace_seconds = INF # the Maiden voyage can't be lost
		$Ship/EngineSystem.min_fuel = 0.3 # ...and never runs dry
	var engine := $Ship/EngineSystem
	engine.fuel_low.connect(func(): show_hint(tr("Coal low! Fill a shovel at the COAL pile (back corner) and press Use at the ENGINE.")))
	engine.out_of_fuel.connect(func(): show_hint(tr("Out of coal: only the sail is pushing. Shovel coal from the pile into the ENGINE!")))
	_handling.rock_hit.connect(_on_rock_hit)
	$Ship/HullSystem.ship_sunk.connect(_on_sunk)
	_banner.visible = false
	var pause := PauseMenu.new()
	pause.name = "PauseMenu"
	pause.voyage = self
	add_child(pause)
	_spawn_foam()
	$HUD/CrewJoin.crew_ready.connect(_on_crew_ready)
	if Net.role != "offline":
		$NetSync.setup(Net.role, Net.my_index, Net.peers)
	if not Session.joined_players.is_empty():
		_apply_crew(Session.joined_players) # restart: same crew, straight back to sea
	elif get_tree().current_scene == self:
		$HUD/CrewJoin.visible = true # first launch: choose the crew
	else:
		_start() # running inside tests: everyone aboard


func _start() -> void:
	started = true
	_handling.sail_speed = 1.2 # the sail keeps the ship moving even if the engine dies
	$HUD/CrewJoin.visible = false


func _on_crew_ready(players: Array[int]) -> void:
	Session.joined_players = players
	_apply_crew(players)


## Takes anyone who didn't join (as a human or an AI) off the ship; small crews get a slow
## automatic pump.
func _apply_crew(players: Array[int]) -> void:
	var ai_indexes: Array = Net.remote_ai if Net.role == "client" else Session.ai_crew.keys()
	var aboard := 0
	for player in get_tree().get_nodes_in_group("crew"):
		var index: int = player.player_index
		if players.has(index):
			aboard += 1
		elif ai_indexes.has(index):
			aboard += 1
			if Net.role != "client": # online clients only show the host's AI
				var jobs: Dictionary = Session.ai_crew[index]
				add_ai(index, jobs.primary, jobs.get("secondary", ""))
		else:
			player.remove_from_group("crew")
			player.remove_from_group("camera_focus")
			player.queue_free()
	var hull := $Ship/HullSystem
	hull.auto_pump_rate = hull.pump_rate * 0.3 if aboard <= 3 else 0.0
	_start()


## Hands a crew member over to an AI with a primary and a secondary job.
func add_ai(index: int, primary: String, secondary := "") -> Node:
	for player in get_tree().get_nodes_in_group("crew"):
		if player.player_index == index and not player.has_node("AICrew"):
			var ai := AICrew.new()
			ai.name = "AICrew"
			ai.primary = primary
			ai.secondary = secondary
			player.add_child(ai)
			return ai
	return null


func _physics_process(delta: float) -> void:
	# Keep the (plain) sea under the ship; the foam flecks stay put and show the speed.
	_water.global_position = Vector3(_ship.global_position.x, 0.0, _ship.global_position.z)
	if _crash_flash > 0.0:
		_crash_flash -= delta
		_banner.visible = _crash_flash > 0.0
	if _hint_left > 0.0:
		_hint_left -= delta
		$HUD/Hint.visible = _hint_left > 0.0
	# The controls help fades after the first half minute (H brings it back).
	var help: Label = $HUD/Controls
	help.modulate.a = move_toward(help.modulate.a, 1.0 if _show_help or elapsed < 30.0 else 0.0, delta * 2.0)
	_status.text = tr("%s    Time %s / %s") % [tr(contract.title), _clock(elapsed), _clock(contract.deadline)]
	_status.modulate = Color(1, 0.35, 0.3) if elapsed > contract.deadline else Color.WHITE
	if net_puppet:
		return # online client: the host's snapshots move everything
	$HazardDirector.set_physics_process(started and not finished)
	if not started:
		_handling.throttle = 0.0 # moored until the crew sets sail
	if god_mode:
		$Ship/HullSystem.water = 0.0
		$Ship/EngineSystem.heat = minf($Ship/EngineSystem.heat, 0.6)
		$Ship/EngineSystem.fuel = maxf($Ship/EngineSystem.fuel, 0.5)
	if started and not finished and Net.role != "client":
		_check_takeovers()
	if started and not finished:
		_run_events()
		elapsed += delta
		if _ship.global_position.x >= finish_x:
			_finish()


static func _clock(seconds: float) -> String:
	return "%d:%02d" % [int(seconds) / 60, int(seconds) % 60]


func _unhandled_input(event: InputEvent) -> void:
	var restart: bool = (event is InputEventKey and event.pressed and event.physical_keycode == KEY_R) \
			or (event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_START)
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_H:
		_show_help = not _show_help
	if Net.role == "client":
		return # online: the host decides when to sail again or go back to the dock
	if restart:
		if Net.role == "host":
			Net.start_voyage(Session.contract_index)
		else:
			get_tree().reload_current_scene()
	if finished and event.is_action_pressed("ui_accept"):
		if Net.role == "host":
			Net.back_to_dock()
		else:
			UI.go(DOCK_SCENE) # back to the dock: spend, pick the next contract
	var change_crew: bool = finished and event is InputEventKey and event.pressed and event.physical_keycode == KEY_J
	if change_crew:
		Session.joined_players.clear()
		UI.go(DOCK_SCENE)


## A player presses Jump or Use on their controller mid-voyage: they take over their AI crewmate.
func _check_takeovers() -> void:
	for player in get_tree().get_nodes_in_group("crew"):
		var index: int = player.player_index
		if not player.has_node("AICrew") or (Net.role == "host" and index != 1):
			continue # online, only the host's own controls are on this computer
		if Input.is_action_just_pressed(PlayerControls.action(index, "jump")) \
				or Input.is_action_just_pressed(PlayerControls.action(index, "use")):
			take_over(index)


## A human takes an AI crewmate's place, right where it stands.
func take_over(index: int) -> void:
	for player in get_tree().get_nodes_in_group("crew"):
		if player.player_index != index or not player.has_node("AICrew"):
			continue
		var ai := player.get_node("AICrew")
		player.remove_child(ai)
		ai.queue_free()
		player.get_node("PlayerInput").enabled = true
		player.get_node("Label").text = "P%d" % index
		player.think(tr("I'm in!"), 1.5, "shout")
		if not Session.joined_players.has(index):
			Session.joined_players.append(index)
			Session.joined_players.sort()
		Session.ai_crew.erase(index)
		$CrewBrain.assignments.erase(player)


# --- Developer mode (Esc → Developer) ------------------------------------------------------

const DEV_EVENTS := ["crash", "leak", "flood", "overheat", "stall", "out_of_coal", "rudder", "wave_port",
		"wave_starboard", "loose_cargo", "reach_port", "sink", "add_coins", "unlock_all", "god_mode"]


## Forces an event right now, for testing and tuning. Returns false for an unknown event.
func dev_event(event: String) -> bool:
	var ship := _ship
	match event:
		"crash":
			var rock: Node3D = RockScene.instantiate()
			rock.radius = 1.0
			rock.position = ship.global_position + _handling.forward() * 8.0
			$Reef.add_child(rock)
			_handling.speed = maxf(_handling.speed, _handling.max_speed * 0.8)
			_handling._hit(rock)
		"leak":
			$Ship/HullSystem.add_breach(Vector3(randf_range(-6.0, 6.0), 0.0, 3.0 * (1.0 if randf() < 0.5 else -1.0)))
		"flood":
			$Ship/HullSystem.water = minf(1.0, $Ship/HullSystem.water + 0.3)
		"overheat":
			$Ship/EngineSystem.heat = 1.0
		"stall":
			var engine := $Ship/EngineSystem
			engine.heat = 1.0
			engine.warning_left = 0.01
		"out_of_coal":
			$Ship/EngineSystem.fuel = 0.0
		"rudder":
			$Ship/RudderSystem.try_damage(1.0)
		"wave_port", "wave_starboard":
			$Ship/WaveMotion.big_wave(-1.0 if event == "wave_port" else 1.0)
		"loose_cargo":
			var cargo := $Ship/LoadSystem
			for crate in cargo.crates():
				if crate.lashed:
					get_tree().get_first_node_in_group("cargo_bay").unlash(crate)
					crate.velocity = Vector2(0.0, 3.0)
					cargo.crate_loose.emit(crate)
					break
		"reach_port":
			ship.position.x = finish_x + 1.0
		"sink":
			$Ship/HullSystem.sink_grace_seconds = 0.0
			$Ship/HullSystem.water = 1.0
		"add_coins":
			Session.money += 500
			Session.save_game()
		"unlock_all":
			Session.unlocked = ContractLibrary.all_contracts().size()
			Session.save_game()
		"god_mode":
			god_mode = not god_mode
		_:
			return false
	return true


# --- Contract events and fog --------------------------------------------------------

func _run_events() -> void:
	while _next_event < contract.events.size() and _ship.global_position.x >= contract.events[_next_event][0]:
		var event: Array = contract.events[_next_event]
		_next_event += 1
		match event[1]:
			"leak":
				$Ship/HullSystem.add_breach(Vector3(randf_range(-4.0, 6.0), 0.0, 3.0 * (1.0 if randf() < 0.5 else -1.0)))
			"rudder":
				$Ship/RudderSystem.try_damage(1.0)
			"heat":
				var engine := $Ship/EngineSystem
				engine.heat = maxf(engine.heat, 0.85)
		if event.size() > 2 and event[2] != "":
			show_hint(tr(event[2]))


func show_hint(text: String, seconds := 7.0) -> void:
	hint_shown.emit(text)
	$HUD/Hint.text = text
	$HUD/Hint.visible = true
	_hint_left = seconds


func _apply_fog(on: bool) -> void:
	var telescope := $Ship/Telescope
	telescope.enabled = on
	telescope.visible = on
	var environment: Environment = $WorldEnvironment.environment
	environment.fog_enabled = on
	if on:
		# Light enough that the deck (about 30 m from the camera) stays readable; the sea beyond fades.
		environment.fog_light_color = Color(0.72, 0.75, 0.78)
		environment.fog_density = 0.016
		environment.background_color = Color(0.72, 0.75, 0.78)
	else:
		environment.background_color = Color(0.62, 0.8, 0.93)


# --- Route ---------------------------------------------------------------------

func _build_route() -> void:
	var reef := $Reef
	var count := 0
	for row in contract.rock_rows:
		var radius: float = row[2] if row.size() > 2 else 3.5
		for z in row[1]:
			count += 1
			_add_rock(reef, "Rock%d" % count, Vector3(row[0], 0.0, z), radius, true)
	# Visible cliffs along both sides keep the ship in the channel.
	var x := -40.0
	var i := 0
	while x < finish_x + 80.0:
		for side in [-1.0, 1.0]:
			i += 1
			var wobble := sin(x * 0.07 + side) * 3.0
			_add_rock(reef, "Cliff%d" % i, Vector3(x, 0.0, side * (contract.coast_half_width + 6.0 + wobble)), 6.0, false)
		x += 11.0
	_build_port()


func _add_rock(parent: Node, rock_name: String, where: Vector3, radius: float, hidden: bool) -> void:
	var rock: Node3D = RockScene.instantiate()
	rock.name = rock_name
	rock.radius = radius
	rock.hidden = hidden
	rock.position = where
	parent.add_child(rock)


func _build_port() -> void:
	var buoy_mesh := CylinderMesh.new()
	buoy_mesh.top_radius = 0.6
	buoy_mesh.bottom_radius = 0.8
	buoy_mesh.height = 3.0
	var yellow := StandardMaterial3D.new()
	yellow.albedo_color = Color(1, 0.85, 0.2)
	buoy_mesh.material = yellow
	for side in [-1.0, 1.0]:
		var buoy := MeshInstance3D.new()
		buoy.name = "Buoy%s" % ("Port" if side < 0.0 else "Starboard")
		buoy.mesh = buoy_mesh
		buoy.position = Vector3(finish_x, 1.0, side * 12.0)
		buoy.add_to_group("finish")
		add_child(buoy)
	var dock_mesh := BoxMesh.new()
	dock_mesh.size = Vector3(30, 3, 70)
	var stone := StandardMaterial3D.new()
	stone.albedo_color = Color(0.55, 0.53, 0.5)
	dock_mesh.material = stone
	var dock := MeshInstance3D.new()
	dock.name = "Dock"
	dock.mesh = dock_mesh
	dock.position = Vector3(finish_x + 45.0, 1.0, 0.0)
	add_child(dock)


# --- Events --------------------------------------------------------------------

func _on_rock_hit(_rock: Node3D) -> void:
	hits += 1
	if not finished:
		_banner.text = tr("CRASH!")
		_banner.visible = true
		_crash_flash = 1.0


func _on_sunk() -> void:
	if finished:
		return
	finished = true
	_crash_flash = 0.0
	_handling.throttle = 0.0
	_banner.visible = false
	_show_results()
	voyage_over.emit(false)


func _finish() -> void:
	finished = true
	delivered = true
	_crash_flash = 0.0
	_handling.throttle = 0.0
	_banner.visible = false
	_show_results()
	port_reached.emit()
	voyage_over.emit(true)


func _show_results() -> void:
	var cargo := $Ship/LoadSystem
	var water: float = $Ship/HullSystem.water
	var results := $HUD/Results
	var outcome := {
		"delivered": delivered,
		"contract": contract.title,
		"time_text": _clock(elapsed),
		"deadline_text": _clock(contract.deadline),
		"on_time": elapsed <= contract.deadline,
		"crates": cargo.crates().size(),
		"crates_loaded": maxi(cargo._loaded_crates, cargo.crates().size()),
		"water": water,
		"progress": clampf(_ship.global_position.x / finish_x, 0.0, 1.0),
		"score": results.score(delivered, cargo.cargo_value(), water, elapsed, contract.deadline),
	}
	outcome.earned = Session.record_voyage(Session.contract_index, delivered, outcome.score.total, elapsed)
	outcome.records = Session.last_records.duplicate()
	var key := str(Session.contract_index)
	outcome.best_score = int(Session.best_scores.get(key, 0))
	outcome.best_time_text = _clock(float(Session.best_times[key])) if Session.best_times.has(key) else "-"
	results.show_results(outcome, $VoyageLog.recap())


func _spawn_foam() -> void:
	var flecks := MultiMeshInstance3D.new()
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.8, 0.04, 0.35)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.85, 0.93, 1.0)
	mesh.material = material
	multimesh.mesh = mesh
	var area: float = (finish_x + 120.0) * contract.coast_half_width * 2.0
	multimesh.instance_count = int(area / 25.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in multimesh.instance_count:
		var spot := Vector3(rng.randf_range(-60.0, finish_x + 60.0), 0.03,
				rng.randf_range(-contract.coast_half_width, contract.coast_half_width))
		multimesh.set_instance_transform(i, Transform3D(Basis(Vector3.UP, rng.randf() * TAU), spot))
	flecks.multimesh = multimesh
	add_child(flecks)
