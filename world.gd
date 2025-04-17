extends Node3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if GameManager.role == "passenger":
		print("player is passenger")
	if GameManager.role == "airport_worker":
		print("player is airport worker")
	if GameManager.role == "airline_worker":
		print("player is airline worker")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
