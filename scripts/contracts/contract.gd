extends Resource
## One voyage: where the rocks are, when big waves come, how long you have, what it pays.
## Hand-made (DESIGN.md section 7: hazards are hand-placed; the director only enforces fairness).

@export var title := "Voyage"
@export_multiline var blurb := ""
@export var length := 1300.0 ## metres from the dock to the port buoys
@export var deadline := 330.0 ## seconds; arriving later loses the time bonus
@export var coast_half_width := 45.0 ## metres from the route centre to the cliffs
## Rock rows: each entry is [x, [z, z, ...]] or [x, [z, ...], radius].
@export var rock_rows: Array = []
## Other things at sea: each entry is [x, z, kind] or [x, z, kind, radius];
## kinds: "wreck", "whale", "siren", "atoll", "rock" (a reef rock, hidden).
@export var obstacles: Array = []
## Big waves: each entry is [x, side] (side +1 starboard, -1 port).
@export var waves: Array = []
@export var fog := false
@export var chart_range := 70.0 ## metres the map table can show (fog makes the chart unreliable)
## Scripted moments (the Maiden voyage's lessons): each entry is [x, type, text].
## Types: "hint" (show text), "leak", "rudder", "heat" (each also shows its text, if any).
@export var events: Array = []
@export var pay_per_crate := 100
@export var tutorial := false ## the Maiden voyage: can't be lost, teaches by doing
@export var difficulty := 1 ## 1..4, shown on the dock
## Scores for 1, 2 and 3 stars; leave empty to work them out from the pay (scripts/systems/stars.gd).
@export var star_scores: Array = []
