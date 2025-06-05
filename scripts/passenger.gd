# Basic movement and camera: https://www.youtube.com/watch?v=sVsn9NqpVhg
# Level editor: https://www.youtube.com/watch?v=BUjCtwLO0S8
# model (woman): https://rigmodels.com/model.php?view=Business_Woman-3d-model__9TPXMJCKKPSP3PYW9Y119709R
# model (man): https://www.cgtrader.com/items/2578203/download-page
# boarding pass pic source: https://www.wa.gov.au/media/32906
extends RigidBody3D

var mouse_sensitivity := 0.001 # speed at wich the camera rotates
var twist_input := 0.0 # how much mouse has moved horizontally each frame
var pitch_input := 0.0 # how much mouse has moved vertically each frame

@onready var area := $Area3D
@onready var boarding_card := $boarding_card

@onready var twist_pivot := $TwistPivot
@onready var pitch_pivot := $TwistPivot/PitchPivot

@onready var curr_character_model
@onready var turn_speed := 5.0 # wie schnell modell zur laufrichtung dreht 

@onready var passenger_role = false
@onready var airport_role = false # true je nach GameManager.role
@onready var airline_role = false

@onready var hint_label := $CanvasLayer/Hint_label
var active_hints := {} # alle aktiven hints 

var job_markers = {}
var job_order := ["hgscan", "bodyscan"]

var airline_job_markers = {}
var airline_job_order := ["schalter", "gate"]

var curr_job_index := 0

var curr_customer_at_counter: Node = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	match GameManager.role:
		"passenger":
			curr_character_model = $character
			passenger_role = true
		"airport_worker":
			curr_character_model = $AuxScene
			airport_role = true
		"airline_worker":
			curr_character_model = $airline_worker	
			airline_role = true
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	if area:
		area.body_entered.connect(_on_body_entered)
		area.body_exited.connect(_on_body_exited)
	
	hint_label.visible = false # label ausblenden
	hint_label.self_modulate = Color(1, 0, 0)  # Rot (RGB)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	var input := Vector3.ZERO
	input.x = Input.get_axis("ui_left", "ui_right")
	input.z = Input.get_axis("ui_up", "ui_down")
	
	apply_central_force(twist_pivot.basis * input * 20)

	if Input.is_action_just_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if Input.is_action_just_pressed("show_bcard") and passenger_role:
		show_boarding_card()
		
	if Input.is_action_just_pressed("next_job") and !passenger_role:
		teleport_to_job(self, 1)
	if Input.is_action_just_pressed("previous_job") and !passenger_role:
		teleport_to_job(self, -1)
	
	if Input.is_action_just_pressed("interact") and airline_role and curr_customer_at_counter:
		print("hier")

	twist_pivot.rotate_y(twist_input)
	pitch_pivot.rotate_x(pitch_input)
	# limit viewing
	pitch_pivot.rotation.x = clamp(pitch_pivot.rotation.x,-0.5,0.5)
	#stop camera when mouse stops
	twist_input = 0.0
	pitch_input = 0.0
	
	# Begrenze maximale Geschwindigkeit
	if linear_velocity.length() > 5.0:
		linear_velocity = linear_velocity.normalized() * 5.0

	# Dreht das modell, wenn der spieler sich in ein richtung bewegt
	if input.length() > 0.1:
		var movement_dir = (twist_pivot.basis * input).normalized()
		# Ziel-Rotation berechnen (Y-Rotation zur Bewegungsrichtung)
		var target_rotation = atan2(movement_dir.x, movement_dir.z)
		# airline_worker zum Ziel drehen (glatt über interpolate_angle)
		var current_yaw = curr_character_model.rotation.y
		var new_yaw = lerp_angle(current_yaw, target_rotation, turn_speed * delta)
		
		curr_character_model.rotation.y = new_yaw

func set_job_markers(markers: Dictionary):
	if airport_role:
		job_markers = markers
		print("Job markers erhalten:", job_markers)
		print("Marker selbst:", job_markers.get("hgscan"))
	if airline_role:
		airline_job_markers = markers
		print("Job markers erhalten:", airline_job_markers)
		print("Marker selbst:", airline_job_markers.get("schalter"))

# up_down gibt an ob man zum nächsten job oder zu dem davor teleportiert
func teleport_to_job(player: Node3D, up_down: int):
	if airport_role:
		curr_job_index = (curr_job_index + up_down) % job_order.size()
		var job_name = job_order[curr_job_index]
		var marker = job_markers.get(job_name, null)
		
		if marker:
			player.global_position = marker.global_position
		else:
			print("problem bei airport teleport")
	
	if airline_role:
		curr_job_index = (curr_job_index + up_down) % airline_job_order.size()
		var job_name = airline_job_order[curr_job_index]
		var marker = airline_job_markers.get(job_name, null)
		
		if marker:
			player.global_position = marker.global_position
		else:
			print("problem bei airline teleport")

func teleport_to_previous_job(player: Node3D):
	curr_job_index = (curr_job_index -1) % job_order.size()

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
	show_hint("Customer ist ", curr_customer_at_counter)

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
	
func show_boarding_card():
	if GameManager.is_checked_in:
		boarding_card.visible = true
		await get_tree().create_timer(5).timeout  # Delay in Sekunden
		boarding_card.visible = false
