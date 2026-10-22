extends Node3D
## Floating loot from a sunk pirate ship: sail through it to scoop it up (points for the score, which
## become coins at port). What else to do with loot is an open question (BACKLOG).

signal collected(value: int)

const Toon = preload("res://scripts/systems/toon.gd")

@export var value := 60
@export var pickup_radius := 9.0

var _time := 0.0


func _ready() -> void:
	add_to_group("loot")
	var model: Node3D = (load("res://assets/art/export/models/loot.glb") as PackedScene).instantiate()
	Toon.paint(model)
	model.name = "Model"
	add_child(model)
	_time = randf() * TAU


func _physics_process(delta: float) -> void:
	_time += delta
	position.y = sin(_time * 1.8) * 0.18
	rotation.y += delta * 0.4
	var ship := get_tree().get_first_node_in_group("player_ship") as Node3D
	if ship == null:
		return
	var offset := ship.global_position - global_position
	offset.y = 0.0
	if offset.length() < pickup_radius:
		collect()


func collect() -> void:
	var voyage := get_tree().get_first_node_in_group("voyage")
	if voyage and "bonus_points" in voyage:
		voyage.bonus_points += value
	collected.emit(value)
	UI.play("coin")
	set_physics_process(false)
	var tween := create_tween()
	tween.tween_property(self, "position:y", 4.0, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "scale", Vector3.ZERO, 0.4)
	tween.tween_callback(queue_free)
