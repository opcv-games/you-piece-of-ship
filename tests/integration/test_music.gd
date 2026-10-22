extends GutTest
## Adaptive music: the same tune, climbing in pitch as the ship falls apart.

const LevelScene = preload("res://scenes/levels/voyage.tscn")
const ContractLibrary = preload("res://scripts/contracts/contract_library.gd")
const RockScene = preload("res://scenes/greybox/rock.tscn")

var _level: Node3D
var _music: Node
var _ship: Node3D


func before_each() -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index(&"Music"), false)
	_level = LevelScene.instantiate()
	_level.contract = ContractLibrary.reef_run()
	add_child_autofree(_level)
	_music = _level.get_node("Music")
	_ship = _level.get_node("Ship")
	for player in _level.get_tree().get_nodes_in_group("crew"):
		player.get_node("PlayerInput").enabled = false
	await wait_physics_frames(2)


func after_all() -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index(&"Music"), false)


func test_layers_play_together_on_the_music_bus_and_loop() -> void:
	assert_ne(AudioServer.get_bus_index(&"Music"), -1)
	var lengths := []
	for layer in _music.LAYERS:
		var player: AudioStreamPlayer = _music.get_node(layer)
		assert_eq(player.bus, &"Music")
		assert_true(player.playing, layer + " playing")
		assert_eq((player.stream as AudioStreamWAV).loop_mode, AudioStreamWAV.LOOP_FORWARD, layer + " loops")
		lengths.append(snappedf(player.stream.get_length(), 0.01))
	assert_eq(lengths.filter(func(l): return l != lengths[0]).size(), 0, "all layers the same length (they stay in sync)")


func test_calm_ship_is_relaxed_and_melody_always_on() -> void:
	await wait_seconds(1.0)
	assert_eq(_music.state, 4)
	assert_gt(_music.get_node("melody").volume_db, -20.0)
	assert_almost_eq(_music.pitch, 1.0, 0.01, "normal pitch when all is well")


func test_given_flooding_engine_trouble_and_broken_rudder_then_meltdown() -> void:
	var hull := _ship.get_node("HullSystem")
	for spot in [Vector3(3, 0, 3), Vector3(-2, 0, -3)]:
		hull.add_breach(spot)._warning_left = 0.0
	hull.water = 0.8
	_ship.get_node("EngineSystem").stall_left = 30.0
	_ship.get_node("RudderSystem").state = 2
	watch_signals(_music)
	await wait_seconds(4.0)
	assert_lt(_music.stability, 20.0)
	assert_eq(_music.state, 0, "meltdown")
	assert_almost_eq(_music.pitch, 2.0, 0.05, "an octave up")
	assert_almost_eq(_music.get_node("melody").pitch_scale, _music.pitch, 0.001, "every layer at the same pitch")
	assert_gt(_music.get_node("melody").volume_db, -20.0, "the tune is still there")
	assert_signal_emitted(_music, "state_changed")


func test_pitch_comes_back_down_when_the_crew_recovers() -> void:
	_music.stability = 10.0
	_music._change_state(0)
	await wait_seconds(1.0)
	assert_gt(_music.pitch, 1.5)
	_music.stability = 100.0
	_music._change_state(4)
	await wait_seconds(1.0)
	assert_almost_eq(_music.pitch, 1.0, 0.01)


func test_states_need_a_margin_before_calming_down() -> void:
	assert_eq(_music.state_for(58.0, 2), 2)
	assert_eq(_music.state_for(62.0, 2), 2, "inside the hysteresis band")
	assert_eq(_music.state_for(66.0, 2), 3, "clearly better")
	assert_eq(_music.state_for(38.0, 2), 1, "worse: straight away")


func test_crash_plays_a_sting_and_stall_drops_bass_and_drums() -> void:
	var rock: Node3D = RockScene.instantiate()
	_level.add_child(rock)
	_ship.get_node("ShipHandling").impact.emit(rock)
	assert_true(_music.get_node("sting_crash").playing)
	_ship.get_node("EngineSystem").stalled.emit()
	await wait_physics_frames(3)
	assert_lt(_music.get_node("bass_stable").volume_db, -60.0, "the bass drops out for a beat")
	await wait_seconds(1.5)
	assert_gt(_music.get_node("bass_stable").volume_db, -30.0, "and comes back")


func test_m_and_select_mute_the_music() -> void:
	var press := InputEventKey.new()
	press.physical_keycode = KEY_M
	press.pressed = true
	_music._unhandled_input(press)
	assert_true(_music.is_muted())
	_music._unhandled_input(press)
	assert_false(_music.is_muted())
	var pad := InputEventJoypadButton.new()
	pad.button_index = JOY_BUTTON_BACK
	pad.pressed = true
	_music._unhandled_input(pad)
	assert_true(_music.is_muted())
