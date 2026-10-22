Feature: Carry and drop  (#5)
  # Deck comedy rules (DESIGN.md section 13): carried items drop on knockdown; loose things
  # slide to the low side; all visible and predictable.

  Scenario: Take a plank from the spare parts box
    Given a player standing at the plank box
    When they press Use
    Then they carry a plank above their head and the box has one fewer

  Scenario: Put an item down
    Given a player carrying a plank
    When they press Use away from anything that takes planks
    Then the plank lies on the deck at their feet

  Scenario: A wave knocks a carrier over
    Given a player carrying a plank on a deck listing to port
    When a big wave knocks them down
    Then the plank drops and slides toward the low side of the deck

  Scenario: Holding a station braces you
    Given a player operating the helm
    When a big wave hits
    Then they stay on their feet

  Scenario: Heavy things are slow to carry
    Given a player carrying a rudder pin
    Then they walk at about half speed

  Scenario: Cargo stays lashed until someone moves it
    Given lashed cargo crates on a tilted deck
    Then they do not slide
    When a player picks one up and puts it down on a free cargo spot
    Then it is lashed again

  Scenario: A sliding crate bowls people over
    Given a loose crate sliding fast across the deck
    When it reaches a player
    Then that player is knocked down
