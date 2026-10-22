Feature: Overcooked-style progression
  So that there's always a next goal (Olivier, 2026-10-22)

  Scenario: Stars open routes
    Given the world map with three oceans of three routes
    When the crew earns stars on a route
    Then routes needing that many stars open

  Scenario: Each ocean brings new trouble
    When Whale Waters opens for the first time
    Then a card says what's new there (whales, sirens, shifting cargo)

  Scenario: Hats
    Given 6 stars, then 15 stars
    Then the captain's hat, then the crown, can be worn from the dock
