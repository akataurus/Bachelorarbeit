extends Node3D

@export var speed := 10.0
@onready var is_moving = false

@onready var tractor_node := $"."
@onready var wagon1 := $wagon1
@onready var wagon2 := $wagon2

@onready var drop_position := $baggage_pos
@onready var luggage_on_wagon: int = 0
@onready var luggage_capacity: int = 5

@export var luggage_scene: PackedScene = preload("res://scenes/suitcase.tscn")
@export var luggage_spawn_interval := 10.0  # Alle x Sekunden
@onready var luggage_spawn_marker := $luggage_spawn_marker  # Marker für Spawn-Position
var luggage_timer := 0.0

# Transport-Wegpunkte von Marker3D
var transport_markers: Array[Marker3D] = []
var current_marker_index = 0
var original_position: Vector3

func _ready():
	original_position = global_position  # Merke dir Startposition
	# Lade Transport-Marker aus world.gd
	load_transport_markers()

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("start_truck"):
		start_automatic_transport()
		
	if GameManager.role != "passenger":
		# KOFFER-SPAWNING TIMER
		luggage_timer += delta
		if luggage_timer >= luggage_spawn_interval:
			luggage_timer = 0
			spawn_luggage()

func get_drop_position():
	return drop_position.global_transform.origin + Vector3(0, 0, 0)

func update_luggage_count(count: int):
	if luggage_on_wagon == luggage_capacity:
		print("Wagon full!")
		pass 
	if count == 0:
		pass
	else:
		luggage_on_wagon += 1

func load_transport_markers():
	"""Lädt alle Transport-Marker aus der World-Szene"""
	transport_markers.clear()
	
	# Finde world node (meist die Hauptszene)
	var world = get_tree().current_scene
	
	# Suche nach allen Marker3D nodes mit "transport" im Namen
	var all_markers = find_markers_recursive(world)
	
	# Sortiere Marker nach Namen (transport_1, transport_2, etc.)
	all_markers.sort_custom(func(a, b): return a.name < b.name)
	
	transport_markers = all_markers

func find_markers_recursive(node: Node) -> Array[Marker3D]:
	"""Findet rekursiv alle Marker3D nodes die 'transport' im Namen haben"""
	var markers: Array[Marker3D] = []
	
	# Prüfe aktuellen Node
	if node is Marker3D and "transport" in node.name.to_lower():
		markers.append(node as Marker3D)
	
	# Prüfe alle Kinder rekursiv
	for child in node.get_children():
		markers.append_array(find_markers_recursive(child))
	
	return markers


func start_automatic_transport(): 
	if transport_markers.size() == 0: 
		print("Keine Transport-Route gefunden!") 
		return 
	is_moving = true 
	current_marker_index = 0 
	
	# Starte Bewegung zum ersten Marker 
	move_to_next_marker() 

func move_to_next_marker(): 
	if current_marker_index >= transport_markers.size(): 
		is_moving = false
		return 
	
	var target_marker = transport_markers[current_marker_index] 
	var target_pos = target_marker.global_position 
	
	# Tween für sanfte Bewegung 
	var tween = create_tween() 
	var duration = global_position.distance_to(target_pos) / speed # Bewege zur Marker-Position 
	tween.tween_property(self, "global_position", target_pos, duration) 
	tween.tween_callback(on_marker_reached) 
	
func on_marker_reached(): 
	var current_marker = transport_markers[current_marker_index] 
	current_marker_index += 1 
	
	# Weiter zum nächsten Marker oder Transport beenden 
	if current_marker_index < transport_markers.size(): 
		move_to_next_marker() 
	else: 
		is_moving = false 
	
func spawn_luggage():
	"""Spawnt einen neuen Koffer am Spawn-Marker"""
	if not luggage_spawn_marker:
		print("Luggage spawn marker nicht gefunden!")
		return
	
	var suitcase = luggage_scene.instantiate()
	
	# Füge zur Szene hinzu (nicht zum Truck)
	get_tree().current_scene.add_child(suitcase)
	
	# Position am Marker setzen
	suitcase.global_position = luggage_spawn_marker.global_position
	
	# Zur Gepäck-Gruppe hinzufügen
	suitcase.add_to_group("luggage")
