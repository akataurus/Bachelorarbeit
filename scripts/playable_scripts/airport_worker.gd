# airport worker skript
# Basic movement and camera: https://www.youtube.com/watch?v=sVsn9NqpVhg
# Level editor: https://www.youtube.com/watch?v=BUjCtwLO0S8
# model (woman): https://rigmodels.com/model.php?view=Business_Woman-3d-model__9TPXMJCKKPSP3PYW9Y119709R
# model (man): https://www.cgtrader.com/items/2578203/download-page
# boarding pass pic source: https://www.wa.gov.au/media/32906
extends "res://scripts/playable_scripts/player_base.gd"

@onready var area := $Area3D
@onready var speech_bubble := $Label3D # für die worker um mit npcs zu reden

var job_markers = {}
var job_order := ["hgscan", "bodyscan", "man_check", "loading", "unloading"]

var curr_job_index := 0

var speech_counter = 0 # um zu wissen, welcher Text angezeigt werden soll
@onready var hint_label := $CanvasLayer/Hint_label
var active_hints := {} # alle aktiven hints 

var pending_npc_hand_luggage = null
var pending_npc_for_hand_luggage = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()
	twist_pivot = get_node("TwistPivot")
	pitch_pivot = get_node("TwistPivot/PitchPivot")
	camera = get_node("TwistPivot/PitchPivot/Camera3D")
	curr_character_model = $AuxScene
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	if area:
		area.body_entered.connect(_on_body_entered)
		area.body_exited.connect(_on_body_exited)
	
	hint_label.visible = false # label ausblenden
	hint_label.self_modulate = Color(1, 0, 0)  # Rot (RGB)
	
	ready_completed = true


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	super._process(delta)
	var input := Vector3.ZERO
	input.x = Input.get_axis("ui_left", "ui_right")
	input.z = Input.get_axis("ui_up", "ui_down")
	
	apply_central_force(twist_pivot.basis * input * 20)

	if Input.is_action_just_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
		
	if Input.is_action_just_pressed("next_job"):
		teleport_to_job(self, 1)
	if Input.is_action_just_pressed("previous_job"):
		teleport_to_job(self, -1)
		
	if pending_npc_hand_luggage:
		show_hint("Accept hand luggage: J | Reject hand luggage: N", self)
		
		if Input.is_action_just_pressed("luggage_accept"):  #J-Taste
			accept_hand_luggage()
		elif Input.is_action_just_pressed("luggage_reject"):  # N-Taste
			reject_hand_luggage()

# called from world.gd
func set_job_markers(markers: Dictionary):
	job_markers = markers

# up_down gibt an ob man zum nächsten job oder zu dem davor teleportiert
func teleport_to_job(player: Node3D, up_down: int):
	curr_job_index = (curr_job_index + up_down) % job_order.size()
	var job_name = job_order[curr_job_index]
	var marker = job_markers.get(job_name, null)
	
	if marker:
		player.global_position = marker.global_position
	else:
		print("problem bei airport teleport")
	
	

func teleport_to_previous_job(player: Node3D):
	curr_job_index = (curr_job_index -1) % job_order.size()

func _on_body_entered(body):
	if body.is_in_group("towing_truck"):
		show_hint("Start truck: Q", self)

func _on_body_exited(body):
	if body.is_in_group("towing_truck"):
		hide_hint(self)

# Methoden für die hints
func show_hint(text: String, owner: Node):
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


func set_pending_hand_luggage(hand_luggage: Node, npc: Node):
	"""Wird vom Scanner aufgerufen wenn NPC-Handgepäck wartet"""
	pending_npc_hand_luggage = hand_luggage
	pending_npc_for_hand_luggage = npc
	print("Airport Worker: Handgepäck wartet auf Entscheidung von ", npc.name)

func accept_hand_luggage():
	print("Airport Worker: Handgepäck akzeptiert!")
	
	if pending_npc_hand_luggage and is_instance_valid(pending_npc_hand_luggage):
		# Handgepäck weiter bewegen
		pending_npc_hand_luggage.is_moving_on_belt = true
		pending_npc_hand_luggage.freeze = false
		
		# Grünes Feedback
		if pending_npc_hand_luggage.has_meta("target_scanner"):
			var scanner = pending_npc_hand_luggage.get_meta("target_scanner")
			if scanner.has_method("npc_update_feedback"):
				scanner.npc_update_feedback(true)
	
	# NPC darf weitergehen
	if pending_npc_for_hand_luggage and pending_npc_for_hand_luggage.has_method("hand_luggage_accepted"):
		pending_npc_for_hand_luggage.hand_luggage_accepted()
	
	# Reset
	pending_npc_hand_luggage = null
	pending_npc_for_hand_luggage = null
	hide_hint(self)

func reject_hand_luggage():
	print("Airport Worker: Handgepäck abgelehnt!")
	
	if pending_npc_hand_luggage and is_instance_valid(pending_npc_hand_luggage):
		# Rotes Feedback
		if pending_npc_hand_luggage.has_meta("target_scanner"):
			var scanner = pending_npc_hand_luggage.get_meta("target_scanner")
			if scanner.has_method("npc_update_feedback"):
				scanner.npc_update_feedback(false)
	
	# NPC muss Handgepäck mitnehmen
	if pending_npc_for_hand_luggage and pending_npc_for_hand_luggage.has_method("hand_luggage_rejected"):
		pending_npc_for_hand_luggage.hand_luggage_rejected()
	
	# Reset
	pending_npc_hand_luggage = null
	pending_npc_for_hand_luggage = null
	hide_hint(self)
