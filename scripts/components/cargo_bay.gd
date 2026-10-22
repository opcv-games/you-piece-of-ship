extends Node3D
## The cargo bay: crates start lashed on its spots (Marker3D children). Putting a crate down
## near a free spot lashes it again. Crates are the delivery score, and their positions set
## the ship's balance (load and balance system).

const ItemScene = preload("res://scenes/greybox/item.tscn")

@export var crate_value := 100
@export var radius := 1.1 ## how close to a free spot you must be to lash a crate there

var _spots: Dictionary = {} ## Marker3D -> crate or null


func _ready() -> void:
	add_to_group("cargo_bay")
	add_to_group("interactables")
	var items_root: Node3D = get_parent().get_node("Items")
	for spot in get_children():
		if spot is Marker3D:
			var crate: Node3D = ItemScene.instantiate()
			crate.kind = "crate"
			crate.value = crate_value
			items_root.add_child(crate)
			_spots[spot] = null
			lash(crate, spot)


func lash(crate: Node3D, spot: Marker3D) -> void:
	_spots[spot] = crate
	crate.lashed = true
	crate.velocity = Vector2.ZERO
	crate.position = crate.get_parent().to_local(spot.global_position)
	crate.position.y = 0.0
	crate.rotation = Vector3.ZERO


func unlash(crate: Node3D) -> void:
	for spot in _spots:
		if _spots[spot] == crate:
			_spots[spot] = null
	crate.lashed = false


func lashed_count() -> int:
	var count := 0
	for spot in _spots:
		if _spots[spot] != null and is_instance_valid(_spots[spot]):
			count += 1
	return count


func _free_spot_near(player: Node3D) -> Marker3D:
	var best: Marker3D = null
	var best_distance := radius
	for spot in _spots:
		if _spots[spot] != null and is_instance_valid(_spots[spot]):
			continue
		var offset: Vector3 = player.global_position - spot.global_position
		offset.y = 0.0
		if offset.length() <= best_distance:
			best = spot
			best_distance = offset.length()
	return best


func distance_to_player(player: Node3D) -> float:
	var spot := _free_spot_near(player)
	if spot == null:
		return INF
	var offset: Vector3 = player.global_position - spot.global_position
	offset.y = 0.0
	return offset.length()


func can_interact(player: Node3D) -> bool:
	return player.carried != null and player.carried.kind == "crate" and _free_spot_near(player) != null


func interact(player: Node3D) -> void:
	var spot := _free_spot_near(player)
	var crate: Node3D = player.carried
	crate.drop()
	lash(crate, spot)
