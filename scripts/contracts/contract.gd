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
## Big waves: each entry is [x, side] (side +1 starboard, -1 port).
@export var waves: Array = []
@export var fog := false
@export var pay_per_crate := 100
@export var tutorial := false ## the Maiden voyage: can't be lost, teaches by doing
