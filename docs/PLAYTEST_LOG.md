# Playtest Log

One entry per hypothesis. Newest first.

## 2026-10-22 — Hazard director  (#8)
Hypothesis: If a big wave never lands while two systems are already failing or right after a recovery, then players will blame their own choices rather than the game, increasing Thrill of danger (fair near-saves).
Variable: calm window 20 s; max failing systems 1
Sessions: 0 — built overnight, not yet player-tested
Observed: pending
Biggest weakness: pending
Decision: merged to main; survey question 'did you understand why things went wrong?' checks it

## 2026-10-22 — The Reef Run route  (#9)
Hypothesis: If one voyage paces calm, complication, calm, overlap and a peak in the last third, then the crew will feel a rising arc and cheer at port, increasing Thrill of danger.
Variable: route length 1300 m, deadline 5:30
Sessions: 0 — built overnight, not yet player-tested
Observed: pending
Biggest weakness: pending
Decision: merged to main; tune deadline and rock density after the first couch playtest

## 2026-10-22 — Load and balance  (#7)
Hypothesis: If loose cargo tilts the deck and can be thrown overboard to save the ship, then the crew will argue about sacrificing cargo, increasing Social interaction and Comedy.
Variable: heel per crate-metre 1.2 degrees
Sessions: 0 — built overnight, not yet player-tested
Observed: pending
Biggest weakness: pending
Decision: merged to main; tune after the first couch playtest

## 2026-10-22 — Rudder damage  (#6)
Hypothesis: If a hard hit makes the wheel pull to one side until someone hauls the heavy pin to the helm, then the captain will call for help and the slow pin-carrier will be the centre of attention, increasing Comedy and Thrill of danger.
Variable: pull strength 0.35 of full wheel
Sessions: 0 — built overnight, not yet player-tested
Observed: pending
Biggest weakness: pending
Decision: merged to main; tune after the first couch playtest

## 2026-10-22 — Engine heat caps speed  (#4)
Hypothesis: If full throttle overheats the engine and only the engineer can see the gauge, then the engineer will shout "slow down!" while the navigator wants speed, increasing Social interaction.
Variable: heat rise (full throttle reaches 80% in about 18 s, 100% in about 22 s)
Sessions: 0 — built overnight, not yet player-tested
Observed: pending
Biggest weakness: pending
Decision: merged to main; tune after the first couch playtest

## 2026-10-22 — Hull breach changes handling  (#3)
Hypothesis: If a rock hit cracks the hull and water visibly slows and tilts the ship, then the crew will split up (someone pumps, two patch, the captain slows down) and argue about priorities, increasing Social interaction and Thrill of danger.
Variable: flow rate (1 open leak fills the ship in 70 s)
Sessions: 0 — built overnight, not yet player-tested
Observed: pending
Biggest weakness: pending
Decision: merged to main; tune after the first couch playtest

## 2026-10-22 — Carry and drop  (#5)
Hypothesis: If carried items drop when a wave knocks you over and then slide to the low side, then crew will chase runaway planks and yell "grab a station!" before waves, increasing Comedy.
Variable: knockdown on big waves (on/off); wave roll 14 degrees
Sessions: 0 — built overnight, not yet player-tested
Observed: pending
Biggest weakness: pending
Decision: merged to main so later systems can build on it; keep or change after the first couch playtest

## 2026-10-22 — Background music (requested by Olivier)
Hypothesis: If a lively shanty loops in the background, ducks on crashes and speeds up near port, then the crew will feel the mood (frantic, goofy) and the run's tension, increasing Comedy and Thrill of danger. Risk: music makes any build feel better, so it can hide whether the mechanics are fun; mute (M) during fun-gate tests.
Variable: music on/off (M key or Music node "music_enabled")
Sessions: 1 (self: 1, others: 0)
Observed: Olivier: "everything is excellent."
Biggest weakness: none reported.
Decision: KEPT.

## 2026-10-22 — Juice pass on existing moments (requested by Olivier)
Hypotheses (one per effect; each has its own switch on the GameFeel node, so each is kept or removed on its own):
- Crash (shake + 80 ms freeze + debris/spray + "CRASH!" pop): if a crash is felt, then the crew will groan and blame each other, increasing Comedy.
- Wake foam at bow and stern: if speed shows on the water, then the captain will feel the speed without reading the HUD, increasing Thrill of danger.
- Squash and stretch on jump/land: if jumps have weight, then players will hop around more, increasing Comedy.
- Port confetti: if arriving is celebrated, then the crew will cheer, increasing Thrill of danger (the release).
Variable: each effect on/off
Sessions: 1 (self: 1, others: 0)
Observed: Olivier: "everything is excellent." No readability problems reported.
Biggest weakness: none reported.
Decision: KEPT, all four effects.

## 2026-10-22 — Station-bound information  (#2)
Hypothesis: If submerged rocks are shown only on a map table at the bow while the wheel is at the stern, then the navigator will shout directions and the captain will steer by their calls, increasing Social interaction.
Variable: chart visible only while someone stands at the map table (on/off)
Sessions: 1 (self: 1, others: 0)
Observed: The navigator could warn the captain in time; steering by the ship's own left/right was "fine"; difficulty (12 rocks, ~1 min run) "fine".
Biggest weakness: none reported for the mechanic; Olivier asked for a higher resolution and more game feel (juice), handled as the next step.
Decision: KEPT. Not yet tested with a second person, which is the real test of the callout loop.

## 2026-10-22 — Walk on a rocking ship, together  (#1)
Hypothesis: If four players share one deck that rolls ±8° on a slow swell, then they will stumble into each other and laugh while still feeling in control of where they go, increasing Comedy and Social interaction.
Variable: wave roll amplitude (starting value 8°)
Sessions: 1 (self: 1, others: 0)
Observed: Rocking strength "ok"; each player always knows which capsule is theirs and where it faces; bumping into each other and the mast is "fine" (neutral, not yet funny).
Biggest weakness: there is nothing to do on deck yet. Expected at this step: posts and tasks arrive with #2 (map table), #3 (hull breach), #4 (engine heat), #5 (carry and drop).
Decision: KEPT, roll stays at 8°. The deck works as a foundation; nothing to tune until there is a job to do on it.

<!--
## YYYY-MM-DD — <hypothesis name>  (#issue)
Hypothesis: If ..., then ..., increasing <form of fun>.
Variable: <name> <old> → <new>
Sessions: <n> (self: x, others: y)
Observed:
Biggest weakness:
Decision: KEPT / REVERTED — why
-->
