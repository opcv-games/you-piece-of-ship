extends RefCounted
## Gives every couch player their own controls: controller N drives player N.
## Players 1 and 2 also get keyboard keys so one person can test without four controllers.
## Keys use physical positions, so W A S D is Z Q S D on a French keyboard.
## "use" takes over or leaves a station (helm).

const VERBS := ["left", "right", "up", "down", "jump", "use"]
const DEADZONE := 0.2
const KEYS := {
	1: {"left": KEY_A, "right": KEY_D, "up": KEY_W, "down": KEY_S, "jump": KEY_SPACE, "use": KEY_E},
	2: {"left": KEY_LEFT, "right": KEY_RIGHT, "up": KEY_UP, "down": KEY_DOWN, "jump": KEY_ENTER, "use": KEY_SHIFT},
}


static func action(index: int, verb: String) -> String:
	return "p%d_%s" % [index, verb]


## Creates the p<N>_<verb> actions for players 1..count. Safe to call more than once.
static func ensure_actions(count: int) -> void:
	for index in range(1, count + 1):
		for verb in VERBS:
			var name := action(index, verb)
			if InputMap.has_action(name):
				continue
			InputMap.add_action(name, DEADZONE)
			for event in _events(index, verb):
				InputMap.action_add_event(name, event)


static func _events(index: int, verb: String) -> Array[InputEvent]:
	var device := index - 1
	var events: Array[InputEvent] = []
	match verb:
		"left":
			events.append(_stick(device, JOY_AXIS_LEFT_X, -1.0))
			events.append(_button(device, JOY_BUTTON_DPAD_LEFT))
		"right":
			events.append(_stick(device, JOY_AXIS_LEFT_X, 1.0))
			events.append(_button(device, JOY_BUTTON_DPAD_RIGHT))
		"up":
			events.append(_stick(device, JOY_AXIS_LEFT_Y, -1.0))
			events.append(_button(device, JOY_BUTTON_DPAD_UP))
		"down":
			events.append(_stick(device, JOY_AXIS_LEFT_Y, 1.0))
			events.append(_button(device, JOY_BUTTON_DPAD_DOWN))
		"jump":
			events.append(_button(device, JOY_BUTTON_A))
		"use":
			events.append(_button(device, JOY_BUTTON_X))
	var keys: Dictionary = KEYS.get(index, {})
	if keys.has(verb):
		var key := InputEventKey.new()
		key.physical_keycode = keys[verb]
		if keys[verb] == KEY_SHIFT:
			key.location = KEY_LOCATION_RIGHT # right Shift only, left Shift is near player 1
		events.append(key)
	return events


static func _stick(device: int, axis: JoyAxis, direction: float) -> InputEventJoypadMotion:
	var event := InputEventJoypadMotion.new()
	event.device = device
	event.axis = axis
	event.axis_value = direction
	return event


static func _button(device: int, button: JoyButton) -> InputEventJoypadButton:
	var event := InputEventJoypadButton.new()
	event.device = device
	event.button_index = button
	return event
