Feature: Walk on a rocking ship, together  (#1)
  # Foundation for Comedy and Social interaction: four players share one moving deck on one screen.
  # Each scenario maps to a GUT test in tests/.

  Scenario: The deck rocks with the waves
    Given the ship is at sea
    When time passes
    Then the deck rolls and pitches within its set limits and returns through level

  Scenario: Nobody slides off a tilted deck
    Given four players standing still on the deck
    When the deck rolls for 3 seconds
    Then every player is still on the deck, close to where they stood

  Scenario: Four players walk to the bow together
    Given four local players with controllers on a rolling deck
    When all walk to the bow
    Then none slides off
    And the camera keeps all four in view

  Scenario: Each player has their own controls
    Given four players
    When the game starts
    Then each player has their own move and jump controls
