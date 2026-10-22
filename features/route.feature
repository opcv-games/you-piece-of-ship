Feature: One 5-minute route with waves, rocks, port and deadline  (#9)

  Scenario: The route is laid out from its contract
    Given the Reef Run contract
    Then its hidden rocks are placed as authored and cannot be seen from the deck
    And visible cliffs line both sides of the channel
    And the port buoys stand at the end of the route

  Scenario: Pacing starts calm
    Given the Reef Run contract
    Then there are no rocks in the first 200 metres
    And the big waves come later in the voyage

  Scenario: The chart points to port
    Given the port is beyond the chart's range
    Then an arrow on the chart's rim points to it with the distance

  Scenario: The deadline
    Given the voyage is running
    Then the time and the deadline are shown
    When the deadline passes
    Then the clock turns red

  Scenario: Hitting a cliff is a crash
    Given the ship sails into the coastline
    Then it crashes like on a rock
