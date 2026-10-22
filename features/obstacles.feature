Feature: Varied obstacles at sea
  So that every route feels different (Olivier, 2026-10-22)

  Scenario: Whale
    Given a whale near the route
    Then it swims back and forth across the channel
    And while it dives the ship can pass over it

  Scenario: Siren
    Given a siren on her rock beside the lane
    When the ship comes close
    Then her song pulls the wheel toward her until the ship has passed

  Scenario: Navigator calls them by name
    When the navigator sees a wreck ahead
    Then the bubble says "Wreck, 12 o'clock, 40 m!"
