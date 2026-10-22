extends Node
## An AI crewmate (a child of a crew member). It drives the same stick and buttons a human would,
## so it follows the same rules: walk there, press Use, hold up to shovel, Jump to vent.
## Its job comes from the CrewBrain: primary job, secondary job, or wherever help is needed.

const STATION_FOR := {"helm": "Helm", "navigator": "MapTable", "engine": "Engine", "pump": "Pump"}

@export var primary := "engine"
@export var secondary := "pump"
@export var arrive_distance := 0.6
@export var callout_interval := 2.5

var job := "" ## what it is doing right now (for tests and the label)
var target: Node3D = null ## the thing it is working on (carpenter, cargo)

var _player: CharacterBody3D
var _ship: Node3D
var _brain: Node
var _bubble: Label3D
var _bubble_left := 0.0
var _use_cooldown := 0.0
var _callout_left := 0.0
var _reverse_left := 0.0
var _shovelling := false
var _progress_check := 0.6
var _last_position := Vector3.ZERO
var _sidestep_left := 0.0
var _sidestep := Vector2.ZERO
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	add_to_group("ai_crew")
	_player = get_parent()
	_player.get_node("PlayerInput").enabled = false
	_ship = _player.get_parent().get_parent() as Node3D
	_brain = get_tree().get_first_node_in_group("crew_brain")
	_ship.get_node("ShipHandling").impact.connect(func(_rock): _reverse_left = 2.0)
	_rng.seed = _player.player_index * 31
	_bubble = Label3D.new()
	_bubble.name = "Bubble"
	_bubble.position = Vector3(0, 3.6, 0)
	_bubble.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_bubble.no_depth_test = true
	_bubble.font_size = 52
	_bubble.outline_size = 14
	_bubble.modulate = Color(1.0, 0.95, 0.6)
	_bubble.visible = false
	_player.add_child(_bubble)
	_player.get_node("Label").text = "P%d AI" % _player.player_index


func say(text: String, seconds := 2.2) -> void:
	_bubble.text = text
	_bubble.visible = true
	_bubble_left = seconds


func _physics_process(delta: float) -> void:
	_use_cooldown -= delta
	_reverse_left -= delta
	if _bubble_left > 0.0:
		_bubble_left -= delta
		_bubble.visible = _bubble_left > 0.0
	_player.move_input = Vector2.ZERO
	if _player.knocked > 0.0:
		return
	job = _brain.job_of(_player) if _brain else primary
	if _player.station and _station_job(_player.station) != job:
		_press_use() # not my job any more: let go
		return
	match job:
		"helm", "engine", "pump":
			_run_station(job, delta)
		"navigator":
			_navigate(delta)
		"carpenter":
			_carpentry(delta)
		"cargo":
			_cargo(delta)


func _station_job(station: Node3D) -> String:
	match String(station.name):
		"Helm":
			return "helm"
		"Engine":
			return "engine"
		"Pump":
			return "pump"
		"MapTable", "Telescope":
			return "navigator"
	return "carpenter" # leaks and the cooling pipe


# --- Moving and pressing ------------------------------------------------------------

## Walks toward a point on the deck. Returns true once there.
func _walk_to(point: Vector3, delta: float, arrive := arrive_distance) -> bool:
	var to := point - _player.global_position
	to.y = 0.0
	if to.length() <= arrive:
		_progress_check = 0.6
		return true
	var direction := Vector2(to.x, to.z).normalized()
	if _sidestep_left > 0.0:
		_sidestep_left -= delta
		direction = (direction * 0.4 + _sidestep).normalized()
	_player.move_input = direction
	# Stuck behind the mast or a crate? Step sideways for a moment.
	_progress_check -= delta
	if _progress_check <= 0.0:
		_progress_check = 0.6
		if _player.global_position.distance_to(_last_position) < 0.25 and _sidestep_left <= 0.0:
			var side := 1.0 if _rng.randf() < 0.5 else -1.0
			_sidestep = Vector2(-direction.y, direction.x) * side
			_sidestep_left = 0.7
		_last_position = _player.global_position
	return false


func _press_use() -> void:
	if _use_cooldown <= 0.0:
		_player.use_requested = true
		_use_cooldown = 0.5


func _drop_carried() -> void:
	if _player.carried:
		_player.carried.drop()


# --- Station jobs -----------------------------------------------------------------

func _run_station(station_job: String, delta: float) -> void:
	var station := _ship.get_node(STATION_FOR[station_job])
	if _player.station == station:
		match station_job:
			"helm":
				_steer()
			"engine":
				_stoke()
		return
	_drop_carried()
	if _walk_to(station.global_position, delta, 0.9):
		_press_use()


func _stoke() -> void:
	var engine := _ship.get_node("EngineSystem")
	if engine.fuel < 0.6:
		_shovelling = true
	elif engine.fuel > 0.95:
		_shovelling = false
	_player.move_input = Vector2(0, -1) if _shovelling else Vector2.ZERO
	if engine.heat > 0.9 and engine.vent_ready_in <= 0.0:
		_player.jump_requested = true # vent steam


func _steer() -> void:
	var handling := _ship.get_node("ShipHandling")
	var engine := _ship.get_node("EngineSystem")
	var wanted := 0.8
	var engineer_present: bool = _ship.get_node("Engine").is_active()
	if engine.heat > 0.85:
		wanted = 0.6 if engineer_present else 0.45
	if _reverse_left > 0.0:
		wanted = -0.3 # just hit something: back off
	var voyage := _ship.get_parent()
	if "finished" in voyage and voyage.finished:
		wanted = 0.0
	var stick_y := 0.0
	if handling.throttle < wanted - 0.03:
		stick_y = -1.0
	elif handling.throttle > wanted + 0.03:
		stick_y = 1.0
	_player.move_input = Vector2(_autopilot(), stick_y)


## Steers away from the known rocks ahead and back toward the middle of the channel, with a strong
## push away from the cliffs near its edges. Hidden rocks are only known while someone reads the map
## table (or the telescope marked them). The route runs along +X, so the channel is world Z.
func _autopilot() -> float:
	return steer_for(_ship.global_position, _ship.rotation.y, _known_rocks(), _channel_half_width())


## Stick x for a ship at here/yaw among known rocks: positive = steer to starboard.
static func steer_for(here: Vector3, yaw: float, rocks: Array, half_width: float) -> float:
	var fwd := Vector3(cos(yaw), 0.0, -sin(yaw))
	var right := Vector3(-fwd.z, 0.0, fwd.x)
	var go_starboard := clampf(-here.z / half_width, -1.0, 1.0) * 0.8 # pull to the middle, harder near the edges
	if absf(here.z) > half_width - 6.0:
		go_starboard -= signf(here.z) * 1.2 # too close to the cliffs: come back
	var toward_middle := -signf(here.z) if absf(here.z) > 1.0 else 1.0
	# Room to spare around rocks: half the hull (3.5 m) plus 3.5 m, or plus 2 m in a narrow channel.
	var margin := 5.5 if half_width < 20.0 else 7.0
	for rock in rocks:
		var offset: Vector3 = rock.global_position - here
		var along := offset.dot(fwd)
		if along < -5.0 or along > 80.0:
			continue
		var across := offset.dot(right)
		if absf(across) < rock.radius + margin:
			# Pass on the side away from the rock; nearly dead ahead, pass on the channel's middle side.
			var away := -signf(across) if absf(across) > 1.5 else toward_middle
			go_starboard += away * 1.5 * (1.0 - maxf(along, 0.0) / 80.0)
	var target_yaw := -clampf(go_starboard, -1.0, 1.0) * 0.6 # positive yaw = bow to port
	return clampf((yaw - target_yaw) * 4.0, -1.0, 1.0) # stick right turns to starboard


func _known_rocks() -> Array:
	var chart_on: bool = _ship.get_node("MapTable").is_active()
	var chart_range := _chart_range()
	var known := []
	for rock in get_tree().get_nodes_in_group("rocks"):
		if not rock.hidden:
			continue # cliffs: the lane stays inside the channel instead
		var distance: float = rock.global_position.distance_to(_ship.global_position)
		if rock.revealed or (chart_on and distance <= chart_range) or _marked(rock):
			known.append(rock)
	return known


func _channel_half_width() -> float:
	var voyage := _ship.get_parent()
	if "contract" in voyage and voyage.contract:
		return voyage.contract.coast_half_width - 9.0
	return 30.0


func _chart_range() -> float:
	var voyage := _ship.get_parent()
	if "contract" in voyage and voyage.contract:
		return voyage.contract.chart_range
	return 70.0


func _marked(rock: Node3D) -> bool:
	for child in rock.get_children():
		if child.is_in_group("spot_markers") and child.visible:
			return true
	return false


# --- Navigator ----------------------------------------------------------------------

func _navigate(delta: float) -> void:
	_drop_carried()
	# In fog the chart sees little: the navigator takes the telescope instead.
	var telescope := _ship.get_node("Telescope")
	if telescope.enabled:
		if _player.station != telescope:
			if _walk_to(telescope.global_position, delta, 0.9):
				_press_use()
			return
	else:
		var table := _ship.get_node("MapTable")
		if not _walk_to(table.global_position, delta, 0.8):
			return
	_callout_left -= delta
	if _callout_left <= 0.0:
		_callout_left = callout_interval
		var line := callout()
		if line != "":
			say(line)


## What the navigator shouts: the nearest dangerous rock as a clock bearing, or the port.
func callout() -> String:
	var yaw := _ship.rotation.y
	var fwd := Vector3(cos(yaw), 0.0, -sin(yaw))
	var right := Vector3(-fwd.z, 0.0, fwd.x)
	var best: Node3D = null
	var best_distance := INF
	for rock in get_tree().get_nodes_in_group("rocks"):
		if not rock.hidden:
			continue
		var offset: Vector3 = rock.global_position - _ship.global_position
		offset.y = 0.0
		var along := offset.dot(fwd)
		var sight := _chart_range()
		var telescope := _ship.get_node("Telescope")
		if telescope.enabled and _player.station == telescope:
			sight = telescope.spot_range
		if along <= 0.0 or offset.length() > sight or absf(offset.dot(right)) > rock.radius + 14.0:
			continue
		if offset.length() < best_distance:
			best = rock
			best_distance = offset.length()
	if best:
		var offset: Vector3 = best.global_position - _ship.global_position
		return "Rock, %d o'clock, %d m!" % [clock_hour(offset.dot(fwd), offset.dot(right)), roundi(best_distance)]
	var voyage := _ship.get_parent()
	if "finish_x" in voyage and voyage.finish_x - _ship.global_position.x < 150.0:
		return "Port ahead, %d m!" % roundi(voyage.finish_x - _ship.global_position.x)
	return "Clear ahead!" if _rng.randf() < 0.3 else ""


## Clock bearing from the bow: 12 = dead ahead, 3 = starboard, 9 = port.
static func clock_hour(along: float, across: float) -> int:
	var degrees := rad_to_deg(atan2(across, along))
	var hour := roundi(degrees / 30.0)
	if hour <= 0:
		hour += 12
	return hour


# --- Carpenter ------------------------------------------------------------------------

func _carpentry(delta: float) -> void:
	var task := _pick_task()
	if task.is_empty():
		target = null
		_drop_carried()
		return
	target = task[1]
	match task[0]:
		"hammer", "pipe":
			_drop_carried()
			if _player.station == target:
				return # working on it
			if _walk_to(target.global_position, delta, 0.9):
				_press_use()
		"patch":
			_patch(target, delta)
		"rudder":
			_fetch_and_bring("pin", _ship.get_node("PinBox"), target, delta)


func _patch(breach: Node3D, delta: float) -> void:
	var carried: Node3D = _player.carried
	if carried and (carried.kind == "plank" or (carried.kind == "crate" and not breach.is_plugged)):
		if _walk_to(breach.global_position, delta, 0.9):
			_press_use()
		return
	var box := _ship.get_node("PlankBox")
	if box.stock > 0 or _brain.loose_item("plank") != null:
		_fetch_and_bring("plank", box, breach, delta)
		return
	# Out of planks: stuff a cargo crate in the hole (the cargo is lost).
	if breach.is_plugged:
		return
	var crate := _nearest_crate()
	if crate == null:
		return
	if carried and carried != crate:
		_drop_carried()
	if _walk_to(crate.global_position, delta, 0.9):
		_press_use()


## Gets an item (a loose one on the deck, or one from its box) and brings it to a target.
func _fetch_and_bring(kind: String, box: Node3D, destination: Node3D, delta: float) -> void:
	var carried: Node3D = _player.carried
	if carried and carried.kind == kind:
		if _walk_to(_approach_point(destination), delta, 0.6):
			_press_use()
		return
	_drop_carried()
	var loose: Node3D = _brain.loose_item(kind)
	var source: Node3D = loose if loose else box
	if _walk_to(source.global_position, delta, 0.9):
		_press_use()


## The most urgent carpenter task nobody else is already on (two may hammer the same plank).
## Where to stand to reach a station. The helm's stand point is behind the wheel post (and maybe
## taken by the captain), so deliveries come alongside it instead.
func _approach_point(station: Node3D) -> Vector3:
	if String(station.name) == "Helm":
		var side := 1.0 if _player.global_position.distance_to(station.to_global(Vector3(0.3, 0, 0.95))) \
				< _player.global_position.distance_to(station.to_global(Vector3(0.3, 0, -0.95))) else -1.0
		return station.to_global(Vector3(0.3, 0.0, 0.95 * side))
	return station.global_position


func _pick_task() -> Array:
	var tasks: Array = _brain.carpenter_tasks()
	for task in tasks:
		var others := 0
		for ai in get_tree().get_nodes_in_group("ai_crew"):
			if ai != self and ai.target == task[1] and ai.job == "carpenter":
				others += 1
		var limit := 2 if task[0] in ["hammer", "pipe"] else 1
		if others < limit:
			return task
	return tasks[0] if not tasks.is_empty() else []


func _nearest_crate() -> Node3D:
	var best: Node3D = null
	var best_distance := INF
	for crate in get_tree().get_nodes_in_group("cargo"):
		var distance := _player.global_position.distance_to(crate.global_position)
		if crate.carrier == null and distance < best_distance:
			best = crate
			best_distance = distance
	return best


# --- Cargo -----------------------------------------------------------------------------

func _cargo(delta: float) -> void:
	var carried: Node3D = _player.carried
	if carried and carried.kind == "crate":
		var spot: Marker3D = _ship.get_node("CargoBay").nearest_free_spot(_player.global_position)
		if spot and _walk_to(spot.global_position, delta, 0.5):
			_press_use()
		return
	_drop_carried()
	var crate: Node3D = _brain.fraying_crate()
	if crate == null:
		var loose: Array = _brain.loose_crates()
		crate = loose[0] if not loose.is_empty() else null
	target = crate
	if crate and _walk_to(crate.global_position, delta, 0.9):
		_press_use()
