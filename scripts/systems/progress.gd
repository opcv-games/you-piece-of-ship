extends RefCounted
## The Overcooked-style progression (Olivier, 2026-10-22): three oceans of three routes. Stars open
## new routes; each ocean brings new trouble; stars also unlock hats for the crew.

const OCEANS := [
	{"name": "Calm Cove", "colour": Color(0.45, 0.82, 0.86),
		"new": "Learn the ropes: steering, coal, leaks, the chart. Wrecks and atolls to steer around.",
		"routes": [0, 4, 1], "stars": [0, 1, 3]},
	{"name": "Whale Waters", "colour": Color(0.4, 0.6, 0.92),
		"new": "Whales cross your path, sirens sing to your helmsman, and big swells shift the cargo.",
		"routes": [5, 2, 6], "stars": [5, 7, 9]},
	{"name": "Pirate Sea", "colour": Color(0.55, 0.42, 0.75),
		"new": "Pirates! Fog, storms, a ship without a sail and engines that fail.",
		"routes": [3, 7, 8], "stars": [12, 14, 17]},
]
## Hats and the stars they need.
const HATS := {"tricorn": 0, "bandana": 0, "beanie": 0, "straw": 0, "captain": 6, "crown": 15}


## Stars needed to open a contract (by its index in ContractLibrary.all_contracts()).
static func stars_needed(index: int) -> int:
	for ocean in OCEANS:
		var at: int = ocean.routes.find(index)
		if at >= 0:
			return ocean.stars[at]
	return 0


## Which ocean a contract belongs to (its index in OCEANS).
static func ocean_of(index: int) -> int:
	for i in OCEANS.size():
		if OCEANS[i].routes.has(index):
			return i
	return 0


static func hats_unlocked(total_stars: int) -> Array:
	var open := []
	for hat in HATS:
		if total_stars >= HATS[hat]:
			open.append(hat)
	return open
