extends MeshInstance3D

var player = null

@onready var indicator = $indicator
@onready var indicator2 = $indicator2 # Rückseite des Scanners
@onready var scanner_area = $Area3D
@onready var npc_airport_worker = $"../npc_airport_worker"
@onready var npc_collision_shape = npc_airport_worker.get_node("CollisionShape3D")
@onready var speech_bubble = $"../npc_airport_worker".get_node("speech_bubble")
@onready var anim_player = $"../npc_airport_worker/airport_worker/AnimationPlayer"

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
	if anim_player.current_animation != "happy_idle":
		anim_player.play("happy_idle")

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

# Bestehende Passenger UI
func _on_area_3d_2_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		speech_bubble.visible = true

func _on_area_3d_2_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		speech_bubble.visible = false


# 🔥 ÄNDERN: _on_area_3d_body_entered() 
func _on_area_3d_body_entered(body: Node3D) -> void:
	var is_scan_successful := randf() < 0.5
	# NPC-Handling für Airport Worker
	if body.is_in_group("npc_customer") and GameManager.role == "airport_worker":
		if body == pending_npc:
			print("✅ NPC läuft durch Scanner - benachrichtige Airport Worker für Entscheidung")
			
			# 🔥 WICHTIG: Airport Worker für Entscheidung benachrichtigen
			var airport_worker = get_tree().get_first_node_in_group("airport_worker")
			if airport_worker and airport_worker.has_method("set_body_scan_decision"):
				airport_worker.set_body_scan_decision(pending_npc, self)
				print("Airport Worker für Body Scan Entscheidung benachrichtigt")
				show_scan_feedback(is_scan_successful)
			# Reset pending_npc
			pending_npc = null
			return
	
	# Bestehende Passenger-Logik (unverändert)
	if body.is_in_group("npc_customer") or body.is_in_group("player"):
		show_scan_feedback(is_scan_successful)

# 🔥 NEU: Feedback-Funktion hinzufügen
func show_scan_feedback(is_valid: bool):
	"""Zeigt das Scan-Ergebnis visuell an"""
	var material = indicator.get_active_material(0)
	var material2 = indicator2.get_active_material(0)
	
	if material == null:
		print("⚠️ Kein Material gefunden!")
		return
	
	if is_valid:
		speech_bubble.text = "Scan clear, proceed to boarding."
		material.albedo_color = Color(0, 1, 0) # Grün
		material2.albedo_color = Color(0, 1, 0)
		print("✅ Body Scan: Akzeptiert")
		GameManager.is_bodyscan_checked = true
	else:
		speech_bubble.text = "Please report to manual inspection."
		material.albedo_color = Color(1, 0, 0) # Rot
		material2.albedo_color = Color(1, 0, 0)
		print("❌ Body Scan: Abgelehnt")
	
	# Reset nach Zeit
	await get_tree().create_timer(3.0).timeout
	material.albedo_color = Color(1, 1, 1)
	material2.albedo_color = Color(1, 1, 1)

# 🔥 ENTFERNEN: perform_npc_body_scan() - nicht mehr benötigt
