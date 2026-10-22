extends GutTest
## Background music: plays on its own bus, loops, and M / Select toggles it.

const LevelScene = preload("res://scenes/levels/reef_run.tscn")

var _level: Node3D
var _music: AudioStreamPlayer


func before_each() -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index(&"Music"), false)
	_level = LevelScene.instantiate()
	add_child_autofree(_level)
	_music = _level.get_node("Music")
	await wait_physics_frames(2)


func after_all() -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index(&"Music"), false)


func test_given_game_starts_then_music_plays_on_music_bus_and_loops() -> void:
	assert_ne(AudioServer.get_bus_index(&"Music"), -1, "a Music bus exists")
	assert_eq(_music.bus, &"Music")
	assert_true(_music.playing, "music starts with the game")
	assert_eq((_music.stream as AudioStreamWAV).loop_mode, AudioStreamWAV.LOOP_FORWARD, "music loops")


func test_given_music_playing_when_m_pressed_then_muted_and_again_unmuted() -> void:
	var press := InputEventKey.new()
	press.physical_keycode = KEY_M
	press.pressed = true
	_music._unhandled_input(press)
	assert_true(_music.is_muted(), "M mutes")
	_music._unhandled_input(press)
	assert_false(_music.is_muted(), "M again unmutes")


func test_given_music_when_controller_select_pressed_then_muted() -> void:
	var press := InputEventJoypadButton.new()
	press.button_index = JOY_BUTTON_BACK
	press.pressed = true
	_music._unhandled_input(press)
	assert_true(_music.is_muted())


func test_given_music_when_rock_hit_then_ducks_then_recovers() -> void:
	var normal := _music.volume_db
	_level.get_node("Ship/ShipHandling").rock_hit.emit(_level.get_node("Reef/Rock1"))
	await wait_seconds(0.3)
	assert_lt(_music.volume_db, normal - 3.0, "quieter during the crash")
	await wait_seconds(1.0)
	assert_almost_eq(_music.volume_db, normal, 0.5, "back to normal")
