extends Node
## What survives between voyages (autoload "Session"): the crew, the chosen contract, money,
## upgrades, unlocked contracts and best scores. Money and progress are saved to disk
## (user://save.json); the crew is not, it's chosen fresh at the dock each time.

const SAVE_PATH := "user://save.json"
const Upgrades = preload("res://scripts/systems/upgrades.gd")

var joined_players: Array[int] = [] ## human player indexes 1..4; empty = not chosen yet
var ai_crew := {} ## player index -> {"primary": job, "secondary": job} for AI crewmates
var contract_index := 0
var money := 0
var upgrades: Array = [] ## owned upgrade ids
var unlocked := 1 ## how many contracts are open
var best_scores := {} ## contract index (as text) -> best score
var best_times := {} ## contract index (as text) -> fastest delivery in seconds
var last_records := {"score": false, "time": false} ## did the last voyage set a personal best?
var language := "" ## "en" or "fr"; empty = follow the computer's language
var music_volume_db := -8.0
var band_captions := true
var fullscreen := false
var last_join_address := "" ## the friend's address last used with Join
var persist := true ## false while running automated tests: never touch the player's save


func _ready() -> void:
	for arg in OS.get_cmdline_args():
		if arg.ends_with("gut_cmdln.gd"):
			persist = false
	load_game()
	apply_settings()


## Language, music volume and fullscreen from the saved settings.
func apply_settings() -> void:
	var locale := language if language != "" else OS.get_locale_language()
	TranslationServer.set_locale("fr" if locale == "fr" else "en")
	var bus := AudioServer.get_bus_index(&"Music")
	if bus >= 0:
		AudioServer.set_bus_volume_db(bus, music_volume_db + 8.0) # layers are mixed for -8 dB
	if persist and DisplayServer.get_name() != "headless":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_MAXIMIZED)


## Records a finished voyage: earnings, best score, and the next contract unlocks on delivery.
## Returns the money earned.
func record_voyage(index: int, delivered: bool, score: int, seconds := -1.0) -> int:
	var earned := score if delivered else 0
	money += earned
	var key := str(index)
	last_records = {"score": false, "time": false}
	if delivered and score > int(best_scores.get(key, 0)):
		last_records.score = true
	best_scores[key] = maxi(int(best_scores.get(key, 0)), score)
	if delivered and seconds >= 0.0 and (not best_times.has(key) or seconds < float(best_times[key])):
		last_records.time = true
		best_times[key] = seconds
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


## Turns an AI crewmate on for an empty slot, with sensible default jobs.
func enable_ai(index: int) -> void:
	var used := []
	for other in ai_crew.values():
		used.append(other.primary)
	var primary := "carpenter"
	# Four crew: one at the map, one at the furnace, one fixing things; the helm for whoever is left.
	for job in ["navigator", "engine", "carpenter", "helm", "pump", "cargo"]:
		if not used.has(job):
			primary = job
			break
	var backups := {"navigator": "carpenter", "engine": "carpenter", "helm": "pump", "carpenter": "pump",
			"pump": "carpenter", "cargo": "carpenter"}
	ai_crew[index] = {"primary": primary, "secondary": backups[primary]}
	joined_players.erase(index)
	save_game()


func disable_ai(index: int) -> void:
	ai_crew.erase(index)
	save_game()


func reset_progress() -> void:
	money = 0
	upgrades = []
	unlocked = 1
	best_scores = {}
	best_times = {}
	save_game()


func save_game() -> void:
	if not persist:
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({"money": money, "upgrades": upgrades, "unlocked": unlocked,
				"best_scores": best_scores, "best_times": best_times, "ai_crew": ai_crew, "language": language,
				"music_volume_db": music_volume_db, "band_captions": band_captions, "fullscreen": fullscreen,
				"last_join_address": last_join_address}))


func load_game() -> void:
	if not persist or not FileAccess.file_exists(SAVE_PATH):
		return
	var data = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if data is Dictionary:
		money = int(data.get("money", 0))
		upgrades = data.get("upgrades", [])
		unlocked = int(data.get("unlocked", 1))
		best_scores = data.get("best_scores", {})
		best_times = data.get("best_times", {})
		language = data.get("language", "")
		music_volume_db = float(data.get("music_volume_db", -8.0))
		band_captions = bool(data.get("band_captions", true))
		fullscreen = bool(data.get("fullscreen", false))
		last_join_address = data.get("last_join_address", "")
		ai_crew = {}
		var saved_ai = data.get("ai_crew", {})
		if saved_ai is Dictionary:
			for key in saved_ai:
				ai_crew[int(key)] = saved_ai[key] # JSON keys come back as text
