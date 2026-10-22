Feature: Engine heat caps speed  (#4)
  # The engineer trades speed for heat; the crew argues about going fast.

  Scenario: Overheating caps speed
    Given full throttle
    When heat passes 80 percent
    Then top speed is capped

  Scenario: Overheating stalls the engine after a warning
    Given heat at 100 percent
    When the 5 second warning ends
    Then the engine stalls for 20 seconds and the cooling pipe bursts

  Scenario: Venting saves the engine but knocks people over
    Given heat at 100 percent and a crew member standing next to the engine
    When the engineer vents steam
    Then the heat drops, the stall is avoided and the bystander is knocked down

  Scenario: Coal
    Given the coal pile beside the engine (it never runs out)
    Then a full firebox lasts about 2.5 minutes at full throttle
    And when it gets low, "COAL LOW!" shows over the engine and a hint says how to shovel
    Given the engine runs out of coal
    Then the ship only limps along
    When the engineer shovels (Use at the engine, hold up)
    Then the firebox refills, empty to full in 5 seconds

  Scenario: The Maiden Voyage never strands a crew
    Given the Maiden Voyage
    Then the firebox never drops below 30 percent

  Scenario: A flooded ship works the engine harder
    Given water in the hull
    Then the engine heats faster at full throttle

  Scenario: Fixing the burst cooling pipe
    Given a burst cooling pipe
    When two crew work on it for 4 seconds
    Then it is fixed

  Scenario: Only the engine room shows the gauge
    Given nobody at the engine
    Then the heat gauge is hidden
    When a player operates the engine
    Then the heat gauge shows
