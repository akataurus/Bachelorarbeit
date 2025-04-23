# Dieses Script wird an alle Objekte gehängt, wo man einen Koffer ablegen 
# kann. z.B. Schalter oder Hgscanner
extends Node3D

@onready var drop_position := $baggage_pos
@onready var area := $luggage_stop
@onready var feedback := $"../feedback"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	drop_position = get_node_or_null("baggage_pos")
	if drop_position == null:
		print("drop_position ist null!")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func get_drop_position():
	return drop_position.global_transform.origin + Vector3(0, 0, 0)

func update_feedback():
	var is_scan_successful := randf() < 0.5 # Wahrscheinlichkeit für grünen scan
	var material = feedback.get_active_material(0)
	
	if is_scan_successful:
		material.albedo_color = Color(0, 1, 0) # Grün
	else:
		material.albedo_color = Color(1, 0, 0) # Rot
