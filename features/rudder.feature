Feature: Rudder damage and the rudder pin swap  (#6)

  Scenario: A hard hit damages the rudder, after a warning
    Given the ship hits a rock above half speed with an intact rudder
    Then the wheel shudders for 5 seconds and the hull does not crack
    And then steering response halves and the wheel pulls to one side

  Scenario: A slow hit cracks the hull instead
    Given the ship hits a rock below half speed
    Then the hull cracks and the rudder is fine

  Scenario: One impact, one failure
    Given the rudder is already damaged
    When the ship hits a rock hard
    Then the hull cracks

  Scenario: Swap the rudder pin
    Given a damaged rudder
    When a crew member brings the rudder pin to the helm and presses Use
    Then steering is normal again

  Scenario: A broken rudder pulls even with nobody steering
    Given a damaged rudder and nobody at the wheel
    When the ship sails
    Then it drifts off course
