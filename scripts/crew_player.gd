extends CharacterBody3D
## One crew member: walk, run and jump, Overcooked-style.
## Crew live inside the ship node, so the rocking deck carries them; they never need to
## fight the waves to stay on board, only to walk where they want (Comedy without frustration).

const COLORS := [
	Color(0.9, 0.25, 0.2), # player 1: red
	Color(0.2, 0.45, 0.95), # player 2: blue
	Color(0.95, 0.8, 0.15), # player 3: yellow
	Color(0.25, 0.75, 0.3), # player 4: green
]

@export_range(1, 4) var player_index := 1
@export var walk_speed := 5.0 ## metres per second
@export var acceleration := 40.0
@export var jump_velocity := 6.0
@export var gravity := 20.0

var move_input := Vector2.ZERO ## x = right, y = towards the camera
var jump_requested := false

@onready var _visual: Node3D = $Visual


func _ready() -> void:
	add_to_group("crew")
	add_to_group("camera_focus")
	# The ship already carries us (we are its child), so don't also add the deck's motion.
	platform_floor_layers = 0
	var body_material := StandardMaterial3D.new()
	body_material.albedo_color = COLORS[player_index - 1]
	$Visual/Body.material_override = body_material
	$Label.text = "P%d" % player_index
	$Label.modulate = COLORS[player_index - 1].lightened(0.3)


func _physics_process(delta: float) -> void:
	var direction := Vector3(move_input.x, 0.0, move_input.y).limit_length(1.0)
	velocity.x = move_toward(velocity.x, direction.x * walk_speed, acceleration * delta)
	velocity.z = move_toward(velocity.z, direction.z * walk_speed, acceleration * delta)
	if is_on_floor():
		if jump_requested:
			velocity.y = jump_velocity
	else:
		velocity.y -= gravity * delta
	jump_requested = false
	move_and_slide()
	if direction.length() > 0.1:
		_visual.rotation.y = atan2(direction.x, direction.z)
