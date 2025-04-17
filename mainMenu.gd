extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_passenger_pressed() -> void:
	GameManager.role = "passenger"
	_start_game()


func _on_airport_worker_pressed() -> void:
	GameManager.role = "airport_worker"
	_start_game()


func _on_airline_worker_pressed() -> void:
	GameManager.role = "airline_worker"
	_start_game()

func _start_game():
	get_tree().change_scene_to_file("res://world.tscn")
