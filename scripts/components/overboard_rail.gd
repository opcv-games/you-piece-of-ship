extends Node
## The rails, as something to interact with: carrying a cargo crate close to a rail and pressing
## Use throws it overboard (emergency measure, DESIGN.md section 13).

@export var reach := 1.1 ## metres from the rail's inner edge

var _ship: Node3D
var _load: Node


func _ready() -> void:
	add_to_group("interactables")
	_ship = get_parent()
	_load = _ship.get_node("LoadSystem")


func distance_to_player(player: Node3D) -> float:
	var local: Vector3 = _ship.to_local(player.global_position)
	var to_side: float = _ship.deck_width * 0.5 - absf(local.z)
	var to_end: float = _ship.deck_length * 0.5 - absf(local.x)
	return minf(to_side, to_end)


func can_interact(player: Node3D) -> bool:
	return player.carried != null and player.carried.kind == "crate" and distance_to_player(player) <= reach


func interact(player: Node3D) -> void:
	_load.throw_overboard(player.carried)
