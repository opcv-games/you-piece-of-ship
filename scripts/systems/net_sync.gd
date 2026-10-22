extends Node
## Online play, host-authoritative (DESIGN.md section 10, risk 1). The host runs the whole voyage;
## clients only show it. Each client sends its stick every frame and its button presses reliably;
## the host sends a snapshot 20 times a second plus one-off events (crash, waves, hints, results).
## Crew and item positions are ship-local, so the rocking deck can't drift apart between screens.

const ItemScene = preload("res://scenes/greybox/item.tscn")
const PlayerControls = preload("res://scripts/systems/player_controls.gd")
const SEND_INTERVAL := 0.05

var role := "offline" ## "host", "client" or "offline"
var local_index := 1 ## the player this machine controls
var peer_players := {} ## host only: peer id -> player index
var local_move_override = null ## tests: drive this client's stick without a keyboard

var _voyage: Node3D
var _ship: Node3D
var _send_left := 0.0
var _items := {} ## client: net id -> item


func _ready() -> void:
	_voyage = get_parent()
	_ship = _voyage.get_node("Ship")


func setup(new_role: String, index: int, peers := {}) -> void:
	role = new_role
	local_index = index
	peer_players = peers
	if role == "host":
		_listen_for_events()
		for player in get_tree().get_nodes_in_group("crew"):
			if peer_players.values().has(player.player_index):
				player.get_node("PlayerInput").enabled = false # driven by the network
	elif role == "client":
		_become_puppet()


# --- Client ----------------------------------------------------------------------

func _become_puppet() -> void:
	_voyage.net_puppet = true
	for system in ["WaveMotion", "ShipHandling", "HullSystem", "EngineSystem", "RudderSystem", "LoadSystem"]:
		_ship.get_node(system).set_physics_process(false)
	_voyage.get_node("HazardDirector").set_physics_process(false)
	_voyage.get_node("VoyageLog").set_physics_process(false)
	for station in get_tree().get_nodes_in_group("stations"):
		station.set_physics_process(false)
	for player in get_tree().get_nodes_in_group("crew"):
		player.set_physics_process(false)
		player.get_node("PlayerInput").enabled = false
	for item in get_tree().get_nodes_in_group("items"):
		item.remove_from_group("items")
		item.remove_from_group("cargo")
		item.queue_free() # the host's items arrive with the snapshots


func _send_input() -> void:
	var move: Vector2 = local_move_override if local_move_override != null else Input.get_vector(
			PlayerControls.action(1, "left"), PlayerControls.action(1, "right"),
			PlayerControls.action(1, "up"), PlayerControls.action(1, "down"))
	_input_state.rpc_id(1, move)
	if Input.is_action_just_pressed(PlayerControls.action(1, "jump")):
		_input_press.rpc_id(1, "jump")
	if Input.is_action_just_pressed(PlayerControls.action(1, "use")):
		_input_press.rpc_id(1, "use")


## Tests: press a button on this client as if the player did.
func press(kind: String) -> void:
	_input_press.rpc_id(1, kind)


@rpc("authority", "call_remote", "unreliable_ordered")
func _snapshot(data: Dictionary) -> void:
	_voyage.elapsed = data.t
	_ship.position = data.ship[0]
	_ship.rotation = data.ship[1]
	var handling := _ship.get_node("ShipHandling")
	handling.speed = data.sys[11]
	handling.throttle = data.sys[10]
	for player in get_tree().get_nodes_in_group("crew"):
		var state: Array = data.crew.get(player.player_index, [])
		if state.is_empty():
			continue
		player.position = state[0]
		var visual: Node3D = player.get_node("Visual")
		visual.rotation.y = state[1]
		player.knocked = state[2]
		visual.rotation.x = -PI / 2.0 if state[2] > 0.0 else 0.0
		visual.position.y = 0.35 if state[2] > 0.0 else 0.0
	_apply_items(data.items)
	_apply_systems(data)


func _apply_items(states: Dictionary) -> void:
	var items_root := _ship.get_node("Items")
	for id in states:
		var state: Array = states[id]
		var item: Node3D = _items.get(id)
		if item == null or not is_instance_valid(item):
			item = ItemScene.instantiate()
			item.net_id = id
			item.kind = state[0]
			items_root.add_child(item)
			item.set_physics_process(false)
			_items[id] = item
		item.position = state[1]
		item.rotation = state[2]
	for id in _items.keys():
		if not states.has(id):
			if is_instance_valid(_items[id]):
				_items[id].queue_free()
			_items.erase(id)


func _apply_systems(data: Dictionary) -> void:
	var leaks: Array = data.leaks
	var hull := _ship.get_node("HullSystem")
	var breaches: Array = hull.breaches()
	for i in mini(leaks.size(), breaches.size()):
		var breach = breaches[i]
		breach.state = leaks[i][0]
		breach.has_plank = leaks[i][1]
		breach.is_plugged = leaks[i][2]
		breach.progress = leaks[i][3]
		breach._warning_left = leaks[i][4]
		breach._refresh()
	var sys: Array = data.sys
	hull.water = sys[0]
	hull._apply_effects(0.0)
	var engine := _ship.get_node("EngineSystem")
	engine.heat = sys[1]
	engine.fuel = sys[2]
	engine.stall_left = sys[3]
	engine.warning_left = sys[4]
	engine.vent_ready_in = sys[5]
	var pipe := _ship.get_node("CoolingPipe")
	pipe.broken = sys[6]
	pipe.progress = sys[7]
	pipe._refresh()
	engine._apply_effects()
	_ship.get_node("RudderSystem").state = sys[8]
	_ship.get_node("PlankBox").stock = data.stock[0]
	_ship.get_node("PinBox").stock = data.stock[1]
	for path in data.stations:
		var station := _ship.get_node_or_null(NodePath(path))
		if station == null:
			continue
		var info: Array = data.stations[path]
		station.status_text = info[0]
		station.occupants.clear()
		for index in info[1]:
			var player := _player(index)
			if player:
				station.occupants.append(player)


@rpc("authority", "call_remote", "reliable")
func _event(kind: String, args: Array) -> void:
	var feel := _voyage.get_node("GameFeel")
	match kind:
		"crash":
			var rock := _voyage.get_node_or_null("Reef/" + args[0])
			if rock:
				rock.reveal()
				_voyage._on_rock_hit(rock)
				feel._on_rock_hit(rock)
		"wave_warning":
			feel._on_wave_warning(args[0])
		"wave_struck":
			feel._on_wave_struck(args[0])
		"hint":
			_voyage.show_hint(args[0])
		"spotted":
			var rock := _voyage.get_node_or_null("Reef/" + args[0])
			if rock:
				_ship.get_node("Telescope").mark(rock)
		"port":
			feel._on_port_reached()
		"results":
			_voyage.finished = true
			_voyage.delivered = args[0].delivered
			var story: Array[Dictionary] = []
			story.assign(args[1])
			_voyage.get_node("HUD/Results").show_results(args[0], story)


# --- Host ------------------------------------------------------------------------

func _listen_for_events() -> void:
	var waves := _ship.get_node("WaveMotion")
	_ship.get_node("ShipHandling").impact.connect(func(rock): _broadcast("crash", [String(rock.name)]))
	waves.wave_warning.connect(func(side): _broadcast("wave_warning", [side]))
	waves.wave_struck.connect(func(side): _broadcast("wave_struck", [side]))
	_voyage.hint_shown.connect(func(text): _broadcast("hint", [text]))
	_ship.get_node("Telescope").spotted.connect(func(rock): _broadcast("spotted", [String(rock.name)]))
	_voyage.port_reached.connect(func(): _broadcast("port", []))
	_voyage.voyage_over.connect(func(_delivered): _broadcast("results", [
			_voyage.get_node("HUD/Results").outcome, _voyage.get_node("VoyageLog").recap()]))


func _broadcast(kind: String, args: Array) -> void:
	if multiplayer.has_multiplayer_peer() and not multiplayer.get_peers().is_empty():
		_event.rpc(kind, args)


@rpc("any_peer", "call_remote", "unreliable_ordered")
func _input_state(move: Vector2) -> void:
	var player := _player(peer_players.get(multiplayer.get_remote_sender_id(), 0))
	if player:
		player.move_input = move.limit_length(1.0)


@rpc("any_peer", "call_remote", "reliable")
func _input_press(kind: String) -> void:
	var player := _player(peer_players.get(multiplayer.get_remote_sender_id(), 0))
	if player == null:
		return
	if kind == "jump":
		player.jump_requested = true
	elif kind == "use":
		player.use_requested = true


func _build_snapshot() -> Dictionary:
	var crew := {}
	for player in get_tree().get_nodes_in_group("crew"):
		crew[player.player_index] = [player.position, player.get_node("Visual").rotation.y, player.knocked]
	var items := {}
	for item in get_tree().get_nodes_in_group("items"):
		items[item.net_id] = [item.kind, item.position, item.rotation]
	var leaks := []
	for breach in _ship.get_node("HullSystem").breaches():
		leaks.append([breach.state, breach.has_plank, breach.is_plugged, breach.progress, breach._warning_left])
	var engine := _ship.get_node("EngineSystem")
	var pipe := _ship.get_node("CoolingPipe")
	var handling := _ship.get_node("ShipHandling")
	var stations := {}
	for station in get_tree().get_nodes_in_group("stations"):
		var indexes := []
		for player in station.occupants:
			indexes.append(player.player_index)
		stations[String(_ship.get_path_to(station))] = [station.status_text, indexes]
	return {
		"t": _voyage.elapsed,
		"ship": [_ship.position, _ship.rotation],
		"crew": crew,
		"items": items,
		"leaks": leaks,
		"sys": [_ship.get_node("HullSystem").water, engine.heat, engine.fuel, engine.stall_left, engine.warning_left,
				engine.vent_ready_in, pipe.broken, pipe.progress, _ship.get_node("RudderSystem").state,
				0.0, handling.throttle, handling.speed],
		"stock": [_ship.get_node("PlankBox").stock, _ship.get_node("PinBox").stock],
		"stations": stations,
	}


# --- Both ------------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	if role == "offline" or not multiplayer.has_multiplayer_peer():
		return
	if role == "client":
		_send_input()
		return
	_send_left -= delta
	if _send_left <= 0.0 and not multiplayer.get_peers().is_empty():
		_send_left = SEND_INTERVAL
		_snapshot.rpc(_build_snapshot())


func _player(index: int) -> Node3D:
	for player in get_tree().get_nodes_in_group("crew"):
		if player.player_index == index:
			return player
	return null
