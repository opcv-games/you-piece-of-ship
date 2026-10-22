Feature: Online multiplayer, host-authoritative  (#14)

  Scenario: Hosting and joining
    Given one player hosts from the dock
    When a friend joins with the host's address
    Then the friend becomes P2 (then P3, P4) and plays with their own keyboard or controller

  Scenario: The host runs the voyage
    Given an online voyage
    Then the host simulates the ship and sends snapshots; the client shows the same ship, crew and items
    And the client's stick moves its own crew member on both screens

  Scenario: Only the host picks
    Given an online crew at the dock
    Then only the host can choose a contract, restart or go back to the dock

  Scenario: Couch play is unchanged
    Given nobody hosts or joins
    Then the dock and voyages work exactly as before
