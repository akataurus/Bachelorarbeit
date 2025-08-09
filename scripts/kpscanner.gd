extends MeshInstance3D

@onready var indicator = $indicator
@onready var indicator2 = $indicator2
@onready var scanner_area = $Area3D  # Für Spieler-Interaktion
@onready var npc_airport_worker = $"../npc_airport_worker"
@onready var npc_collision_shape = npc_airport_worker.get_node("CollisionShape3D")
@onready var speech_bubble = $"../npc_airport_worker".get_node("speech_bubble")

# 🔥 NEU: Variablen für NPC-Management
var pending_npc = null
var scanner_active = false
var scan_result = false  # Vordefiniertes Scan-Ergebnis

func _ready() -> void:
	if GameManager.role != "passenger":
		npc_collision_shape.disabled = true
		
	scanner_area.body_entered.connect(_on_body_entered) 
	
	# Scanner-Collision verbinden
	var scanner_collision = $ScannerCollision
	if scanner_collision:
		scanner_collision.body_entered.connect(_on_scanner_collision_body_entered)
	
	await get_tree().process_frame
	speech_bubble.text = "You can go through now."
	speech_bubble.visible = false

# 🔥 NEU: Wird vom NPC aufgerufen
func notify_airport_worker_for_body_scan(npc: Node):
	"""Benachrichtigt Airport Worker über wartenden NPC am Körperscanner"""
	var airport_worker = get_tree().get_first_node_in_group("airport_worker")
	if airport_worker and airport_worker.has_method("set_pending_body_scan"):
		airport_worker.set_pending_body_scan(npc, self)
		print("Airport Worker über Body Scan benachrichtigt")
	else:
		print("❌ Kein Airport Worker für Body Scan gefunden")

# 🔥 GEÄNDERT: Nur Scanner vorbereiten, nicht ausführen
func start_body_scan(npc: Node):
	"""Bereitet den Körperscanner für den NPC vor"""
	print("Körperscanner vorbereitet für NPC")
	pending_npc = npc
	scanner_active = true
	
	# 🔥 Scan-Ergebnis vorbestimmen (aber noch nicht ausführen)
	scan_result = randf() < 0.7  # 70% Erfolgsrate
	
	# NPC darf durch den Scanner gehen
	speech_bubble.text = "Please walk through the scanner..."
	
	if pending_npc and pending_npc.has_method("walk_through_scanner"):
		pending_npc.walk_through_scanner(self)

# 🔥 NEU: Wird von der CollisionShape getriggert
func _on_scanner_collision_body_entered(body: Node3D):
	"""Wird ausgelöst wenn NPC tatsächlich durch den Scanner läuft"""
	if body == pending_npc and scanner_active:
		print("NPC läuft durch Körperscanner - führe Scan aus")
		perform_body_scan()

func perform_body_scan():
	"""Führt den eigentlichen Scan durch"""
	var material = indicator.get_active_material(0)
	var material2 = indicator2.get_active_material(0)
	
	if material == null:
		print("⚠️ Kein Material gefunden!")
		return
	
	await get_tree().create_timer(0.5).timeout  # Kurze Verzögerung für Realismus
	
	if scan_result:
		speech_bubble.text = "Looks good, move on please."
		material.albedo_color = Color(0, 1, 0) # Grün
		material2.albedo_color = Color(0, 1, 0)
		print("✅ Body Scan erfolgreich")
		
		# NPC darf weitergehen
		if pending_npc and pending_npc.has_method("body_scan_completed"):
			pending_npc.body_scan_completed(true)
			
	else:
		speech_bubble.text = "Please go to manual body scan."
		material.albedo_color = Color(1, 0, 0) # Rot
		material2.albedo_color = Color(1, 0, 0)
		print("❌ Body Scan fehlgeschlagen")
		
		# NPC muss zum manuellen Check
		if pending_npc and pending_npc.has_method("body_scan_completed"):
			pending_npc.body_scan_completed(false)
	
	# Reset nach Zeit
	await get_tree().create_timer(2.0).timeout
	material.albedo_color = Color(1, 1, 1)
	material2.albedo_color = Color(1, 1, 1)
	
	# Cleanup
	pending_npc = null
	scanner_active = false

# Bestehende Funktion für Spieler (unverändert)
func _on_body_entered(body):
	if body.is_in_group("player"):
		var is_scan_successful := randf() < 0.5
		var material = indicator.get_active_material(0)
		var material2 = indicator2.get_active_material(0)
		
		if is_scan_successful:
			speech_bubble.text = "Looks good, move on please."
			material.albedo_color = Color(0, 1, 0)
			material2.albedo_color = Color(0, 1, 0)
			GameManager.is_bodyscan_checked = true
		else:
			speech_bubble.text = "Please go to manual body scan."
			material.albedo_color = Color(1, 0, 0)
			material2.albedo_color = Color(1, 0, 0)
		
		await get_tree().create_timer(2).timeout
		material.albedo_color = Color(1, 1, 1)
		material2.albedo_color = Color(1, 1, 1)

func _on_area_3d_2_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		speech_bubble.visible = true

func _on_area_3d_2_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		speech_bubble.visible = false


func _on_area_3d_body_entered(body: Node3D) -> void:
	pass # Replace with function body.
