Feature: Dock: contract choice, upgrade shop and the voyage loop  (#13)

  Scenario: Earnings and unlocking
    Given the crew delivers a contract with a score of 700
    Then they earn 700 coins and the next contract unlocks
    But a sunk voyage earns nothing and unlocks nothing

  Scenario: Buying an upgrade
    Given 500 coins
    When the crew buys the bigger pumps (350)
    Then 150 coins remain and the pumps are owned
    And an upgrade can't be bought twice or without enough coins

  Scenario: Every upgrade has a catch
    Then the overclocked engine is faster but heats faster
    And the reinforced hull leaks slower but is slower and turns worse
    And bigger pumps pump faster but burn coal
    And the second spares crate brings more planks and a pin but one fewer cargo crate

  Scenario: Choosing a contract needs a crew
    Given nobody has joined at the dock
    When a contract is chosen
    Then the dock asks players to press Use to join
    When players join and choose an unlocked contract
    Then the voyage starts with that crew and contract
    And locked contracts can't be chosen
