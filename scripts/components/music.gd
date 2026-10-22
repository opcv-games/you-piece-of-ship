extends AudioStreamPlayer
## Background music on its own "Music" audio bus, so it can be muted or mixed separately.
## Placeholder until Phase 4: a synthesised loop of "Drunken Sailor" (tools/make_shanty.py).
## Mute with M or the controller's Select/Back button. Reacts to the voyage: it ducks on a
## crash so the hit lands, and speeds up a little as the port gets close (Thrill of danger).

@export var music_enabled := true
@export_range(-40.0, 6.0) var music_volume_db := -8.0
@export var duck_on_crash := true
@export var duck_db := -12.0 ## how much quieter during a crash
@export var duck_seconds := 0.5
@export var faster_near_port := true
@export var port_tempo_boost := 0.08 ## +8% speed right at the port
@export var port_warning_metres := 80.0
@export var ship: Node3D
@export var finish_x := 300.0

var _duck_left := 0.0


func _ready() -> void:
	bus = &"Music"
	volume_db = music_volume_db
	if ship:
		ship.get_node("ShipHandling").rock_hit.connect(_on_rock_hit)
	if music_enabled and stream:
		play()


func _process(delta: float) -> void:
	_duck_left = maxf(0.0, _duck_left - delta)
	var target_db := music_volume_db + (duck_db if _duck_left > 0.0 else 0.0)
	volume_db = move_toward(volume_db, target_db, 60.0 * delta)
	pitch_scale = 1.0
	if faster_near_port and ship:
		var to_port := finish_x - ship.global_position.x
		if to_port < port_warning_metres:
			pitch_scale = 1.0 + port_tempo_boost * clampf(1.0 - to_port / port_warning_metres, 0.0, 1.0)


func _unhandled_input(event: InputEvent) -> void:
	var pressed_m: bool = event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_M
	var pressed_select: bool = event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_BACK
	if pressed_m or pressed_select:
		toggle_mute()


func is_muted() -> bool:
	return AudioServer.is_bus_mute(AudioServer.get_bus_index(&"Music"))


## Mutes or unmutes the whole Music bus (stays that way after a restart with R).
func toggle_mute() -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index(&"Music"), not is_muted())


func _on_rock_hit(_rock: Node3D) -> void:
	if duck_on_crash:
		_duck_left = duck_seconds
