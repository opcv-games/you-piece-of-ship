extends "res://scripts/components/station.gd"
## A hole in the hull (one of a few fixed spots along the rails). Lifecycle:
## cracking (5 s warning: creak and a little spray) -> open (water pours in) -> fixed by
##  - an emergency crate plug (stops most of the flow, the crate's cargo is lost), or
##  - a plank patch: put a plank on it, then hammer; 2 crew is quick, 1 crew is slow.
## Visible on the ship itself, never only as a number (DESIGN.md section 2).

signal opened
signal sealed
signal plugged

enum State { NONE, CRACKING, OPEN }

@export var warning_seconds := 5.0
@export var patch_seconds_two := 4.0 ## hammering time with two crew
@export var patch_seconds_one := 12.0 ## hammering time alone
@export var plug_flow := 0.3 ## share of the flow a crate plug lets through
@export var plank_flow := 0.6 ## share of the flow while a plank is being hammered on

var state := State.NONE
var is_plugged := false
var has_plank := false
var progress := 0.0 ## 0..1 of the plank patch
var _warning_left := 0.0

var _hole: MeshInstance3D
var _plank: MeshInstance3D
var _plug: MeshInstance3D
var _spray: CPUParticles3D


func _ready() -> void:
	super._ready()
	station_name = "LEAK"
	max_occupants = 2
	radius = 1.3
	_build_visuals()
	_refresh()


func _build_visuals() -> void:
	var side := signf(position.z) if position.z != 0.0 else 1.0
	var at_rail := Vector3(0.0, 0.03, side * 0.6)
	_hole = _box("Hole", Vector3(0.9, 0.04, 0.55), Color(0.08, 0.06, 0.05), at_rail)
	_plank = _box("Plank", Vector3(1.2, 0.12, 0.35), Color(0.82, 0.62, 0.38), at_rail + Vector3(0, 0.06, 0))
	_plug = _box("Plug", Vector3(0.8, 0.8, 0.8), Color(0.78, 0.45, 0.2), at_rail + Vector3(0, 0.4, 0))
	_spray = CPUParticles3D.new()
	_spray.name = "Spray"
	_spray.position = at_rail
	_spray.amount = 40
	_spray.lifetime = 0.9
	var drop := BoxMesh.new()
	drop.size = Vector3(0.12, 0.12, 0.12)
	var water := StandardMaterial3D.new()
	water.albedo_color = Color(0.75, 0.9, 1.0)
	drop.material = water
	_spray.mesh = drop
	_spray.direction = Vector3.UP
	_spray.spread = 20.0
	_spray.gravity = Vector3(0, -12, 0)
	_spray.initial_velocity_min = 3.0
	_spray.initial_velocity_max = 5.0
	add_child(_spray)
	var label := Label3D.new()
	label.name = "Label"
	label.position = Vector3(0, 2.0, side * 0.6)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.font_size = 56
	label.outline_size = 12
	label.modulate = Color(1.0, 0.75, 0.6)
	add_child(label)


func _box(node_name: String, size: Vector3, color: Color, where: Vector3) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	mesh.material = material
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	instance.position = where
	add_child(instance)
	return instance


## Starts a new crack here. Returns false if this spot is already damaged.
func crack() -> bool:
	if state != State.NONE:
		return false
	state = State.CRACKING
	_warning_left = warning_seconds
	is_plugged = false
	has_plank = false
	progress = 0.0
	_refresh()
	return true


## How much water comes in through this spot (0 = none, 1 = a full open breach).
func flow() -> float:
	if state != State.OPEN:
		return 0.0
	if has_plank:
		return plank_flow
	if is_plugged:
		return plug_flow
	return 1.0


func _physics_process(delta: float) -> void:
	if state == State.CRACKING:
		_warning_left -= delta
		if _warning_left <= 0.0:
			state = State.OPEN
			opened.emit()
	if has_plank and not occupants.is_empty():
		var seconds := patch_seconds_two if occupants.size() >= 2 else patch_seconds_one
		progress += delta / seconds
		if progress >= 1.0:
			_seal()
	_refresh()


func _seal() -> void:
	release_all()
	state = State.NONE
	has_plank = false
	is_plugged = false
	progress = 0.0
	sealed.emit()


func _refresh() -> void:
	enabled = state != State.NONE
	_hole.visible = enabled
	_plank.visible = has_plank
	_plug.visible = is_plugged and not has_plank
	_spray.emitting = enabled and flow() > 0.0 or state == State.CRACKING
	_spray.initial_velocity_max = 2.5 if state == State.CRACKING or flow() < 1.0 else 5.0
	match state:
		State.CRACKING:
			status_text = "Cracking! %d" % ceili(_warning_left)
		State.OPEN:
			if has_plank:
				status_text = "Use: hammer (2 crew = fast) %d%%" % roundi(progress * 100.0)
			elif is_plugged:
				status_text = "Plugged. Bring a plank!"
			else:
				status_text = "Bring a plank (or a crate)!"
		_:
			status_text = ""


# --- Interaction -----------------------------------------------------------------

func accepts_item(item: Node3D, _player: Node3D) -> bool:
	if not enabled or has_plank:
		return false
	if item.kind == "plank":
		return true
	return item.kind == "crate" and not is_plugged


func receive_item(item: Node3D, player: Node3D) -> void:
	if item.kind == "plank":
		item.consume()
		has_plank = true
		occupy(player) # start hammering straight away
	elif item.kind == "crate":
		item.consume() # the cargo is lost
		is_plugged = true
		plugged.emit()
	_refresh()


func can_interact(player: Node3D) -> bool:
	if not player.carried and not has_plank:
		return false
	return super.can_interact(player)


func _show_prompt() -> bool:
	return false # the status line already says what to do
