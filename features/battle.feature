Feature: Sea battles
  So that pirates make some routes exciting (Olivier, 2026-10-22)

  Scenario: Pirates attack from the side
    Given pirates appear on the port side
    When they come level with the ship
    Then they fire a broadside, and a ball that lands on deck cracks the hull

  Scenario: Fight back
    Given a cannonball from the rack in the middle of the deck
    When a crew member loads a port cannon, aims with the stick and presses Jump
    Then the ball flies out and three hits sink the pirates
    And floating loot appears that the ship scoops up by sailing through it

  Scenario: Outrun them
    When the ship sails at full throttle
    Then the pirates fall behind and give up
