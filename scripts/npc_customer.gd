# npc customer skript
extends CharacterBody3D

@export var speed := 2.0
var path := []
var current_path_index := 0
var waiting = false
const wait_at_index := 5

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
		if current_path_index == wait_at_index:
			waiting = true
			print("wartet am Schalter")
			if not has_placed_luggage:
				place_luggage_on_scale()
			return
		if current_path_index >= path.size():
			waiting = true
			velocity = Vector3.ZERO
			print("npc hat ende erreicht")
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
	print("Spawne Koffer für NPC")
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

	print("NPC legt Koffer auf die Waage")

	# Finde den Schalter und dessen baggage_pos Marker
	var target_schalter = find_nearest_drop_position()
	if not target_schalter:
		print("❌ Schalter nicht gefunden!")
		return

	if target_schalter.has_method("get_drop_position"):
		npc_suitcase.global_position = target_schalter.get_drop_position()
		npc_suitcase.rotation = Vector3(deg_to_rad(-90), 0, 0)
		has_placed_luggage = true
		npc_suitcase.freeze = false
		npc_suitcase.gravity_scale = 0.7 # standard gravity
		npc_suitcase.is_moving_on_belt = true
		print("koffer platziert")
	else:
		print("schalter hat keine get_drop_position mehtode!")

func find_nearest_drop_position():
	var schalter_nodes = get_tree().get_nodes_in_group("schalter")
	if schalter_nodes.size() == 0:
		print("schalter nicht gefunden")
		return null

	var nearest_schalter = null
	var shortest_distance = INF

	for schalter in schalter_nodes:
		# Nur Schalter berücksichtigen, die get_drop_position() haben
		if not schalter.has_method("get_drop_position"):
			print("continued")
			continue
			
		var drop_pos = schalter.get_drop_position()
		var distance = global_position.distance_to(drop_pos)

		print("Distanz zu ", schalter.name, " drop_position: ", distance)
		
		if distance < shortest_distance:
			shortest_distance = distance
			nearest_schalter = schalter

	print("Nächstgelegener Schalter: ", nearest_schalter.name if nearest_schalter else "None")
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
	print("npc despawn")
	queue_free()
