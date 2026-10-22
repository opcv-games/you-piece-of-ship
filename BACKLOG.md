# You Piece of Ship — Backlog

> Agile, not a roadmap. Only "Now" is committed. Re-prioritize after every development cycle.
> Tags: `[innovation]` 40% hooks · `[standard]` genre conventions · `[tech]` infrastructure
> Milestones: **Ugly Prototype** (Milestone A, DESIGN.md §9) then **Vertical Slice** (Milestone B)

## Now (committed, top = highest priority) — Milestone A

## Next (likely, not committed)

## Later (deliberately vague)
- Art, sound, juice

## Parked (good ideas that are out of scope until the core loop is proven)
- Fire, crew overboard, floating cargo recovery
- 2-player mode, split screen, mixed couch-plus-online groups
- Secret objectives, ship combat, many classes, crafting, campaign, permadeath, cosmetics

## Done
- #14 Online multiplayer, host-authoritative, lobby on the dock (2026-10-22, built and checked on one Mac over localhost; not yet tested between two computers)
- #13 Dock: contract choice, upgrade shop with four trade-off upgrades, saved progress, voyage-to-voyage loop (2026-10-22, built, not yet player-tested)
- #12 Fog and the bow telescope (2026-10-22, built, not yet player-tested)
- #11 Four hand-made contracts with the Maiden voyage tutorial (2026-10-22, built, not yet player-tested)
- #10 Results screen with event recap, quick restart, crew join, 3-player auto pump (2026-10-22, built, not yet player-tested)
- #8 Hazard director and fairness rules: wave timing with calm windows, two-failure cap, all failures warn 5 s, sinking grace (2026-10-22, built, not yet player-tested)
- #9 One 5-minute route (Reef Run): contract-built rocks, cliffs, port and dock, deadline clock, chart port arrow (2026-10-22, built, not yet player-tested)
- #7 Load and balance: cargo heel and trim, fraying ropes before waves, loose crates, cargo overboard (2026-10-22, built, not yet player-tested)
- Two-player tasks: plank patch and cooling pipe (fast with 2 crew, slow alone) — built with #3 and #4
- #6 Rudder damage and the rudder pin swap (2026-10-22, built, not yet player-tested)
- #4 Engine heat caps speed: engine room with coal and heat gauge, speed cap, warning then stall, vent knockdown, burst cooling pipe two-player fix, flooded ship heats faster (2026-10-22, built, not yet player-tested)
- #3 Hull breach changes handling: leaks with warning, crate plug, plank patch (1-2 crew), pump, water slows/sinks/lists the ship, sinking grace (2026-10-22, built, not yet player-tested)
- #5 Carry and drop: planks, rudder pins, cargo crates; knockdowns drop items; items slide to the low side; big waves (2026-10-22, built, not yet player-tested)
- Background music (placeholder sea shanty loop, M to mute): requested twice by Olivier, added early on 2026-10-22; final music still Phase 4
- #2 Station-bound information: helm, heading-up map table chart, hidden reef run to port (2026-10-22)
- #1 Walk on a rocking ship, together: grey ship on scripted waves, four couch players, shared camera (2026-10-22)
- Phase 1: Committee Summary approved (2026-10-22)

## Questions for Olivier
- Plank patch: design says two players; I let one player patch slowly (12 s instead of 4 s) so small crews and solo tests aren't stuck. Keep, or make it strictly two players?
- Lashing the wheel (design's emergency measure for the rudder) is not built: the throttle already changes the turn rate, and the pull continues with nobody at the wheel. Is that enough, or do you want an explicit 'lash the wheel' action?
- The Reef Run deadline (5:30) was calibrated with a simulated crew. After the first real playtest: too tight, too loose?
- Upgrade prices (300-500 coins) and pay (60-160 per crate) are first guesses. After a full 4-contract session, do you want to buy all four by the end, or only two?
- Simulated crews (perfect navigator, venting engineer, pumper, but nobody repairing) finished the Maiden Voyage in 4:05, the Reef Run in 4:53 and the Fog Bank in 5:42, and sank in The Narrows near the end. Is The Narrows the right kind of hard once real crews repair things?
- Online play has only been checked on one Mac (localhost). The first test between two computers on your Wi-Fi may need macOS to allow incoming connections for Godot. Do you want to try it with a friend?
- Online clients don't earn coins in their own save; the host's save holds the crew's progress. OK?
