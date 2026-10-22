extends Node3D
## First route: sail through a reef that only the map table can see, to the port buoys.
## A short, replayable run (about a minute) so the captain/navigator call-out loop can be judged.

signal port_reached

@export var finish_x := 300.0 ## the ship's bow side crosses this line to reach port

var hits := 0
var finished := false
var _time := 0.0
var _crash_flash := 0.0

@onready var _ship: Node3D = $Ship
@onready var _handling: Node = $Ship/ShipHandling
@onready var _water: Node3D = $Water
@onready var _status: Label = $HUD/Status
@onready var _banner: Label = $HUD/Banner


func _ready() -> void:
	_handling.rock_hit.connect(_on_rock_hit)
	_banner.visible = false
	_spawn_foam()


func _physics_process(delta: float) -> void:
	# Keep the (plain) sea under the ship; the foam flecks stay put and show the speed.
	_water.global_position = Vector3(_ship.global_position.x, 0.0, _ship.global_position.z)
	if _crash_flash > 0.0:
		_crash_flash -= delta
		_banner.visible = _crash_flash > 0.0
	if not finished:
		_time += delta
		if _ship.global_position.x >= finish_x:
			_finish()
	_status.text = "Speed %d%%    Rocks hit: %d    Time: %ds" % [
		roundi(_handling.speed / _handling.max_speed * 100.0), hits, int(_time)]


func _unhandled_input(event: InputEvent) -> void:
	var restart: bool = (event is InputEventKey and event.pressed and event.physical_keycode == KEY_R) \
			or (event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_START)
	if restart:
		get_tree().reload_current_scene()


func _on_rock_hit(_rock: Node3D) -> void:
	hits += 1
	if not finished:
		_banner.text = "CRASH!"
		_banner.visible = true
		_crash_flash = 1.0


func _finish() -> void:
	finished = true
	_crash_flash = 0.0
	_handling.throttle = 0.0
	_banner.text = "PORT REACHED in %d s with %d rock hit%s!\nPress R (or Start) to sail again" % [
		int(_time), hits, "" if hits == 1 else "s"]
	_banner.visible = true
	port_reached.emit()


func _spawn_foam() -> void:
	var flecks := MultiMeshInstance3D.new()
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.8, 0.04, 0.35)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.85, 0.93, 1.0)
	mesh.material = material
	multimesh.mesh = mesh
	multimesh.instance_count = 900
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in multimesh.instance_count:
		var spot := Vector3(rng.randf_range(-60.0, finish_x + 60.0), 0.03, rng.randf_range(-60.0, 60.0))
		multimesh.set_instance_transform(i, Transform3D(Basis(Vector3.UP, rng.randf() * TAU), spot))
	flecks.multimesh = multimesh
	add_child(flecks)
