# airline worker skript

extends "res://scripts/playable_scripts/player_base.gd"

@onready var area := $Area3D
@onready var speech_bubble := $Label3D # für die worker um mit npcs zu reden

var airline_job_markers = {}
var airline_job_order := ["schalter", "gate"]

var curr_job_index := 0
var curr_customer_at_counter: Node = null

@onready var hint_label :=$CanvasLayer/Hint_label
var active_hints := {} # alle aktiven hints 

var speech_counter = 0 # um zu wissen, welcher Text angezeigt werden soll
var pending_npc_suitcase = null # Der Koffer, der auf Entscheidung wartet
var pending_npc = null # der zugehörige npc

@onready var anim_player := $business_man_walk/AnimationPlayer
@onready var anim_player2 := $business_man_walk/AnimationPlayer2


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	twist_pivot = get_node("TwistPivot")
	pitch_pivot = get_node("TwistPivot/PitchPivot")
	camera = get_node("TwistPivot/PitchPivot/Camera3D")
	super._ready()
	curr_character_model = $airline_worker

	if area:
		area.body_entered.connect(_on_body_entered)
		area.body_exited.connect(_on_body_exited)
	
	hint_label.visible = false # label ausblenden
	hint_label.self_modulate = Color(1, 0, 0)  # Rot (RGB)
	
	anim_player.get_animation("walking").loop = true
	ready_completed = true


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	super._process(delta)
	
	if Input.is_action_just_pressed("next_job"):
		teleport_to_job(self, 1)
		dialogue("") # Text löschen bei teleport
	if Input.is_action_just_pressed("previous_job"):
		teleport_to_job(self, -1)
		dialogue("") # Text löschen bei teleport
	
	if Input.is_action_just_pressed("interact") and curr_job_index == 0:
		match speech_counter % 3: 
			0:
				show_hint("Check in customer: E", self)
				dialogue("Hello, ID please!")
			1:
				show_hint("Finish check in: E", self)
				dialogue("Thanks, I'm checking you in...")
			2:
				hide_hint(self)
				dialogue("Alright, you are checked in. \n Go to the security check now please.")

	if curr_customer_at_counter:
		pass
		#show_hint("ID check: E", self)
	else:
		hide_hint(self)
	
	if pending_npc_suitcase:
		show_hint("Accept luggage: J | Reject luggage: N", self)
		
		if Input.is_action_just_pressed("luggage_accept"):
			accept_luggage()
		elif Input.is_action_just_pressed("luggage_reject"):
			reject_luggage()

# aufgerufen von world.gd
func set_job_markers(markers: Dictionary):
	airline_job_markers = markers

# up_down gibt an ob man zum nächsten job oder zu dem davor teleportiert
func teleport_to_job(player: Node3D, up_down: int):
	curr_job_index = (curr_job_index + up_down) % airline_job_order.size()
	var job_name = airline_job_order[curr_job_index]
	var marker = airline_job_markers.get(job_name, null)
	
	if marker:
		player.global_position = marker.global_position
	else:
		print("problem bei airline teleport")

func teleport_to_previous_job(player: Node3D):
	curr_job_index = (curr_job_index -1) % airline_job_order.size()

func _on_body_entered(body):
	if body.is_in_group("schalter"):
		show_hint("Ausweis vorzeigen: R", self)
		# hier Ausweiskontrolle implementieren!

func _on_body_exited(body):
	if body.is_in_group("schalter"):
		hide_hint(self)

func set_curr_customer(customer):
	curr_customer_at_counter = customer
	#show_hint("Customer ist ", curr_customer_at_counter)

# Methoden für die hints
func show_hint(text: String, owner: Node):
	if text == "Pick up luggage: E":
		pass
	active_hints[owner] = text
	update_hint()

func hide_hint(owner: Node):
	active_hints.erase(owner)
	update_hint()

func update_hint():
	var combined = ""
	for hint in active_hints.values():
		combined += hint + "\n"
	hint_label.text = combined.strip_edges()
	hint_label.visible = active_hints.size() > 0

# dialog mit kunde am schalter
# dialog mit kunde am schalter
func dialogue(text: String):
	if curr_customer_at_counter:
		# 1. Worker spricht
		speech_bubble.text = text
		await get_tree().create_timer(2.0).timeout  # Worker Text 2 Sekunden anzeigen
		speech_bubble.text = ""
		# 2. Kurze Pause zwischen den Sprechern
		await get_tree().create_timer(0.5).timeout
		# 3. Customer antwortet (und warten bis Customer fertig ist)
		await curr_customer_at_counter.dialogue(speech_counter)

		speech_counter += 1
		if speech_counter >= 3:
			speech_counter = 0



func accept_luggage():
	print("Airline Worker: Koffer akzeptiert!")
	
	if pending_npc_suitcase and is_instance_valid(pending_npc_suitcase):
		# Koffer weiter auf Fließband bewegen
		pending_npc_suitcase.is_moving_on_belt = true
		pending_npc_suitcase.freeze = false
		
		# Grünes Feedback
		if pending_npc_suitcase.has_meta("target_schalter"):
			var schalter = pending_npc_suitcase.get_meta("target_schalter")
			if schalter.has_method("npc_update_feedback"):
				schalter.npc_update_feedback(true)  # Grün
	
	# NPC darf weitergehen
	if pending_npc and pending_npc.has_method("luggage_accepted"):
		pending_npc.luggage_accepted()
	
	# Reset
	pending_npc_suitcase = null
	pending_npc = null
	hide_hint(self)
	
	
func reject_luggage():
	print("Airline Worker: Koffer abgelehnt!")
	
	if pending_npc_suitcase and is_instance_valid(pending_npc_suitcase):
		# Rotes Feedback
		if pending_npc_suitcase.has_meta("target_schalter"):
			var schalter = pending_npc_suitcase.get_meta("target_schalter")
			if schalter.has_method("npc_update_feedback"):
				schalter.npc_update_feedback(false)  # Rot
	
	# NPC muss Koffer mitnehmen und abhauen
	if pending_npc and pending_npc.has_method("luggage_rejected"):
		pending_npc.luggage_rejected()
	
	# Reset
	pending_npc_suitcase = null
	pending_npc = null
	hide_hint(self)
	
func set_pending_luggage(suitcase: Node, npc: Node):
	"""Wird vom Schalter aufgerufen wenn NPC-Koffer wartet"""
	pending_npc_suitcase = suitcase
	pending_npc = npc
	print("Airline Worker: Koffer wartet auf Entscheidung von ", npc.name)
