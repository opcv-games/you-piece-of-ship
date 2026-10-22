extends "res://scripts/components/station.gd"
## The engine room. While operating it: hold up to shovel coal; press Jump to vent steam.
## The heat and fuel gauge only shows to the player here (station-bound information).

signal vent_requested(player: Node3D)


func secondary_action(player: Node3D) -> void:
	vent_requested.emit(player)
