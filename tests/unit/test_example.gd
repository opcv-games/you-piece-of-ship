extends GutTest
## Example BDD-style test. Name tests test_given_<state>_when_<action>_then_<outcome>.
## Replace with tests for features/core_loop.feature.


func test_given_fresh_project_when_tests_run_then_gut_is_wired_up() -> void:
	assert_true(true, "GUT runs headless in CI")
