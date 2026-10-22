extends Control
## Crew screen before the first voyage: each player presses their Jump button to join (or leave);
## any joined player presses Use to set sail. Players who didn't join are taken off the ship.

signal crew_ready(players: Array[int])

const PlayerControls = preload("res://scripts/systems/player_controls.gd")
const COLORS := [Color(0.9, 0.25, 0.2), Color(0.2, 0.45, 0.95), Color(0.95, 0.8, 0.15), Color(0.25, 0.75, 0.3)]

var joined: Array[int] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	PlayerControls.ensure_actions(4)


func toggle(index: int) -> void:
	if joined.has(index):
		joined.erase(index)
	else:
		joined.append(index)
		joined.sort()
	queue_redraw()


func start() -> bool:
	if joined.is_empty() or not visible:
		return false
	visible = false
	crew_ready.emit(joined.duplicate())
	return true


func _process(_delta: float) -> void:
	if not visible:
		return
	for index in range(1, 5):
		if Input.is_action_just_pressed(PlayerControls.action(index, "jump")):
			toggle(index)
		if joined.has(index) and Input.is_action_just_pressed(PlayerControls.action(index, "use")):
			start()


func _draw() -> void:
	var font := ThemeDB.fallback_font
	var box := Rect2(size * 0.5 - Vector2(360, 170), Vector2(720, 340))
	draw_rect(box, Color(0.06, 0.1, 0.18, 0.9))
	draw_string(font, Vector2(box.position.x, box.position.y + 56), "YOU PIECE OF SHIP", HORIZONTAL_ALIGNMENT_CENTER,
			box.size.x, 40, Color(1, 0.85, 0.3))
	draw_string(font, Vector2(box.position.x, box.position.y + 92), "Press Jump to join the crew (Space, Enter, or A)",
			HORIZONTAL_ALIGNMENT_CENTER, box.size.x, 18, Color.WHITE)
	for i in 4:
		var slot := Rect2(box.position + Vector2(40 + i * 165, 120), Vector2(145, 120))
		var on := joined.has(i + 1)
		draw_rect(slot, COLORS[i] if on else Color(1, 1, 1, 0.08))
		draw_string(font, slot.position + Vector2(0, 52), "P%d" % (i + 1), HORIZONTAL_ALIGNMENT_CENTER, slot.size.x, 32,
				Color.WHITE)
		draw_string(font, slot.position + Vector2(0, 92), "ready!" if on else "press Jump", HORIZONTAL_ALIGNMENT_CENTER,
				slot.size.x, 16, Color.WHITE)
	var hint := "Then press Use (E, Right Shift, or X) to set sail" if not joined.is_empty() else ""
	if not joined.is_empty() and joined.size() <= 3:
		hint += "\nSmall crew: the ship gets a slow automatic pump"
	draw_multiline_string(font, Vector2(box.position.x, box.end.y - 50), hint, HORIZONTAL_ALIGNMENT_CENTER, box.size.x,
			17, -1, Color(1, 0.85, 0.3))
