extends GutTest
## features/game_feel.feature

const LevelScene = preload("res://scenes/levels/voyage.tscn")
const RockScene = preload("res://scenes/greybox/rock.tscn")

var _level: Node3D
var _feel: Node
var _ship: Node3D
var _camera: Camera3D


func before_each() -> void:
	_level = LevelScene.instantiate()
	add_child_autofree(_level)
	_feel = _level.get_node("GameFeel")
	_ship = _level.get_node("Ship")
	_camera = _level.get_node("SharedCamera")
	for player in _level.get_tree().get_nodes_in_group("crew"):
		player.get_node("PlayerInput").enabled = false
	await wait_physics_frames(2)


func after_each() -> void:
	Engine.time_scale = 1.0


func _crash() -> Node3D:
	var rock: Node3D = RockScene.instantiate()
	_level.add_child(rock)
	rock.global_position = _ship.global_position + Vector3(9, -_ship.global_position.y, 0)
	_ship.get_node("ShipHandling").rock_hit.emit(rock)
	return rock


func test_given_sailing_when_rock_hit_then_screen_shakes_and_settles() -> void:
	_crash()
	assert_gt(_camera.trauma, 0.0, "camera is shaking")
	await wait_seconds(2.0)
	assert_almost_eq(_camera.trauma, 0.0, 0.001, "shake settles")


func test_given_sailing_when_rock_hit_then_game_freezes_briefly_then_resumes() -> void:
	_crash()
	assert_lt(Engine.time_scale, 0.5, "hit-stop slows time")
	await wait_seconds(0.5)
	assert_eq(Engine.time_scale, 1.0, "time back to normal")


func test_given_sailing_when_rock_hit_then_debris_flies() -> void:
	var before := _level.get_children().size()
	_crash()
	var bursts := 0
	for child in _level.get_children():
		if child is CPUParticles3D and child.emitting:
			bursts += 1
	assert_gte(bursts, 2, "debris and spray emitters")


func test_given_effects_off_when_rock_hit_then_nothing_happens() -> void:
	_feel.shake_enabled = false
	_feel.hitstop_enabled = false
	_feel.debris_enabled = false
	_crash()
	assert_eq(_camera.trauma, 0.0)
	assert_eq(Engine.time_scale, 1.0)
	for child in _level.get_children():
		assert_false(child is CPUParticles3D, "no debris")


func test_given_ship_stopped_then_no_wake_and_moving_then_wake() -> void:
	var wake: CPUParticles3D = _ship.get_node("BowWake")
	await wait_physics_frames(2)
	assert_false(wake.emitting, "no foam when stopped")
	_ship.get_node("ShipHandling").speed = _ship.get_node("ShipHandling").max_speed
	await wait_physics_frames(2)
	assert_true(wake.emitting, "foam when moving")
	assert_gt(_feel.wake_ratio, 0.9, "full foam at full speed")


func test_given_crew_jumps_then_body_stretches_and_returns() -> void:
	var player: Node3D = _level.get_tree().get_nodes_in_group("crew")[0]
	await wait_seconds(0.3)
	player.jump_requested = true
	await wait_physics_frames(3)
	assert_gt(player.get_node("Visual").scale.y, 1.02, "stretched on jump")
	await wait_seconds(1.5)
	assert_almost_eq(player.get_node("Visual").scale.y, 1.0, 0.01, "back to normal")


func test_given_port_reached_then_confetti_bursts() -> void:
	_level.port_reached.emit()
	var confetti := 0
	for child in _level.get_children():
		if child is CPUParticles3D and child.emitting:
			confetti += 1
	assert_gte(confetti, 1)
