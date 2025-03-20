extends Node3D

@onready var drop_position := $bildschirm

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	drop_position = get_node_or_null(".")
	if drop_position == null:
		print("drop_position ist null!")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func get_drop_position():
	print(drop_position)
	return drop_position.global_transform.origin + Vector3(0.5, 0.3, 0)
