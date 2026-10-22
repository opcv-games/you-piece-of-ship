Feature: Adaptive music (Olivier, 2026-10-22)
  # The same cheerful shanty; the worse the ship gets, the more the band has a nervous breakdown.

  Scenario: Five moods from one tune
    Given a hidden stability score from 0 to 100 (water, leaks, engine, rudder, cargo, waves, hits)
    Then 80-100 plays a relaxed oom-pah, 60-79 a busier groove, 40-59 adds percussion, a chromatic bass and a nervous counter-melody, 20-39 tense harmony, frantic drums and brass, 0-19 a meltdown
    And the melody is always there

  Scenario: No flickering
    Given the score hovers around a threshold
    Then calming down needs a 5-point margin and the score recovers slower than it falls

  Scenario: The band reacts
    When the ship hits a rock, the band hits a crash
    When the engine stalls, the bass and drums drop out for a beat
    When the crew narrowly recovers, a fanfare plays
    When the ship reaches port, a triumphant cadence; when it sinks, a sad trombone
    And a small band corner comments ("The tuba player has left the building.") unless captions are off

  Scenario: Mute
    When a player presses M or Select
    Then the music mutes, and unmutes on the next press
