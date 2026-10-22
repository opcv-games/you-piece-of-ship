extends Node
## Online lobby (autoload "Net"). The host's player is P1; each joining machine gets the next
## free slot (P2..P4) and plays with its own keyboard (W A S D) or controller. The host picks the
## contract; everyone goes to sea together and back to the dock together.

signal peers_changed
signal connected(index: int)
signal connection_failed
signal disconnected

const PORT := 7777
const VOYAGE_SCENE := "res://scenes/levels/voyage.tscn"
const DOCK_SCENE := "res://scenes/levels/dock.tscn"

var role := "offline" ## "offline", "host" or "client"
var peers := {} ## host: peer id -> player index
var my_index := 1


func host(port := PORT) -> Error:
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_server(port, 3)
	if error != OK:
		return error
	multiplayer.multiplayer_peer = peer
	role = "host"
	my_index = 1
	peers.clear()
	if not multiplayer.peer_connected.is_connected(_on_peer_connected):
		multiplayer.peer_connected.connect(_on_peer_connected)
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	peers_changed.emit()
	return OK


func join(address: String, port := PORT) -> Error:
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_client(address, port)
	if error != OK:
		return error
	multiplayer.multiplayer_peer = peer
	role = "client"
	if not multiplayer.connection_failed.is_connected(_on_connection_failed):
		multiplayer.connection_failed.connect(_on_connection_failed)
		multiplayer.server_disconnected.connect(_on_server_disconnected)
	return OK


func leave() -> void:
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	role = "offline"
	peers.clear()
	my_index = 1
	peers_changed.emit()


func crew() -> Array[int]:
	var players: Array[int] = [1]
	for index in peers.values():
		players.append(index)
	players.sort()
	return players


## Host: everyone sets sail on this contract.
func start_voyage(contract_index: int) -> void:
	if role != "host":
		return
	_start.rpc(contract_index, crew(), Session.upgrades)


## Host: everyone back to the dock.
func back_to_dock() -> void:
	if role == "host":
		_to_dock.rpc()


func local_addresses() -> PackedStringArray:
	var found := PackedStringArray()
	for address in IP.get_local_addresses():
		if address.count(".") == 3 and not address.begins_with("127.") and not address.begins_with("169.254"):
			found.append(address)
	return found


@rpc("authority", "call_local", "reliable")
func _start(contract_index: int, players: Array, upgrades: Array) -> void:
	Session.contract_index = contract_index
	Session.joined_players.assign(players)
	Session.upgrades = upgrades
	get_tree().change_scene_to_file(VOYAGE_SCENE)


@rpc("authority", "call_local", "reliable")
func _to_dock() -> void:
	get_tree().change_scene_to_file(DOCK_SCENE)


@rpc("authority", "call_remote", "reliable")
func _assigned(index: int) -> void:
	my_index = index
	connected.emit(index)


func _on_peer_connected(id: int) -> void:
	if role != "host":
		return
	var taken := peers.values()
	for index in range(2, 5):
		if not taken.has(index):
			peers[id] = index
			_assigned.rpc_id(id, index)
			break
	peers_changed.emit()


func _on_peer_disconnected(id: int) -> void:
	peers.erase(id)
	peers_changed.emit()


func _on_connection_failed() -> void:
	leave()
	connection_failed.emit()


func _on_server_disconnected() -> void:
	leave()
	disconnected.emit()
	get_tree().change_scene_to_file(DOCK_SCENE)
