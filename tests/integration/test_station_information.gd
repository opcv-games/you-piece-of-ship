extends GutTest
## features/station_information.feature

const LevelScene = preload("res://scenes/levels/voyage.tscn")
const RockScene = preload("res://scenes/greybox/rock.tscn")

var _level: Node3D
var _ship: Node3D
var _helm: Node3D
var _map_table: Node3D
var _chart: Control
var _crew: Array[Node] = []
var _rock: Node3D


func before_each() -> void:
	_level = LevelScene.instantiate()
	add_child_autofree(_level)
	_ship = _level.get_node("Ship")
	_helm = _ship.get_node("Helm")
	_map_table = _ship.get_node("MapTable")
	_chart = _level.get_node("HUD/MapChart")
	_crew = _level.get_tree().get_nodes_in_group("crew")
	for player in _crew:
		player.get_node("PlayerInput").enabled = false
	# A submerged rock 60 metres ahead of the ship.
	_rock = RockScene.instantiate()
	_level.add_child(_rock)
	_rock.global_position = _ship.global_position + Vector3(60, -_ship.global_position.y, 0)
	await wait_physics_frames(2)


func _walk_to(player: Node3D, station: Node3D) -> void:
	player.global_position = station.global_position + Vector3(0, 0.1, 0)
	await wait_physics_frames(5)


func test_given_hidden_rock_when_player_at_helm_then_rock_not_drawn() -> void:
	await _walk_to(_crew[0], _helm)
	_crew[0].use_requested = true
	await wait_physics_frames(3)
	assert_eq(_helm.occupant, _crew[0], "P1 took the helm")
	assert_false(_rock.get_node("Mesh").is_visible_in_tree(), "rock is not drawn in the 3D view")
	assert_false(_chart.visible, "nobody is at the map table, so no chart")


func test_given_hidden_rock_when_player_at_map_table_then_chart_shows_it() -> void:
	await _walk_to(_crew[2], _map_table)
	assert_true(_chart.visible, "chart shown while someone stands at the map table")
	var mark: Vector2 = _chart.chart_point(_rock.global_position)
	var expected := Vector2(0, -60.0 * _chart.chart_scale())
	assert_almost_eq(mark.x, expected.x, 4.0, "rock is straight ahead on the chart")
	assert_almost_eq(mark.y, expected.y, 4.0, "rock is 60 m ahead on the chart")
	assert_true(_chart.rock_marks().size() >= 1, "rock is drawn on the chart")


func test_given_player_reading_chart_when_walking_away_then_chart_hidden() -> void:
	await _walk_to(_crew[2], _map_table)
	assert_true(_chart.visible)
	_crew[2].global_position = _ship.to_global(Vector3(-3, 0.1, 1.5))
	await wait_physics_frames(5)
	assert_false(_chart.visible)


func test_given_player_at_helm_when_pushing_up_and_left_then_ship_speeds_up_and_turns_port() -> void:
	await _walk_to(_crew[0], _helm)
	_crew[0].use_requested = true
	await wait_physics_frames(2)
	_crew[0].move_input = Vector2(-1, -1)
	await wait_seconds(3.0)
	var handling := _ship.get_node("ShipHandling")
	assert_gt(handling.throttle, 0.5, "throttle went up")
	assert_gt(handling.speed, 0.5, "ship is moving")
	assert_gt(_ship.rotation.y, 0.01, "bow turned to port")
	assert_almost_eq(_ship.to_local(_crew[0].global_position).x, _helm.position.x, 0.2, "captain stays at the wheel")


func test_given_player_at_helm_when_using_again_then_leaves_helm() -> void:
	await _walk_to(_crew[0], _helm)
	_crew[0].use_requested = true
	await wait_physics_frames(2)
	_crew[0].use_requested = true
	await wait_physics_frames(2)
	assert_null(_helm.occupant)
	assert_null(_crew[0].station)
