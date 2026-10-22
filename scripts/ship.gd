extends AnimatableBody3D
## The grey ship. Its WaveMotion child rocks it; everything on board is a child of it.
## The ship is itself the moving physics body (AnimatableBody3D): moving a parent node does not
## move a physics body in Godot. sync_to_physics is off in ship.tscn: with it on, Godot 4.7
## applied the heave but dropped the roll.
## Crew and items live in ship space, so "downhill" on the deck comes from local_gravity().

const PixelArt = preload("res://scripts/systems/pixel_art.gd")

@export var pixel_art := true ## dress the ship with Olivier's pixel-art tiles (false: grey box)

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
	if pixel_art:
		_dress()


## Pixel-art dressing: plank textures on deck, hull and rails, crate-built spare boxes, a coal pile
## and a see-through sail. Collision and every station stay exactly as in the grey box.
func _dress() -> void:
	$DeckMesh.material_override = PixelArt.tiled_material("deck", Vector2(4.8, 4.8))
	$Hull.material_override = PixelArt.tiled_material("hull", Vector2(2.4, 0.6))
	$MastMesh.material_override = PixelArt.tiled_material("hull", Vector2(2.4, 0.6), Color(1.3, 1.2, 1.1))
	for rail in ["RailPortMesh", "RailStarboardMesh", "RailBowMesh", "RailSternMesh", "Bowsprit"]:
		get_node(rail).material_override = PixelArt.tiled_material("trim", Vector2(4.8, 0.6))
	$Pump/PumpMesh.material_override = PixelArt.tiled_material("hull", Vector2(1.2, 0.3))
	for box in ["PlankBox/BoxMesh", "PinBox/BoxMesh"]:
		get_node(box).material_override = PixelArt.tiled_material("crate", Vector2(1.0, 0.7))
	var coal := get_node_or_null("Engine/CoalPile") as MeshInstance3D
	if coal:
		coal.visible = false
		var lumps := PixelArt.make_sprite(PixelArt.texture("coal"), 0.06)
		lumps.name = "CoalSprite"
		lumps.position = coal.position - Vector3(0, coal.position.y, 0)
		get_node("Engine").add_child(lumps)
	var sail := PixelArt.make_sprite(PixelArt.texture("sail"), 0.02, false)
	sail.name = "Sail"
	sail.alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED
	sail.modulate = Color(1, 1, 1, 0.6) # partly see-through: never fully hides the deck
	sail.offset = Vector2.ZERO
	sail.position = $MastMesh.position + Vector3(0.96, 0.7, 0.0)
	add_child(sail)


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
