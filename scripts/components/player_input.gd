extends Node
## Reads one player's controls and feeds them to the crew member that owns this node.
## Kept apart from movement so tests (and, later, online input) can drive a player
## without a controller.

const PlayerControls = preload("res://scripts/systems/player_controls.gd")

@export var enabled := true

@onready var _player: Node = get_parent()


func _ready() -> void:
	PlayerControls.ensure_actions(4)
	process_physics_priority = -1 # read input before the player moves


func _physics_process(_delta: float) -> void:
	if not enabled:
		return
	var i: int = _player.player_index
	_player.move_input = Input.get_vector(
		PlayerControls.action(i, "left"), PlayerControls.action(i, "right"),
		PlayerControls.action(i, "up"), PlayerControls.action(i, "down"))
	if Input.is_action_just_pressed(PlayerControls.action(i, "jump")):
		_player.jump_requested = true
