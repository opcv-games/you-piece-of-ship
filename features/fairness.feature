Feature: Hazard director and fairness rules  (#8)

  Scenario: Big waves arrive where the contract puts them
    Given all systems are fine
    When the ship reaches a wave's position on the route
    Then the big wave starts (with its 5 second warning)

  Scenario: No new hazard while two systems fail
    Given the hull is leaking and the rudder is broken
    When the ship reaches a wave's position
    Then the wave waits

  Scenario: Calm after a recovery
    Given the crew just fixed a system
    Then no new big wave starts for 20 seconds

  Scenario: A postponed wave is dropped
    Given a wave has been waiting
    When the ship is 200 metres past it
    Then it is skipped

  Scenario: Every failure warns first
    Then leaks crack for 5 s, the rudder shudders for 5 s, the engine whistles for 5 s,
    And big waves and fraying ropes warn for 5 s before anything breaks

  Scenario: No sinking right after the first failure
    Then the ship cannot sink within 60 seconds of its first failure
