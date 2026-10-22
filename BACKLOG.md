# You Piece of Ship — Backlog

> Agile, not a roadmap. Only "Now" is committed. Re-prioritize after every development cycle.
> Tags: `[innovation]` 40% hooks · `[standard]` genre conventions · `[tech]` infrastructure
> Milestones: **Ugly Prototype** (Milestone A, DESIGN.md §9) then **Vertical Slice** (Milestone B)

## Now (committed, top = highest priority) — Milestone A
- [ ] `[tech]` **Walk on a rocking ship, together**
  As a player on the couch, I want to walk and jump on a deck that rolls with waves alongside three friends on one screen, so that the ship feels like a shared physical space (serves: Comedy, Social interaction).
  - Given four local players with controllers on a rolling deck, When all walk to the bow, Then none slides off and the camera keeps all four in view.
- [ ] `[innovation]` **Station-bound information**
  As the navigator, I want hidden rocks to show only on the map table, so that the captain needs my callouts (serves: Social interaction).
  - Given a submerged rock ahead, When the captain looks forward, Then it is not visible.
  - Given a submerged rock ahead, When a player stands at the map table, Then its position is shown.
- [ ] `[innovation]` **Hull breach changes handling**
  As the crew, I want a leak to make the ship heavier and slower, so that damage changes what we must do (serves: Thrill of danger).
  - Given an open breach, When 20 s pass, Then the water level rises and top speed drops.
  - Given a patched and pumped breach, When the water is gone, Then top speed recovers.
- [ ] `[innovation]` **Engine heat caps speed**
  As the engineer, I want to trade speed for heat, so that the crew argues about going fast (serves: Social interaction, Thrill of danger).
  - Given full throttle, When heat passes 80%, Then top speed is capped.
  - Given heat at 100%, When the 5 s warning ends, Then the engine stalls for 20 s.
- [ ] `[standard]` **Carry and drop**
  As any player, I want to carry one item and drop it when knocked down, so that accidents happen (serves: Comedy).
  - Given a player carrying a plank, When a wave knocks them down, Then the plank drops and slides toward the low side of the deck.

## Next (likely, not committed)
- [ ] Rudder damage and the throttle-steering workaround
- [ ] Load and balance (cargo shifting, deck tilt)
- [ ] Two-player tasks (big patch, cooling pipe)
- [ ] Results screen with event recap
- [ ] One 5-minute route with rocks, waves and a port

## Later (deliberately vague)
- Contracts and the upgrade shop
- Fog and the telescope
- Online play
- Art, sound, juice

## Parked (good ideas that are out of scope until the core loop is proven)
- Fire, crew overboard, floating cargo recovery
- 2-player mode, split screen, mixed couch-plus-online groups
- Secret objectives, ship combat, many classes, crafting, campaign, permadeath, cosmetics

## Done
- Phase 1: Committee Summary approved (2026-10-22)
