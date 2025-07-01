extends Node3D

@onready var passenger_spawn := $spawns/passenger_spawn

@export var npc_passenger_scene: PackedScene
@export var npc_passenger_spawn_interval := 30.0
@export var npc_passengers_per_spawn := 0

#@export var npc_customer_scene: PackedScene
@export var npc_customer_spawn_interval := 50.0
@export var npc_customer_per_spawn := 1

@onready var npc_customer_scene = preload("res://scenes/npc_customer.tscn")

@onready var queue_markers := [
	$customer_path/Marker3D,
	$customer_path/Marker3D2,
	$customer_path/Marker3D3,
	$customer_path/Marker3D4
]

var queue_slots := []

var timer1 := 0.0
var timer2 := 0.0

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
			var hgscan_node = $customer_path/job_positions/airport_worker/hgscan
			var bodyscan_node = $customer_path/job_positions/airport_worker/bodyscan
			
			airport_worker.global_transform.origin = hgscan_node.global_transform.origin
			add_child(airport_worker)
			
			airport_worker.set_job_markers({
				"hgscan": hgscan_node,
				"bodyscan": bodyscan_node
			})
			print("Spieler-Skriptpfad:", airport_worker.get_script().resource_path)


		"airline_worker":
			var airline_worker_scene = load("res://scenes/playable/airline_worker.tscn")
			var airline_worker = airline_worker_scene.instantiate()
			var schalter_node := $customer_path/job_positions/airline_worker/schalter
			var gate_node := $customer_path/job_positions/airline_worker/gate
			
			airline_worker.global_transform.origin = schalter_node.global_transform.origin
			add_child(airline_worker)
			
			airline_worker.set_job_markers({
				"schalter": schalter_node,
				"gate": gate_node
			})

		_:
			push_error("no acceptable role!")
	#spawn_customer() #testzwecke

func _process(delta: float) -> void:
	timer1 += delta
	timer2 += delta

	if timer1 >= npc_passenger_spawn_interval:
		timer1 = 0
		spawn_passenger()

	if timer2 >= npc_customer_spawn_interval:
		timer2 = 0
		spawn_customer()

func spawn_passenger():
	for i in npc_passengers_per_spawn:
		var passenger = npc_passenger_scene.instantiate()
		passenger.global_transform.origin = passenger_spawn.global_transform.origin
		add_child(passenger)

func spawn_customer():
	for i in npc_customer_per_spawn:
		if queue_slots.size() >= queue_markers.size():
			print("Schlange voll!")
			return

		var customer = npc_customer_scene.instantiate()
		
		var target_marker = queue_markers[queue_slots.size()]
		queue_slots.append(customer)
		add_child(customer)

		# Zusätzlich: Pfad sammeln (optional, falls sie nachher weiterlaufen sollen)
		var markers := $customer_path.get_children()
		var path: Array = []
		for marker in markers:
			if marker is Marker3D:
				path.append(marker.global_transform.origin)

		if customer.has_method("set_path"):
			customer.set_path(path)
