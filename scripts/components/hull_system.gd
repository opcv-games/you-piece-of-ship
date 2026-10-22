extends Node
## Hull and water (DESIGN.md section 13). Rock impacts crack the hull at the nearest free leak
## spot; open leaks let water in; the pump takes it out. Water makes the ship heavier:
## slower, harder to turn, lower in the sea and listing toward the leaks. A full ship sinks,
## but never within 60 s of the first failure (fairness rule).

signal breach_opened(breach: Node3D)
signal breach_sealed(breach: Node3D)
signal breach_plugged(breach: Node3D)
signal ship_sunk

@export var flow_rate := 1.0 / 70.0 ## water (0..1) per second for each fully open leak
@export var pump_rate := 1.0 / 18.0 ## water removed per second while someone pumps
@export var auto_pump_rate := 0.0 ## slow automatic pump (3-player crews)
@export_range(0.0, 1.0) var speed_loss := 0.45 ## top speed lost when full of water
@export_range(0.0, 1.0) var turn_loss := 0.3
@export var sink_metres := 0.7 ## how much lower the ship sits when full
@export var list_degrees := 6.0 ## heel toward the leaks when full
@export var sink_grace_seconds := 60.0
@export var cracks_from_rocks := true
@export var same_rock_grace := 8.0 ## seconds before bumping the same rock again can crack more hull

var water := 0.0 ## 0 = dry, 1 = sunk
var sunk := false
var first_failure_at := -1.0 ## seconds since start when the first leak appeared
var elapsed := 0.0

var _ship: Node3D
var _handling: Node
var _waves: Node
var _pump: Node3D
var _breaches: Array[Node3D] = []
var _deck_water: MeshInstance3D
var _last_rock: Node3D
var _last_rock_at := -INF


func _ready() -> void:
	_ship = get_parent()
	_handling = _ship.get_node("ShipHandling")
	_waves = _ship.get_node("WaveMotion")
	_pump = _ship.get_node_or_null("Pump")
	for child in _ship.get_children():
		if child.has_method("crack"):
			_breaches.append(child)
			child.opened.connect(func(): breach_opened.emit(child))
			child.sealed.connect(func(): breach_sealed.emit(child))
			child.plugged.connect(func(): breach_plugged.emit(child))
	_handling.rock_hit.connect(_on_rock_hit)
	_build_deck_water()


func breaches() -> Array[Node3D]:
	return _breaches


func open_breach_count() -> int:
	var count := 0
	for breach in _breaches:
		if breach.state != 0:
			count += 1
	return count


## Cracks the free leak spot nearest to a ship-local point. Returns it, or null if none is free.
func add_breach(near_local: Vector3) -> Node3D:
	var best: Node3D = null
	var best_distance := INF
	for breach in _breaches:
		if breach.state != 0:
			continue
		var distance := breach.position.distance_to(near_local)
		if distance < best_distance:
			best = breach
			best_distance = distance
	if best and best.crack():
		if first_failure_at < 0.0:
			first_failure_at = elapsed
		return best
	return null


func _on_rock_hit(rock: Node3D) -> void:
	if not cracks_from_rocks:
		return
	# Bouncing off the same rock again right away is one accident, not a new one.
	if rock == _last_rock and elapsed - _last_rock_at < same_rock_grace:
		return
	_last_rock = rock
	_last_rock_at = elapsed
	# One impact starts at most one new failure: a hard hit takes the rudder if it is intact.
	var rudder := _ship.get_node_or_null("RudderSystem")
	if rudder and rudder.try_damage(_handling.impact_speed / _handling.max_speed):
		return
	add_breach(_ship.to_local(rock.global_position))


func _physics_process(delta: float) -> void:
	step(delta)


func step(delta: float) -> void:
	elapsed += delta
	if sunk:
		return
	var inflow := 0.0
	var side := 0.0
	for breach in _breaches:
		var amount: float = breach.flow()
		inflow += amount
		side += amount * signf(breach.position.z)
	water += inflow * flow_rate * delta
	if _pump and _pump.is_active():
		water -= pump_rate * delta
	water -= auto_pump_rate * delta
	water = clampf(water, 0.0, 1.0)
	if first_failure_at >= 0.0 and elapsed - first_failure_at < sink_grace_seconds:
		water = minf(water, 0.95) # can't sink this soon after the first failure
	_apply_effects(side / maxf(inflow, 0.001) if inflow > 0.0 else 0.0)
	if water >= 1.0:
		sunk = true
		ship_sunk.emit()


func _apply_effects(leak_side: float) -> void:
	_handling.speed_limits["water"] = 1.0 - speed_loss * water
	_handling.turn_limits["water"] = 1.0 - turn_loss * water
	_waves.sink = sink_metres * water
	# Positive roll lowers starboard (+Z): list toward the side the water comes in.
	var current: float = _waves.list_sources.get("water", 0.0)
	var target := deg_to_rad(list_degrees) * water * leak_side
	_waves.list_sources["water"] = move_toward(current, target, deg_to_rad(2.0) * get_physics_process_delta_time())
	if _pump:
		_pump.status_text = "water %d%%" % roundi(water * 100.0)
	_deck_water.visible = water > 0.02
	var depth := 0.45 * water
	_deck_water.scale.y = maxf(depth, 0.001)
	_deck_water.position.y = depth * 0.5


func _build_deck_water() -> void:
	var mesh := BoxMesh.new()
	mesh.size = Vector3(_ship.deck_length - 0.4, 1.0, _ship.deck_width - 0.4)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.2, 0.5, 0.8, 0.55)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh.material = material
	_deck_water = MeshInstance3D.new()
	_deck_water.name = "DeckWater"
	_deck_water.mesh = mesh
	_deck_water.visible = false
	_ship.add_child.call_deferred(_deck_water)
