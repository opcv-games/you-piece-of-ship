Feature: Station-bound information
  # First innovation: what you can see depends on the station you stand at.
  # Each scenario maps to at least one GUT test in tests/.

  Scenario: Hidden rock is invisible from the helm
    Given a submerged rock 60 metres ahead of the ship
    When a player stands at the helm
    Then the rock is not drawn in that player's view

  Scenario: Hidden rock is shown on the map table
    Given a submerged rock 60 metres ahead of the ship
    When a player stands at the map table
    Then the map table shows the rock's position relative to the ship

  Scenario: Leaving the map table hides the chart
    Given a player is reading the map table
    When the player walks away from the map table
    Then the chart is no longer shown
