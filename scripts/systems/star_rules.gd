extends Node
## This voyage's star thresholds, as a node so the Developer panel can tune them live ("Stars").

@export var star_1 := 1
@export var star_2 := 500
@export var star_3 := 800


func _ready() -> void:
	add_to_group("dev_tunable")
	set_meta("dev_group", "Stars")


func limits() -> Array:
	return [star_1, star_2, star_3]
