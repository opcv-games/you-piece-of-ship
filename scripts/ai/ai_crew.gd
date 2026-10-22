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
var _intent := "" ## the last plan shown in a thought bubble
var _intent_quiet := 0.0
var _use_cooldown := 0.0
var _callout_left := 0.0
var _reverse_left := 0.0
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
	# This voyage's own brain (never another voyage's that is being cleared away).
	var voyage := _ship.get_parent()
	_brain = voyage.get_node_or_null("CrewBrain") if voyage else null
	if _brain == null:
		_brain = get_tree().get_first_node_in_group("crew_brain")
	_ship.get_node("ShipHandling").impact.connect(func(_rock): _reverse_left = 2.0)
	_rng.seed = _player.player_index * 31
	_player.get_node("Label").text = tr("P%d AI") % _player.player_index


## A callout everyone should hear (the navigator's rocks): a yellow shout bubble.
func say(text: String, seconds := 2.2) -> void:
	_player.think(text, seconds, "shout")
	_intent_quiet = seconds


## What I'm about to do, in a thought bubble, shown when the plan changes (not every frame).
func intend(text: String) -> void:
	if text == _intent or _intent_quiet > 0.0:
		return
	_intent = text
	_player.think(text, 2.0, "think")


func _physics_process(delta: float) -> void:
	_use_cooldown -= delta
	_reverse_left -= delta
	_intent_quiet -= delta
	_player.move_input = Vector2.ZERO
	if _player.knocked > 0.0:
		return
	job = _brain.job_of(_player) if _brain else primary
	if _player.station and _player.station.is_in_group("fishing_spots"):
		if _fishing_ok() and job != "navigator" and job != "engine" and job != "helm" and job != "pump":
			_fish()
			return
		_press_use() # something needs doing: reel in
		return
	if _player.station and _station_job(_player.station) != job:
		_press_use() # not my job any more: let go
		return
	match job:
		"engine":
			_engineer(delta)
		"helm", "pump":
			_run_station(job, delta)
		"navigator":
			_navigate(delta)
		"carpenter":
			_carpentry(delta)
		"cargo":
			_cargo(delta)
		"gunner":
			_gunner(delta)


func _station_job(station: Node3D) -> String:
	if station.is_in_group("cannons"):
		return "gunner"
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


## Uses a specific thing (a station, a box, an item, the pile...), never just "whatever is nearest".
func _use_on(thing: Node) -> void:
	if _use_cooldown <= 0.0:
		_player.interact_with(thing)
		_use_cooldown = 0.5


func _drop_carried() -> void:
	if _player.carried:
		_player.carried.drop()


# --- Station jobs -----------------------------------------------------------------

func _run_station(station_job: String, delta: float) -> void:
	var station := _ship.get_node(STATION_FOR[station_job])
	if _player.station == station:
		if station_job == "helm":
			_steer()
		return
	_drop_carried()
	intend(tr("To the helm!") if station_job == "helm" else tr("Pumping!"))
	if _walk_to(station.global_position, delta, 0.9):
		_use_on(station)


## The engineer's loop: fill a shovel at the coal pile, carry it to the furnace, feed it. When the
## engine runs hot, take the controls (empty-handed) and vent. With the firebox full, wait by the
## furnace with a loaded shovel, ready.
func _engineer(delta: float) -> void:
	var engine := _ship.get_node("EngineSystem")
	var furnace := _ship.get_node("Engine")
	var carrying_coal: bool = _player.carried != null and _player.carried.kind == "coal"
	var vent_at: float = engine.heat_cap_threshold # above this, top speed is capped: vent
	if _player.station == furnace:
		if engine.heat > vent_at and engine.vent_ready_in <= 0.0:
			intend(tr("Too hot! Venting!"))
			_player.jump_requested = true # vent steam
		elif engine.heat < 0.6 or engine.vent_ready_in > 0.0 and engine.fuel < 0.7:
			_press_use() # cool enough (or coal needed): let go of the controls
		return
	if engine.heat > vent_at and engine.vent_ready_in <= 0.0 and not carrying_coal:
		if _walk_to(furnace.global_position, delta, 0.9):
			_use_on(furnace)
		return
	if _player.carried and not carrying_coal:
		_drop_carried()
	if carrying_coal:
		intend(tr("Coal for the furnace!"))
		if _walk_to(furnace.global_position, delta, 1.0) and engine.fuel < 0.9:
			_use_on(furnace) # feed the fire
		return
	var pile := _ship.get_node("CoalPile")
	if engine.fuel < 0.9:
		intend(tr("Need coal!"))
	if _walk_to(pile.global_position, delta, 1.0):
		_use_on(pile)


func _steer() -> void:
	var handling := _ship.get_node("ShipHandling")
	var engine := _ship.get_node("EngineSystem")
	var wanted := 0.8
	if engine.heat > 0.93 or engine.is_warning():
		wanted = 0.45 # about to overheat: ease off until the engineer vents
	if _brain and _brain.threat() != null and engine.heat < 0.9 and not engine.is_warning():
		wanted = 1.0 # pirates: full speed to outrun them
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
		var centre: Vector3 = rock.avoid_centre() if rock.has_method("avoid_centre") else rock.global_position
		var size: float = rock.avoid_radius() if rock.has_method("avoid_radius") else rock.radius
		var offset: Vector3 = centre - here
		var along := offset.dot(fwd)
		if along < -5.0 - size or along > 80.0 + size:
			continue
		var across := offset.dot(right)
		if absf(across) < size + margin:
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
		if _is_cliff(rock):
			continue # cliffs: the lane stays inside the channel instead
		if not rock.hidden:
			known.append(rock) # wrecks, whales, sirens, atolls: everyone can see them
			continue
		var distance: float = rock.global_position.distance_to(_ship.global_position)
		if rock.revealed or (chart_on and distance <= chart_range) or _marked(rock):
			known.append(rock)
	return known


static func _is_cliff(rock: Node3D) -> bool:
	return ("kind" in rock and rock.kind == "cliff") or (not ("kind" in rock) and not rock.hidden)


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
	intend(tr("To the map!"))
	# In fog the chart sees little: the navigator takes the telescope instead.
	var telescope := _ship.get_node("Telescope")
	if telescope.enabled:
		if _player.station != telescope:
			if _walk_to(telescope.global_position, delta, 0.9):
				_use_on(telescope)
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
		if _is_cliff(rock):
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
		var hour := clock_hour(offset.dot(fwd), offset.dot(right))
		var what: String = best.call_name() if best.has_method("call_name") else "Rock"
		if what == "Siren":
			return tr("Siren, %d o'clock! Don't listen!") % hour
		return tr(what + ", %d o'clock, %d m!") % [hour, roundi(best_distance)]
	var voyage := _ship.get_parent()
	if "finish_x" in voyage and voyage.finish_x - _ship.global_position.x < 150.0:
		return tr("Port ahead, %d m!") % roundi(voyage.finish_x - _ship.global_position.x)
	return tr("Clear ahead!") if _rng.randf() < 0.3 else ""


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
		_idle_work(delta)
		return
	target = task[1]
	intend({"hammer": tr("Hammering the leak!"), "pipe": tr("Fixing the pipe!"), "patch": tr("Going to fix leak!"),
			"rudder": tr("Fetching a rudder pin!")}.get(task[0], ""))
	match task[0]:
		"hammer", "pipe":
			_drop_carried()
			if _player.station == target:
				return # working on it
			if _walk_to(target.global_position, delta, 0.9):
				_use_on(target)
		"patch":
			_patch(target, delta)
		"rudder":
			_fetch_and_bring("pin", _ship.get_node("PinBox"), target, delta)


func _patch(breach: Node3D, delta: float) -> void:
	var carried: Node3D = _player.carried
	if carried and (carried.kind == "plank" or (carried.kind == "crate" and not breach.is_plugged)):
		if _walk_to(breach.global_position, delta, 0.9):
			_use_on(breach)
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
		_use_on(crate)


## Gets an item (a loose one on the deck, or one from its box) and brings it to a target.
func _fetch_and_bring(kind: String, box: Node3D, destination: Node3D, delta: float) -> void:
	var carried: Node3D = _player.carried
	if carried and carried.kind == kind:
		if _walk_to(_approach_point(destination), delta, 0.6):
			_use_on(destination)
		return
	_drop_carried()
	var loose: Node3D = _brain.loose_item(kind)
	var source: Node3D = loose if loose else box
	if _walk_to(source.global_position, delta, 1.2): # items can be reached from 1.3 m
		_use_on(source)


## The most urgent carpenter task nobody else is already on (two may hammer the same plank).
## Where to stand to reach a station. The helm's stand point is behind the wheel post (and maybe
## taken by the captain), so deliveries come alongside it instead.
func _approach_point(station: Node3D) -> Vector3:
	if String(station.name) == "Helm":
		var side := 1.0 if _player.global_position.distance_to(station.to_global(Vector3(0.3, 0, 0.95))) \
				< _player.global_position.distance_to(station.to_global(Vector3(0.3, 0, -0.95))) else -1.0
		return station.to_global(Vector3(0.3, 0.0, 0.95 * side))
	return station.global_position


## Nothing to repair: still be useful. Pump any water, help keep the furnace fed, re-tie loose
## cargo, or hold a plank ready near the middle of the deck for the next leak.
func _idle_work(delta: float) -> void:
	var hull := _ship.get_node("HullSystem")
	var pump := _ship.get_node("Pump")
	if hull.water > 0.01 and (pump.occupant == null or pump.occupant == _player):
		_drop_carried()
		if _player.station != pump and _walk_to(pump.global_position, delta, 0.9):
			_use_on(pump)
		return
	if not _brain.loose_crates().is_empty() or _brain.fraying_crate() != null:
		_cargo(delta)
		return
	var engine := _ship.get_node("EngineSystem")
	var carrying: Node3D = _player.carried
	if engine.fuel < 0.7 or (carrying and carrying.kind == "coal"):
		_engineer(delta) # lend a hand with the coal
		return
	if _fishing_ok():
		var spot := _free_fishing_spot()
		if spot:
			_drop_carried()
			intend(tr("Gone fishing!"))
			if _walk_to(spot.global_position, delta, 0.8):
				_use_on(spot)
			return
	if carrying == null and _ship.get_node("PlankBox").stock > 1:
		var box := _ship.get_node("PlankBox")
		if _walk_to(box.global_position, delta, 0.9):
			_use_on(box)
		return
	if carrying and carrying.kind != "plank":
		_drop_carried()
	_walk_to(_ship.to_global(Vector3(-1.0, 0.0, 1.6 if _player.player_index % 2 == 0 else -1.6)), delta, 0.8)


## All's well aboard: no water, no leaks, nothing to repair, no loose cargo, coal and heat fine.
func _fishing_ok() -> bool:
	var hull := _ship.get_node("HullSystem")
	var engine := _ship.get_node("EngineSystem")
	if hull.water > 0.01 or not _brain.carpenter_tasks().is_empty() or not _brain.loose_crates().is_empty():
		return false
	for breach in hull.breaches():
		if breach.state != 0:
			return false
	return engine.fuel >= 0.6 and engine.heat < engine.heat_cap_threshold and _brain.fraying_crate() == null \
			and _brain.threat() == null


func _free_fishing_spot() -> Node3D:
	for spot in get_tree().get_nodes_in_group("fishing_spots"):
		if _ship.is_ancestor_of(spot) and (spot.occupant == null or spot.occupant == _player):
			return spot
	return null


## Fishing: strike when the float dips (most of the time: nobody's perfect).
func _fish() -> void:
	var spot: Node3D = _player.station
	if spot.phase == spot.Phase.BITE and spot.bite_left < spot.bite_window - 0.25:
		if _rng.randf() < 0.75:
			_player.jump_requested = true
		else:
			spot.bite_left = 0.0 # missed it


## Whether this crewmate is busy right now: moving, working a station, carrying something, or
## reading the chart (tests check that nobody stands around).
func is_working() -> bool:
	if _player.station or _player.carried or _player.knocked > 0.0:
		return true
	if Vector2(_player.velocity.x, _player.velocity.z).length() > 0.4:
		return true
	return job == "navigator" and _ship.get_node("MapTable").crew_nearby().has(_player)


func _pick_task() -> Array:
	var tasks: Array = _brain.carpenter_tasks()
	# Already holding the right part? Finish that repair first (no dropping it halfway).
	var carried: Node3D = _player.carried
	if carried:
		for task in tasks:
			if (carried.kind == "pin" and task[0] == "rudder") or (carried.kind == "plank" and task[0] == "patch"):
				return task
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


# --- Gunner ------------------------------------------------------------------------------

## Fight the pirates: load a cannon on their side, aim at them, fire; fetch another ball.
func _gunner(delta: float) -> void:
	var enemy: Node3D = _brain.threat()
	if enemy == null:
		if _player.station:
			_press_use()
		return
	var right: Vector3 = _ship.global_basis.z
	var side := signf((enemy.global_position - _ship.global_position).dot(right))
	var cannon: Node3D = _player.station if _player.station and _player.station.is_in_group("cannons") else null
	if cannon:
		if not cannon.loaded:
			_press_use() # fired: go and fetch another ball
			return
		var wanted := _aim_for(cannon, enemy)
		if absf(wanted - cannon.aim) > 0.06:
			_player.move_input = Vector2(signf(wanted - cannon.aim) * cannon.side, 0.0)
		else:
			intend(tr("Fire!"))
			_player.jump_requested = true
		return
	var loaded := _cannon_on(side, true)
	if loaded and (_player.carried == null or _player.carried.kind != "ball"):
		_drop_carried()
		intend(tr("To the cannon!"))
		if _walk_to(loaded.global_position, delta, 0.8):
			_use_on(loaded)
		return
	var empty := _cannon_on(side, false)
	if empty == null:
		return
	intend(tr("Load the cannon!"))
	_fetch_and_bring("ball", _ship.get_node("BallRack"), empty, delta)


## A free cannon on that side, loaded or not.
func _cannon_on(side: float, loaded: bool) -> Node3D:
	var best: Node3D = null
	var best_distance := INF
	for cannon in get_tree().get_nodes_in_group("cannons"):
		if not _ship.is_ancestor_of(cannon) or cannon.side != side or cannon.loaded != loaded:
			continue
		if cannon.occupant != null and cannon.occupant != _player:
			continue
		var distance := _player.global_position.distance_to(cannon.global_position)
		if distance < best_distance:
			best = cannon
			best_distance = distance
	return best


## The aim (-1..1) that points this cannon at the enemy.
static func _aim_for(cannon: Node3D, enemy: Node3D) -> float:
	var to := enemy.global_position - cannon.global_position
	var out: Vector3 = cannon.global_basis.z * cannon.side
	var along: Vector3 = cannon.global_basis.x
	var angle := atan2(to.dot(along), to.dot(out))
	return clampf(angle / deg_to_rad(cannon.aim_limit_degrees), -1.0, 1.0)


# --- Cargo -----------------------------------------------------------------------------

func _cargo(delta: float) -> void:
	var carried: Node3D = _player.carried
	if carried and carried.kind == "crate":
		var spot: Marker3D = _ship.get_node("CargoBay").nearest_free_spot(_player.global_position)
		if spot and _walk_to(spot.global_position, delta, 0.5):
			_use_on(_ship.get_node("CargoBay"))
		return
	_drop_carried()
	var crate: Node3D = _brain.fraying_crate()
	if crate == null:
		var loose: Array = _brain.loose_crates()
		crate = loose[0] if not loose.is_empty() else null
	target = crate
	if crate:
		intend(tr("Tying down cargo!"))
	if crate and _walk_to(crate.global_position, delta, 0.9):
		_use_on(crate)
