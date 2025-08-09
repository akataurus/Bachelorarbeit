# Skript vom Handgepäckscanner
extends Node3D

@onready var drop_position := $baggage_pos
@onready var area := $luggage_stop
@onready var feedback := $"../feedback"

@onready var counter_worker := $"../npc_hgscan"
@onready var worker_collshape := $"../npc_hgscan/CollisionShape3D"
@onready var speech_bubble := $"../npc_hgscan".get_node("speech_bubble")
var passenger_in_range := false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if GameManager.role != "passenger": #npc arbeiter entfernen
		counter_worker.visible = false
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
		GameManager.is_hgscan_checked = true
	else:
		material.albedo_color = Color(1, 0, 0) # Rot
		speech_bubble.text = "Oh no, seems like you \n have bad stuff in here!"
		await get_tree().create_timer(4).timeout  # Delay in Sekunden
		speech_bubble.text = "Let me scan it manually..."
		await get_tree().create_timer(5).timeout  # Delay in Sekunden
		speech_bubble.text = ""
		start_man_check()
		# animation für scannen hier

func npc_update_feedback(is_valid: bool):
	var material = feedback.get_active_material(0)
	if material == null:
		print("⚠️ Kein Material gefunden!")
		return
	
	print("NPC Handgepäck Feedback: ", "Akzeptiert" if is_valid else "Abgelehnt")
	
	if is_valid:
		material.albedo_color = Color(0, 1, 0) # Grün
		print("✅ NPC Handgepäck: Akzeptiert")
	else:
		material.albedo_color = Color(1, 0, 0) # Rot
		print("❌ NPC Handgepäck: Abgelehnt")
		
	# Nach Zeit zurücksetzen
	await get_tree().create_timer(3.0).timeout
	material.albedo_color = Color(1, 1, 1)

# Airport Worker benachrichtigen
func notify_airport_worker(hand_luggage: Node, npc: Node):
	"""Benachrichtigt den Airport Worker über wartendes Handgepäck"""
	var airport_worker = get_tree().get_first_node_in_group("airport_worker")
	if airport_worker and airport_worker.has_method("set_pending_hand_luggage"):
		airport_worker.set_pending_hand_luggage(hand_luggage, npc)
		print("Airport Worker benachrichtigt über wartendes Handgepäck")
	else:
		print("❌ Kein Airport Worker gefunden")

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		passenger_in_range = true
		speech_bubble.visible = true


func _on_area_3d_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		passenger_in_range = false
		speech_bubble.visible = false

func start_man_check():
	var path_markers := $"../man_scan_path".get_children()
	var path: Array[Vector3] = []
	
	for marker in path_markers:
		if marker is Marker3D:
			path.append(marker.global_transform.origin)
	
	var npc = $"../npc_hgscan"
	npc.set_player(self)
	npc.start_walk_path(path as Array[Vector3])

func man_scan_result():
	var roll := randf() # Zahl zwischen 0 und 1
	if roll < 0.05:
		speech_bubble.text = "Illegal Stuff found! Go to the Police!"
	if roll < 0.20:
		speech_bubble.text = "Forbidden Stuff found! \n Please put them in the bin."
	else:
		speech_bubble.text = "Okay, all good. Proceed to the gate."


func _on_luggage_stop_body_entered(body: Node3D) -> void:
	pass # Replace with function body.
