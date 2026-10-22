extends Node
## What survives a restart (autoload "Session"): who joined the crew and which contract is being
## sailed. Restarting with R keeps the crew, so a new attempt starts in seconds.

var joined_players: Array[int] = [] ## player indexes 1..4; empty = not chosen yet
var contract_index := 0
