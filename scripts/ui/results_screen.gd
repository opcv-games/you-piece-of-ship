extends Control
## Results: did we make it, how long, how much cargo, how dry, the score, and the story of what
## went wrong. R / Start sails again with the same crew; J changes the crew.

const PANEL := Color(0.06, 0.1, 0.18, 0.92)
const GOOD := Color(0.55, 0.95, 0.55)
const BAD := Color(1.0, 0.55, 0.45)
const TEXT := Color(0.95, 0.95, 0.95)

var outcome := {}
var recap: Array[Dictionary] = []


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Scores a finished voyage. Delivered: cargo value + up to 200 for a dry hull + 2 per second
## early. Sunk: nothing delivered, score 0.
static func score(delivered: bool, cargo_value: int, water: float, elapsed: float, deadline: float) -> Dictionary:
	if not delivered:
		return {"cargo": 0, "hull": 0, "time": 0, "total": 0}
	var hull := roundi((1.0 - water) * 200.0)
	var time := maxi(0, roundi((deadline - elapsed) * 2.0))
	return {"cargo": cargo_value, "hull": hull, "time": time, "total": cargo_value + hull + time}


func show_results(data: Dictionary, story: Array[Dictionary]) -> void:
	outcome = data
	recap = story
	visible = true
	queue_redraw()


func _draw() -> void:
	if outcome.is_empty():
		return
	var font := ThemeDB.fallback_font
	var box := Rect2(size * 0.5 - Vector2(380, 280), Vector2(760, 560))
	draw_rect(box, PANEL)
	var x := box.position.x + 30.0
	var y := box.position.y + 56.0
	var title: String = "DELIVERED!" if outcome.delivered else "SUNK!"
	draw_string(font, Vector2(box.position.x, y), title, HORIZONTAL_ALIGNMENT_CENTER, box.size.x, 44,
			GOOD if outcome.delivered else BAD)
	y += 30.0
	draw_string(font, Vector2(box.position.x, y), outcome.contract, HORIZONTAL_ALIGNMENT_CENTER, box.size.x, 18, TEXT)
	y += 40.0
	var s: Dictionary = outcome.score
	var lines := [
		["Time", "%s (deadline %s)" % [outcome.time_text, outcome.deadline_text], outcome.on_time],
		["Cargo", "%d of %d crates" % [outcome.crates, outcome.crates_loaded], outcome.crates == outcome.crates_loaded],
		["Hull", "%d%% dry" % roundi((1.0 - outcome.water) * 100.0), outcome.water < 0.3],
	]
	if not outcome.delivered:
		lines.append(["Distance", "%d%% of the way" % roundi(outcome.progress * 100.0), false])
	if outcome.has("best_score"):
		lines.append(["Best", "%d points, %s" % [outcome.best_score, outcome.best_time_text], true])
	for line in lines:
		draw_string(font, Vector2(x, y), line[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(1, 1, 1, 0.7))
		draw_string(font, Vector2(x + 120, y), line[1], HORIZONTAL_ALIGNMENT_LEFT, -1, 20, GOOD if line[2] else BAD)
		y += 28.0
	draw_string(font, Vector2(x, y + 6), "SCORE %d" % s.total, HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color(1, 0.85, 0.3))
	if outcome.has("earned"):
		draw_string(font, Vector2(box.end.x - 230, y + 6), "+%d coins" % outcome.earned, HORIZONTAL_ALIGNMENT_RIGHT, 200, 24,
				Color(1, 0.85, 0.3))
	draw_string(font, Vector2(x + 220, y + 4), "cargo %d + dry hull %d + early %d" % [s.cargo, s.hull, s.time],
			HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1, 1, 1, 0.6))
	var records: Dictionary = outcome.get("records", {})
	if records.get("score", false) or records.get("time", false):
		var what := "NEW BEST SCORE & TIME!" if records.score and records.time else ("NEW BEST SCORE!" if records.score else "NEW BEST TIME!")
		draw_string(font, Vector2(box.position.x, box.position.y + 22), what, HORIZONTAL_ALIGNMENT_CENTER, box.size.x, 22,
				Color(1, 0.85, 0.3))
	y += 48.0
	draw_string(font, Vector2(x, y), "WHAT HAPPENED", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1, 1, 1, 0.7))
	y += 26.0
	if recap.is_empty():
		draw_string(font, Vector2(x, y), "Nothing went wrong. Suspicious.", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, TEXT)
	for entry in recap:
		var stamp := "%d:%02d" % [int(entry.time) / 60, int(entry.time) % 60]
		var color := BAD if entry.kind == "bad" else (GOOD if entry.kind == "good" else TEXT)
		draw_string(font, Vector2(x, y), stamp, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1, 1, 1, 0.5))
		draw_string(font, Vector2(x + 60, y), entry.text, HORIZONTAL_ALIGNMENT_LEFT, box.size.x - 120, 16, color)
		y += 21.0
	draw_string(font, Vector2(box.position.x, box.end.y - 22), "Enter / A: back to the dock     R / Start: sail again     J: change crew",
			HORIZONTAL_ALIGNMENT_CENTER, box.size.x, 18, Color(1, 0.85, 0.3))
