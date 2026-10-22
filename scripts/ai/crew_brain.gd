extends Node
## The AI crew's shared brain (one per voyage). Humans choose first: whatever station a human is
## using is theirs. Every half second each AI picks between its primary and secondary job by need:
## an urgent secondary (a leak, a flooding hold) beats a routine primary (a calm sea at the chart).
## With neither needed, it goes wherever help is most urgent.

const JOBS := ["helm", "navigator", "engine", "pump", "carpenter", "cargo"]
const STATION_FOR := {"helm": "Helm", "navigator": "MapTable", "engine": "Engine", "pump": "Pump"}
const LABELS := {"helm": "Helm", "navigator": "Navigator", "engine": "Engine", "pump": "Pump",
		"carpenter": "Carpenter", "cargo": "Cargo"}

@export var ship: Node3D
@export var think_interval := 0.5

var assignments := {} ## AI player -> job they are doing now

var _think_left := 0.0


func _ready() -> void:
	add_to_group("crew_brain")


## How much a job needs someone right now: 0 = not at all, 1 = routine, 2 = urgent, 3 = critical.
func need(job: String) -> int:
	if STATION_FOR.has(job) and _human_at(STATION_FOR[job]):
		return 0 # a human has it
	if job == "navigator" and _human_at("Telescope"):
		return 0
	match job:
		"helm":
			return 3 # someone must always steer
		"navigator":
			if _rocks_ahead(45.0):
				return 3 # a rock close ahead: the captain needs the callouts now
			return 2 if _rocks_ahead() else 1
		"engine":
			var engine := ship.get_node("EngineSystem")
			if engine.is_warning() or engine.fuel < 0.15:
				return 3
			return 2 if engine.fuel < 0.5 or engine.heat > 0.8 else 1
		"pump":
			var water: float = ship.get_node("HullSystem").water
			return 3 if water > 0.5 else (2 if water > 0.2 else (1 if water > 0.02 else 0))
		"carpenter":
			if carpenter_tasks().is_empty():
				return 0
			return 3 if ship.get_node("HullSystem").water > 0.5 else 2
		"cargo":
			return 1 if not loose_crates().is_empty() or _fraying_crate() != null else 0
	return 0


func job_needed(job: String) -> bool:
	return need(job) > 0


## Hidden rocks within reach of the chart (plus a little warning distance) ahead of the bow.
func _rocks_ahead(within := -1.0) -> bool:
	var yaw := ship.rotation.y
	var fwd := Vector3(cos(yaw), 0.0, -sin(yaw))
	var reach := 100.0
	var voyage := ship.get_parent()
	if "contract" in voyage and voyage.contract:
		reach = voyage.contract.chart_range + 30.0
	if within > 0.0:
		reach = within
	for rock in get_tree().get_nodes_in_group("rocks"):
		if not rock.hidden:
			continue
		var along: float = (rock.global_position - ship.global_position).dot(fwd)
		if along > -5.0 and along < reach:
			return true
	return false


func _human_at(station_name: String) -> bool:
	var station := ship.get_node_or_null(station_name)
	if station == null:
		return false
	for player in station.readers():
		if not player.has_node("AICrew"):
			return true
	return false


func _exclusive(job: String) -> bool:
	return job in ["helm", "navigator", "engine", "pump"]


func _physics_process(delta: float) -> void:
	_think_left -= delta
	if _think_left > 0.0:
		return
	_think_left = think_interval
	think()


## Hands out jobs: humans first (by being there), then each AI in player order.
func think() -> void:
	var taken := {}
	var ais := []
	for player in get_tree().get_nodes_in_group("crew"):
		if player.has_node("AICrew"):
			ais.append(player)
	ais.sort_custom(func(a, b): return a.player_index < b.player_index)
	assignments.clear()
	for player in ais:
		var ai: Node = player.get_node("AICrew")
		# Finish an errand: someone carrying a plank or a pin keeps carpentering while it's needed.
		if player.carried and player.carried.kind in ["plank", "pin"] and need("carpenter") > 0:
			assignments[player] = "carpenter"
			continue
		var job := ""
		var best := 0
		for wanted in [ai.primary, ai.secondary]: # ties go to the primary
			if wanted == "" or (_exclusive(wanted) and taken.has(wanted)):
				continue
			var level := need(wanted)
			if level > best:
				job = wanted
				best = level
		# Something critical nobody covers beats anything less than critical.
		for level in [3, 2]:
			if best >= level:
				break
			for fallback in ["helm", "pump", "carpenter", "engine", "navigator", "cargo"]:
				if need(fallback) == level and not (_exclusive(fallback) and taken.has(fallback)):
					job = fallback
					best = level
					break
		if job == "":
			job = ai.primary # nothing urgent: stay near your post
		taken[job] = true
		assignments[player] = job


func job_of(player: Node3D) -> String:
	return assignments.get(player, "")


# --- What needs fixing ------------------------------------------------------------

## Carpenter work, most urgent first: [kind, target]. Kinds: "hammer", "patch", "pipe", "rudder".
func carpenter_tasks() -> Array:
	var tasks := []
	var hull := ship.get_node("HullSystem")
	for breach in hull.breaches():
		if breach.state != 0 and breach.has_plank and breach.occupants.size() < 2:
			tasks.append(["hammer", breach])
	for breach in hull.breaches():
		if breach.state != 0 and not breach.has_plank:
			tasks.append(["patch", breach])
	var pipe := ship.get_node("CoolingPipe")
	if pipe.broken and pipe.occupants.size() < 2:
		tasks.append(["pipe", pipe])
	if ship.get_node("RudderSystem").is_damaged() and (ship.get_node("PinBox").stock > 0 or _loose("pin") != null):
		tasks.append(["rudder", ship.get_node("Helm")])
	return tasks


func loose_crates() -> Array:
	var loose := []
	for crate in get_tree().get_nodes_in_group("cargo"):
		if not crate.lashed and crate.carrier == null and crate.get_parent() and ship.is_ancestor_of(crate):
			loose.append(crate)
	return loose


func _fraying_crate() -> Node3D:
	var cargo := ship.get_node("LoadSystem")
	var crate = cargo._fraying
	return crate if crate and is_instance_valid(crate) and crate.lashed else null


func fraying_crate() -> Node3D:
	return _fraying_crate()


## A loose item of this kind lying on the deck, if any.
func _loose(kind: String) -> Node3D:
	for item in get_tree().get_nodes_in_group("items"):
		if item.kind == kind and item.carrier == null and not item.lashed and ship.is_ancestor_of(item):
			return item
	return null


func loose_item(kind: String) -> Node3D:
	return _loose(kind)
