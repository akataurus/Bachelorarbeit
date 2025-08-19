# airport worker skript
# Basic movement and camera: https://www.youtube.com/watch?v=sVsn9NqpVhg
# Level editor: https://www.youtube.com/watch?v=BUjCtwLO0S8
# model source: https://www.mixamo.com/#/?page=2&type=Character
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
var pending_npc_for_manual_check = null

var pending_npc_for_body_scan = null
var current_body_scanner = null
var body_scan_pending_decision = false

@onready var anim_player = $worker_model/AnimationPlayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()
	twist_pivot = get_node("TwistPivot")
	pitch_pivot = get_node("TwistPivot/PitchPivot")
	camera = get_node("TwistPivot/PitchPivot/Camera3D")
	curr_character_model = $worker_model
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	if area:
		area.body_entered.connect(_on_body_entered)
		area.body_exited.connect(_on_body_exited)
	
	hint_label.visible = false # label ausblenden
	hint_label.self_modulate = Color(1, 0, 0)  # Rot (RGB)
	
	ready_completed = true
	var library = AnimationLibrary.new()
	library.add_animation("idle", load("res://assets/animations/happy_idle.res"))
	library.add_animation("walk", load("res://assets/animations/walking.res"))


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
		
	if pending_npc_hand_luggage and not body_scan_pending_decision:
		show_hint("Accept hand luggage: J | Reject hand luggage: N", self)
		
		if Input.is_action_just_pressed("luggage_accept"):  # J-Taste
			accept_hand_luggage()
		elif Input.is_action_just_pressed("luggage_reject"):  # N-Taste
			reject_hand_luggage()
	
	# Body Scanner Start
	if pending_npc_for_body_scan and not body_scan_pending_decision:
		show_hint("Start body scan: E", self)
		
		if Input.is_action_just_pressed("interact"):  # B-Taste
			start_body_scan()

	# body Scanner entscheidung nach scan
	if body_scan_pending_decision:
		show_hint("Body scan result - Accept: J | Reject: N", self)
		
		if Input.is_action_just_pressed("luggage_accept"):
			accept_body_scan()
		if Input.is_action_just_pressed("luggage_reject"):
			reject_body_scan()
			
	if pending_npc_for_manual_check:
		show_hint("Manual body check - Accept: J | Reject: N", self)
		if Input.is_action_just_pressed("luggage_accept"):
			accept_manual_check()
		if Input.is_action_just_pressed("luggage_reject"):
			reject_manual_check()
		
	if input_vector.length() > 0.1:
		if anim_player.current_animation != "walk":
			anim_player.play("walking")
	else:
		if anim_player.current_animation != "idle":
			anim_player.play("happy_idle")


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
	
# ========== BODY SCANNER MANAGEMENT ==========
func set_pending_body_scan(npc: Node, scanner: Node):
	"""Wird vom Body Scanner aufgerufen wenn NPC wartet"""
	pending_npc_for_body_scan = npc
	current_body_scanner = scanner
	print("Airport Worker: NPC wartet am Körperscanner")

func start_body_scan():
	print("Airport Worker: Startet Körperscanner")
	
	if current_body_scanner and current_body_scanner.has_method("start_body_scan"):
		current_body_scanner.start_body_scan(pending_npc_for_body_scan)
	
	hide_hint(self)

func set_body_scan_decision(npc: Node, scanner: Node):
	"""Wird aufgerufen wenn NPC durch Scanner gelaufen ist und auf Entscheidung wartet"""
	pending_npc_for_body_scan = npc
	current_body_scanner = scanner
	body_scan_pending_decision = true
	print("Airport Worker: NPC wartet auf Body Scan Entscheidung")

func accept_body_scan():
	print("Airport Worker: Body Scan akzeptiert!")
	
	# Grünes Feedback am Scanner
	if current_body_scanner and current_body_scanner.has_method("show_scan_feedback"):
		current_body_scanner.show_scan_feedback(true)
	
	# NPC darf weitergehen
	if pending_npc_for_body_scan and pending_npc_for_body_scan.has_method("body_scan_accepted"):
		pending_npc_for_body_scan.body_scan_accepted()
	
	# Reset
	_reset_body_scan_state()

func reject_body_scan():
	print("Airport Worker: Body Scan abgelehnt!")
	
	# Rotes Feedback am Scanner
	if current_body_scanner and current_body_scanner.has_method("show_scan_feedback"):
		current_body_scanner.show_scan_feedback(false)
	
	# NPC muss zum manuellen Check
	if pending_npc_for_body_scan and pending_npc_for_body_scan.has_method("body_scan_rejected"):
		pending_npc_for_body_scan.body_scan_rejected()
	
	# Reset
	_reset_body_scan_state()

# ========== MANUAL CHECK MANAGEMENT ==========
func set_pending_manual_check(npc: Node):
	"""Wird aufgerufen wenn NPC am Manual Check wartet"""
	pending_npc_for_manual_check = npc
	print("Airport Worker: NPC wartet am Manual Check Point")

func accept_manual_check():
	print("Airport Worker: Manual Check akzeptiert!")
	
	if pending_npc_for_manual_check and pending_npc_for_manual_check.has_method("manual_check_accepted"):
		pending_npc_for_manual_check.manual_check_accepted()
	
	pending_npc_for_manual_check = null
	hide_hint(self)

func reject_manual_check():
	print("Airport Worker: Manual Check abgelehnt!")
	
	if pending_npc_for_manual_check and pending_npc_for_manual_check.has_method("manual_check_rejected"):
		pending_npc_for_manual_check.manual_check_rejected()
	
	pending_npc_for_manual_check = null
	hide_hint(self)

func _reset_body_scan_state():
	"""Setzt alle Body Scanner Variablen zurück"""
	pending_npc_for_body_scan = null
	current_body_scanner = null
	body_scan_pending_decision = false
	hide_hint(self)

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
		pending_npc_hand_luggage.is_moving_on_belt = false
		pending_npc_hand_luggage.freeze = true
		pending_npc_hand_luggage.gravity_scale = 0
		
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
