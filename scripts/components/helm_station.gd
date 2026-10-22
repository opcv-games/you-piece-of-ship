extends "res://scripts/components/station.gd"
## The helm: Use to steer (stick left/right = wheel, up/down = throttle). Bringing the rudder pin
## here fixes a broken rudder.


func _rudder() -> Node:
	return get_parent().get_node_or_null("RudderSystem")


func accepts_item(item: Node3D, _player: Node3D) -> bool:
	var rudder := _rudder()
	return item.kind == "pin" and rudder != null and rudder.is_damaged()


func receive_item(item: Node3D, _player: Node3D) -> void:
	item.consume()
	_rudder().repair()
