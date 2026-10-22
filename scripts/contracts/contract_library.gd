extends RefCounted
## All hand-made contracts. Milestone A uses the Reef Run; Milestone B adds the others.

const Contract = preload("res://scripts/contracts/contract.gd")


static func reef_run() -> Resource:
	var contract := Contract.new()
	contract.title = "Reef Run"
	contract.blurb = "Six crates of tinned sardines through the Gull Reef. Five minutes, if nothing breaks."
	contract.length = 1300.0
	contract.deadline = 330.0
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


static func by_index(index: int) -> Resource:
	var all := all_contracts()
	return all[clampi(index, 0, all.size() - 1)]


static func all_contracts() -> Array:
	return [reef_run()]
