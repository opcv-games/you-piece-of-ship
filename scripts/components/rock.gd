extends Node3D
## A submerged rock: invisible from the deck, shown only on the map table's chart.
## After the ship hits it, it is revealed to everyone (a visible scar of the mistake: Comedy).

@export var radius := 3.5 ## metres
@export var hidden := true ## submerged: only the chart shows it. Cliffs are not hidden.

var revealed := false


func _ready() -> void:
	add_to_group("rocks")
	$Mesh.scale = Vector3(radius, radius * 0.4, radius) if hidden else Vector3(radius, radius * 1.6, radius)
	$Mesh.visible = not hidden
	revealed = not hidden


func reveal() -> void:
	revealed = true
	$Mesh.visible = true
