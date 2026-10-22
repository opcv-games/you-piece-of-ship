extends Control
## Engine room gauge: heat (with the 80% line), coal, vent and pipe status.
## Only shown while someone operates the engine (station-bound information).

@export var station: Node3D
@export var engine: Node

const BACK := Color(0.12, 0.1, 0.09, 0.9)
const HEAT_OK := Color(0.95, 0.6, 0.15)
const HEAT_HOT := Color(0.95, 0.2, 0.15)
const COAL := Color(0.55, 0.55, 0.6)


func _process(_delta: float) -> void:
	visible = station != null and station.has_human_reader()
	if visible:
		queue_redraw()


func _draw() -> void:
	var font := ThemeDB.fallback_font
	draw_rect(Rect2(Vector2.ZERO, size), BACK)
	var names := PackedStringArray()
	for reader in station.readers():
		names.append("P%d" % reader.player_index)
	draw_string(font, Vector2(12, 26), "ENGINE ROOM  " + ", ".join(names), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)
	_bar(Vector2(12, 44), "HEAT", engine.heat, HEAT_HOT if engine.heat > engine.heat_cap_threshold else HEAT_OK, engine.heat_cap_threshold)
	_bar(Vector2(12, 92), tr("COAL (shovel it from the pile)"), engine.fuel, COAL, -1.0)
	var lines := PackedStringArray()
	lines.append("Jump: vent steam" if engine.vent_ready_in <= 0.0 else "vent ready in %ds" % ceili(engine.vent_ready_in))
	if engine.coal_wetness > 0.2:
		lines.append(tr("WET COAL: -%d%% speed") % roundi(engine.wet_coal_penalty * engine.coal_wetness * 100.0))
	if engine.is_pipe_burst():
		lines.append("COOLING PIPE BURST")
	if engine.is_stalled():
		lines.append("STALLED %ds" % ceili(engine.stall_left))
	elif engine.is_warning():
		lines.append("OVERHEAT! VENT NOW %d" % ceili(engine.warning_left))
	for i in lines.size():
		draw_string(font, Vector2(12, 140 + i * 18), lines[i], HORIZONTAL_ALIGNMENT_LEFT, size.x - 24, 16, Color(1, 0.85, 0.5))


func _bar(at: Vector2, title: String, value: float, color: Color, marker: float) -> void:
	var font := ThemeDB.fallback_font
	var width := size.x - 24
	draw_string(font, at + Vector2(0, 0), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(1, 1, 1, 0.8))
	var rect := Rect2(at + Vector2(0, 8), Vector2(width, 20))
	draw_rect(rect, Color(0, 0, 0, 0.5))
	draw_rect(Rect2(rect.position, Vector2(width * clampf(value, 0.0, 1.0), 20)), color)
	if marker >= 0.0:
		var x := rect.position.x + width * marker
		draw_line(Vector2(x, rect.position.y - 3), Vector2(x, rect.end.y + 3), Color.WHITE, 2.0)
