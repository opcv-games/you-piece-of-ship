Feature: Fishing
  So that idle crew always have something fun to do (Olivier, 2026-10-22)

  Scenario: Catching a fish
    Given a crew member at a fishing spot with the line cast
    When the float dips and they press Jump in time
    Then they catch something (sardine, goldfish, squid, pufferfish or, rarely, treasure)
    And its points are added to the voyage score

  Scenario: AI fish only when all is calm
    Given an AI carpenter with nothing to repair
    Then it goes fishing
    When a leak opens
    Then it reels in and goes to fix it
