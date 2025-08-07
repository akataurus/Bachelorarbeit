extends Node3D
@onready var luggage_pos = $luggage_drop_pos

func _ready():
	pass

func get_drop_position():
	if luggage_pos:
		return luggage_pos.global_transform.origin + Vector3(0, 0, 0)
	else:
		print("luggage_pos is null, using fallback position")
		return global_transform.origin + Vector3(0, 1, 0)
