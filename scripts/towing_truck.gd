extends RigidBody3D

@export var speed := 10.0
@export var turn_speed := 1.5

var is_controlled := false
var player: Node3D = null

@onready var driver_seat_area := $tractor/driver_seat_area

func _ready():
	# Optional: Spielergruppe vorausgesetzt
	driver_seat_area.body_entered.connect(_on_driver_area_entered)
	driver_seat_area.body_exited.connect(_on_driver_area_exited)

func _on_driver_area_entered(body):
	if body.is_in_group("player"):
		player = body
		#player.show_hint("E: Fahrzeug fahren", self)

func _on_driver_area_exited(body):
	if body == player:
		player = null
		#player.hide_hint(self)

func _unhandled_input(event):
	if event.is_action_pressed("interact") and player:
		is_controlled = true
		player.visible = false # Spieler verstecken
		#player.hide_hint(self)
		print("Fahrzeug wird jetzt gesteuert")

func _physics_process(delta):
	if not is_controlled:
		return

	var input_dir = Vector3.ZERO
	if Input.is_action_pressed("ui_up"):
		input_dir.z -= 1
	if Input.is_action_pressed("ui_down"):
		input_dir.z += 1
	if Input.is_action_pressed("ui_left"):
		rotation.y += turn_speed * delta
	if Input.is_action_pressed("ui_right"):
		rotation.y -= turn_speed * delta

	if input_dir != Vector3.ZERO:
		var move = -transform.basis.z
		apply_central_force(move * speed * 100)
