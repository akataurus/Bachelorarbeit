extends Node3D

@onready var passenger_spawn := $spawns/passenger_spawn # empty Nodes as starting position
@onready var airportw_spawn := $spawns/airportw_spawn # die 3 hier sind für spieler
@onready var airlinew_spawn := $spawns/airlinew_spawn

@export var npc_passenger_scene: PackedScene
@export var npc_passenger_spawn:= Vector3(0,0,0)
@export var npc_passenger_spawn_interval := 20.0 # alle 3 Sekunden neuer npc
@export var npc_passengers_per_spawn := 0 # anzahl der auf einmal gespawnten npcs

@export var npc_customer_scene: PackedScene
@export var npc_customer_spawn:= Vector3(-30, 0, 40)
@export var npc_customer_spawn_interval := 15.0
@export var npc_customer_per_spawn := 1
# damit npcs nicht komplett aufeinander spawnen:
var offset := Vector3(randf_range(-2, 2), 0, randf_range(-2, 2)) 

var timer1 := 0.0
var timer2 := 0.0

# Called when the node enters the scene tree for the first time.
func _ready():
	match GameManager.role:
		"passenger":
			var player_scene = load("res://scenes/playable/passenger.tscn")
			var player = player_scene.instantiate()
			player.global_transform.origin = passenger_spawn.global_transform.origin
			add_child(player)

		"airport_worker":
			var airport_worker_scene = preload("res://scenes/playable/airport_worker.tscn")
			var airport_worker = airport_worker_scene.instantiate()
			
			airport_worker.global_transform.origin = $job_positions/airport_worker/hgscan.global_transform.origin
			add_child(airport_worker)

			var hgscan_node = $job_positions/airport_worker/hgscan
			var bodyscan_node = $job_positions/airport_worker/bodyscan
			print("Node im World-Kontext:", hgscan_node)

			airport_worker.set_job_markers({
				"hgscan": hgscan_node,
				"bodyscan": bodyscan_node
			})

		"airline_worker":
			var airline_worker_scene = load("res://scenes/playable/airline_worker.tscn")
			var airline_worker = airline_worker_scene.instantiate()
			add_child(airline_worker)
			airline_worker.global_transform.origin = airlinew_spawn.global_transform.origin

			var schalter_node := $job_positions/airline_worker/schalter
			var gate_node := $job_positions/airline_worker/gate
			airline_worker.set_job_markers({
				"schalter": schalter_node,
				"gate": gate_node
			})
			
		_:
			push_error("no acceptable role!")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	timer1 += delta
	timer2 += delta
	if timer1 >= npc_passenger_spawn_interval:
		timer1 = 0
		spawn_npc("passenger") # spawn a passenger
	if timer2 >= npc_customer_spawn_interval:
		timer2 = 0
		spawn_npc("customer") # spawn a customer
		

func spawn_npc(npc_type: String):
	if npc_type == "passenger":
		for i in npc_passengers_per_spawn:
			npc_passenger_scene = load("res://scenes/npc_passenger.tscn")
			var passenger = npc_passenger_scene.instantiate()
			passenger.global_transform.origin = npc_passenger_spawn + offset
			get_parent().add_child(passenger)
			
	elif npc_type == "customer":
		for i in npc_customer_per_spawn:
			npc_customer_scene = load("res://scenes/npc_customer.tscn")
			var customer = npc_customer_scene.instantiate()
			customer.global_transform.origin = npc_customer_spawn + offset
			get_parent().add_child(customer)

			# Pfad sammeln aus CustomerPaths Node
			var markers := $customer_path.get_children()
			var path: Array = []

			for marker in markers:
				if marker is Marker3D:
					path.append(marker.global_transform.origin)

			# Pfad an Customer übergeben
			customer.set_path(path)

			get_parent().add_child(customer)
