extends GutTest
## features/rocking_deck.feature — "Each player has their own controls"

const PlayerControls = preload("res://scripts/systems/player_controls.gd")


func test_given_four_players_when_game_starts_then_each_has_own_controls() -> void:
	PlayerControls.ensure_actions(4)
	for index in range(1, 5):
		for verb in ["left", "right", "up", "down", "jump"]:
			var action := PlayerControls.action(index, verb)
			assert_true(InputMap.has_action(action), action + " exists")
			assert_gt(InputMap.action_get_events(action).size(), 0, action + " has a button")


func test_given_controls_when_checking_controller_then_each_player_uses_own_pad() -> void:
	PlayerControls.ensure_actions(4)
	for index in range(1, 5):
		var pad_devices := []
		for event in InputMap.action_get_events(PlayerControls.action(index, "jump")):
			if event is InputEventJoypadButton:
				pad_devices.append(event.device)
		assert_eq(pad_devices, [index - 1], "player %d jumps with controller %d" % [index, index])
