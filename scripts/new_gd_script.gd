# Basic movement and camera: https://www.youtube.com/watch?v=sVsn9NqpVhg
# Level editor: https://www.youtube.com/watch?v=BUjCtwLO0S8
extends RigidBody3D

var mouse_sensitivity := 0.001 # speed at wich the camera rotates
var twist_input := 0.0 # how much mouse has moved horizontally each frame
var pitch_input := 0.0 # how much mouse has moved vertically each frame

@onready var area := $Area3D

@onready var twist_pivot := $TwistPivot
@onready var pitch_pivot := $TwistPivot/PitchPivot

@onready var hint_label := $CanvasLayer/Hint_label
var active_hints := {} # alle aktiven hints 

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
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
	
	apply_central_force(twist_pivot.basis * input * 1200.0 * delta)

	if Input.is_action_just_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	twist_pivot.rotate_y(twist_input)
	pitch_pivot.rotate_x(pitch_input)
	# limit viewing
	pitch_pivot.rotation.x = clamp(pitch_pivot.rotation.x,-0.5,0.5)
	#stop camera when mouse stops
	twist_input = 0.0
	pitch_input = 0.0

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
