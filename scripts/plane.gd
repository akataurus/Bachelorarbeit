extends Node3D

@onready var luggage_pos = $luggage_drop_pos

func get_drop_position():
	return luggage_pos.global_transform.origin + Vector3(0, 0, 0)
