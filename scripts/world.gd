extends Node3D

@onready var passenger_spawn := $spawns/passenger_spawn # empty Nodes as starting position
@onready var airportw_spawn := $spawns/airportw_spawn # die 3 hier sind für spieler
@onready var airlinew_spawn := $spawns/airlinew_spawn

@export var npc_passenger_scene: PackedScene
@export var npc_passenger_spawn:= Vector3(0,0,0)
@export var npc_passenger_spawn_interval := 20.0 # alle 3 Sekunden neuer npc
@export var npc_passengers_per_spawn := 3 # anzahl der auf einmal gespawnten npcs

@export var npc_customer_scene: PackedScene
@export var npc_customer_spawn:= Vector3(0, 0, 0)
@export var npc_customer_spawn_interval := 15.0
@export var npc_customer_per_spawn := 3
# damit npcs nicht komplett aufeinander spawnen:
var offset := Vector3(randf_range(-2, 2), 0, randf_range(-2, 2)) 

var timer1 := 0.0
var timer2 := 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if GameManager.role == "passenger":
		print("player is passenger")
	if GameManager.role == "airport_worker":
		print("player is airport worker")
	if GameManager.role == "airline_worker":
		print("player is airline worker")

	match GameManager.role:
		"passenger":
			var player_scene = load("res://scenes/playable/passenger.tscn")
			var player = player_scene.instantiate()
			player.global_transform.origin = passenger_spawn.global_transform.origin
			add_child(player)
		"airport_worker":
			var player_scene = load("res://scenes/playable/airport_worker.tscn")
			var player = player_scene.instantiate()
			add_child(player)
			player.global_transform.origin = airportw_spawn.global_transform.origin
		"airline_worker":
			var player_scene = load("res://scenes/playable/airline_worker.tscn")
			var player = player_scene.instantiate()
			add_child(player)
			player.global_transform.origin = airlinew_spawn.global_transform.origin
		_:
			push_error("no acceptable role!")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	timer1 += delta
	timer2 += delta
	if timer1 >= npc_passenger_spawn_interval:
		timer1 = 0
		spawn_passenger("passenger") # spawn a passenger
	if timer2 >= npc_customer_spawn_interval:
		timer2 = 0
		spawn_passenger("customer") # spawn a customer
		

func spawn_passenger(npc_type: String):
	if npc_type == "passenger":
		for i in npc_passengers_per_spawn:
			print("spawning passenger")
			npc_passenger_scene = load("res://scenes/npc_passenger.tscn")
			var passenger = npc_passenger_scene.instantiate()
			passenger.global_transform.origin = npc_passenger_spawn + offset
			get_parent().add_child(passenger)
			
	if npc_type == "customer":
		for i in npc_customer_per_spawn:
			print("spawning customer")
			npc_customer_scene = load("res://scenes/npc_customer.tscn")
			var customer = npc_customer_scene.instantiate()
			customer.global_transform.origin = npc_customer_spawn + offset
			get_parent().add_child(customer)
