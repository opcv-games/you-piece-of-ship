extends RefCounted
## The four shop upgrades (DESIGN.md section 9). Each one changes a post's job rather than
## removing it: every gain comes with a cost someone on board will feel.

const DATA := {
	"overclocked_engine": {
		"title": "Overclocked engine", "price": 450,
		"gain": "+20% top speed", "cost": "heats up 45% faster: more venting",
	},
	"reinforced_hull": {
		"title": "Reinforced hull", "price": 500,
		"gain": "leaks 40% slower, +3 s crack warning", "cost": "heavier: -8% speed, -10% turning",
	},
	"bigger_pumps": {
		"title": "Bigger pumps", "price": 350,
		"gain": "pump 80% faster", "cost": "the pump burns coal: more shovelling",
	},
	"second_spares_crate": {
		"title": "Second spare-parts crate", "price": 300,
		"gain": "+3 planks, +1 rudder pin", "cost": "one fewer cargo crate to sell",
	},
}

const ORDER := ["overclocked_engine", "reinforced_hull", "bigger_pumps", "second_spares_crate"]


## Applies the owned upgrades to a ship that has just been built.
static func apply(ship: Node3D, owned: Array) -> void:
	var handling := ship.get_node("ShipHandling")
	var engine := ship.get_node("EngineSystem")
	var hull := ship.get_node("HullSystem")
	if owned.has("overclocked_engine"):
		handling.max_speed *= 1.2
		engine.heat_rise *= 1.45
	if owned.has("reinforced_hull"):
		hull.flow_rate *= 0.6
		for breach in hull.breaches():
			breach.warning_seconds += 3.0
		handling.speed_limits["reinforced"] = 0.92
		handling.turn_limits["reinforced"] = 0.9
	if owned.has("bigger_pumps"):
		hull.pump_rate *= 1.8
		engine.pump_coal_burn = 0.01
	if owned.has("second_spares_crate"):
		ship.get_node("PlankBox").stock += 3
		ship.get_node("PinBox").stock += 1
		var crates := ship.get_tree().get_nodes_in_group("cargo")
		if not crates.is_empty():
			crates[-1].consume() # the spares take a cargo spot
