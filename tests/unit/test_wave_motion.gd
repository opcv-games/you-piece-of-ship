extends GutTest
## features/rocking_deck.feature — "The deck rocks with the waves"

const WaveMotion = preload("res://scripts/components/wave_motion.gd")


func test_given_ship_at_sea_when_time_passes_then_roll_and_pitch_stay_within_limits() -> void:
	var waves := WaveMotion.new()
	var max_roll := 0.0
	var max_pitch := 0.0
	for i in 2000:
		var pose: Dictionary = waves.sample(i * 0.01)
		max_roll = maxf(max_roll, absf(pose.roll))
		max_pitch = maxf(max_pitch, absf(pose.pitch))
	assert_lte(max_roll, deg_to_rad(waves.roll_degrees) + 0.0001)
	assert_lte(max_pitch, deg_to_rad(waves.pitch_degrees) + 0.0001)
	assert_gt(max_roll, deg_to_rad(waves.roll_degrees) * 0.9, "the deck actually reaches its full roll")
	waves.free()


func test_given_ship_at_sea_when_time_passes_then_deck_rolls_both_ways() -> void:
	var waves := WaveMotion.new()
	var saw_left := false
	var saw_right := false
	for i in 1000:
		var roll: float = waves.sample(i * 0.01).roll
		saw_left = saw_left or roll < -0.05
		saw_right = saw_right or roll > 0.05
	assert_true(saw_left and saw_right)
	waves.free()


func test_given_calm_sea_when_time_passes_then_deck_stays_level() -> void:
	var waves := WaveMotion.new()
	waves.intensity = 0.0
	var pose: Dictionary = waves.sample(3.7)
	assert_almost_eq(pose.roll, 0.0, 0.0001)
	assert_almost_eq(pose.pitch, 0.0, 0.0001)
	assert_almost_eq(pose.heave, 0.0, 0.0001)
	waves.free()
