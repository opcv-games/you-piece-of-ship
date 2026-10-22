Feature: Developer mode
  So that Olivier can tune and test the game without editing code

  Scenario: Esc opens the pause menu
    Given a voyage is running offline
    When a player presses Esc
    Then the game pauses and shows Resume, Restart, Dock, Main menu and Developer

  Scenario: Live tuning
    Given the Developer panel is open
    When Olivier moves the "heat rise" slider
    Then the engine heats at the new rate straight away
    And the values can be saved to and loaded from presets 1 to 3

  Scenario: Forcing events
    When Olivier presses "Open a leak", "Break the rudder" or "Reach port"
    Then that event happens immediately
