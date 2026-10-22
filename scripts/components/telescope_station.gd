extends "res://scripts/components/station.gd"
## The bow telescope (fog contracts). While someone looks through it, rocks ahead (within range and
## a cone around the bow) get a red marker above the water that everyone can see for a few seconds.
## It stands apart from the map table: one navigator can't use both (Social: split the job).

signal spotted(rock: Node3D)

@export var spot_range := 90.0
@export var spot_cone_degrees := 35.0
@export var marker_seconds := 5.0
@export var scan_interval := 0.5

var _scan_left := 0.0
var _markers := {} ## rock -> marker


func _ready() -> void:
	super._ready()
	enabled = false # only fog contracts bring the telescope out (see voyage.gd)


func _physics_process(delta: float) -> void:
	if occupant == null:
		return
	_scan_left -= delta
	if _scan_left > 0.0:
		return
	_scan_left = scan_interval
	for rock in spotted_rocks():
		mark(rock)
		spotted.emit(rock)


## Hidden rocks ahead of the bow within the telescope's range and cone.
func spotted_rocks() -> Array[Node3D]:
	var ship := get_parent() as Node3D
	var yaw := ship.rotation.y
	var fwd := Vector3(cos(yaw), 0.0, -sin(yaw))
	var found: Array[Node3D] = []
	for rock in get_tree().get_nodes_in_group("rocks"):
		if not rock.hidden or rock.revealed:
			continue
		var offset: Vector3 = rock.global_position - global_position
		offset.y = 0.0
		var distance := offset.length()
		if distance > spot_range or distance < 1.0:
			continue
		if rad_to_deg(fwd.angle_to(offset)) <= spot_cone_degrees:
			found.append(rock)
	return found


func mark(rock: Node3D) -> void:
	var marker: MeshInstance3D = _markers.get(rock)
	if marker == null or not is_instance_valid(marker):
		marker = MeshInstance3D.new()
		var mesh := CylinderMesh.new()
		mesh.top_radius = 0.1
		mesh.bottom_radius = 1.2
		mesh.height = 3.0
		var red := StandardMaterial3D.new()
		red.albedo_color = Color(1.0, 0.2, 0.15)
		red.emission_enabled = true
		red.emission = Color(1.0, 0.2, 0.15)
		mesh.material = red
		marker.mesh = mesh
		marker.add_to_group("spot_markers")
		rock.add_child(marker)
		marker.position = Vector3(0, 1.5, 0)
		_markers[rock] = marker
	marker.visible = true
	marker.set_meta("until", Time.get_ticks_msec() + int(marker_seconds * 1000.0))


func _process(delta: float) -> void:
	super._process(delta)
	var now := Time.get_ticks_msec()
	for rock in _markers.keys():
		var marker = _markers[rock]
		if is_instance_valid(marker) and marker.visible and now > int(marker.get_meta("until", 0)):
			marker.visible = false
	status_text = "spotting %d rock%s" % [_count_visible(), "" if _count_visible() == 1 else "s"] if occupant else ""


func _count_visible() -> int:
	var count := 0
	for marker in _markers.values():
		if is_instance_valid(marker) and marker.visible:
			count += 1
	return count
