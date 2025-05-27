# Dieses Script wird an alle Objekte gehängt, wo man einen Koffer ablegen 
# kann. z.B. Schalter oder Hgscanner
extends Node3D

@onready var drop_position := $baggage_pos
@onready var area := $luggage_stop
@onready var feedback := $"../feedback"

@onready var counter_worker := $"../Player"
@onready var worker_collshape := $"../Player/CollisionShape3D"
@onready var speech_bubble := $"../Player".get_node("speech_bubble")
var passenger_in_range := false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if GameManager.role != "passenger":
		counter_worker.visible = false#
		worker_collshape.disabled = true
		
	await get_tree().process_frame
	speech_bubble.text = "Welcome! \n Please put your luggage on the scanner."
	speech_bubble.visible = false # kein text am Anfang
	
	drop_position = get_node_or_null("baggage_pos")
	if drop_position == null:
		print("drop_position ist null!")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if passenger_in_range and !GameManager.is_checked_in and Input.is_action_just_pressed("hg_interact"):
		speech_bubble.text = "Please check in at the airport counter first!"
	if passenger_in_range and GameManager.is_checked_in and Input.is_action_just_pressed("hg_interact"):
		speech_bubble.text = "Thanks!"

func get_drop_position():
	return drop_position.global_transform.origin + Vector3(0, 0, 0)

func update_feedback():
	var is_scan_successful := randf() < 0.5 # Wahrscheinlichkeit für grünen scan
	var material = feedback.get_active_material(0)
	
	if is_scan_successful:
		material.albedo_color = Color(0, 1, 0) # Grün
		speech_bubble.text = "Okay, looks good. \n You can go to the gate now."
		GameManager.is_sec_checked = true
	else:
		material.albedo_color = Color(1, 0, 0) # Rot
		speech_bubble.text = "Oh no, seems like you \n have bad stuff in here!"
		await get_tree().create_timer(4).timeout  # Delay in Sekunden
		speech_bubble.text = "Let me scan it manually..."
		await get_tree().create_timer(5).timeout  # Delay in Sekunden
		speech_bubble.text = ""
		# animation für scannen hier

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		passenger_in_range = true
		speech_bubble.visible = true


func _on_area_3d_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		passenger_in_range = false
		speech_bubble.visible = false
