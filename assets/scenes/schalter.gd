extends Node3D

@onready var drop_position := $bildschirm

func get_drop_position():
	return drop_position.global_transform.origin + Vector3(0, 0.5, 0)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
