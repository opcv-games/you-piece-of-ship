extends GutTest
## features/ai_crew.feature — the navigator's clock bearings

const AICrew = preload("res://scripts/ai/ai_crew.gd")


func test_clock_hours() -> void:
	assert_eq(AICrew.clock_hour(40.0, 0.0), 12, "dead ahead")
	assert_eq(AICrew.clock_hour(0.0, 30.0), 3, "starboard beam")
	assert_eq(AICrew.clock_hour(0.0, -30.0), 9, "port beam")
	assert_eq(AICrew.clock_hour(35.0, 20.0), 1, "a little to starboard")
	assert_eq(AICrew.clock_hour(20.0, 35.0), 2)
