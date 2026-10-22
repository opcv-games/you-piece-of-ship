extends Node3D
## A place on the ship that owns some information or controls (DESIGN.md section 12).
## Information belongs to the station, not the player: whoever stands here gets it,
## which is what makes crew call things out to each other (Social interaction).

@export var station_name := "Station"
@export var radius := 1.3 ## metres: how close a crew member must stand
@export var needs_use := true ## true: press Use to take it over (helm). false: standing here is enough (map table)

var occupant: Node3D = null


func _ready() -> void:
	add_to_group("stations")


## Crew members standing within reach (distance measured along the deck, ignoring height).
func crew_nearby() -> Array[Node3D]:
	var nearby: Array[Node3D] = []
	for player in get_tree().get_nodes_in_group("crew"):
		var offset: Vector3 = player.global_position - global_position
		offset.y = 0.0
		if offset.length() <= radius:
			nearby.append(player)
	return nearby


## The players currently getting this station's information.
func readers() -> Array[Node3D]:
	if needs_use:
		var users: Array[Node3D] = []
		if occupant:
			users.append(occupant)
		return users
	return crew_nearby()


func is_active() -> bool:
	return not readers().is_empty()


func occupy(player: Node3D) -> bool:
	if not needs_use or occupant != null:
		return false
	occupant = player
	player.station = self
	return true


func release(player: Node3D) -> void:
	if occupant == player:
		occupant = null
		player.station = null
