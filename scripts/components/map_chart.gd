extends Control
## The chart on the map table. Heading-up: the top of the chart is wherever the bow points,
## so "rock at 2 o'clock" means the same thing to the navigator and the captain.
## Only shown while a crew member stands at the map table (Social: the navigator must call it out).

@export var station: Node3D ## the map table
@export var ship: Node3D
@export var range_metres := 70.0 ## about 12 s of warning at full speed

const SEA := Color(0.07, 0.16, 0.3, 0.92)
const RING := Color(1, 1, 1, 0.15)
const ROCK := Color(0.75, 0.72, 0.68)
const SHIP := Color(1, 1, 1)
const FINISH := Color(1, 0.85, 0.2)


func _process(_delta: float) -> void:
	visible = station != null and station.is_active()
	if visible:
		queue_redraw()


## Pixels per metre.
func chart_scale() -> float:
	return (minf(size.x, size.y) * 0.5 - 8.0) / range_metres


## Where a world position appears on the chart, relative to the chart centre (the ship).
func chart_point(world: Vector3) -> Vector2:
	var yaw := ship.rotation.y
	var fwd := Vector3(cos(yaw), 0.0, -sin(yaw))
	var right := Vector3(-fwd.z, 0.0, fwd.x)
	var offset := world - ship.global_position
	return Vector2(offset.dot(right), -offset.dot(fwd)) * chart_scale()


## Chart positions of every rock within range.
func rock_marks() -> Array[Vector2]:
	var marks: Array[Vector2] = []
	var limit := minf(size.x, size.y) * 0.5 - 4.0
	for rock in get_tree().get_nodes_in_group("rocks"):
		var mark := chart_point(rock.global_position)
		if mark.length() < limit:
			marks.append(mark)
	return marks


func _draw() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.5
	var px := chart_scale()
	draw_circle(center, radius, SEA)
	for ring_metres in [20.0, 40.0, 60.0]:
		draw_arc(center, ring_metres * px, 0.0, TAU, 64, RING, 1.5)
	for buoy in get_tree().get_nodes_in_group("finish"):
		var mark := chart_point(buoy.global_position)
		if mark.length() < radius - 4.0:
			draw_circle(center + mark, 5.0, FINISH)
	for rock in get_tree().get_nodes_in_group("rocks"):
		var mark := chart_point(rock.global_position)
		if mark.length() < radius - 4.0:
			draw_circle(center + mark, maxf(4.0, rock.radius * px), ROCK)
	# The ship: a triangle pointing up (the bow), drawn to scale.
	var bow := 7.0 * px
	var beam := 3.0 * px
	draw_colored_polygon(PackedVector2Array([center + Vector2(0, -bow), center + Vector2(beam, bow),
			center + Vector2(-beam, bow)]), SHIP)
	var names := PackedStringArray()
	for reader in station.readers():
		names.append("P%d" % reader.player_index)
	draw_string(ThemeDB.fallback_font, Vector2(0, -8), "MAP TABLE  read by " + ", ".join(names),
			HORIZONTAL_ALIGNMENT_CENTER, size.x, 18, Color(1, 1, 1))
