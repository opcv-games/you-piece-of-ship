extends SceneTree
## Manual online check, run together with host_check.gd (see tests/net/README.md).
## Joins 127.0.0.1:7790, pushes its stick right once at sea, and prints what it sees.

var net
var frames := 0
var at_sea := -1


func _initialize() -> void:
	Engine.max_fps = 60 # real time, so the network has time to talk
	root.get_node("Session").persist = false
	net = root.get_node("Net")



func _process(_delta: float) -> bool:
	frames += 1
	if frames == 5:
		print("CLIENT joining: ", net.join("127.0.0.1", 7790))
	if at_sea < 0 and current_scene and current_scene.name == "Voyage":
		at_sea = frames
		print("CLIENT at sea as P%d" % net.my_index)
	if at_sea > 0 and frames == at_sea + 30:
		current_scene.get_node("NetSync").local_move_override = Vector2.RIGHT
	if at_sea > 0 and frames == at_sea + 120:
		current_scene.get_node("NetSync").local_move_override = Vector2.ZERO
	if at_sea > 0 and frames == at_sea + 300:
		var ship = current_scene.get_node("Ship")
		var p2 = null
		for player in get_nodes_in_group("crew"):
			if player.player_index == 2:
				p2 = player
		print("CLIENT ship_x=%.2f p2_x=%.2f items=%d" % [ship.position.x, p2.position.x, get_nodes_in_group("items").size()])
	if at_sea > 0 and frames == at_sea + 390:
		var results = current_scene.get_node("HUD/Results")
		print("CLIENT results_visible=%s delivered=%s" % [results.visible, results.outcome.get("delivered", "?")])
	if frames > 1200 or (at_sea > 0 and frames > at_sea + 400):
		quit()
	return false
