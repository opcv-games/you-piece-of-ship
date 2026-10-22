extends Node
## Online lobby (autoload "Net"). The host's player is P1; each joining machine gets the next
## free slot (P2..P4) and plays with its own keyboard (W A S D) or controller. The host picks the
## contract; everyone goes to sea together and back to the dock together.

signal peers_changed
signal connected(index: int)
signal connection_failed
signal disconnected
signal host_checked(report: Dictionary) ## what the internet check found when hosting (see host_report)

const PORT := 7777
const VOYAGE_SCENE := "res://scenes/levels/voyage.tscn"
const DOCK_SCENE := "res://scenes/levels/dock.tscn"

var role := "offline" ## "offline", "host" or "client"
var peers := {} ## host: peer id -> player index
var my_index := 1
var remote_ai: Array = [] ## client: the host's AI crew indexes (shown, not simulated here)

## Hosting over the internet (Olivier, 2026-10-22): when hosting, ask the router (UPnP) to open
## UDP 7777, read the router's outside address, and ask an HTTPS "what's my IP" service for the
## real public address. If they differ (or the router's is a shared 100.64-127 address), the
## provider shares one address between customers (CGNAT): nobody outside can reach this machine.
const PUBLIC_IP_URL := "https://api.ipify.org"
var host_report := {} ## {state: "checking" | "open" | "cgnat" | "no_upnp", public, router, local}
var _upnp: UPNP
var _mapped_port := 0
var _thread: Thread
var _router_known := false
var _public_known := false


func host(port := PORT) -> Error:
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_server(port, 3)
	if error != OK:
		return error
	multiplayer.multiplayer_peer = peer
	role = "host"
	my_index = 1
	peers.clear()
	check_internet_hosting(port)
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
	close_router_port()
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
	_start.rpc(contract_index, crew(), Session.ai_crew.keys(), Session.upgrades)


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
func _start(contract_index: int, players: Array, ai_indexes: Array, upgrades: Array) -> void:
	Session.contract_index = contract_index
	var humans: Array[int] = []
	for index in players:
		if not ai_indexes.has(index): # a slot can't be both
			humans.append(index)
	Session.joined_players = humans
	remote_ai = ai_indexes
	Session.upgrades = upgrades
	UI.go(VOYAGE_SCENE)


@rpc("authority", "call_local", "reliable")
func _to_dock() -> void:
	UI.go(DOCK_SCENE)


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
			Session.ai_crew.erase(index) # the friend takes this AI's place
			_assigned.rpc_id(id, index)
			break
	peers_changed.emit()


func _on_peer_disconnected(id: int) -> void:
	var index: int = peers.get(id, 0)
	peers.erase(id)
	if index > 0 and role == "host":
		Session.enable_ai(index) # an AI takes the empty place again
	peers_changed.emit()


func _on_connection_failed() -> void:
	leave()
	connection_failed.emit()


func _on_server_disconnected() -> void:
	leave()
	disconnected.emit()
	get_tree().change_scene_to_file(DOCK_SCENE)


# --- Internet hosting ----------------------------------------------------------------------------

## Opens the game's port on the router (UPnP) and works out whether friends elsewhere can reach us.
## Runs in the background; listen to host_checked for the result.
func check_internet_hosting(port := PORT) -> void:
	host_report = {"state": "checking", "public": "", "router": "", "local": ", ".join(local_addresses()), "upnp": false}
	_router_known = false
	_public_known = false
	host_checked.emit(host_report)
	if _thread and _thread.is_started():
		_thread.wait_to_finish()
	_thread = Thread.new()
	_thread.start(_open_router_port.bind(port))
	var request := HTTPRequest.new()
	request.timeout = 8.0
	add_child(request)
	request.request_completed.connect(func(result, code, _headers, body):
		if result == HTTPRequest.RESULT_SUCCESS and code == 200:
			host_report.public = body.get_string_from_utf8().strip_edges()
		request.queue_free()
		_public_known = true
		_finish_report())
	if request.request(PUBLIC_IP_URL) != OK:
		_public_known = true


## Runs on a background thread: UPnP discovery can take a few seconds.
func _open_router_port(port: int) -> void:
	var upnp := UPNP.new()
	var found := upnp.discover(2500, 2, "InternetGatewayDevice") == UPNP.UPNP_RESULT_SUCCESS
	var router := ""
	var mapped := 0
	if found and upnp.get_gateway() and upnp.get_gateway().is_valid_gateway():
		if upnp.add_port_mapping(port, port, "You Piece of Ship", "UDP", 0) == UPNP.UPNP_RESULT_SUCCESS:
			mapped = port
		router = upnp.query_external_address()
	call_deferred("_router_done", upnp, router, mapped)


func _router_done(upnp: UPNP, router: String, mapped: int) -> void:
	_upnp = upnp
	_mapped_port = mapped
	host_report.router = router
	host_report.upnp = mapped != 0
	_router_known = true
	_finish_report()


## Decides once both the router and the public address are known (either may have failed).
func _finish_report() -> void:
	if not (_router_known and _public_known):
		return
	var router: String = host_report.router
	var public: String = host_report.public
	if is_shared_address(router) or (router != "" and public != "" and router != public):
		host_report.state = "cgnat"
	elif host_report.upnp:
		host_report.state = "open"
	else:
		host_report.state = "no_upnp"
	host_checked.emit(host_report)


## True for addresses an internet provider uses to share one public address (CGNAT, 100.64/10)
## or for private addresses a router should never show as its outside address.
static func is_shared_address(address: String) -> bool:
	var parts := address.split(".")
	if parts.size() != 4:
		return false
	var a := int(parts[0])
	var b := int(parts[1])
	return (a == 100 and b >= 64 and b <= 127) or a == 10 or (a == 192 and b == 168) or (a == 172 and b >= 16 and b <= 31)


## One plain sentence for the dock about who can join us.
func host_message() -> String:
	match host_report.get("state", ""):
		"checking":
			return tr("Checking whether friends on the internet can reach you...")
		"open":
			return tr("Friends can join you at: %s") % host_report.public
		"cgnat":
			return tr("Your internet connection can't host for friends elsewhere (your provider shares one address between customers). Ask your friend to host instead. Same Wi-Fi friends can join at: %s") % host_report.local
		"no_upnp":
			return tr("Your router didn't open the game's door automatically (UPnP is off). Friends elsewhere probably can't join: ask them to host, or open UDP port 7777 on your router. Same Wi-Fi friends can join at: %s") % host_report.local
	return ""


## The address friends should type (public if reachable, otherwise the local one).
func join_address() -> String:
	if host_report.get("state", "") == "open":
		return host_report.public
	return local_addresses()[0] if not local_addresses().is_empty() else ""


func close_router_port() -> void:
	if _upnp and _mapped_port != 0:
		_upnp.delete_port_mapping(_mapped_port, "UDP")
	_mapped_port = 0


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_PREDELETE:
		close_router_port()
		if _thread and _thread.is_started():
			_thread.wait_to_finish()
