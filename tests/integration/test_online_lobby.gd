extends GutTest
## features/online.feature (the two-machine part is checked by tests/net/, see its README)

const DockScene = preload("res://scenes/levels/dock.tscn")


func after_each() -> void:
	Net.role = "offline"
	Net.peers.clear()
	Net.my_index = 1
	Session.joined_players.clear()


func test_host_crew_is_p1_plus_joined_friends() -> void:
	Net.role = "host"
	Net.peers = {1234: 2, 5678: 3}
	assert_eq(Net.crew(), [1, 2, 3] as Array[int])


func test_client_cannot_pick_contract() -> void:
	Net.role = "client"
	Net.my_index = 2
	var dock: Control = DockScene.instantiate()
	add_child_autofree(dock)
	await wait_physics_frames(2)
	dock.toggle_crew(1)
	assert_false(dock.start_contract(0))
	assert_string_contains(dock._online_status.text, "P2")


func test_offline_voyage_has_no_network_role() -> void:
	var level: Node3D = load("res://scenes/levels/voyage.tscn").instantiate()
	add_child_autofree(level)
	await wait_physics_frames(2)
	assert_eq(level.get_node("NetSync").role, "offline")
	assert_false(level.net_puppet)


func test_shared_addresses_are_detected_as_cgnat() -> void:
	assert_true(Net.is_shared_address("100.72.160.1"), "provider-shared range (CGNAT)")
	assert_true(Net.is_shared_address("192.168.0.1"))
	assert_false(Net.is_shared_address("179.152.174.239"), "a real public address")
	assert_false(Net.is_shared_address(""))


func test_host_report_messages() -> void:
	Net.host_report = {"state": "open", "public": "203.0.113.7", "router": "203.0.113.7", "local": "192.168.0.2"}
	assert_string_contains(Net.host_message(), "203.0.113.7")
	assert_eq(Net.join_address(), "203.0.113.7")
	Net.host_report = {"state": "cgnat", "public": "203.0.113.7", "router": "100.72.0.9", "local": "192.168.0.2"}
	assert_string_contains(Net.host_message(), "Ask your friend to host")
	Net.host_report = {}
