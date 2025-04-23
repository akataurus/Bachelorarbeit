# Dieses Script wird an alle Objekte gehängt, wo man einen Koffer ablegen 
# kann. z.B. Schalter oder Hgscanner
extends Node3D

@onready var drop_position := $baggage_pos
@onready var feedback_light := $weight_feedback
@onready var monitor_feedback := $monitor_feedback

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

func update_feedback(is_valid: bool):
	print("update_feedback")
	var material = feedback_light.get_active_material(0)
	var material2 = monitor_feedback.get_active_material(0)
	if material == null:
		print("⚠️ Kein Material gefunden!")
		return
		
	if is_valid:
		material.albedo_color = Color(0, 1, 0) # Grün
		material2.albedo_color = Color(0, 1, 0)
	else:
		material.albedo_color = Color(1, 0, 0) # Rot
		material2.albedo_color = Color(1, 0, 0) # Rot
	
	await get_tree().create_timer(2).timeout 
	material.albedo_color = Color(1, 1, 1) # Weiß
	material2.albedo_color = Color(1, 1, 1) 
