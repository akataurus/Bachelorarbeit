# npc customer skript
extends CharacterBody3D

@export var speed := 2.0
var path := []
var current_path_index := 0
var waiting = false
var wait_at_indices := [5, 7, 10, 12] # indizes wo interagiert wird
const current_wait_index := 0

@onready var label = $Label3D
var label_time = 2.0 # Zeit, wie lange text angezeigt wird

var npc_suitcase = null
@export var suitcase_scene: PackedScene = preload("res://scenes/suitcase.tscn")
var has_placed_luggage = false

func _ready():
	call_deferred("_post_ready")
	
	#print("NPC ready, CollisionShape vorhanden?: ", $CollisionShape3D)

# wegen timing issues
func _post_ready(): 
	spawn_suitcase()

# von world.gd aufgerufen
func set_path(p: Array):
	path = p
	current_path_index = 0
	waiting = false

func set_wait_points(indices: Array):
	# setze pfad indizes an denen der npc warten soll
	wait_at_indices = indices
	wait_at_indices.sort() # für korrekte reihenfolge
	print("npc wartepunkte gesetzt: ", wait_at_indices)

# von einem worker aufgerufen
func resume_from_wait():
	waiting = false
	
func _physics_process(delta):
	if path.is_empty() or waiting:
		return
	
	var target_pos = path[current_path_index]
	var direction = target_pos - global_position
	direction.y = 0

	# Wenn nah genug -> anhalten
	if direction.length() < 0.1:
		current_path_index += 1
		if current_path_index in wait_at_indices:
			waiting = true
			print("npc wartet an index ", current_path_index)
			
			# für schalter
			if current_path_index == 5 and not has_placed_luggage:
				place_luggage_on_scale()
			return
		if current_path_index >= path.size():
			waiting = true
			velocity = Vector3.ZERO
			despawn()
			return
	else:
		velocity = direction.normalized() * speed

	if npc_suitcase and is_instance_valid(npc_suitcase) and not has_placed_luggage:
		move_suitcase_with_npc()
	move_and_slide()

	# Rotation zur Bewegungsrichtung
	if velocity.length() > 0.01:
		var target_yaw = atan2(velocity.x, velocity.z)
		var current_yaw = rotation.y
		rotation.y = lerp_angle(current_yaw, target_yaw, 5 * delta)

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") and body.has_method("set_curr_customer"):
		body.set_curr_customer(self)
		update_label("Hello!")

func spawn_suitcase():
	npc_suitcase = suitcase_scene.instantiate()
	# Koffer zur Szene hinzufügen (nicht als Child des NPCs)
	get_tree().current_scene.add_child(npc_suitcase)
	# Koffer-Position neben dem NPC setzen
	npc_suitcase.global_position = global_position + Vector3(1, 0, 0)
	# Koffer als NPC-Gepäck markieren
	npc_suitcase.add_to_group("npc_luggage")
	npc_suitcase.set_meta("owner_npc", self)
	# Koffer-Physik für NPC anpassen
	npc_suitcase.freeze = true
	npc_suitcase.gravity_scale = 0

func move_suitcase_with_npc():
	 # Koffer folgt dem NPC mit leichtem Offset
	var target_pos = global_position + Vector3(1.2, 0, -0.5)  # Rechts hinter dem NPC
	npc_suitcase.global_position = npc_suitcase.global_position.lerp(target_pos, 0.1)

func place_luggage_on_scale():
	if not npc_suitcase or has_placed_luggage:
		return


	var target_schalter = find_nearest_drop_position()
	if not target_schalter:
		print("Schalter nicht gefunden!")
		return

	if target_schalter.has_method("get_drop_position"):
		npc_suitcase.global_position = target_schalter.get_drop_position()
		npc_suitcase.rotation = Vector3(deg_to_rad(-90), 0, 0)
		has_placed_luggage = true
		
		# Koffer aktivieren
		npc_suitcase.freeze = false
		npc_suitcase.gravity_scale = 0.7
		npc_suitcase.is_moving_on_belt = true
		
		# Finde das StaticBody3D in der schalter-Gruppe für diesen Schalter
		var schalter_static_body = find_schalter_static_body(target_schalter)
		if schalter_static_body:
			npc_suitcase.drop_target = schalter_static_body
		else:
			print("StaticBody3D für Schalter nicht gefunden")
		
		
		# Feedback triggern
		npc_suitcase.set_meta("target_schalter", target_schalter)
		if target_schalter.has_method("npc_update_feedback"):
			var is_valid = npc_suitcase.weight < npc_suitcase.weight_limit
			target_schalter.npc_update_feedback(is_valid)
		
	npc_suitcase.set_meta("target_schalter", target_schalter)
	
	# Airline Worker benachrichtigen statt sofortiges Feedback
	if target_schalter.has_method("notify_airline_worker"):
		target_schalter.notify_airline_worker(npc_suitcase, self)
	else:
		print("schalter hat keine get_drop_position mehtode!")

func find_schalter_static_body(schalter_node: Node):
	"""Findet das StaticBody3D das zu diesem Schalter gehört"""
	# Suche in der schalter-Gruppe nach dem StaticBody3D
	var schalter_nodes = get_tree().get_nodes_in_group("schalter")
	
	for node in schalter_nodes:
		if node is StaticBody3D:
			# Überprüfe ob dieses StaticBody3D zum richtigen Schalter gehört
			var node_parent = node.get_parent()
			while node_parent:
				if node_parent == schalter_node:
					return node
				node_parent = node_parent.get_parent()
	
	return null

func find_nearest_drop_position():
	var schalter_nodes = get_tree().get_nodes_in_group("schalter")
	
	if schalter_nodes.size() == 0:
		print("schalter nicht gefunden")
		return null

	var nearest_schalter = null
	var shortest_distance = INF

	for schalter_node in schalter_nodes:
		
		var actual_schalter = null
		
		# Für StaticBody3D: Suche Parent mit get_drop_position()
		if schalter_node is StaticBody3D:
			var parent = schalter_node.get_parent()
			while parent:
				if parent.has_method("get_drop_position"):
					actual_schalter = parent
					break
				parent = parent.get_parent()
		# Für andere Nodes: Direkt prüfen
		elif schalter_node.has_method("get_drop_position"):
			actual_schalter = schalter_node
		
		if not actual_schalter:
			print("Keine get_drop_position Methode gefunden")
			continue
			
		var drop_pos = actual_schalter.get_drop_position()
		var distance = global_position.distance_to(drop_pos)

		
		if distance < shortest_distance:
			shortest_distance = distance
			nearest_schalter = actual_schalter

	return nearest_schalter


func dialogue(counter: int):
	var response_text = ""
	var should_leave = false

	match counter % 3:
		0: # "Hello, ID please!"
			response_text = "Here is my ID."
		1: # "Thanks, I'm checking you in..."
			response_text = "Thank you!"
		2: # "Go to the security check now."
			response_text = "Thanks! Good bye"
			should_leave = true

	# Customer Text anzeigen
	label.text = response_text
	await get_tree().create_timer(label_time).timeout
	label.text = ""

	# Falls letzter Dialog -> Customer geht weg
	if should_leave:
		await get_tree().create_timer(0.5).timeout  # Kurze Pause
		waiting = false

func update_label(text: String):
	label.text = text 
	await get_tree().create_timer(label_time).timeout  # Delay in Sekunden
	label.text = ""
	
func despawn():
	queue_free()

func luggage_accepted():
	"""Wird aufgerufen wenn Airline Worker Koffer akzeptiert"""
	update_label("Thank you!")
	await get_tree().create_timer(2.0).timeout
	
	# NPC kann weitergehen (Pfad fortsetzen oder despawnen)
	waiting = false

func luggage_rejected():
	"""Wird aufgerufen wenn Airline Worker Koffer ablehnt"""
	update_label("Oh no! I'll take it back...")
	await get_tree().create_timer(2.0).timeout
	
	# Koffer wieder mitnehmen
	take_suitcase_back()
	
	# NPC geht weg
	await get_tree().create_timer(1.0).timeout
	waiting = false # npc geht weiter
	
func take_suitcase_back():
	"""NPC nimmt seinen Koffer wieder mit"""
	if npc_suitcase and is_instance_valid(npc_suitcase):
		print("NPC nimmt Koffer zurück")
		
		# Koffer stoppen
		npc_suitcase.is_moving_on_belt = false
		npc_suitcase.freeze = true
		npc_suitcase.gravity_scale = 0
		
		# Koffer zurück zum NPC bewegen
		npc_suitcase.global_position = global_position + Vector3(1, 0, 0)
		
		# Optional: Koffer wieder als "mitgetragen" markieren
		has_placed_luggage = false


	
	
	
