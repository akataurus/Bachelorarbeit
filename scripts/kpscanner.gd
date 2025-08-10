extends MeshInstance3D

var player = null

@onready var indicator = $indicator
@onready var indicator2 = $indicator2 # Rückseite des Scanners
@onready var scanner_area = $Area3D
@onready var npc_airport_worker = $"../npc_airport_worker"
@onready var npc_collision_shape = npc_airport_worker.get_node("CollisionShape3D")
@onready var speech_bubble = $"../npc_airport_worker".get_node("speech_bubble")

# Für Airport Worker NPC-Management
var pending_npc = null
var scan_result = false

func _ready() -> void:
	if GameManager.role != "passenger":
		npc_collision_shape.disabled = true
		
	
	await get_tree().process_frame
	speech_bubble.text = "You can go through now."
	speech_bubble.visible = false

func _process(delta: float) -> void:
	pass

# Wird vom NPC aufgerufen
func notify_airport_worker_for_body_scan(npc: Node):
	var airport_worker = get_tree().get_first_node_in_group("airport_worker")
	if airport_worker and airport_worker.has_method("set_pending_body_scan"):
		airport_worker.set_pending_body_scan(npc, self)
		print("Airport Worker über Body Scan benachrichtigt")

# Airport Worker startet Scanner
func start_body_scan(npc: Node):
	print("Körperscanner bereit für NPC")
	pending_npc = npc
	scan_result = randf() < 0.7  # 70% Erfolgsrate
	
	speech_bubble.text = "Please walk through the scanner..."
	
	# 🔥 EINFACH: NPC läuft einfach weiter
	if pending_npc and pending_npc.has_method("resume_from_wait"):
		pending_npc.resume_from_wait()

# NPC Body Scan
func perform_npc_body_scan():
	var material = indicator.get_active_material(0)
	var material2 = indicator2.get_active_material(0)
	
	if material == null:
		print("⚠️ Kein Material gefunden!")
		return
	
	await get_tree().create_timer(0.5).timeout
	
	if scan_result:
		speech_bubble.text = "Looks good, move on please."
		material.albedo_color = Color(0, 1, 0) # Grün
		material2.albedo_color = Color(0, 1, 0)
		print("✅ NPC Body Scan erfolgreich")
		
		# 🔥 EINFACH: NPC geht weiter
		if pending_npc and pending_npc.has_method("resume_from_wait"):
			pending_npc.resume_from_wait()
	else:
		speech_bubble.text = "Please go to manual body scan."
		material.albedo_color = Color(1, 0, 0) # Rot
		material2.albedo_color = Color(1, 0, 0)
		print("❌ NPC Body Scan fehlgeschlagen")
		
		# NPC geht auch weiter (zum manuellen Check)
		if pending_npc and pending_npc.has_method("resume_from_wait"):
			pending_npc.resume_from_wait()
	
	# Reset
	await get_tree().create_timer(2.0).timeout
	material.albedo_color = Color(1, 1, 1)
	material2.albedo_color = Color(1, 1, 1)
	pending_npc = null

# Bestehende Passenger UI
func _on_area_3d_2_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		speech_bubble.visible = true

func _on_area_3d_2_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		speech_bubble.visible = false


func _on_area_3d_body_entered(body: Node3D) -> void:
	# NPC-Handling für Airport Worker
	print("body: ", body, "is_in_group: ", body.is_in_group("airport_worker"))
	print("gamemanager role = ", GameManager.role)
	if body.is_in_group("npc_customer") and GameManager.role == "airport_worker":
		print("NPC läuft durch Scanner - Scan wird ausgeführt")
		perform_npc_body_scan()
		return
	
	# Bestehende Passenger-Logik (unverändert)
	if body.is_in_group("airport_worker") or body.is_in_group("player"):
		var is_scan_successful := randf() < 0.5
		
		var material = indicator.get_active_material(0)
		var material2 = indicator2.get_active_material(0)
		if material == null:
			print("⚠️ Kein Material gefunden!")
			return
		
		if is_scan_successful:
			speech_bubble.text = "Looks good, move on please."
			material.albedo_color = Color(0, 1, 0) # Grün
			material2.albedo_color = Color(0, 1, 0) 
			GameManager.is_bodyscan_checked = true
		else:
			speech_bubble.text = "Looks like you might have something on you. \n go to the manual body scan please."
			material.albedo_color = Color(1, 0, 0) # Rot
			material2.albedo_color = Color(1, 0, 0) # Rot
		
		await get_tree().create_timer(2).timeout 
		material.albedo_color = Color(1, 1, 1) # Weiß
		material2.albedo_color = Color(1, 1, 1)
