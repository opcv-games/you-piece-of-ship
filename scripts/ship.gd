extends AnimatableBody3D
## The grey ship. Its WaveMotion child rocks it; everything on board is a child of it.
## The ship is itself the moving physics body (AnimatableBody3D): moving a parent node does not
## move a physics body in Godot, and later loose crates (issue #5) need a real moving deck to slide on.
## sync_to_physics is off in ship.tscn: with it on, Godot 4.7 applied the heave but dropped the roll.

## Deck size comes from the floor's collision box, so there is one source of truth.
var deck_length: float:
	get:
		return ($Floor.shape as BoxShape3D).size.x
var deck_width: float:
	get:
		return ($Floor.shape as BoxShape3D).size.z
