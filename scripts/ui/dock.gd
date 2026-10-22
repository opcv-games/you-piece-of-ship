extends Control
## The dock between voyages: the crew joins (each player presses Use), picks the next contract and
## spends its earnings in the shop. Menus use the standard UI keys: arrows / D-pad to move,
## Enter / Space / A to confirm, so any player can drive them.

signal contract_started(index: int)

const ContractLibrary = preload("res://scripts/contracts/contract_library.gd")
const Upgrades = preload("res://scripts/systems/upgrades.gd")
const PlayerControls = preload("res://scripts/systems/player_controls.gd")
const VOYAGE_SCENE := "res://scenes/levels/voyage.tscn"
const COLORS := [Color(0.9, 0.25, 0.2), Color(0.2, 0.45, 0.95), Color(0.95, 0.8, 0.15), Color(0.25, 0.75, 0.3)]

var joined: Array[int] = []
var contract_buttons: Array[Button] = []
var shop_buttons := {} ## upgrade id -> Button

var _money: Label
var _online_status: Label
var _address: LineEdit
var _details: Label
var _message: Label
var _crew_slots: Array[Panel] = []


func _ready() -> void:
	PlayerControls.ensure_actions(4)
	joined = Session.joined_players.duplicate()
	_build()
	Net.peers_changed.connect(refresh)
	Net.connected.connect(func(_index): refresh())
	Net.connection_failed.connect(func(): _message.text = "Couldn't reach the host. Check the address.")
	Net.disconnected.connect(func(): _message.text = "The host left.")
	refresh()
	if not contract_buttons.is_empty():
		contract_buttons[clampi(Session.unlocked - 1, 0, contract_buttons.size() - 1)].grab_focus()


func _process(_delta: float) -> void:
	if Net.role != "offline":
		return # online: the crew is whoever is connected
	for index in range(1, 5):
		if Input.is_action_just_pressed(PlayerControls.action(index, "use")):
			toggle_crew(index)


func toggle_crew(index: int) -> void:
	if joined.has(index):
		joined.erase(index)
	else:
		joined.append(index)
		joined.sort()
	_message.text = ""
	refresh()


## Starts a contract with the current crew. Returns false (with a message) if it can't.
func start_contract(index: int) -> bool:
	if Net.role == "client":
		_message.text = "The host chooses the contract."
		return false
	if index >= Session.unlocked:
		_message.text = "Locked: deliver the previous contract first."
		return false
	if joined.is_empty():
		_message.text = "Nobody aboard! Each player presses Use (E, Right Shift or X) to join."
		return false
	Session.contract_index = index
	Session.joined_players = joined.duplicate()
	contract_started.emit(index)
	if Net.role == "host":
		Net.start_voyage(index) # everyone sets sail together
		return true
	if is_inside_tree() and get_tree().current_scene == self:
		get_tree().change_scene_to_file(VOYAGE_SCENE)
	return true


func buy(id: String) -> bool:
	var ok := Session.buy(id)
	_message.text = "Bought: %s" % Upgrades.DATA[id].title if ok else "Not enough coins."
	refresh()
	return ok


func refresh() -> void:
	if Net.role != "offline":
		joined = Net.crew() if Net.role == "host" else joined
	_money.text = "Coins: %d" % Session.money
	match Net.role:
		"host":
			_online_status.text = "Hosting: %d aboard. Friends join with your address: %s" % [
					Net.crew().size(), ", ".join(Net.local_addresses())]
		"client":
			_online_status.text = "Online as P%d (your keyboard W A S D or controller). The host picks the contract." % Net.my_index
		_:
			_online_status.text = "Play online: one friend hosts, the others join with the host's address."
	for i in 4:
		var on := joined.has(i + 1)
		var style := StyleBoxFlat.new()
		style.bg_color = COLORS[i] if on else Color(1, 1, 1, 0.08)
		_crew_slots[i].add_theme_stylebox_override("panel", style)
		(_crew_slots[i].get_child(0) as Label).text = "P%d\n%s" % [i + 1, "aboard" if on else "press Use"]
	var contracts := ContractLibrary.all_contracts()
	for i in contracts.size():
		var c: Resource = contracts[i]
		var button := contract_buttons[i]
		if i < Session.unlocked:
			var best: int = int(Session.best_scores.get(str(i), 0))
			button.text = "%d. %s   %s   %d coins/crate   %s%s" % [i + 1, c.title, "*".repeat(c.difficulty),
					c.pay_per_crate, _clock(c.deadline), "   best %d" % best if best > 0 else ""]
		else:
			button.text = "%d. LOCKED (deliver the previous contract)" % (i + 1)
	for id in Upgrades.ORDER:
		var data: Dictionary = Upgrades.DATA[id]
		var owned := Session.upgrades.has(id)
		shop_buttons[id].text = "%s   %s\n+ %s\n- %s" % [data.title, "OWNED" if owned else "%d coins" % data.price,
				data.gain, data.cost]
		shop_buttons[id].disabled = owned


static func _clock(seconds: float) -> String:
	return "%d:%02d" % [int(seconds) / 60, int(seconds) % 60]


func _build() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var background := ColorRect.new()
	background.color = Color(0.07, 0.13, 0.22)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 40
	root.offset_right = -40
	root.offset_top = 16
	root.offset_bottom = -12
	root.add_theme_constant_override("separation", 7)
	add_child(root)
	var header := HBoxContainer.new()
	root.add_child(header)
	header.add_child(_label("THE DOCK", 34, Color(1, 0.85, 0.3)))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	_money = _label("Coins: 0", 26, Color(1, 0.85, 0.3))
	header.add_child(_money)
	root.add_child(_label("CREW: each player presses Use (E, Right Shift or X) to come aboard", 16, Color.WHITE))
	var crew := HBoxContainer.new()
	crew.add_theme_constant_override("separation", 12)
	root.add_child(crew)
	for i in 4:
		var slot := Panel.new()
		slot.custom_minimum_size = Vector2(120, 50)
		var text := _label("", 16, Color.WHITE)
		text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		text.set_anchors_preset(Control.PRESET_FULL_RECT)
		slot.add_child(text)
		crew.add_child(slot)
		_crew_slots.append(slot)
	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 30)
	root.add_child(columns)
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(left)
	left.add_child(_label("CONTRACTS", 20, Color(1, 1, 1, 0.8)))
	var contracts := ContractLibrary.all_contracts()
	for i in contracts.size():
		var button := _button()
		button.pressed.connect(start_contract.bind(i))
		button.focus_entered.connect(func(): _details.text = contracts[i].blurb)
		left.add_child(button)
		contract_buttons.append(button)
	_details = _label("", 15, Color(1, 1, 1, 0.75))
	_details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left.add_child(_details)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(right)
	right.add_child(_label("SHOP (every upgrade has a catch)", 20, Color(1, 1, 1, 0.8)))
	for id in Upgrades.ORDER:
		var button := _button()
		button.pressed.connect(buy.bind(id))
		right.add_child(button)
		shop_buttons[id] = button
	var online := HBoxContainer.new()
	online.add_theme_constant_override("separation", 10)
	root.add_child(online)
	var host_button := _button()
	host_button.text = "Host online game"
	host_button.custom_minimum_size = Vector2(190, 36)
	host_button.pressed.connect(_host)
	online.add_child(host_button)
	_address = LineEdit.new()
	_address.text = "127.0.0.1"
	_address.custom_minimum_size = Vector2(170, 36)
	online.add_child(_address)
	var join_button := _button()
	join_button.text = "Join"
	join_button.custom_minimum_size = Vector2(80, 36)
	join_button.pressed.connect(_join)
	online.add_child(join_button)
	var leave_button := _button()
	leave_button.text = "Leave"
	leave_button.custom_minimum_size = Vector2(80, 36)
	leave_button.pressed.connect(func(): Net.leave(); refresh())
	online.add_child(leave_button)
	_online_status = _label("", 15, Color(0.6, 0.85, 1.0))
	online.add_child(_online_status)
	_message = _label("", 17, Color(1, 0.6, 0.5))
	root.add_child(_message)
	root.add_child(_label("Arrows / D-pad: choose     Enter / Space / A: confirm", 15, Color(1, 1, 1, 0.6)))


func _host() -> void:
	if Net.host() != OK:
		_message.text = "Couldn't start hosting (is another game already hosting on this computer?)."
	refresh()


func _join() -> void:
	if Net.join(_address.text.strip_edges()) != OK:
		_message.text = "That address doesn't look right."
	else:
		_message.text = "Joining %s..." % _address.text
	refresh()


func _label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label


func _button() -> Button:
	var button := Button.new()
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.add_theme_font_size_override("font_size", 15)
	button.custom_minimum_size = Vector2(0, 36)
	return button
