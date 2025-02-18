# Basic movement and camera: https://www.youtube.com/watch?v=sVsn9NqpVhg
# Level editor: https://www.youtube.com/watch?v=BUjCtwLO0S8
extends RigidBody3D

var mouse_sensitivity := 0.001 # speed at wich the camera rotates
var twist_input := 0.0 # how much mouse has moved horizontally each frame
var pitch_input := 0.0 # how much mouse has moved vertically each frame

@onready var twist_pivot := $TwistPivot
@onready var pitch_pivot := $TwistPivot/PitchPivot

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	

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
