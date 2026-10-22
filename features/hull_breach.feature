Feature: Hull breach changes handling  (#3)
  # Coupled systems (DESIGN.md section 13): water makes the ship heavier, slower, lower and listing.

  Scenario: Hitting a rock cracks the hull, with a warning
    Given the ship hits a rock
    Then the nearest leak spot cracks and sprays for 5 seconds before water pours in

  Scenario: A hull breach slows the ship
    Given an open breach
    When 20 seconds pass
    Then the water level rises and top speed drops

  Scenario: Patching and pumping restores speed
    Given a patched breach and a flooded ship
    When the water is pumped out
    Then top speed recovers

  Scenario: Two crew patch fast, one crew patches slowly
    Given a plank on a breach
    When two crew hammer it for 4 seconds
    Then it is sealed
    But one crew alone needs about 12 seconds

  Scenario: Emergency crate plug
    Given an open breach
    When a crew member stuffs a cargo crate into it
    Then the flow drops to 30 percent and that cargo is lost

  Scenario: The ship sinks only after a fair chance
    Given the first leak appeared less than 60 seconds ago
    Then the ship cannot sink yet
    When the ship fills with water after that
    Then the ship sinks

  Scenario: Water lists the ship toward the leaks
    Given open leaks on the starboard side
    When water comes in
    Then the ship heels toward starboard
