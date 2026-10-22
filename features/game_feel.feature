Feature: Game feel on existing moments (juice pass, requested by Olivier 2026-10-22)
  # Every effect has its own on/off switch and strength on the GameFeel node in reef_run.tscn,
  # so each one can be kept or removed after playtesting. No effect may hide information.

  Scenario: A rock crash is felt
    Given the ship is sailing
    When it hits a rock
    Then the screen shakes, the game freezes for a split second, debris and spray fly, and "CRASH!" pops

  Scenario: Speed is visible on the water
    Given the ship is moving
    Then foam sprays from the bow and stern, more at higher speed, and none when stopped

  Scenario: Jumps have weight
    Given a crew member jumps or lands
    Then their body stretches on the jump and squashes on landing, then returns to normal

  Scenario: Reaching port is celebrated
    Given the ship crosses the port buoys
    Then confetti bursts over the ship

  Scenario: Effects can be switched off
    Given an effect is switched off
    Then that moment plays with no effect and the game is otherwise unchanged
