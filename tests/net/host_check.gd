extends SceneTree
## Manual online check, run together with client_check.gd (see tests/net/README.md).
## Hosts on port 7790, starts the Reef Run when a client joins, sails, and prints what it sees.

var net
var frames := 0
var started_at := -1


func _initialize() -> void:
	Engine.max_fps = 60 # real time, so the network has time to talk
	root.get_node("Session").persist = false
	net = root.get_node("Net")



func _process(_delta: float) -> bool:
	frames += 1
	if frames == 2:
		print("HOST listening: ", net.host(7790))
	if started_at < 0 and net.peers.size() == 1 and frames > 30:
		started_at = frames
		net.start_voyage(1)
	if started_at > 0 and frames == started_at + 30:
		var ship = current_scene.get_node("Ship")
		ship.get_node("ShipHandling").throttle = 1.0
		var p1 = _player(1)
		p1.get_node("PlayerInput").enabled = false
		p1.global_position = ship.get_node("PlankBox").global_position
	if started_at > 0 and frames == started_at + 40:
		_player(1).use_requested = true
	if started_at > 0 and frames == started_at + 330:
		var ship = current_scene.get_node("Ship")
		var p2 = _player(2)
		print("HOST ship_x=%.2f p2_x=%.2f items=%d p1_carries=%s" % [ship.position.x, p2.position.x,
				get_nodes_in_group("items").size(), _player(1).carried.kind if _player(1).carried else "none"])
	if started_at > 0 and frames == started_at + 340:
		current_scene.get_node("Ship").position.x = current_scene.finish_x - 1.0 # sail into port
	if frames > 1200 or (started_at > 0 and frames > started_at + 420):
		quit()
	return false


func _player(index: int):
	for player in get_nodes_in_group("crew"):
		if player.player_index == index:
			return player
	return null
