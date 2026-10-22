Feature: Load and balance  (#7)

  Scenario: Cargo position tilts the ship
    Given cargo moved to the starboard side
    Then the ship lists to starboard

  Scenario: Ropes fray before a big wave
    Given lashed cargo and a big wave coming
    Then one crate's rope frays (warning)
    When the wave hits and nobody secured it
    Then that crate breaks loose and slides

  Scenario: Cargo overboard
    Given a player carrying a crate at the rail
    When they press Use
    Then the crate goes overboard, the ship is lighter and that cargo's value is lost
