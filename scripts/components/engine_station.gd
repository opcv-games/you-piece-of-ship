extends "res://scripts/components/station.gd"
## The engine room (furnace). Bring a shovel of coal from the pile and press Use here to feed it.
## Operating the engine (Use with empty hands) shows the heat and coal gauge to that player only
## (station-bound information); Jump while operating vents steam.

signal vent_requested(player: Node3D)
signal coal_fed(coal: Node3D)


func secondary_action(player: Node3D) -> void:
	vent_requested.emit(player)


func accepts_item(item: Node3D, _player: Node3D) -> bool:
	return item.kind == "coal"


func receive_item(item: Node3D, _player: Node3D) -> void:
	coal_fed.emit(item)
	item.consume()
