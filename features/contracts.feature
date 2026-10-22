Feature: Four hand-made contracts  (#11) and Fog and the bow telescope  (#12)

  Scenario: Four contracts of rising intensity
    Then there are four contracts: Maiden Voyage, Reef Run, The Narrows, Fog Bank
    And each pays more than the one before

  Scenario: The Maiden voyage teaches by doing and can't be lost
    Given the Maiden Voyage
    When the ship reaches each lesson
    Then a hint explains it, and the leak, heat and rudder lessons happen on cue
    And the ship cannot sink

  Scenario: Fog shortens the chart
    Given the Fog Bank
    Then fog covers the sea and the chart only shows rocks within 30 metres
    And the bow telescope is available

  Scenario: The telescope spots rocks
    Given a crew member at the bow telescope in fog
    Then rocks ahead within 90 metres get a red marker everyone can see

  Scenario: No telescope in clear weather
    Given the Reef Run
    Then the telescope is put away
