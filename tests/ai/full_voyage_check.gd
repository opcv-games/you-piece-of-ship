extends SceneTree
## Full-voyage check for the AI crew: one human who never touches the controls plus three AI
## crewmates must deliver the contract. Runs fast with a fixed frame rate:
##   godot --headless --fixed-fps 60 -s tests/ai/full_voyage_check.gd -- <contract index>
## Exits with code 0 when delivered, 1 otherwise.

const ContractLibrary = preload("res://scripts/contracts/contract_library.gd")

var level: Node3D
var frames := 0


func _initialize() -> void:
	var session := root.get_node("Session")
	session.persist = false
	session.joined_players = [1] as Array[int]
	session.ai_crew = {
		2: {"primary": "helm", "secondary": "pump"},
		3: {"primary": "navigator", "secondary": "carpenter"},
		4: {"primary": "engine", "secondary": "carpenter"},
	}
	var index := 0
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		index = int(args[0])
	level = load("res://scenes/levels/voyage.tscn").instantiate()
	level.contract = ContractLibrary.by_index(index)
	root.add_child(level)


func _physics_process(_delta: float) -> bool:
	frames += 1
	if frames == 3:
		for player in get_nodes_in_group("crew"):
			if not player.has_node("AICrew"):
				player.get_node("PlayerInput").enabled = false # the human stands still
	if frames % 1800 == 0:
		var ship := level.get_node("Ship")
		print("t=%ds x=%.0f water=%.2f heat=%.2f coal=%.2f hits=%d" % [frames / 60, ship.position.x,
				ship.get_node("HullSystem").water, ship.get_node("EngineSystem").heat,
				ship.get_node("EngineSystem").fuel, level.hits])
	if level.finished or frames > 60 * 720:
		print("RESULT %s delivered=%s time=%ds deadline=%ds hits=%d" % [level.contract.title, level.delivered,
				int(level.elapsed), int(level.contract.deadline), level.hits])
		for entry in level.get_node("VoyageLog").recap(14):
			print("  %ds %s" % [int(entry.time), entry.text])
		quit(0 if level.delivered else 1)
	return false
