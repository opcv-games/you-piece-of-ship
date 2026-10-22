extends Node
## What survives between voyages (autoload "Session"): the crew, the chosen contract, money,
## upgrades, unlocked contracts and best scores. Money and progress are saved to disk
## (user://save.json); the crew is not, it's chosen fresh at the dock each time.

const SAVE_PATH := "user://save.json"
const Upgrades = preload("res://scripts/systems/upgrades.gd")

var joined_players: Array[int] = [] ## player indexes 1..4; empty = not chosen yet
var contract_index := 0
var money := 0
var upgrades: Array = [] ## owned upgrade ids
var unlocked := 1 ## how many contracts are open
var best_scores := {} ## contract index (as text) -> best score
var persist := true ## false while running automated tests: never touch the player's save


func _ready() -> void:
	for arg in OS.get_cmdline_args():
		if arg.ends_with("gut_cmdln.gd"):
			persist = false
	load_game()


## Records a finished voyage: earnings, best score, and the next contract unlocks on delivery.
## Returns the money earned.
func record_voyage(index: int, delivered: bool, score: int) -> int:
	var earned := score if delivered else 0
	money += earned
	var key := str(index)
	best_scores[key] = maxi(int(best_scores.get(key, 0)), score)
	if delivered:
		unlocked = maxi(unlocked, index + 2)
	save_game()
	return earned


func can_buy(id: String) -> bool:
	return not upgrades.has(id) and money >= int(Upgrades.DATA[id].price)


func buy(id: String) -> bool:
	if not can_buy(id):
		return false
	money -= int(Upgrades.DATA[id].price)
	upgrades.append(id)
	save_game()
	return true


func reset_progress() -> void:
	money = 0
	upgrades = []
	unlocked = 1
	best_scores = {}
	save_game()


func save_game() -> void:
	if not persist:
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({"money": money, "upgrades": upgrades, "unlocked": unlocked,
				"best_scores": best_scores}))


func load_game() -> void:
	if not persist or not FileAccess.file_exists(SAVE_PATH):
		return
	var data = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if data is Dictionary:
		money = int(data.get("money", 0))
		upgrades = data.get("upgrades", [])
		unlocked = int(data.get("unlocked", 1))
		best_scores = data.get("best_scores", {})
