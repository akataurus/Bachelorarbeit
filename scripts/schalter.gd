# Dieses Script wird an alle Objekte gehängt, wo man einen Koffer ablegen 
# kann. z.B. Schalter oder Hgscanner
extends Node3D

@onready var drop_position := $baggage_pos
@onready var feedback_light := $weight_feedback
@onready var monitor_feedback := $monitor_feedback

@onready var counter_worker := $"../Player"
@onready var worker_shape := $"../Player/CollisionShape3D"
@onready var speech_bubble := $"../Player".get_node("speech_bubble")
var passenger_in_range := false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	drop_position = get_node_or_null("baggage_pos")
	if drop_position == null:
		print("drop_position ist null!")
	
	if GameManager.role != "passenger":
		counter_worker.visible = false
		worker_shape.disabled = true
	
	await get_tree().process_frame
	speech_bubble.text = "Welcome! Please put your luggage on the scale."
	speech_bubble.visible = false # kein text am Anfang
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if passenger_in_range and Input.is_action_just_pressed("show_ID"):
		# implement animation here
		show_ID_check_dialogue()
	if passenger_in_range and Input.is_action_just_pressed("interact"):
		show
		
func show_ID_check_dialogue():
	speech_bubble.text = "Thanks!"
	await get_tree().create_timer(1.5).timeout  # Delay in Sekunden
	speech_bubble.text = "Let me check you in..."
	await get_tree().create_timer(5).timeout  # Delay in Sekunden
	speech_bubble.text = "Alright, all set up."
	await get_tree().create_timer(2).timeout
	speech_bubble.text = "You can go to the security check now."
	GameManager.is_checked_in = true

func get_drop_position():
	return drop_position.global_transform.origin + Vector3(0, 0, 0)

func update_feedback(is_valid: bool):
	var material = feedback_light.get_active_material(0)
	var material2 = monitor_feedback.get_active_material(0)
	if material == null:
		print("⚠️ Kein Material gefunden!")
		return
		
	if is_valid:
		speech_bubble.text = "Okay, please show your ID."
		material.albedo_color = Color(0, 1, 0) # Grün
		material2.albedo_color = Color(0, 1, 0)
	else:
		speech_bubble.text = "Oh no! Please go to the scale and \n remove something from your luggage."
		material.albedo_color = Color(1, 0, 0) # Rot
		material2.albedo_color = Color(1, 0, 0) # Rot
		await get_tree().create_timer(10).timeout  # Delay in Sekunden
		speech_bubble.text = "Welcome! \n Please put your luggage on the scale."
	
	await get_tree().create_timer(2).timeout 
	material.albedo_color = Color(1, 1, 1) # Weiß
	material2.albedo_color = Color(1, 1, 1) 
	

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		passenger_in_range = true
		speech_bubble.visible = true

func _on_area_3d_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		passenger_in_range = false
		speech_bubble.visible = false
