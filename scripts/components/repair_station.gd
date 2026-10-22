extends "res://scripts/components/station.gd"
## A two-player repair spot (burst cooling pipe). Only usable while broken; progress runs while
## crew work on it: fast with two, slow alone (so small crews aren't stuck).

signal repaired

@export var repair_seconds_two := 4.0
@export var repair_seconds_one := 12.0
@export var broken_text := "BURST! Use: fix (2 crew = fast)"

var broken := false
var progress := 0.0


func _ready() -> void:
	super._ready()
	max_occupants = 2
	_refresh()


func break_it() -> void:
	broken = true
	progress = 0.0
	_refresh()


func _physics_process(delta: float) -> void:
	if broken and not occupants.is_empty():
		var seconds := repair_seconds_two if occupants.size() >= 2 else repair_seconds_one
		progress += delta / seconds
		if progress >= 1.0:
			broken = false
			progress = 0.0
			release_all()
			repaired.emit()
	_refresh()


func _refresh() -> void:
	enabled = broken
	status_text = "%s %d%%" % [tr(broken_text), roundi(progress * 100.0)] if broken else ""
	var steam := get_node_or_null("Steam") as CPUParticles3D
	if steam:
		steam.emitting = broken


func _show_prompt() -> bool:
	return false
