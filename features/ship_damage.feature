Feature: Damage changes how the ship handles

  Scenario: A hull breach slows the ship
    Given the ship is at full speed with an open hull breach
    When 20 seconds pass
    Then the water level in the hold has risen
    And the ship's top speed is lower than before

  Scenario: Patching and pumping restores speed
    Given the hold is flooded and the breach is patched
    When the water is pumped out
    Then the ship's top speed returns to normal

  Scenario: Overheating caps speed, then stalls the engine
    Given the engine is at full throttle
    When the heat passes 80 percent
    Then the ship's top speed is capped
    And when the heat reaches 100 percent the engine stalls for 20 seconds after a 5 second warning
