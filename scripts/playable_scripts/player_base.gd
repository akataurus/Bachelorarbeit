# this is general stuff for movement/camera
# Basic movement and camera: https://www.youtube.com/watch?v=sVsn9NqpVhg
# Level editor: https://www.youtube.com/watch?v=BUjCtwLO0S8
# model (woman): https://rigmodels.com/model.php?view=Business_Woman-3d-model__9TPXMJCKKPSP3PYW9Y119709R
# model (man): https://www.cgtrader.com/items/2578203/download-page
# boarding pass pic source: https://www.wa.gov.au/media/32906
extends RigidBody3D
@onready var ready_completed = false
var mouse_sensitivity := 0.002
var twist_input := 0.0
var pitch_input := 0.0

var twist_pivot 
var pitch_pivot 
var camera 

@onready var curr_character_model 

@export var turn_speed := 5.0
@export var input_vector := Vector3.ZERO # für bewegung

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	if twist_pivot == null:
		twist_pivot = get_node("TwistPivot")
	if pitch_pivot == null:
		pitch_pivot = get_node("TwistPivot/PitchPivot")
	if camera == null:
		camera = get_node("TwistPivot/PitchPivot/Camera3D")

	if camera:
		camera.current = true

func _process(delta: float) -> void:
	if not ready_completed:
		return
	# --- Bewegung ---
	input_vector.x = Input.get_axis("ui_left", "ui_right")
	input_vector.z = Input.get_axis("ui_up", "ui_down")

	if input_vector != Vector3.ZERO:
		var dir = (twist_pivot.global_transform.basis * input_vector).normalized()
		apply_central_force(dir * 20)

		# Modell zur Bewegung drehen
		if curr_character_model:
			var target_yaw = atan2(dir.x, dir.z)
			var current_yaw = curr_character_model.rotation.y
			curr_character_model.rotation.y = lerp_angle(current_yaw, target_yaw, turn_speed * delta)

	# --- Kamera-Rotation ---
	twist_pivot.rotate_y(twist_input)
	pitch_pivot.rotation.x = clamp(pitch_input, -0.5, 0.5)

	# Eingabe zurücksetzen
	twist_input = 0.0
	# pitch_input NICHT zurücksetzen!

	# --- Begrenze Maximalgeschwindigkeit ---
	if linear_velocity.length() > 5.0:
		linear_velocity = linear_velocity.normalized() * 5.0
	


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		twist_input -= event.relative.x * mouse_sensitivity
		pitch_input -= event.relative.y * mouse_sensitivity
