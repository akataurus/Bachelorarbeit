extends Node

var role := "" # can be "passenger", "airport_worker" or "airline_worker"
var is_checked_in := false # true after passenger is checked in
var is_hgscan_checked := false # true after hg is checked
var is_bodyscan_checked := false # true after body is checked

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
