extends RefCounted
## All hand-made contracts, in the order they unlock (DESIGN.md section 7: four contracts of
## rising intensity; the last one in fog).

const Contract = preload("res://scripts/contracts/contract.gd")


static func all_contracts() -> Array:
	return [maiden_voyage(), reef_run(), the_narrows(), fog_bank()]


static func by_index(index: int) -> Resource:
	var all := all_contracts()
	return all[clampi(index, 0, all.size() - 1)]


## Contract 1 (DESIGN.md section 8): teaches by doing and cannot be lost.
static func maiden_voyage() -> Resource:
	var contract := Contract.new()
	contract.title = "Maiden Voyage"
	contract.blurb = "A short hop with spare sails. Learn the ropes; nobody sinks today."
	contract.length = 1100.0
	contract.deadline = 420.0
	contract.tutorial = true
	contract.difficulty = 1
	contract.pay_per_crate = 60
	# Buoy lane at 0:45: small hidden markers only the map table shows.
	contract.rock_rows = [
		[190, [-9, 9], 1.5], [215, [-9, 9], 1.5], [240, [-6, 12], 1.5], [265, [-3, 15], 1.5],
		[290, [0, 18], 1.5], [315, [-3, 15], 1.5],
		[930, [6], 2.5],
	]
	contract.waves = [[700, 1]]
	contract.events = [
		[0, "hint", "Welcome aboard! Walk to a station and press Use. Captain: HELM, hold UP for throttle."],
		[50, "hint", "Engineer: fill a shovel at the COAL pile (back corner), carry it to the ENGINE and press Use. The pile never runs out."],
		[120, "hint", "Buoys ahead! Navigator: stand at the MAP TABLE and call where they are."],
		[360, "leak", "A wave cracked the hull! Fetch a PLANK, put it on the LEAK, hammer it. Someone: PUMP!"],
		[520, "heat", "Headwind! The engine runs hot. Engineer: at the ENGINE, Jump vents steam (stand clear!)."],
		[680, "hint", "Big wave coming: grab a station so you don't fall over!"],
		[880, "rudder", "Rudder trouble! Bring the PIN to the HELM. Two problems at once: split up!"],
		[880, "leak", ""],
		[1040, "hint", "Port ahead! Steer between the yellow buoys."],
	]
	return contract


static func reef_run() -> Resource:
	var contract := Contract.new()
	contract.title = "Reef Run"
	contract.blurb = "Six crates of tinned sardines through the Gull Reef. Five minutes, if nothing breaks."
	contract.length = 1300.0
	contract.deadline = 330.0
	contract.difficulty = 2
	# Pacing (DESIGN.md section 7): calm departure, first complication, calm, overlap, peak, port.
	contract.rock_rows = [
		[220, [0]],
		[280, [-14, 12]],
		[340, [-6, 20, -30]],
		[400, [8, -22]],
		[520, [-35]],
		[620, [0, 25, -25]],
		[680, [-12, 14]],
		[730, [3, -30, 32]],
		[780, [-18, 20]],
		[830, [8, -40]],
		[1000, [-8, 10, 30]],
		[1040, [18, -20]],
		[1080, [0, -30, 34]],
		[1120, [-14, 12]],
		[1160, [24, -4, -36]],
		[1200, [10, -18]],
		[1240, [-6, 30]],
	]
	contract.waves = [[380, 1], [760, -1], [1100, 1]]
	return contract


static func the_narrows() -> Resource:
	var contract := Contract.new()
	contract.title = "The Narrows"
	contract.blurb = "Fragile glassware through a channel barely wider than the ship. Mind the walls."
	contract.length = 1400.0
	contract.deadline = 345.0
	contract.coast_half_width = 26.0
	contract.difficulty = 3
	contract.pay_per_crate = 130
	# Rocks near the walls sit against the cliffs, so there are no ship-sized pockets to wedge in.
	contract.rock_rows = [
		[200, [-8]], [250, [8]], [300, [-19, 6]], [350, [19, -4]], [400, [0]],
		[470, [-19, 10]], [560, [6]], [610, [-8, 19]], [660, [2, -19]], [710, [-6, 19]],
		[760, [19, -10]], [810, [0]], [900, [-19, 8]], [960, [19, -6]], [1010, [-2, 19]],
		[1060, [-19, 6]], [1110, [13, -11]], [1160, [0, 19]], [1210, [-19, 8]], [1260, [19, -4]],
		[1320, [-6, 10]],
	]
	contract.waves = [[330, -1], [640, 1], [980, -1], [1240, 1]]
	return contract


static func fog_bank() -> Resource:
	var contract := Contract.new()
	contract.title = "Fog Bank"
	contract.blurb = "Medicine for the lighthouse keeper. The fog is so thick the chart can't help much: use the telescope."
	contract.length = 1400.0
	contract.deadline = 390.0
	contract.coast_half_width = 40.0
	contract.fog = true
	contract.chart_range = 30.0
	contract.difficulty = 4
	contract.pay_per_crate = 160
	contract.rock_rows = [
		[220, [0, -20]], [290, [14, -10]], [360, [-4, 22]], [430, [10, -24]],
		[520, [-14, 4]], [590, [18, -6]], [660, [-20, 8]], [720, [0, 26]],
		[800, [-10, 14]], [870, [6, -18]], [940, [-24, 2, 22]], [1010, [12, -8]],
		[1080, [-4, 20]], [1150, [16, -14]], [1220, [-8, 6]], [1290, [2, -22, 20]],
	]
	contract.waves = [[480, 1], [900, -1], [1200, 1]]
	contract.events = [
		[0, "hint", "Thick fog: the chart only sees 30 m. Navigator: the TELESCOPE at the bow spots rocks further ahead."],
	]
	return contract
