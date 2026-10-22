extends GutTest
## features/rocking_deck.feature — "Nobody slides off" and "Four players walk to the bow together"

const MainScene = preload("res://scenes/levels/rocking_deck.tscn")

var _level: Node3D
var _ship: Node3D
var _crew: Array[Node] = []
var _camera: Camera3D


func before_each() -> void:
	_level = MainScene.instantiate()
	add_child_autofree(_level)
	_ship = _level.get_node("Ship")
	_camera = _level.get_node("SharedCamera")
	_crew = _level.get_tree().get_nodes_in_group("crew")
	for player in _crew:
		player.get_node("PlayerInput").enabled = false
	# Rough sea: test harder than the default swell.
	_ship.get_node("WaveMotion").intensity = 1.5


func _deck_position(player: Node3D) -> Vector3:
	return _ship.to_local(player.global_position)


func _assert_on_deck(player: Node3D) -> void:
	var p := _deck_position(player)
	assert_true(absf(p.x) < _ship.deck_length / 2.0, "%s is within the deck length (x=%.2f)" % [player.name, p.x])
	assert_true(absf(p.z) < _ship.deck_width / 2.0, "%s is within the deck width (z=%.2f)" % [player.name, p.z])
	assert_true(p.y > -0.1 and p.y < 0.5, "%s stands on the deck (y=%.2f)" % [player.name, p.y])


func test_given_crew_on_deck_then_there_are_four_players() -> void:
	assert_eq(_crew.size(), 4)


func test_given_crew_standing_still_when_deck_rolls_then_nobody_slides() -> void:
	await wait_physics_frames(10)
	var start := {}
	for player in _crew:
		start[player] = _deck_position(player)
	await wait_seconds(3.0)
	for player in _crew:
		_assert_on_deck(player)
		var drift: float = (_deck_position(player) - start[player]).length()
		assert_lt(drift, 0.3, "%s drifted %.2f m" % [player.name, drift])


func test_given_four_players_when_all_walk_to_bow_then_none_slides_off() -> void:
	for player in _crew:
		player.move_input = Vector2.RIGHT  # bow is to the right of the screen
	await wait_seconds(3.5)
	for player in _crew:
		_assert_on_deck(player)
		# The deck has furniture now (mast, cargo), so some crew stop against it on the way.
		assert_gt(_deck_position(player).x, -1.5, "%s walked well toward the bow" % player.name)


func test_given_four_players_when_all_walk_to_bow_then_camera_keeps_all_in_view() -> void:
	for player in _crew:
		player.move_input = Vector2.RIGHT
	await wait_seconds(3.5)
	for player in _crew:
		assert_true(_camera.is_position_in_frustum(player.global_position), "%s is on screen" % player.name)


func test_given_players_spread_to_corners_then_camera_keeps_all_in_view() -> void:
	var directions := [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]
	for i in _crew.size():
		_crew[i].move_input = directions[i]
	await wait_seconds(3.0)
	for player in _crew:
		_assert_on_deck(player)
		assert_true(_camera.is_position_in_frustum(player.global_position), "%s is on screen" % player.name)
