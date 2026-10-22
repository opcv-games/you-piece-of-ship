Feature: AI crewmates
  # Olivier, 2026-10-22: playing alone he couldn't finish the Maiden Voyage. Empty slots can be AI.

  Scenario: Humans choose first
    Given a human operating a station
    Then no AI takes that station
    And a human who walks up to a station an AI holds takes it over

  Scenario: Primary and secondary jobs
    Given an AI with primary job "navigator" and secondary job "carpenter"
    When rocks are near
    Then it reads the chart and calls them out
    When a leak opens while the sea ahead is clear
    Then it switches to fixing the leak

  Scenario: The navigator calls out rocks
    Given an AI at the map table and a rock ahead to starboard
    Then a speech bubble says "Rock, 2 o'clock, 40 m!" style callouts

  Scenario: The engineer keeps the engine going
    Given an AI engineer
    When the coal runs low it shovels, and when the engine is about to overheat it vents

  Scenario: The carpenter patches leaks and swaps the rudder pin
    Given an open leak and a broken rudder
    Then an AI carpenter fetches a plank and patches, and brings the pin to the helm

  Scenario: One human and three AIs can finish
    Given one human who does nothing and three AI crewmates
    Then they deliver the Maiden Voyage and the Reef Run (tests/ai/full_voyage_check.gd)
