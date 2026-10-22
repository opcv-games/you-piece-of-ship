extends "res://scripts/components/station.gd"
## A fishing spot at the rail (Olivier, 2026-10-22: "if players are idle they can fish; fishing
## adds points"). Use takes the rod and casts; wait for the float to dip ("!"), then press Jump
## quickly to strike. Too early or too late and it gets away. Each catch adds to the voyage score.

signal caught(catch: Dictionary, player: Node3D)
signal got_away(player: Node3D)

const Toon = preload("res://scripts/systems/toon.gd")
const MODELS := "res://assets/art/export/models/"
## [name, model, points, chance weight]
const CATCHES := [
	["Sardine", "fish_sardine", 20, 55.0],
	["Goldfish", "fish_goldfish", 50, 20.0],
	["Squid", "fish_squid", 40, 12.0],
	["Pufferfish", "fish_pufferfish", 35, 10.0],
	["Treasure!", "chest", 150, 3.0],
]

enum Phase { IDLE, WAITING, BITE }

@export var bite_min := 3.0 ## seconds before a fish bites, at least
@export var bite_max := 8.0
@export var bite_window := 0.9 ## seconds to strike once the float dips
@export var cast_distance := 3.2 ## metres out from the rail

var phase := Phase.IDLE
var wait_left := 0.0
var bite_left := 0.0
var catches := 0

var _rng := RandomNumberGenerator.new()
var _rod: Node3D
var _bobber: Node3D
var _line: MeshInstance3D
var _time := 0.0


func _ready() -> void:
	super._ready()
	add_to_group("fishing_spots")
	station_name = "FISHING"
	prompt = "Use: fish"
	radius = 1.1
	_rng.randomize()
	_build()


func _build() -> void:
	var side := signf(position.z) if position.z != 0.0 else 1.0
	var label := Label3D.new()
	label.name = "Label"
	label.position = Vector3(0, 2.3, side * 0.3)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.font_size = 56
	label.outline_size = 12
	add_child(label)
	_rod = Node3D.new()
	_rod.name = "Rod"
	add_child(_rod)
	var pole := MeshInstance3D.new()
	var stick := CylinderMesh.new()
	stick.top_radius = 0.025
	stick.bottom_radius = 0.045
	stick.height = 2.4
	pole.mesh = stick
	pole.material_override = Toon.material("wood_light")
	pole.position = Vector3(0, 1.6, side * 0.75)
	pole.rotation.x = side * deg_to_rad(55)
	_rod.add_child(pole)
	_bobber = Node3D.new()
	_bobber.name = "Bobber"
	var ball := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.16
	sphere.height = 0.32
	ball.mesh = sphere
	ball.material_override = Toon.material("paint_red")
	_bobber.add_child(ball)
	var cap := MeshInstance3D.new()
	var top := SphereMesh.new()
	top.radius = 0.1
	top.height = 0.12
	cap.mesh = top
	cap.material_override = Toon.material("trim_cream")
	cap.position.y = 0.12
	_bobber.add_child(cap)
	_bobber.position = Vector3(0, -1.0, side * cast_distance)
	add_child(_bobber)
	_line = MeshInstance3D.new()
	_line.name = "Line"
	var thread := CylinderMesh.new()
	thread.top_radius = 0.008
	thread.bottom_radius = 0.008
	thread.height = 1.0
	_line.mesh = thread
	_line.material_override = Toon.material("trim_cream")
	add_child(_line)
	_show_tackle(false)


func _show_tackle(on: bool) -> void:
	_bobber.visible = on
	_line.visible = on


## The rod tip, in this spot's own space.
func _tip() -> Vector3:
	var side := signf(position.z) if position.z != 0.0 else 1.0
	return Vector3(0, 1.6 + cos(deg_to_rad(55)) * 1.2, side * (0.75 + sin(deg_to_rad(55)) * 1.2))


func occupy(player: Node3D) -> bool:
	if not super.occupy(player):
		return false
	_cast()
	return true


func release(player: Node3D) -> void:
	super.release(player)
	if occupants.is_empty():
		phase = Phase.IDLE
		_show_tackle(false)


func _cast() -> void:
	phase = Phase.WAITING
	wait_left = _rng.randf_range(bite_min, bite_max)
	_show_tackle(true)


## Jump while fishing: strike. Right after a bite it's a catch; any other time the fish is scared.
func secondary_action(player: Node3D) -> void:
	strike(player)


func strike(player: Node3D) -> void:
	if phase == Phase.BITE:
		var catch := roll_catch()
		catches += 1
		var voyage := get_tree().get_first_node_in_group("voyage")
		if voyage and "bonus_points" in voyage:
			voyage.bonus_points += int(catch.points)
		player.think(tr("%s +%d") % [tr(catch.name), catch.points], 2.0, "shout")
		_show_catch(catch)
		caught.emit(catch, player)
	elif phase == Phase.WAITING:
		player.think(tr("Too early!"), 1.2)
		got_away.emit(player)
	_cast()


## Picks what bites, by weight.
func roll_catch() -> Dictionary:
	var total := 0.0
	for entry in CATCHES:
		total += entry[3]
	var pick := _rng.randf() * total
	for entry in CATCHES:
		pick -= entry[3]
		if pick <= 0.0:
			return {"name": entry[0], "model": entry[1], "points": entry[2]}
	return {"name": CATCHES[0][0], "model": CATCHES[0][1], "points": CATCHES[0][2]}


## The catch flies out of the water in an arc onto the deck and pops away.
func _show_catch(catch: Dictionary) -> void:
	var path := MODELS + String(catch.model) + ".glb"
	if not ResourceLoader.exists(path):
		return
	var fish: Node3D = (load(path) as PackedScene).instantiate()
	Toon.paint(fish)
	fish.position = _bobber.position
	fish.scale = Vector3.ONE * (1.6 if catch.model != "chest" else 0.9)
	add_child(fish)
	var tween := fish.create_tween()
	tween.tween_property(fish, "position", Vector3(0, 3.2, 0), 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(fish, "rotation:z", TAU, 0.45)
	tween.tween_interval(0.5)
	tween.tween_property(fish, "scale", Vector3.ZERO, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_callback(fish.queue_free)


func _physics_process(delta: float) -> void:
	_time += delta
	match phase:
		Phase.WAITING:
			wait_left -= delta
			if wait_left <= 0.0:
				phase = Phase.BITE
				bite_left = bite_window
				if occupant:
					occupant.think("!", bite_window, "shout")
		Phase.BITE:
			bite_left -= delta
			if bite_left <= 0.0:
				if occupant:
					occupant.think(tr("It got away..."), 1.2)
					got_away.emit(occupant)
				_cast()
	if _bobber.visible:
		var side := signf(position.z) if position.z != 0.0 else 1.0
		var dip := -0.35 if phase == Phase.BITE and fmod(_time, 0.3) < 0.15 else 0.0
		# The float sits on the sea surface (the ship's deck is 1.2 m above it).
		var sea_y := to_local(Vector3(0, 0.05, 0) + global_position * Vector3(1, 0, 1)).y
		_bobber.position = Vector3(0.0, sea_y + sin(_time * 2.0) * 0.06 + dip, side * cast_distance)
		var tip := _tip()
		var span := _bobber.position - tip
		_line.position = tip + span * 0.5
		(_line.mesh as CylinderMesh).height = span.length()
		_line.basis = Basis(Quaternion(Vector3.UP, span.normalized()))
