extends Control
## The world map (Olivier, 2026-10-22, Overcooked-style progression): three oceans of three routes,
## painted as a cheerful sea chart. Each route is a port you sail to; stars earned on routes open
## the next ones; a new ocean says what new trouble it brings; hats unlock with stars too.
## Pick a route, read its card, Set sail.

const ContractLibrary = preload("res://scripts/contracts/contract_library.gd")
const Progress = preload("res://scripts/systems/progress.gd")
const VOYAGE_SCENE := "res://scenes/levels/voyage.tscn"
const DOCK_SCENE := "res://scenes/levels/dock.tscn"
const MENU_SCENE := "res://scenes/ui/main_menu.tscn"
## Where each route's port sits on the 1152 x 648 map, by contract index.
const SPOTS := {0: Vector2(120, 470), 4: Vector2(215, 355), 1: Vector2(300, 470),
		5: Vector2(400, 300), 2: Vector2(490, 430), 6: Vector2(585, 300),
		3: Vector2(675, 440), 7: Vector2(760, 290), 8: Vector2(850, 400)}
const PATH := [0, 4, 1, 5, 2, 6, 3, 7, 8]

var selected := 0
var route_buttons := {} ## contract index -> Button

var _card: PanelContainer
var _card_title: Label
var _card_ocean: Label
var _card_text: Label
var _card_stars: Label
var _card_details: Label
var _sail: Button
var _stars_label: Label
var _popup: PanelContainer
var _time := 0.0


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	if Net.role != "client":
		Session.fill_crew_with_ai()
	_build()
	var open: Array = Session.open_contracts()
	select(open[-1] if not open.is_empty() else 0)
	_check_new_ocean()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if _popup and _popup.visible:
			_popup.visible = false
		else:
			UI.go(DOCK_SCENE)


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


## Shows a route's card. Locked routes show what they need.
func select(index: int) -> void:
	selected = index
	var contract: Resource = ContractLibrary.by_index(index)
	var ocean: Dictionary = Progress.OCEANS[Progress.ocean_of(index)]
	var open := Session.is_open(index)
	_card_title.text = tr(contract.title)
	_card_ocean.text = tr(ocean.name)
	_card_ocean.add_theme_color_override("font_color", ocean.colour.lightened(0.3))
	var got: int = int(Session.stars.get(str(index), 0))
	_card_stars.text = "★".repeat(got) + "☆".repeat(3 - got)
	if open:
		_card_text.text = tr(contract.blurb)
		var lines := PackedStringArray()
		lines.append(tr("Deadline %s    %d coins a chest") % [_clock(contract.deadline), contract.pay_per_crate])
		lines.append(tr("Danger: %s") % "⚓".repeat(contract.difficulty))
		var trouble := _trouble(contract)
		if trouble != "":
			lines.append(tr("Watch out for: %s") % trouble)
		if Session.best_scores.has(str(index)) and int(Session.best_scores[str(index)]) > 0:
			var best_time: String = _clock(float(Session.best_times[str(index)])) if Session.best_times.has(str(index)) else "-"
			lines.append(tr("Best: %d points, %s") % [int(Session.best_scores[str(index)]), best_time])
		_card_details.text = "\n".join(lines)
	else:
		_card_text.text = tr("Locked. Earn %d stars to open this route (you have %d).") % [Progress.stars_needed(index),
				Session.total_stars()]
		_card_details.text = ""
	_sail.disabled = not open or Net.role == "client"
	_sail.text = tr("Set sail!") if Net.role != "client" else tr("The host picks the route")
	queue_redraw()


## What makes a route tricky, in a few words.
static func _trouble(contract: Resource) -> String:
	var parts := PackedStringArray()
	var kinds := {}
	for entry in contract.obstacles:
		kinds[entry[2]] = true
	for kind in ["whale", "siren", "wreck", "atoll"]:
		if kinds.has(kind):
			parts.append(TranslationServer.translate({"whale": "whales", "siren": "sirens", "wreck": "wrecks", "atoll": "atolls"}[kind]))
	if not contract.enemies.is_empty():
		parts.append(TranslationServer.translate("pirates"))
	if contract.fog:
		parts.append(TranslationServer.translate("fog"))
	if contract.storm:
		parts.append(TranslationServer.translate("a storm"))
	if contract.equipment.has("no_sail"):
		parts.append(TranslationServer.translate("no sail"))
	for event in contract.events:
		if event[1] == "cargo_shift":
			parts.append(TranslationServer.translate("shifting cargo"))
		elif event[1] == "stall":
			parts.append(TranslationServer.translate("engine failure"))
		elif event[1] == "flood":
			parts.append(TranslationServer.translate("flooding"))
	return ", ".join(parts)


## Sets sail on the selected route with the current crew (empty posts are AI).
func set_sail() -> bool:
	if not Session.is_open(selected) or Net.role == "client":
		UI.play("error")
		return false
	Session.contract_index = selected
	if Net.role == "host":
		Net.start_voyage(selected)
		return true
	if is_inside_tree() and get_tree().current_scene == self:
		UI.go(VOYAGE_SCENE)
	return true


func _check_new_ocean() -> void:
	for i in Progress.OCEANS.size():
		var first: int = Progress.OCEANS[i].routes[0]
		if Session.is_open(first) and not Session.seen_oceans.has(i):
			Session.seen_oceans.append(i)
			Session.save_game()
			_show_popup(i)
			return


func _show_popup(ocean_index: int) -> void:
	var ocean: Dictionary = Progress.OCEANS[ocean_index]
	(_popup.get_node("Box/Title") as Label).text = tr("NEW OCEAN: %s") % tr(ocean.name)
	(_popup.get_node("Box/Text") as Label).text = tr(ocean.new)
	_popup.visible = true
	UI.pop_in(_popup)
	UI.play("stamp")


static func _clock(seconds: float) -> String:
	return "%d:%02d" % [int(seconds) / 60, int(seconds) % 60]


# --- Drawing the sea chart --------------------------------------------------------------------

func _draw() -> void:
	var view := size
	draw_rect(Rect2(Vector2.ZERO, view), Color(0.33, 0.7, 0.86))
	# Three ocean regions, each its own tint, with soft wave squiggles.
	var bands := [Rect2(20, 120, 320, 470), Rect2(330, 120, 300, 470), Rect2(620, 120, 280, 470)]
	for i in bands.size():
		var band: Rect2 = bands[i]
		var colour: Color = Progress.OCEANS[i].colour
		var open := Session.is_open(Progress.OCEANS[i].routes[0])
		draw_rect(band, Color(colour, 0.55 if open else 0.25))
		for row in 7:
			for col in 5:
				var p := band.position + Vector2(30 + col * 62 + (row % 2) * 30, 40 + row * 64)
				p.x += sin(_time * 0.8 + row + col) * 4.0
				draw_arc(p, 10, PI * 1.1, PI * 1.9, 8, Color(1, 1, 1, 0.35), 2.0)
				draw_arc(p + Vector2(20, 0), 10, PI * 1.1, PI * 1.9, 8, Color(1, 1, 1, 0.35), 2.0)
		draw_string_outline(get_theme_default_font(), band.position + Vector2(0, 38), tr(Progress.OCEANS[i].name).to_upper(),
				HORIZONTAL_ALIGNMENT_CENTER, band.size.x, 24, 8, Color(0.05, 0.1, 0.2, 0.6))
		draw_string(get_theme_default_font(), band.position + Vector2(0, 38), tr(Progress.OCEANS[i].name).to_upper(),
				HORIZONTAL_ALIGNMENT_CENTER, band.size.x, 24, Color(1, 1, 1, 0.95 if open else 0.5))
	# The dotted route from port to port.
	for i in PATH.size() - 1:
		var a: Vector2 = SPOTS[PATH[i]]
		var b: Vector2 = SPOTS[PATH[i + 1]]
		var open := Session.is_open(PATH[i + 1])
		var dashes := int(a.distance_to(b) / 14.0)
		for d in dashes:
			if d % 2 == 0:
				draw_line(a.lerp(b, float(d) / dashes), a.lerp(b, float(d + 1) / dashes), Color(1, 0.95, 0.8, 0.9 if open else 0.35), 4.0)
	# Little islands with a port at each route.
	for index in SPOTS:
		var p: Vector2 = SPOTS[index]
		draw_circle(p + Vector2(0, 8), 34, Color(0.98, 0.86, 0.58))
		draw_circle(p + Vector2(-10, 0), 20, Color(0.45, 0.78, 0.42))
		draw_circle(p + Vector2(12, -2), 16, Color(0.4, 0.72, 0.38))
	# Route names above their islands.
	for index in SPOTS:
		var p: Vector2 = SPOTS[index]
		var name_text: String = tr(ContractLibrary.by_index(index).title)
		var tint := Color.WHITE if Session.is_open(index) else Color(1, 1, 1, 0.55)
		draw_string_outline(get_theme_default_font(), p + Vector2(-80, -44), name_text, HORIZONTAL_ALIGNMENT_CENTER, 160, 15, 6,
				Color(0.05, 0.1, 0.2, 0.8))
		draw_string(get_theme_default_font(), p + Vector2(-80, -44), name_text, HORIZONTAL_ALIGNMENT_CENTER, 160, 15, tint)
	# Selection ring.
	var at: Vector2 = SPOTS[selected]
	draw_arc(at, 46 + sin(_time * 4.0) * 3.0, 0, TAU, 40, UI.YELLOW, 5.0)


func _build() -> void:
	var title := Label.new()
	title.text = tr("WORLD MAP")
	title.position = Vector2(24, 18)
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", UI.YELLOW)
	title.add_theme_constant_override("outline_size", 10)
	add_child(title)
	_stars_label = Label.new()
	_stars_label.text = tr("★ %d stars") % Session.total_stars()
	_stars_label.position = Vector2(420, 28)
	_stars_label.add_theme_font_size_override("font_size", 28)
	_stars_label.add_theme_color_override("font_color", UI.YELLOW)
	_stars_label.add_theme_constant_override("outline_size", 8)
	add_child(_stars_label)
	for index in SPOTS:
		var button := Button.new()
		button.name = "Route%d" % index
		var got: int = int(Session.stars.get(str(index), 0))
		button.text = ("★".repeat(got) + "☆".repeat(3 - got)) if Session.is_open(index) else (tr("🔒 %d★") % Progress.stars_needed(index))
		button.add_theme_font_size_override("font_size", 15)
		button.custom_minimum_size = Vector2(86, 34)
		button.position = SPOTS[index] + Vector2(-43, 34)
		button.focus_entered.connect(select.bind(index))
		button.mouse_entered.connect(select.bind(index))
		button.pressed.connect(func(): select(index); set_sail())
		add_child(button)
		route_buttons[index] = button
	_card = PanelContainer.new()
	_card.position = Vector2(915, 110)
	_card.custom_minimum_size = Vector2(220, 430)
	add_child(_card)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	_card.add_child(box)
	_card_ocean = Label.new()
	_card_ocean.add_theme_font_size_override("font_size", 14)
	box.add_child(_card_ocean)
	_card_title = Label.new()
	_card_title.add_theme_font_size_override("font_size", 24)
	_card_title.add_theme_color_override("font_color", UI.YELLOW)
	_card_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_card_title)
	_card_stars = Label.new()
	_card_stars.add_theme_font_size_override("font_size", 30)
	_card_stars.add_theme_color_override("font_color", UI.YELLOW)
	box.add_child(_card_stars)
	_card_text = Label.new()
	_card_text.add_theme_font_size_override("font_size", 14)
	_card_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_card_text.custom_minimum_size = Vector2(200, 0)
	box.add_child(_card_text)
	_card_details = Label.new()
	_card_details.add_theme_font_size_override("font_size", 13)
	_card_details.add_theme_color_override("font_color", Color(1, 1, 1, 0.8))
	_card_details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_card_details.custom_minimum_size = Vector2(200, 0)
	box.add_child(_card_details)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(spacer)
	_sail = Button.new()
	_sail.custom_minimum_size = Vector2(0, 52)
	_sail.add_theme_font_size_override("font_size", 22)
	_sail.pressed.connect(set_sail)
	box.add_child(_sail)
	var dock := Button.new()
	dock.text = tr("Crew & shop (dock)")
	dock.pressed.connect(func(): UI.go(DOCK_SCENE))
	box.add_child(dock)
	# Hats unlocked by stars, along the bottom.
	var hats := Label.new()
	var parts := PackedStringArray()
	for hat in Progress.HATS:
		if Progress.HATS[hat] > 0:
			var got: bool = Session.total_stars() >= Progress.HATS[hat]
			parts.append(("✓ " if got else "") + tr("%s hat at %d★") % [tr(hat.capitalize()), Progress.HATS[hat]])
	hats.text = tr("Unlocks: ") + "    ".join(parts)
	hats.position = Vector2(24, 604)
	hats.add_theme_font_size_override("font_size", 16)
	hats.add_theme_constant_override("outline_size", 6)
	add_child(hats)
	# The "new ocean" announcement.
	_popup = PanelContainer.new()
	_popup.name = "Popup"
	_popup.position = Vector2(300, 220)
	_popup.custom_minimum_size = Vector2(520, 0)
	_popup.visible = false
	add_child(_popup)
	var pop := VBoxContainer.new()
	pop.name = "Box"
	_popup.add_child(pop)
	var pop_title := Label.new()
	pop_title.name = "Title"
	pop_title.add_theme_font_size_override("font_size", 28)
	pop_title.add_theme_color_override("font_color", UI.YELLOW)
	pop_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pop.add_child(pop_title)
	var pop_text := Label.new()
	pop_text.name = "Text"
	pop_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pop_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pop.add_child(pop_text)
	var ok := Button.new()
	ok.text = tr("Aye aye!")
	ok.pressed.connect(func(): _popup.visible = false)
	pop.add_child(ok)
