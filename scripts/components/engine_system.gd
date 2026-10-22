extends Node
## Engine heat and fuel (DESIGN.md section 13). Full throttle heats the engine; a heavy, flooded
## ship heats it faster (coupling rule 3). Above 80% heat top speed is capped; at 100% a
## 5 s warning (steam and whistle) then a 20 s stall, which also bursts the cooling pipe.
## The engineer shovels coal (hold up) and can vent steam (Jump): instant cooling that
## knocks over anyone standing close (emergency measure at a cost).

signal overheat_warning
signal stalled
signal restarted
signal vented(player: Node3D)
signal pipe_burst
signal pipe_fixed
signal out_of_fuel
signal fuel_low

@export_group("Heat")
@export var heat_rise := 0.05 ## heat per second at full throttle above the cool point
@export var cool_point := 0.55 ## throttle below which the engine cools down
@export var heat_cap_threshold := 0.8
@export_range(0.0, 1.0) var heat_cap_speed := 0.7 ## top speed factor while above the threshold
@export var warning_seconds := 5.0
@export var stall_seconds := 20.0
@export var water_heat_factor := 0.8 ## a full ship makes the engine heat this much faster
@export var burst_pipe_factor := 1.6 ## heat builds this much faster with a burst pipe
@export_group("Fuel")
## The coal pile a few steps away never runs out: keeping the firebox full takes someone's time.
@export var fuel_burn := 1.0 / 150.0 ## firebox used per second at full throttle (a full one lasts 2.5 min)
@export var shovel_load := 0.15 ## firebox filled by one full shovel of dry coal
@export_range(0.0, 1.0) var wet_coal_penalty := 0.35 ## top speed lost with a firebox of soaked coal
@export_range(0.0, 1.0) var wet_coal_burn := 0.4 ## a shovel of soaked coal gives this much less heat
@export var low_fuel := 0.25 ## below this, "COAL LOW!" shows over the engine for everyone
@export_range(0.0, 1.0) var min_fuel := 0.0 ## the firebox never drops below this (the Maiden Voyage uses 0.3)
@export_range(0.0, 1.0) var no_fuel_speed := 0.15
@export var pump_coal_burn := 0.0 ## coal per second the pump uses while running (bigger pumps)
@export_group("Vent")
@export var vent_cooling := 0.5
@export var vent_cooldown := 8.0
@export var vent_knock_radius := 3.0

var heat := 0.0
var fuel := 1.0
var coal_wetness := 0.0 ## how soaked the coal in the firebox is (0..1)
var stall_left := 0.0
var warning_left := 0.0
var vent_ready_in := 0.0

var _ship: Node3D
var _handling: Node
var _hull: Node
var _station: Node3D
var _pipe: Node3D
var _steam: CPUParticles3D


func _ready() -> void:
	_ship = get_parent()
	_handling = _ship.get_node("ShipHandling")
	_hull = _ship.get_node_or_null("HullSystem")
	_station = _ship.get_node("Engine")
	_pipe = _ship.get_node("CoolingPipe")
	_station.vent_requested.connect(vent)
	_station.coal_fed.connect(feed)
	_handling.impact.connect(_spill_shovels)
	_pipe.repaired.connect(func(): pipe_fixed.emit())
	_steam = _station.get_node_or_null("Steam")


func is_stalled() -> bool:
	return stall_left > 0.0


func is_warning() -> bool:
	return warning_left > 0.0


func is_pipe_burst() -> bool:
	return _pipe.broken


func _physics_process(delta: float) -> void:
	_burn_pump_coal(delta)
	step(delta)


func _burn_pump_coal(delta: float) -> void:
	var pump := _ship.get_node_or_null("Pump")
	if pump_coal_burn > 0.0 and pump and pump.is_active():
		fuel = maxf(0.0, fuel - pump_coal_burn * delta)


## A shovel of coal goes into the firebox. Wet coal gives less and makes the whole fire worse.
func feed(coal: Node3D) -> void:
	var added: float = shovel_load * coal.amount * (1.0 - wet_coal_burn * coal.wetness)
	var total := fuel + added
	if total > 0.0:
		coal_wetness = (coal_wetness * fuel + coal.wetness * added) / total
	fuel = minf(1.0, total)


## A hit while someone carries coal spills half the shovel onto the deck.
func _spill_shovels(_rock: Node3D) -> void:
	for player in get_tree().get_nodes_in_group("crew"):
		if player.carried and player.carried.kind == "coal":
			player.carried.spill(0.5)


func step(delta: float) -> void:
	vent_ready_in = maxf(0.0, vent_ready_in - delta)
	var throttle: float = absf(_handling.throttle) # going astern works the engine too
	if is_stalled():
		stall_left -= delta
		heat = maxf(0.0, heat - 0.03 * delta)
		if stall_left <= 0.0:
			stall_left = 0.0
			restarted.emit()
	else:
		var had_fuel := fuel > 0.0
		var was_low := fuel < low_fuel
		fuel = maxf(min_fuel, fuel - fuel_burn * throttle * delta)
		if not was_low and fuel < low_fuel:
			fuel_low.emit()
		if had_fuel and fuel <= 0.0:
			out_of_fuel.emit()
		var drive := throttle if fuel > 0.0 else 0.0
		var heaviness: float = 1.0 + water_heat_factor * (_hull.water if _hull else 0.0)
		var change := heat_rise * (drive - cool_point) / (1.0 - cool_point)
		if change > 0.0:
			change *= heaviness * (burst_pipe_factor if is_pipe_burst() else 1.0)
		elif is_pipe_burst():
			change *= 0.5 # a burst pipe also cools badly
		heat = clampf(heat + change * delta, 0.0, 1.0)
		_update_warning(delta)
	_apply_effects()


func _update_warning(delta: float) -> void:
	if warning_left > 0.0:
		if heat < 0.97: # vented or throttled back in time
			warning_left = 0.0
			return
		warning_left -= delta
		if warning_left <= 0.0:
			warning_left = 0.0
			stall_left = stall_seconds
			if not _pipe.broken:
				_pipe.break_it()
				pipe_burst.emit()
			stalled.emit()
	elif heat >= 1.0:
		warning_left = warning_seconds
		overheat_warning.emit()


func _apply_effects() -> void:
	var factor := 1.0
	if is_stalled():
		factor = 0.0
	elif fuel <= 0.0:
		factor = no_fuel_speed
	elif heat > heat_cap_threshold:
		factor = heat_cap_speed
	factor *= 1.0 - wet_coal_penalty * coal_wetness
	_handling.speed_limits["engine"] = factor
	if _steam:
		_steam.emitting = heat > heat_cap_threshold or is_stalled()
		_steam.initial_velocity_max = 6.0 if is_warning() or is_stalled() else 3.0
	if is_stalled():
		_station.status_text = "STALLED %ds" % ceili(stall_left)
	elif is_warning():
		_station.status_text = "OVERHEAT! Jump: vent  %d" % ceili(warning_left)
	elif heat > heat_cap_threshold:
		_station.status_text = "HOT"
	elif fuel <= 0.0:
		_station.status_text = tr("NO COAL! Shovel from the pile")
	elif fuel < low_fuel:
		_station.status_text = tr("COAL LOW! Shovel from the pile")
	elif coal_wetness > 0.2:
		_station.status_text = tr("WET COAL")
	else:
		_station.status_text = ""


## Vents steam: big instant cooling, but knocks down crew standing close to the engine.
func vent(player: Node3D = null) -> bool:
	if vent_ready_in > 0.0:
		return false
	heat = maxf(0.0, heat - vent_cooling)
	vent_ready_in = vent_cooldown
	for crew in get_tree().get_nodes_in_group("crew"):
		if crew == player:
			continue
		var offset: Vector3 = crew.global_position - _station.global_position
		offset.y = 0.0
		if offset.length() <= vent_knock_radius:
			var away := _ship.global_basis.inverse() * offset.normalized()
			crew.knock_down(Vector2(away.x, away.z))
	vented.emit(player)
	return true
