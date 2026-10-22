Feature: Results screen with event recap, quick restart, crew join  (#10)

  Scenario: The voyage tells its story
    Given the ship hits a rock and a crew member is knocked over
    Then the voyage log records both with their times

  Scenario: Results when delivered
    Given the ship reaches port
    Then the results show the time vs the deadline, cargo delivered, hull, score and what happened

  Scenario: Results when sunk
    Given the ship sinks
    Then the results say SUNK with a score of 0 and how far the crew got

  Scenario: Score
    Then the score is cargo value + up to 200 for a dry hull + 2 points per second early

  Scenario: Quick restart keeps the crew
    Given a crew of players 1 and 3 was chosen
    When the voyage restarts
    Then only players 1 and 3 are aboard, straight away

  Scenario: Small crews get help
    Given a crew of 3 or fewer
    Then a slow automatic pump runs

  Scenario: Joining the crew
    Given the crew screen
    When players press Jump to join and one presses Use
    Then the voyage starts with exactly those players

  Scenario: Personal bests
    Given a delivered contract
    Then the best score and best time for that contract are saved
    And the results say "NEW BEST!" when one is beaten
    And the dock shows them on the contract
