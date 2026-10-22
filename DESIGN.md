# You Piece of Ship — Design Document

> **Current phase:** 3 — Ugly Prototype
> **Last updated:** 2026-10-22
> This file is the Committee's memory. Read it before every Godot or Blender action. Update it after every approved decision.

## 1. Pitch
**You Piece of Ship is a 4-player co-op party game where you steer, read charts, stoke the engine and patch the hull of one rickety cargo ship to reach port, but every breakdown changes how the ship handles, so one bad call snowballs into a disaster you can almost save.**

Short form: *Four terrible sailors. One ship. Every mistake makes it worse.*

<details><summary>Pitch iterations</summary>

| Round | Pitch | What changed |
|---|---|---|
| 1 | A co-op party game where you crew a ship to deliver cargo, but the ship keeps falling apart. | v0.1 high concept. "Falling apart" is a theme, not a mechanic. |
| 2 | A co-op party game where four friends each run one post on a cargo ship to beat a deadline, but every mistake physically breaks the ship. | Names the micro verb and macro goal. |
| 3 | (current pitch) | The hook becomes a mechanic: damage changes handling, which creates the cascade and the near-save. |

</details>

## 2. MDA
### Aesthetics (target forms of fun, ranked — confirmed by Olivier)
1. **Comedy** — a player sprints across the deck with the only replacement pipe, a wave tilts the ship, the pipe slides overboard, and all four players scream at once.
2. **Social interaction** — the navigator shouts "reef, 3 o'clock, hard left NOW" and the captain, who cannot see it, trusts them and swings the wheel.
3. **Thrill of danger** — the ship limps into port at 4% hull with water at the cabin door, and the crew cheers like they won a final.

Advancement (upgrades) supports these but is not a pillar: if an upgrade makes the game less funny, it is cut.

### MDA chain
| Aesthetic (feel) | ← Dynamic (emergent behavior) | ← Mechanic (rule) |
|---|---|---|
| Comedy | Slapstick accidents: dropped parts, collisions, players knocked over | Carried items drop on knockdown; deck tilts with waves and load; loose objects slide downhill; players collide |
| Comedy | Bad decisions with visible, ridiculous consequences | Damage is shown on the ship itself (water level, smoke, missing plank), never only as a number |
| Social interaction | Constant callouts, requests and arguments | Information is bound to stations; only the player at a station can read it |
| Social interaction | The crew negotiates which problem to solve first | Systems compete: speed raises heat, repairs need low speed, the route needs speed |
| Social interaction | Pairs form for big jobs | A few tasks (large patch, cooling pipe) need two players for 3–5 s |
| Thrill of danger | Cascades: one mistake spawns two more problems | Coupled systems (hull ↔ load ↔ handling ↔ engine) |
| Thrill of danger | Near-saves | Warnings before every failure; emergency measures that buy time at a cost; nothing fails twice from one cause |

## 3. Core Loops
- **Micro (every 1–5 s): read, shout, act.** Read your station, call out what matters, act on a call (turn the wheel, open a valve, slap a patch, run to a problem). Must be fun in a grey box with four players and no art.
- **Mid (every 30–90 s): routine → complication → crisis → recover.** A hazard director guarantees at least 20 s of routine after every recovery.
- **Macro (one voyage, 5–8 min): contract → sail → deliver → upgrade.** Paid on cargo, time and hull; spend on one upgrade; take a harder contract.
- **How macro feeds back into micro:** every upgrade changes a post's job rather than removing it (overclocked engine = more for the engineer to watch; reinforced hull = captain plans turns earlier). Contract modifiers (fog, night, fragile cargo) change which station is busiest.

## 4. Genre, Mood & Audience
- **Genre / comparables:** chaotic co-op party game, 3D, third person, 2–4 players (designed for 4), playable on one couch (one shared screen, a controller each) and online. Comparables: Overcooked, Lovers in a Dangerous Spacetime, Sea of Thieves, Keep Talking and Nobody Explodes.
- **Mood (3 adjectives):** frantic, goofy, triumphant.
- **For:** groups of friends who already play Overcooked or Moving Out together, on the same couch or on voice chat, in 30–90 minute sessions; mixed skill levels.
- **Not for:** solo players, competitive players who want PvP, players who want a deep sailing simulation, players who want long-term character progression.

## 5. Uniqueness
The damage itself is the level design: a broken ship handles differently, so each mistake rewrites everyone's job for the next two minutes. Mechanic: coupled ship systems where damage changes handling (section 13).

| Comparable | What we do differently |
|---|---|
| Overcooked | Problems are caused by the crew's own earlier choices and chain into each other |
| Lovers in a Dangerous Spacetime | Damage changes handling and creates new physical work; information is split across stations |
| Sea of Thieves | Short authored voyages with a deadline and party-game readability, not a sandbox |
| Keep Talking and Nobody Explodes | The information split is spatial and swappable, and everyone also has hands-on work |

## 6. Feature Split (60 / 40)
| Feature | Type | Serves | Notes |
|---|---|---|---|
| Station-bound information (map, gauges, telescope) | Innovation | Social | Prototype first |
| Coupled ship systems (hull, heat, rudder, load) | Innovation | Danger, Comedy | Signature mechanic |
| Damage changes handling | Innovation | Danger | Part of coupled systems |
| Conflicting urgency (speed vs heat vs repair vs route) | Innovation | Social | Emerges from systems; tune, don't script |
| Two-player tasks (big patch, cooling pipe) | Innovation | Social, Comedy | Max 2 in the slice |
| Voyage recap (chain of events) | Innovation | Comedy | Event log shown as a timeline on results |
| Walk, run, jump, carry, interact | Standard | All | Overcooked-style controls |
| Exaggerated deck physics (tilt, slide, knockdown) | Standard | Comedy | Simple and predictable, not a sim |
| Helm, throttle, wind | Standard | Danger | Arcade handling |
| Deadline timer and route with port | Standard | Danger | |
| Results screen with score | Standard | Advancement | Cargo + time + hull |
| Quick restart | Standard | All | Under 10 s |
| Upgrade shop with trade-offs | Standard | Advancement | 4 upgrades in the slice |
| Couch play on one shared screen | Standard | Social | Milestone A |
| Online lobby, drop-in and reassign | Standard | Social | Milestone B, host-authoritative |
| Contract modifiers | Standard | Danger | Fog only in the slice |
| Fire | Next | Danger | Fourth system once the first three are fun |
| Crew overboard and rescue | Next | Comedy | Costly to network |
| Floating cargo recovery, extra upgrades | Later | Advancement | |
| Secret objectives, ship combat, many classes, crafting, campaign, permadeath | Parked | — | |

## 7. Pacing
- **One voyage (5–8 min):** calm departure (45 s) → first complication (one system) → recovery + calm (≥ 20 s) → rising section, two systems overlap → peak crisis in the last third → port in sight, release. Hazards are hand-placed; the director only enforces fairness rules and calm windows.
- **The slice (~30 min):** four contracts of rising intensity; the shop between them is the rest stop. Contract 4 adds fog.

## 8. Onboarding
Contract 1, "Maiden voyage", teaches by doing and cannot be lost:
1. **0:00 Dock.** Stations glow; walking to one shows a one-line prompt ("Hold to steer"). No tutorial screens.
2. **0:45 Open water.** A buoy lane teaches steering and callouts: buoys appear on the map table before the captain can see them.
3. **1:30 First leak.** A scripted wave cracks one plank; teaches patching and pumping. Cannot sink the ship.
4. **2:30 Heat.** A headwind forces full throttle; the whistle teaches venting.
5. **3:30 Small cascade.** A gentle rock hit cracks the hull and nudges the rudder at once: feel the coupling safely.
6. **4:30 Port.** Results and recap. Failure means a later dock and lower score.

## 9. Vertical Slice Boundary
**Milestone A — Ugly Prototype (Phase 3 fun gate):** one grey ship, four stations, one 5-minute route with rocks and waves, hull + heat + rudder coupled, carry and knockdown, local couch play on one shared screen (no networking yet), results screen, restart. Passes when a group of four (not only Olivier) asks for another run unprompted and can explain why they sank.

**Milestone B — Vertical Slice. Target length:** ~30 minutes.
- **IN:** one ship; four stations; four hand-made contracts (last in fog); four systems (hull, heat, rudder, load); two two-player tasks; the three deck comedy rules; upgrade shop with 4 trade-off upgrades (overclocked engine, reinforced hull, bigger pumps, second spare-parts crate); results with event recap; couch play on one shared screen; online lobby for 3–4 players with drop-in reassignment; final art, sound and juice for all of the above.
- **OUT (explicitly not building):** fire, crew overboard, floating cargo, second ship, procedural routes, campaign map, more than 4 upgrades, 2-player mode, split screen, mixed couch-plus-online groups, cosmetics, secret objectives, combat, crafting, persistent progression.

**Playtest survey (every Milestone A session):** Did you have something useful to do most of the time? Did you understand why things went wrong? Did your actions help the team? Did the crew recover from something that seemed hopeless? Did you immediately want another attempt? Who did you talk to most, and about what?

## 10. Risks
| Risk | Why it matters | How we test it early |
|---|---|---|
| Networked physics on a moving ship feels laggy or desyncs | Comedy dies if a knockdown looks different on each screen | Milestone A is couch-only. First Milestone B task: two Godot instances on LAN, host-authoritative, players in ship-local space, scripted buoyancy instead of a rigid-body sim |
| One player bosses the others | Social interaction becomes one person playing through three | Survey "who did you talk to most"; if lopsided, move a key reading off the captain's path |
| Deckhand overloaded, captain bored | Breaks the "nobody idles" rule | Log idle time per post; target under 15% |
| Cascades feel unfair, not funny | Players blame the game | Survey "did you understand why things went wrong"; lengthen that failure's warning |
| Upgrades remove the chaos | Advancement fights Comedy | Every upgrade adds a decision; playtest contract 4 fully upgraded |
| Shared couch screen softens the information split | Everyone can glance at the map | Navigator's edge = hands and attention on the chart; watch whether players still call out |
| Not enough testers for 4-player sessions | Fun gate needs four people | Book a weekly group of four early |

## 11. Decision Log
| Date | Decision | Why | Evidence (playtest / issue) |
|---|---|---|---|
| 2026-10-22 | Committee Summary approved; project scaffolded | Phase 1 complete | Olivier: "yes" |
| 2026-10-22 | Godot 4 engine | Free; matches the Committee tooling | Olivier confirmed |
| 2026-10-22 | Two milestones: 5-min prototype, 30-min slice | Prove the loop before progression | Olivier confirmed |
| 2026-10-22 | Couch first, online second | Couch needs no networking; riskiest tech waits until fun is proven | Olivier: online and couch |
| 2026-10-22 | Non-developer mode | Olivier has not coded before | Olivier: technical comfort (a) |
| 2026-10-22 | Roles become station-bound posts | Fixes role swapping, disconnects and couch play; gives the Crisis beat a cost | Design review of v0.1 |
| 2026-10-22 | Four coupled systems; fire and overboard to Next | Fewer, deeper systems make cascades readable | Design review of v0.1 |
| 2026-10-22 | Fog hides hazards from the helm | Gives the navigator unique, necessary information | Design review of v0.1 |
| 2026-10-22 | Ship is one moving body rocked by scripted waves (roll 8°, pitch 3°, heave 0.3 m); crew are children of the ship | Players stay on board without a physics sim; the motion is predictable and ship-local, ready for networking (Risk 1) | #1, tests/integration/test_rocking_deck.gd |
| 2026-10-22 | One shared camera, level with the horizon, always framing the whole ship and all crew | Couch play on one screen; nobody hunts for themselves; the deck visibly rocks against a steady view | #1 |
| 2026-10-22 | Stations are spots on the deck: the helm (stern) needs Use and takes over the stick; the map table (bow) works by standing at it | Information and controls belong to the station, not the player (section 12); captain and navigator are 10 m apart so they must shout | #2 |
| 2026-10-22 | Map table chart is heading-up, 70 m range, shown in a screen corner only while someone stands at the table; the camera leaves that corner free | "Rock at 2 o'clock" means the same to captain and navigator; the shared couch screen is a known risk (section 10) | #2 |
| 2026-10-22 | Rock hits stop the ship, bounce it back and reveal the rock; no hull damage yet | Damage arrives with #3; this keeps #2 about callouts only | #2 |
| 2026-10-22 | Small juice pass (crash, wake, squash, confetti) on the GameFeel node, each effect switchable | Requested by Olivier before Phase 4; kept small and reversible so each effect can be kept or cut | Olivier request |
| 2026-10-22 | Placeholder music: synthesised "Drunken Sailor" loop (public-domain tune) on a Music bus; M / Select mutes; ducks on crash, speeds up near port | Requested twice by Olivier; mute it for fun-gate playtests so music doesn't mask the mechanics | Olivier request |
| 2026-10-22 | Ship enlarged to 18 x 7 m with a fixed layout: helm (stern), map table (bow, port), spare-parts boxes (port, amidships), cargo bay of 6 lashed crates (forward of the mast) | Room for four stations, repairs and running around; side lanes stay clear so crew can cross the ship | #5 |
| 2026-10-22 | Use is one context button: leave a station, apply or drop the carried item, pick up, take over a station (nearest in reach wins) | One button keeps couch controls learnable for mixed-skill groups (section 4) | #5 |
| 2026-10-22 | Big waves warn for 5 s (sign + side), then roll the ship 14 degrees; anyone not holding a station is knocked down and drops what they carry; loose items slide downhill; fast crates bowl people over | Deck comedy rules and fairness rule (warning of at least 5 s), section 13 | #5 |
| 2026-10-22 | Six fixed leak spots along the rails; a rock cracks the nearest free one (5 s cracking warning, then water); the same rock can't crack more hull for 8 s | Readable, predictable damage on the ship itself; fairness: warnings and one failure per impact | #3 |
| 2026-10-22 | Fixes: crate plug (flow to 30%, cargo lost) or plank patch (place plank, hammer: 4 s with 2 crew, 12 s alone); pump at the stern removes water | Emergency measure at a cost vs proper fix (section 13); one-person patching stays possible for small crews | #3 |
| 2026-10-22 | Water effects: top speed up to -45%, turning -30%, sits 0.7 m lower, lists up to 6 degrees toward the leaks; full = sunk, never within 60 s of the first failure | Damage changes handling (the signature mechanic); fairness rule | #3 |
| 2026-10-22 | Engine room (stern starboard): hold up to shovel coal, Jump to vent steam; heat and coal gauge only shows to the engineer, in the top-right HUD corner | Station-bound information; the engineer has hands-on work all the time (no idling) | #4 |
| 2026-10-22 | Heat rises above 55% throttle and faster with water aboard; >80% caps top speed at 70%; 100% gives a 5 s warning then a 20 s stall that bursts the cooling pipe; venting cools 50% but knocks over crew within 3 m (8 s cooldown); burst pipe heats 1.6x faster until fixed (4 s with 2 crew, 12 s alone) | Conflicting urgency (speed vs heat) and coupling rule 3; emergency measure at a cost | #4 |
| 2026-10-22 | Impacts above half speed damage an intact rudder instead of the hull (otherwise the hull cracks): one impact, one failure | Coupling rule 1 combined with fairness rule 'one impact starts at most one new failure' | #6 |
| 2026-10-22 | Broken rudder: 5 s wheel shudder warning, then half steering response and a pull to one side even with nobody steering; fix by carrying the single spare rudder pin (half walking speed) to the helm | Rudder row of section 13; one spare makes a second rudder break a real crisis | #6 |
| 2026-10-22 | Cargo position sets heel (1.2 degrees per crate-metre off centre, max 12) and trim; top speed is for a full load, +2% per crate lost | Load and balance row of section 13; throwing cargo is an emergency measure with a reward cost | #7 |
| 2026-10-22 | Before each big wave one lashed crate's rope frays (label on the crate); if nobody takes it in hand before the wave hits, it breaks loose toward the low side | Crates rattle, ropes fray warning (section 13); the wave becomes a decision, not just a knockdown | #7 |
| 2026-10-22 | Carry a crate to any rail and press Use to throw it overboard | Emergency measure: lower reward; a crate stuffed in a leak is also lost cargo | #7 |
| 2026-10-22 | Voyages are built from hand-made contracts (rocks, waves, deadline, pay); the Reef Run is the Milestone A route: 1300 m, deadline 5:30, calm first 200 m, peak rocks in the last third | Pacing of section 7; the same data drives Milestone B's four contracts | #9 |
| 2026-10-22 | Visible cliffs line the channel 45 m either side; hitting them is a crash; the chart shows a PORT arrow with the distance when the port is beyond its range | Keeps the navigator's job about the reef, not about finding the way | #9 |
| 2026-10-22 | Main scene is now scenes/levels/voyage.tscn; a Session autoload remembers the crew and chosen contract across restarts | Quick restart (< 10 s) and contract choice later | #9 |
| 2026-10-22 | Hazard director: big waves start at their contract position only while at most one system (hull, engine, rudder, load) is failing and 20 s after the last recovery; a wave still waiting 200 m later is dropped | Fairness rules of section 13 and calm windows of section 7; hand-placed hazards, director only enforces fairness | #8 |
| 2026-10-22 | Results: DELIVERED/SUNK, time vs deadline, cargo, hull, score = cargo value + up to 200 for a dry hull + 2 per second early (sunk = 0), and a 'what happened' timeline from the voyage log | Survey: 'did you understand why things went wrong?'; the recap is the comedy replay (section 6) | #10 |
| 2026-10-22 | Crew screen on first launch: press Jump to join, Use to set sail; R restarts with the same crew in seconds; J changes crew; 3 or fewer players get a slow automatic pump (30% of the pump) | Quick restart under 10 s; 3-player rule of section 12 | #10 |
| 2026-10-22 | Rocks deflect the ship (back off, sidestep, bow turns 10 degrees away); scraping along the coast or re-bumping a rock within 8 s is one accident | A simulated full voyage showed straight-ahead crashes trapping the ship against a rock until it sank | #10 |
| 2026-10-22 | Reef Run deadline stays 5:30: a simulated crew at 80% throttle venting at 90% heat arrives in about 4:53; full throttle stalls repeatedly | Simulation calibration; real crews will be slower, check in the first playtest | #10 |

## 12. Posts (roles)
Information and controls belong to the station, not the player. Anyone can use any station.

| Post | Station and what only it shows | Routine job | Calm-time task | Signature failure |
|---|---|---|---|---|
| Captain | Helm on the raised stern: throttle, wheel, wind vane. Sees the surface near the ship, not submerged rocks or anything in fog | Hold course, set speed, call "brace" | Trim the sail for a small speed bonus | Overcorrects, turns broadside to a wave |
| Navigator | Map table below deck: hidden reefs, route, deadline. Telescope on the bow spots hazards in fog but leaves the map unread | Call headings and distances; pick shortcut or safe route | Re-plot a quicker route; recover a blown chart page | Right call, two seconds too late |
| Engineer | Engine room: heat gauge, fuel, pressure valves, power split | Keep heat green, shovel fuel, divert power | Pre-cool before a sprint; prepare spare parts | Overheats at the worst moment |
| Deckhand | No fixed station; hull leak and fire alarms show where to go | Patch, pump, secure cargo | Pre-cut patches; lash cargo; restock toolbox | Patches one leak while another floods behind |

Rules: nobody idles while their system is fine; posts are swappable any time; no permanent classes. With three players there is no dedicated deckhand: the ship gets a slow automatic pump and the other three share repairs. Two-player play is Parked.

## 13. Ship Systems and Cascades
| System | Effect when damaged | Warning (5–10 s) | Emergency measure (at a cost) | Proper fix |
|---|---|---|---|---|
| Hull and water | Water adds weight: slower, lower, deck tilts toward the flood | Planks creak, spray from a seam | Stuff a crate in the hole (stops 70% of flow, crate cargo lost) | Plank patch (two players, 4 s), then pump |
| Engine heat | Above 80% heat top speed is capped; at 100% stall for 20 s | Gauge red, steam, whistle | Vent steam (instant cool, knocks nearby players down) | Fix cooling pipe (two players) |
| Rudder | Steering response halves, then the wheel pulls to one side | Wheel shudders after impact | Lash the wheel and steer with throttle bursts | Swap rudder pin from the spares crate (heavy, walking speed) |
| Load and balance | Shifted cargo or water tilts the deck; loose crates slide and knock players over | Crates rattle, ropes fray | Throw cargo overboard (lower reward) | Re-lash and rebalance cargo |

**Coupling rules:** (1) impacts damage the hull and, above half speed, the rudder; (2) water and shifted load make the ship heavier and tilted, which slows it and worsens steering; (3) a slow, badly steering ship needs more power, raising heat; (4) a stall leaves the ship drifting, making the next impact likely.

**Deck comedy rules:** carried items drop on knockdown; the deck tilts with waves and load and loose things slide to the low side; player bumps are exaggerated. All visible and predictable.

**Fairness rules:** every failure has a warning of at least 5 s; one impact starts at most one new failure directly; no new hazard spawns while two systems are failing; the ship cannot sink within 60 s of its first failure.
