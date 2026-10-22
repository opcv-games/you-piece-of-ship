extends Sprite3D
## A crew member drawn as an animated NES-style pirate (Olivier's sprite sheet), recoloured to the
## player's colour. It always faces the camera and picks its frame from what the player is doing:
## running, walking with a load overhead, idling, working a station, or knocked flat.

const PixelArt = preload("res://scripts/systems/pixel_art.gd")

var animation := "idle"
var column := 3 ## facing the camera

var _player: CharacterBody3D
var _time := 0.0


func setup(player: CharacterBody3D, tint: Variant) -> void:
	_player = player
	texture = PixelArt.crew_texture(tint)
	pixel_size = PixelArt.PIXEL
	texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	shaded = false
	# Facing the camera and drawn over the ship's furniture: a sailor is never hidden behind the
	# mast or a table (readability first), and never sliced by things behind it.
	billboard = BaseMaterial3D.BILLBOARD_ENABLED
	alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED
	transparent = true
	no_depth_test = true
	render_priority = -1 # labels (station names, prompts, P1..P4) still draw over the sprite
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	region_enabled = true
	centered = true
	offset = Vector2(0, PixelArt.CELL.y * 0.5) # feet on the deck
	_show()


func _process(delta: float) -> void:
	if _player == null:
		return
	_time += delta
	animation = _pick_animation()
	var facing: Vector3 = _player.facing
	column = PixelArt.column_for(Vector2(facing.x, facing.z))
	_show()
	_keep_labels_overhead()


## The sprite rises straight up on screen (it faces the camera); a label placed straight up in the
## world would drift sideways with perspective. So the name tag and speech bubble follow the
## camera's "up" instead, staying just above the pirate's head.
func _keep_labels_overhead() -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	var up := camera.global_basis.y.normalized()
	var height := PixelArt.CELL.y * PixelArt.PIXEL
	var label := _player.get_node_or_null("Label") as Node3D
	if label:
		label.global_position = _player.global_position + up * (height + 0.35)
	var bubble := _player.get_node_or_null("Bubble") as Node3D
	if bubble:
		bubble.global_position = _player.global_position + up * (height + 0.95)


func _pick_animation() -> String:
	if _player.knocked > 0.0:
		return "hit"
	if _player.carried:
		return "carry"
	if _player.station:
		return "pull" if String(_player.station.name) == "Pump" else "push"
	var moving := Vector2(_player.velocity.x, _player.velocity.z).length() > 0.6
	return "run" if moving else "idle"


func _show() -> void:
	var fps: float = PixelArt.ANIMATIONS[animation].fps
	var frame := int(_time * fps)
	region_rect = PixelArt.frame_rect(animation, column, frame)
	# A little bob while carrying something overhead.
	position.y = 0.08 if animation == "carry" and Vector2(_player.velocity.x, _player.velocity.z).length() > 0.6 \
			and frame % 2 == 0 else 0.0
