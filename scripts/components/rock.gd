extends Node3D
## A submerged rock: invisible from the deck, shown only on the map table's chart.
## After the ship hits it, it is revealed to everyone (a visible scar of the mistake: Comedy).

@export var radius := 3.5 ## metres

var revealed := false


func _ready() -> void:
	add_to_group("rocks")
	$Mesh.scale = Vector3(radius, radius * 0.4, radius)
	$Mesh.visible = false


func reveal() -> void:
	revealed = true
	$Mesh.visible = true
