extends Camera3D
## One shared couch camera. It stays level with the horizon (so you see the deck rock)
## and pulls back just enough to keep the whole ship and every crew member on screen
## (Social: one screen, one crew, nobody hunting for themselves).

@export var target_group := "camera_focus" ## crew members and the ship's corner markers
@export_range(20.0, 85.0) var view_pitch_degrees := 55.0 ## how steeply we look down
@export var margin := 1.5 ## metres of room around the outermost point
@export_range(0.0, 0.5) var reserve_right := 0.0 ## share of the screen kept free on the right for the HUD (map chart)
@export var min_distance := 12.0
@export var max_distance := 45.0
@export var follow_speed := 4.0


func _ready() -> void:
	snap()


func _physics_process(delta: float) -> void:
	_frame(1.0 - exp(-follow_speed * delta))


## Jump straight to the framing (used at start).
func snap() -> void:
	_frame(1.0)


func _frame(weight: float) -> void:
	var targets := get_tree().get_nodes_in_group(target_group)
	if targets.is_empty():
		return
	var lowest := Vector3.INF
	var highest := -Vector3.INF
	for target in targets:
		lowest = lowest.min(target.global_position)
		highest = highest.max(target.global_position)
	var center := (lowest + highest) * 0.5
	var half_width := (highest.x - lowest.x) * 0.5 + margin
	var pitch := deg_to_rad(view_pitch_degrees)
	# Looking down at an angle, depth on the deck appears shorter on screen by sin(pitch).
	var half_height := (highest.z - lowest.z) * 0.5 * sin(pitch) + (highest.y - lowest.y) * 0.5 + margin
	var screen := get_viewport().get_visible_rect().size
	var aspect := screen.x / screen.y if screen.y > 0.0 else 16.0 / 9.0
	var tan_half_v := tan(deg_to_rad(fov) * 0.5) # fov is vertical
	var usable_aspect := aspect * (1.0 - reserve_right)
	var distance := maxf(half_height / tan_half_v, half_width / (tan_half_v * usable_aspect))
	distance = clampf(distance, min_distance, max_distance)
	var goal := center + Vector3(0.0, sin(pitch), cos(pitch)) * distance
	global_position = global_position.lerp(goal, weight)
	rotation = Vector3(-pitch, 0.0, 0.0)
	# Slide the view right so the ship sits in the free part of the screen.
	h_offset = reserve_right * distance * tan_half_v * aspect
