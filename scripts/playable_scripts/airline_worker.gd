
extends "res://scripts/playable_scripts/player_base.gd"

@onready var area := $Area3D
@onready var speech_bubble := $Label3D # für die worker um mit npcs zu reden

var airline_job_markers = {}
var airline_job_order := ["schalter", "gate"]

var curr_job_index := 0
var curr_customer_at_counter: Node = null

var speech_counter = 0 # um zu wissen, welcher Text angezeigt werden soll

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	curr_character_model = $airline_worker

	if area:
		area.body_entered.connect(_on_body_entered)
		area.body_exited.connect(_on_body_exited)
	
	hint_label.visible = false # label ausblenden
	hint_label.self_modulate = Color(1, 0, 0)  # Rot (RGB)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:

	
		
	if Input.is_action_just_pressed("next_job"):
		teleport_to_job(self, 1)
		dialogue("") # Text löschen bei teleport
	if Input.is_action_just_pressed("previous_job"):
		teleport_to_job(self, -1)
		dialogue("") # Text löschen bei teleport
	
	if Input.is_action_just_pressed("interact") and curr_job_index == 0:
		match speech_counter % 3: 
			0:
				dialogue("Hello, ID please!")
			1:
				dialogue("Thanks, I'm checking you in...")
			2:
				dialogue("Alright, you are checked in. \n Go to the security check now please.")

	if curr_customer_at_counter:
		show_hint("ID check: E", self)
	else:
		hide_hint(self)


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

# camera movement
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			twist_input = - event.relative.x * mouse_sensitivity
			pitch_input = - event.relative.y * mouse_sensitivity

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
func dialogue(text: String):
	if curr_customer_at_counter:
		speech_bubble.text = text
		await get_tree().create_timer(0.5).timeout
		curr_customer_at_counter.dialogue(speech_counter)
		speech_counter += 1
		await get_tree().create_timer(2).timeout  # Delay in Sekunden
		speech_bubble.text = ""
