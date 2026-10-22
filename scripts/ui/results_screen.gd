extends Control
## Results: did we make it, how long, how much cargo, how dry, the score, personal bests, and the
## story of what went wrong. HD cartoon panel; the numbers roll up, coins burst, records get stamped.
## R / Start sails again with the same crew; Enter / A goes back to the dock; J changes the crew.

const GOOD := Color(0.55, 0.95, 0.55)
const BAD := Color(1.0, 0.55, 0.45)

var outcome := {}
var recap: Array[Dictionary] = []

var _panel: PanelContainer
var _title: Label
var _subtitle: Label
var _rows: GridContainer
var _score: Label
var _coins: Label
var _breakdown: Label
var _stamp: Label
var _story: VBoxContainer
var _footer: Label
var _stars: Array[Label] = []
var _next_star: Label


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()


## Scores a finished voyage. Delivered: cargo value + up to 200 for a dry hull + 2 per second
## early. Sunk: nothing delivered, score 0.
## bonus: extra points earned on the way (fish caught, loot scooped up).
static func score(delivered: bool, cargo_value: int, water: float, elapsed: float, deadline: float, bonus := 0) -> Dictionary:
	if not delivered:
		return {"cargo": 0, "hull": 0, "time": 0, "bonus": 0, "total": 0}
	var hull := roundi((1.0 - water) * 200.0)
	var time := maxi(0, roundi((deadline - elapsed) * 2.0))
	return {"cargo": cargo_value, "hull": hull, "time": time, "bonus": bonus, "total": cargo_value + hull + time + bonus}


func show_results(data: Dictionary, story: Array[Dictionary]) -> void:
	outcome = data
	recap = story
	visible = true
	_fill()
	_animate()


func _fill() -> void:
	_title.text = tr("DELIVERED!") if outcome.delivered else tr("SUNK!")
	_title.add_theme_color_override("font_color", UI.YELLOW if outcome.delivered else BAD)
	_subtitle.text = tr(outcome.contract)
	for child in _rows.get_children():
		child.queue_free()
	var lines := [
		[tr("Time"), tr("%s (deadline %s)") % [outcome.time_text, outcome.deadline_text], outcome.on_time],
		[tr("Cargo"), tr("%d of %d crates") % [outcome.crates, outcome.crates_loaded], outcome.crates == outcome.crates_loaded],
		[tr("Hull"), tr("%d%% dry") % roundi((1.0 - outcome.water) * 100.0), outcome.water < 0.3],
	]
	if not outcome.delivered:
		lines.append([tr("Distance"), tr("%d%% of the way") % roundi(outcome.progress * 100.0), false])
	if outcome.has("best_score"):
		lines.append([tr("Best"), tr("%d points, %s") % [outcome.best_score, outcome.best_time_text], true])
	for line in lines:
		var key := Label.new()
		key.text = line[0]
		key.add_theme_color_override("font_color", Color(1, 1, 1, 0.7))
		_rows.add_child(key)
		var value := Label.new()
		value.text = line[1]
		value.add_theme_color_override("font_color", GOOD if line[2] else BAD)
		_rows.add_child(value)
	var s: Dictionary = outcome.score
	_breakdown.text = tr("cargo %d + dry hull %d + early %d") % [s.cargo, s.hull, s.time]
	if s.get("bonus", 0) > 0:
		_breakdown.text += tr(" + fish & loot %d") % s.bonus
	var earned: int = outcome.get("stars", 0)
	var limits: Array = outcome.get("star_limits", [])
	for i in _stars.size():
		_stars[i].add_theme_color_override("font_color", Color(1, 1, 1, 0.18))
	_next_star.text = ""
	if earned < 3 and limits.size() == 3 and outcome.delivered:
		_next_star.text = tr("Next star at %d points") % int(limits[earned])
	_coins.visible = outcome.has("earned")
	var records: Dictionary = outcome.get("records", {})
	_stamp.visible = records.get("score", false) or records.get("time", false)
	if _stamp.visible:
		_stamp.text = tr("NEW BEST SCORE & TIME!") if records.score and records.time else (
				tr("NEW BEST SCORE!") if records.score else tr("NEW BEST TIME!"))
	for child in _story.get_children():
		child.queue_free()
	if recap.is_empty():
		_story.add_child(_line("", tr("Nothing went wrong. Suspicious."), Color.WHITE))
	for entry in recap:
		var stamp := "%d:%02d" % [int(entry.time) / 60, int(entry.time) % 60]
		var color := BAD if entry.kind == "bad" else (GOOD if entry.kind == "good" else Color.WHITE)
		_story.add_child(_line(stamp, _translate(entry), color))
	_footer.text = tr("Enter / A: back to the dock     R / Start: sail again     J: change crew")


func _translate(entry: Dictionary) -> String:
	var args := []
	for arg in entry.get("args", []):
		args.append(tr(arg) if arg is String else arg)
	return tr(entry.get("key", entry.text)) % args if not args.is_empty() else tr(entry.get("key", entry.text))


func _animate() -> void:
	UI.pop_in(_panel)
	UI.play("stamp")
	_title.pivot_offset = _title.size * 0.5
	_title.scale = Vector2(2.2, 2.2)
	_title.create_tween().tween_property(_title, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	UI.roll_up(_score, outcome.score.total, 1.0, tr("SCORE %d"))
	if outcome.has("earned"):
		UI.roll_up(_coins, outcome.earned, 1.0, tr("+%d coins"))
		if outcome.earned > 0:
			get_tree().create_timer(0.9).timeout.connect(func():
				if is_inside_tree():
					UI.coin_burst(_coins.get_global_rect().get_center(), 22))
	for i in int(outcome.get("stars", 0)):
		get_tree().create_timer(1.0 + i * 0.4).timeout.connect(_star_in.bind(i))
	if _stamp.visible:
		_stamp.modulate.a = 0.0
		get_tree().create_timer(1.1 + outcome.get("stars", 0) * 0.4).timeout.connect(_stamp_in)
	var delay := 0.4
	for line in _story.get_children():
		line.modulate.a = 0.0
		line.create_tween().tween_property(line, "modulate:a", 1.0, 0.2).set_delay(delay)
		delay += 0.08


## One earned star lights up: gold, a big pop and a rising chime.
func _star_in(index: int) -> void:
	if not is_inside_tree():
		return
	var star := _stars[index]
	star.add_theme_color_override("font_color", UI.YELLOW)
	star.pivot_offset = star.size * 0.5
	star.scale = Vector2(2.4, 2.4)
	star.rotation = deg_to_rad(-25)
	var tween := star.create_tween().set_parallel()
	tween.tween_property(star, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(star, "rotation", 0.0, 0.3)
	UI.play("coin")
	UI.coin_burst(star.get_global_rect().get_center(), 10)


func _stamp_in() -> void:
	if not is_inside_tree():
		return
	UI.play("stamp")
	_stamp.modulate.a = 1.0
	_stamp.pivot_offset = _stamp.size * 0.5
	_stamp.scale = Vector2(3, 3)
	_stamp.rotation = deg_to_rad(-14)
	var tween := _stamp.create_tween().set_parallel()
	tween.tween_property(_stamp, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_stamp, "rotation", deg_to_rad(-6), 0.25)


func _line(stamp: String, text: String, color: Color) -> HBoxContainer:
	var row := HBoxContainer.new()
	var time := Label.new()
	time.text = stamp
	time.custom_minimum_size = Vector2(56, 0)
	time.add_theme_font_size_override("font_size", 14)
	time.add_theme_color_override("font_color", Color(1, 1, 1, 0.5))
	row.add_child(time)
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", color)
	row.add_child(label)
	return row


func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(700, 0)
	center.add_child(_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	_panel.add_child(box)
	_stamp = Label.new()
	_stamp.add_theme_font_size_override("font_size", 22)
	_stamp.add_theme_color_override("font_color", Color(1, 0.3, 0.25))
	_stamp.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	box.add_child(_stamp)
	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 52)
	_title.add_theme_constant_override("outline_size", 10)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_title)
	_subtitle = Label.new()
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_subtitle)
	var star_row := HBoxContainer.new()
	star_row.alignment = BoxContainer.ALIGNMENT_CENTER
	star_row.add_theme_constant_override("separation", 18)
	box.add_child(star_row)
	for i in 3:
		var star := Label.new()
		star.text = "★"
		star.add_theme_font_size_override("font_size", 64 if i == 1 else 52)
		star.add_theme_constant_override("outline_size", 10)
		star_row.add_child(star)
		_stars.append(star)
	_next_star = Label.new()
	_next_star.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_next_star.add_theme_font_size_override("font_size", 14)
	_next_star.add_theme_color_override("font_color", Color(1, 1, 1, 0.65))
	box.add_child(_next_star)
	_rows = GridContainer.new()
	_rows.columns = 2
	_rows.add_theme_constant_override("h_separation", 24)
	box.add_child(_rows)
	var score_row := HBoxContainer.new()
	box.add_child(score_row)
	_score = Label.new()
	_score.add_theme_font_size_override("font_size", 34)
	_score.add_theme_color_override("font_color", UI.YELLOW)
	_score.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	score_row.add_child(_score)
	_coins = Label.new()
	_coins.add_theme_font_size_override("font_size", 26)
	_coins.add_theme_color_override("font_color", UI.YELLOW)
	score_row.add_child(_coins)
	_breakdown = Label.new()
	_breakdown.add_theme_font_size_override("font_size", 14)
	_breakdown.add_theme_color_override("font_color", Color(1, 1, 1, 0.6))
	box.add_child(_breakdown)
	var heading := Label.new()
	heading.text = tr("WHAT HAPPENED")
	heading.add_theme_color_override("font_color", Color(1, 1, 1, 0.75))
	box.add_child(heading)
	_story = VBoxContainer.new()
	_story.add_theme_constant_override("separation", 0)
	box.add_child(_story)
	_footer = Label.new()
	_footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_footer.add_theme_color_override("font_color", UI.YELLOW)
	_footer.add_theme_font_size_override("font_size", 15)
	box.add_child(_footer)
