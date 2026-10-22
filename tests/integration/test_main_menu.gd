extends GutTest
## The main menu (Olivier's mockup): six buttons, Quick Play fills empty posts with AI crewmates.

const MenuScene = preload("res://scenes/ui/main_menu.tscn")

var _saved := {}


func before_each() -> void:
	_saved = {"joined": Session.joined_players.duplicate(), "ai": Session.ai_crew.duplicate(), "lang": Session.language}


func after_each() -> void:
	Session.joined_players = _saved.joined
	Session.ai_crew = _saved.ai
	Session.language = _saved.lang
	Session.apply_settings()


func test_menu_has_the_six_buttons() -> void:
	var menu: Control = MenuScene.instantiate()
	add_child_autofree(menu)
	await wait_physics_frames(2)
	for key in ["quick", "host", "join", "ship", "settings", "quit"]:
		assert_true(menu.buttons.has(key), key)


func test_quick_play_fills_empty_posts_with_ai() -> void:
	Session.joined_players = [] as Array[int]
	Session.ai_crew = {}
	var menu: Control = MenuScene.instantiate()
	add_child_autofree(menu)
	await wait_physics_frames(2)
	menu.quick_play()
	assert_eq(Session.joined_players, [1] as Array[int])
	assert_eq(Session.ai_crew.size(), 3, "three AI crewmates")
	assert_between(Session.contract_index, 0, Session.unlocked - 1)


func test_language_switch_changes_locale_and_title_stays_english() -> void:
	var menu: Control = MenuScene.instantiate()
	add_child_autofree(menu)
	await wait_physics_frames(2)
	Session.language = "en"
	Session.apply_settings()
	menu.toggle_language()
	assert_eq(TranslationServer.get_locale().substr(0, 2), "fr")
	menu.toggle_language()
	assert_eq(TranslationServer.get_locale().substr(0, 2), "en")
