# source: https://www.cgtrader.com/items/2877263/download-page
# suitcase skript
extends RigidBody3D

@export var pickup_distance := 3  # Maximale Distanz zum Aufheben

var player = null
var is_held = false  # Ob der Koffer aktuell getragen wird
var drop_target = null # speichert drop Ziel falls erkannt wird
var is_dropping = false # workaround für drop() und _on_body_exited()

var is_in_counter_range = false # jewels für hint
var is_in_scale_range = false
var is_in_truck_range = false
var is_in_plane_range = false

var weight: float = 0.0 # gewicht des Koffers
var weight_limit = 20.0 # kein Koffer darf weight_limit überschreiten

var is_moving_on_belt = false 
var belt_direction := Vector3.FORWARD # Richtung der Bewegung
var belt_speed := 1 # Geschwindigkeit für Bewegung

@onready var area := $Area3D
@onready var scanner_exit := get_tree().root.find_child("suitcase_stop", true, false)
@onready var plane

func _ready():
	await get_tree().create_timer(0.1).timeout  # Wartet 0.1 Sekunden
	if area and area is Area3D:
		area.body_entered.connect(_on_body_entered)
		area.body_exited.connect(_on_body_exited)
	if scanner_exit and scanner_exit is Area3D:
		scanner_exit.body_entered.connect(_on_counter_exit_body_entered)
	else:
		print("Fehler: area ist null oder kein Area3D! (ready)")
	
	randomize()
	weight = snapped(randf_range(10.0, 30.0), 0.01) # zwei Nachkommastellen

	plane = find_plane()

func _process(delta):
	if GameManager.role == "airline_worker":
		return # airline worker kann nicht mit koffern interagieren
	if is_moving_on_belt:
		linear_velocity += belt_direction * belt_speed * delta
		return # keine Eingabe möglich wenn koffer in Bewegung
	
	if player and Input.is_action_just_pressed("interact"):
		if is_held:
			drop()
		else:
			pick_up()
	# für hint
	if player and player.has_method("show_hint"):	
		if is_held:
			if is_in_counter_range:
				player.show_hint("Drop luggage on counter: E", self)
			elif is_in_scale_range:
				player.show_hint("Drop luggage on scale: E", self)
			elif is_in_truck_range:
				player.show_hint("Drop luggage on truck: E", self)	
			elif is_in_plane_range:
				player.show_hint("Load luggage on plane: E", self)	
			else:
				player.show_hint("Drop luggage: E", self)
		else:
			if is_in_scale_range:
				player.show_hint("Start minigame: G\nSelect: Space\nPick up luggage: E", self)
			else:
				player.show_hint("Pick up luggage: E", self)

func _on_counter_exit_body_entered(body):
	print("hallo")
	if body == self:
		is_moving_on_belt = false
		if drop_target and drop_target.get_parent().has_method("update_feedback"):
			drop_target.get_parent().update_feedback(weight < weight_limit)


func _on_body_entered(body):
	# Prüft, ob der Spieler in den Bereich tritt
	if body.is_in_group("player"):  
		if GameManager.role == "airline_worker":
			return
		player = body
	# Prüft, ob der Koffer sich in Schalternähe befindet
	elif body.is_in_group("schalter"):  
		drop_target = body
		is_in_counter_range = true
		
	elif body.is_in_group("waage"):
		drop_target = body
		is_in_scale_range = true
	
	elif body.is_in_group("towing_truck"):
		drop_target = body
		is_in_truck_range = true
	
	elif body.is_in_group("suitcase_stop"):
		print("here")
		is_moving_on_belt = false
		
	

func _on_body_exited(body):
	if is_dropping: # ignoriere wegen drop
		return
	
	if body == player and player and player.has_method("hide_hint"):
		if GameManager.role != "airline_worker":
			player.hide_hint(self)
		# Überprüfe, ob der Spieler wirklich weit genug entfernt ist
		if body.global_transform.origin.distance_to(global_transform.origin) > pickup_distance:
			player = null
		if drop_target and drop_target.is_in_group("waage"):
			drop_target.get_parent().set_optcontainer_visible(false) # minigame
	
	if body == drop_target:
		
		if body.is_in_group("schalter"):
			is_in_counter_range = false
		if body.is_in_group("waage"):
			is_in_scale_range = false
			drop_target.get_parent().set_label_text(0.0)
		if body.is_in_group("towing_truck"):
			is_in_truck_range = false
		drop_target = null


func pick_up():
	if player and player.global_transform and not GameManager.role == "airline_worker":
		if player.global_transform.origin.distance_to(global_transform.origin) < pickup_distance:
			is_held = true
			if drop_target and drop_target.is_in_group("waage"):
				drop_target.get_parent().set_optcontainer_visible(false) # minigame
			drop_target = null # reset beim aufheben
			# Physik einfrieren
			freeze = true  # Verhindert Bewegung
			linear_velocity = Vector3.ZERO
			angular_velocity = Vector3.ZERO
			
			reparent(player)  # Koffer wird zum Kind des Spielers
			global_transform = player.global_transform
			position += Vector3(1, 1, 0)  # Hebt den Koffer etwas an
	else:
		print("player ist null oder hat kein global_transform")


func drop():
	is_dropping = true
	is_held = false
	freeze = false # Physik wieder aktivieren
	var drop_position = null
	
	if is_instance_valid(drop_target):
		var parent = drop_target.get_parent()
		var grandparent = drop_target.get_parent().get_parent()
		# Versuche verschiedene Wege um get_drop_position() zu finden
		if drop_target.has_method("get_drop_position"):
			# Drop_target selbst hat die Methode
			drop_position = drop_target.get_drop_position()
		elif parent and parent.has_method("get_drop_position"):
			# Parent vom drop_target hat die Methode
			drop_position = parent.get_drop_position()
		elif grandparent and grandparent.has_method("get_drop_position"):
			# Grandparent von drop_target hat die Methode
			drop_position = grandparent.get_drop_position()
		else:
			# Fallback: Verwende drop_target Position
			print("⚠️ Keine get_drop_position() gefunden, verwende Fallback")
			drop_position = drop_target.global_position + Vector3(0, 1, 0)
			
		global_transform.origin = drop_position
		global_rotation = Vector3(deg_to_rad(90), 0, 0)
		# koffer wurde auf ziel abgelegt
	
		#bewegung aktivieren
		#drop_target.get_parent().update_feedback(weight < weight_limit)
		if drop_target.is_in_group("schalter"):
			is_moving_on_belt = true
		if drop_target.is_in_group("towing_truck"):
			var truck = drop_target.get_parent()
			truck.update_luggage_count(1)
			
			# Entferne aus Player-Hierarchie
			get_parent().remove_child(self)
			
			# Füge direkt zu wagon1 hinzu (einfachste Lösung)
			var wagon1 = truck.get_node("wagon1")
			wagon1.add_child(self)
			
			# RANDOM OFFSET für natürliche Verteilung
			var random_offset = Vector3(
				randf_range(-0.3, 0.3),  # X: links/rechts
				randf_range(-0.1, 0.2),  # Y: hoch/runter (weniger)
				randf_range(-0.2, 0.2)   # Z: vor/zurück
			)
			
			# VERWENDE get_drop_position() für die korrekte Position
			var truck_drop_pos = truck.get_drop_position()
			# Konvertiere von global zu lokaler Position relativ zu wagon1
			global_position = truck_drop_pos
			var local_pos = wagon1.to_local(truck_drop_pos)
			position = local_pos + random_offset
			rotation = Vector3(deg_to_rad(90), 0, 0)
			freeze = true
			gravity_scale = 0
			
			
			is_dropping = false
			return  # Wichtig: Kein reparent zur Szene!
		
	if is_in_scale_range:
		drop_target.get_parent().set_label_text(weight)
		drop_target.get_parent().set_optcontainer_visible(true) # minigame
		
	reparent(get_tree().current_scene)  #Entfernt den Koffer aus der Spielerhierarchie
	
	is_dropping = false

func find_plane():
	var plane = get_tree().current_scene.find_child("plane", true, false)
	if plane:
		return plane
	else:
		print("❌ Plane nicht gefunden!")
		return null

func _on_area_3d_area_entered(area: Area3D) -> void:
	if area.is_in_group("plane_area") and is_held:
		if player and player.has_method("show_hint"):
			is_in_plane_range = true
			if plane:
				drop_target = plane
			else:
				print("plane null")

func _on_area_3d_area_exited(area: Area3D) -> void:
	if area.is_in_group("plane_area") and is_held:
		if player and player.has_method("hide_hint"):
			is_in_plane_range = false
			if drop_target == plane:
				drop_target = null
# called by npc_customer
func npc_update_feedback(npc: Node3D):
	pass
