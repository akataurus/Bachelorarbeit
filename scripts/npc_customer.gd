# NPC Customer 
extends CharacterBody3D

# ========== EXPORTED VARIABLES ==========
@export var speed := 2.0
@export var suitcase_scene: PackedScene = preload("res://scenes/suitcase.tscn")
@export var hand_luggage_scene: PackedScene = preload("res://scenes/hand_luggage.tscn")

# ========== PATH & MOVEMENT ==========
var path := []
var current_path_index := 0
var waiting := false
var wait_at_indices := [5, 7, 10, 11, 12, 13]
var needs_manual_check := false

# ========== UI ==========
@onready var label = $Label3D
var label_time := 2.0

# ========== LUGGAGE ==========
var npc_suitcase = null
var npc_hand_luggage = null
var has_placed_luggage := false
var has_placed_hand_luggage := false

# ========== INITIALIZATION ==========
func _ready():
	call_deferred("_post_ready")

func _post_ready(): 
	_spawn_luggage_based_on_role()

# ========== MOVEMENT & PATH FOLLOWING ==========
func _physics_process(delta):
	if path.is_empty() or waiting:
		return
	
	_follow_path()
	_move_luggage_with_npc()
	move_and_slide()
	_update_rotation()

func _follow_path():
	var target_pos = path[current_path_index]
	var direction = target_pos - global_position
	direction.y = 0

	if direction.length() < 0.1:
		current_path_index += 1
		
		if _should_wait_at_current_index():
			waiting = true
			print("NPC wartet an Index ", current_path_index)
			_handle_wait_point()
			return
			
		if current_path_index >= path.size():
			_finish_path()

	velocity = direction.normalized() * speed

func _update_rotation():
	if velocity.length() > 0.01:
		var target_yaw = atan2(velocity.x, velocity.z)
		var current_yaw = rotation.y
		rotation.y = lerp_angle(current_yaw, target_yaw, 5 * get_physics_process_delta_time())

func _finish_path():
	waiting = true
	velocity = Vector3.ZERO
	despawn()

# ========== LUGGAGE MANAGEMENT ==========
func _spawn_luggage_based_on_role():
	match GameManager.role:
		"airline_worker":
			_spawn_suitcase()
			_spawn_hand_luggage()
		"airport_worker":
			_spawn_hand_luggage()
		_:
			print("Unknown role: ", GameManager.role)

func _spawn_suitcase():
	npc_suitcase = suitcase_scene.instantiate()
	get_tree().current_scene.add_child(npc_suitcase)
	npc_suitcase.global_position = global_position + Vector3(1, 0, 0)
	_setup_luggage_meta(npc_suitcase, "npc_luggage")

func _spawn_hand_luggage():
	print("Spawne Handgepäck für NPC")
	npc_hand_luggage = hand_luggage_scene.instantiate()
	get_tree().current_scene.add_child(npc_hand_luggage)
	npc_hand_luggage.global_position = global_position + Vector3(-1, 0, 0)
	_setup_luggage_meta(npc_hand_luggage, "npc_hand_luggage")

func _setup_luggage_meta(luggage: Node, group_name: String):
	luggage.add_to_group(group_name)
	luggage.set_meta("owner_npc", self)
	luggage.freeze = true
	luggage.gravity_scale = 0



func _move_luggage_with_npc():
	if npc_suitcase and is_instance_valid(npc_suitcase) and not has_placed_luggage:
		_move_luggage_to_position(npc_suitcase, Vector3(1.2, 0, -0.5))
	
	if npc_hand_luggage and is_instance_valid(npc_hand_luggage) and not has_placed_hand_luggage:
		_move_luggage_to_position(npc_hand_luggage, Vector3(-1.2, 0, -0.5))

func _move_luggage_to_position(luggage: Node, offset: Vector3):
	var target_pos = global_position + offset
	luggage.global_position = luggage.global_position.lerp(target_pos, 0.1)

# ========== WAIT POINT HANDLING ==========
func _should_wait_at_current_index() -> bool:
	if current_path_index not in wait_at_indices:
		return false
	
	# Role-specific wait logic
	if GameManager.role == "airport_worker" and current_path_index == 5:
		return false
		
	if current_path_index == 12 and not needs_manual_check:
		print("Manual check nicht nötig - index überspringen")
		return false
	return true

func _handle_wait_point():
	match current_path_index:
		5: # Schalter
			if not has_placed_luggage:
				place_luggage_on_scale()
		7: # Handgepäck-Scanner
			if not has_placed_hand_luggage:
				place_hand_luggage()
		10: # Körper scanner
			request_body_scan()
		12: #manueller check
			request_manual_check()

# ========== LUGGAGE PLACEMENT ==========
func place_luggage_on_scale():
	if not npc_suitcase or has_placed_luggage:
		return

	var target_schalter = _find_nearest_station("schalter")
	if not target_schalter:
		print("❌ Schalter nicht gefunden!")
		return

	_place_luggage_at_station(npc_suitcase, target_schalter, "target_schalter")
	has_placed_luggage = true
	
	# Notify airline worker
	if target_schalter.has_method("notify_airline_worker"):
		target_schalter.notify_airline_worker(npc_suitcase, self)

func place_hand_luggage():
	if not npc_hand_luggage or has_placed_hand_luggage:
		return

	print("NPC legt Handgepäck auf Scanner")
	
	var target_scanner = _find_nearest_station("hgscan")
	if not target_scanner:
		print("❌ Handgepäck-Scanner nicht gefunden!")
		return

	_place_luggage_at_station(npc_hand_luggage, target_scanner, "target_scanner")
	has_placed_hand_luggage = true
	
	# Notify airport worker
	if target_scanner.has_method("notify_airport_worker"):
		target_scanner.notify_airport_worker(npc_hand_luggage, self)

func _place_luggage_at_station(luggage: Node, station: Node, meta_key: String):
	if not station.has_method("get_drop_position"):
		print("❌ Station hat keine get_drop_position Methode!")
		return
	
	# Position and activate luggage
	luggage.global_position = station.get_drop_position()
	luggage.rotation = Vector3(deg_to_rad(-90), 0, 0)
	luggage.freeze = false
	luggage.gravity_scale = 0.7
	luggage.is_moving_on_belt = true
	
	# Set drop target and metadata
	var static_body = _find_static_body_for_station(station)
	if static_body:
		luggage.drop_target = static_body
	
	luggage.set_meta(meta_key, station)

# ========== STATION FINDING ==========
func _find_nearest_station(group_name: String) -> Node:
	var stations = get_tree().get_nodes_in_group(group_name)
	if stations.size() == 0:
		return null

	var nearest_station = null
	var shortest_distance = INF

	for station_node in stations:
		var actual_station = _get_station_with_drop_position(station_node)
		if not actual_station:
			continue
			
		var distance = global_position.distance_to(actual_station.get_drop_position())
		if distance < shortest_distance:
			shortest_distance = distance
			nearest_station = actual_station

	return nearest_station

func _get_station_with_drop_position(node: Node) -> Node:
	if node.has_method("get_drop_position"):
		return node
	
	if node is StaticBody3D:
		var parent = node.get_parent()
		while parent:
			if parent.has_method("get_drop_position"):
				return parent
			parent = parent.get_parent()
	
	return null

func _find_static_body_for_station(station: Node) -> StaticBody3D:
	var group_name = "schalter" if station.is_in_group("schalter") else "hgscan"
	var nodes = get_tree().get_nodes_in_group(group_name)
	
	for node in nodes:
		if node is StaticBody3D:
			if _is_child_of_station(node, station):
				return node
	
	return null

func _is_child_of_station(node: Node, station: Node) -> bool:
	var parent = node.get_parent()
	while parent:
		if parent == station:
			return true
		parent = parent.get_parent()
	return false

# ========== PUBLIC API ==========
func set_path(p: Array):
	path = p
	current_path_index = 0
	waiting = false

func set_wait_points(indices: Array):
	wait_at_indices = indices
	wait_at_indices.sort()
	print("NPC Wartepunkte gesetzt: ", wait_at_indices)

func resume_from_wait():
	waiting = false

# ========== DIALOGUE & INTERACTION ==========
func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") and body.has_method("set_curr_customer"):
		body.set_curr_customer(self)
		update_label("Hello!")

func dialogue(counter: int):
	var responses = ["Here is my ID.", "Thank you!", "Thanks! Good bye"]
	var response_text = responses[counter % 3]
	var should_leave = (counter % 3 == 2)

	label.text = response_text
	await get_tree().create_timer(label_time).timeout
	label.text = ""

	if should_leave:
		await get_tree().create_timer(0.5).timeout
		waiting = false

func update_label(text: String):
	label.text = text 
	await get_tree().create_timer(label_time).timeout
	label.text = ""

# ========== LUGGAGE CALLBACKS ==========
func luggage_accepted():
	update_label("Thank you!")
	await get_tree().create_timer(2.0).timeout
	waiting = false

func luggage_rejected():
	update_label("Oh no! I'll take it back...")
	await get_tree().create_timer(2.0).timeout
	take_suitcase_back()
	await get_tree().create_timer(1.0).timeout
	waiting = false

func hand_luggage_accepted():
	update_label("Thank you!")
	await get_tree().create_timer(2.0).timeout
	collect_hand_luggage()
	waiting = false

func collect_hand_luggage():
	"""NPC sammelt sein Handgepäck wieder ein"""
	if npc_hand_luggage and is_instance_valid(npc_hand_luggage):
		print("NPC sammelt Handgepäck ein")
		
		# Handgepäck zurück zur ursprünglichen Position
		npc_hand_luggage.global_position = global_position + Vector3(-1, 0, 0)
		npc_hand_luggage.is_moving_on_belt = false
		npc_hand_luggage.freeze = true
		npc_hand_luggage.gravity_scale = 0
		
		# Als "nicht platziert" markieren für weiteres Mitführen
		has_placed_hand_luggage = false
		
		print("✅ Handgepäck eingesammelt")

func hand_luggage_rejected():
	"""Wird aufgerufen wenn Airport Worker Handgepäck ablehnt"""
	update_label("This is so embarrassing!")
	await get_tree().create_timer(1.0).timeout
	
	update_label("I'll come back later...")
	await get_tree().create_timer(4.0).timeout
	
	despawn() #npc verschwindet
	npc_hand_luggage.despawn() # handgepäck verschwindet



func take_suitcase_back():
	if npc_suitcase and is_instance_valid(npc_suitcase):
		print("NPC nimmt Koffer zurück")
		_reset_luggage(npc_suitcase, Vector3(1, 0, 0))
		has_placed_luggage = false

func take_hand_luggage_back():
	if npc_hand_luggage and is_instance_valid(npc_hand_luggage):
		print("NPC nimmt Handgepäck zurück")
		_reset_luggage(npc_hand_luggage, Vector3(-1, 0, 0))
		has_placed_hand_luggage = false

func _reset_luggage(luggage: Node, offset: Vector3):
	luggage.is_moving_on_belt = false
	luggage.freeze = true
	luggage.gravity_scale = 0
	luggage.global_position = global_position + offset

# ==========BODY SCAN MANAGEMENT============
func request_body_scan():
	print("NPC wartet am Körperscanner")
	
	var body_scanner = find_nearest_body_scanner()
	if body_scanner and body_scanner.has_method("notify_airport_worker_for_body_scan"):
		body_scanner.notify_airport_worker_for_body_scan(self)
	else:
		print("❌ Körperscanner nicht gefunden")

# Body Scanner Funktionen (nach request_body_scan())
func find_nearest_body_scanner():
	"""Findet den nächsten Körperscanner"""
	var scanners = get_tree().get_nodes_in_group("body_scanner")
	if scanners.size() == 0:
		print("Keine Body Scanner gefunden")
		return null
	
	var nearest = null
	var shortest_distance = INF
	
	for scanner in scanners:
		var distance = global_position.distance_to(scanner.global_position)
		if distance < shortest_distance:
			shortest_distance = distance
			nearest = scanner
	
	print("Nächster Body Scanner: ", nearest.name if nearest else "None")
	return nearest

# Body Scanner Callbacks
func body_scan_accepted():
	"""Wird aufgerufen wenn Airport Worker Body Scan akzeptiert"""
	update_label("Thank you!")
	await get_tree().create_timer(2.0).timeout
	
	# 🔥 Kein Manual Check nötig
	needs_manual_check = false
	waiting = false

func body_scan_rejected():
	"""Wird aufgerufen wenn Airport Worker Body Scan ablehnt"""
	update_label("I need manual inspection...")
	await get_tree().create_timer(2.0).timeout
	
	# 🔥 Manual Check wird benötigt
	needs_manual_check = true
	waiting = false  # Weiter zum Manual Check Index

func request_manual_check():
	"""NPC wartet am Manual Check Point"""
	print("NPC wartet am Manual Check Point")
	
	"""Dreht NPC um 180 Grad zum Spieler"""
	var target_rotation = rotation.y + PI  # 180 Grad hinzufügen
	# Smooth rotation mit Tween
	var tween = create_tween()
	tween.tween_property(self, "rotation:y", target_rotation, 1.0)
	
	# Airport Worker benachrichtigen
	var airport_worker = get_tree().get_first_node_in_group("airport_worker")
	if airport_worker and airport_worker.has_method("set_pending_manual_check"):
		airport_worker.set_pending_manual_check(self)
		print("Airport Worker über Manual Check benachrichtigt")
	else:
		print("❌ Kein Airport Worker für Manual Check gefunden")

func manual_check_accepted():
	"""Wird aufgerufen wenn Airport Worker Manual Check akzeptiert"""
	update_label("Thank you for your patience!")
	await get_tree().create_timer(2.0).timeout
	# Manual Check abgeschlossen
	needs_manual_check = false
	waiting = false

func manual_check_rejected():
	"""Wird aufgerufen wenn Airport Worker Manual Check ablehnt"""
	update_label("I understand... I'll go home.")
	await get_tree().create_timer(2.0).timeout
	
	despawn()
	npc_hand_luggage.despawn()
	
# ========== CLEANUP ==========
func despawn():
	queue_free()
