extends AnimatableBody3D
## The grey ship. Its WaveMotion child rocks it; everything on board is a child of it.
## The ship is itself the moving physics body (AnimatableBody3D): moving a parent node does not
## move a physics body in Godot. sync_to_physics is off in ship.tscn: with it on, Godot 4.7
## applied the heave but dropped the roll.
## Crew and items live in ship space, so "downhill" on the deck comes from local_gravity().

@onready var waves: Node = $WaveMotion

## Deck size comes from the floor's collision box, so there is one source of truth.
var deck_length: float:
	get:
		return ($Floor.shape as BoxShape3D).size.x
var deck_width: float:
	get:
		return ($Floor.shape as BoxShape3D).size.z


func _ready() -> void:
	waves.wave_struck.connect(_on_wave_struck)


## Gravity as seen from the deck (ship-local, metres per second squared). Its x/z part points
## downhill: that is where loose things slide.
func local_gravity() -> Vector3:
	return global_basis.inverse() * Vector3(0.0, -9.8, 0.0)


## Knocks every crew member not holding a station over toward push (ship-local x/z).
func knock_down_crew(push: Vector2) -> Array[Node3D]:
	var fallen: Array[Node3D] = []
	for player in get_tree().get_nodes_in_group("crew"):
		if player.knock_down(push):
			fallen.append(player)
	return fallen


func _on_wave_struck(side: float) -> void:
	# The wave lifts its side, so everyone loose falls toward the other side.
	knock_down_crew(Vector2(0.0, -side))
