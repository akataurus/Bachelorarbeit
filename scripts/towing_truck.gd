extends "res://scripts/playable_scripts/player_base.gd"

@export var speed := 10.0

var is_controlled := false
var player: Node3D = null

@onready var driver_seat_area := $tractor/driver_seat_area
@onready var vehicle_camera := $camera_arm/vehicle_camera



func _ready():
	#vehicle_camera.current = false
	# Optional: Spielergruppe vorausgesetzt
	driver_seat_area.body_entered.connect(_on_driver_area_entered)
	driver_seat_area.body_exited.connect(_on_driver_area_exited)
	
	var curr_character_model = $tractor  # oder $mesh oder ähnlich
	var twist_pivot = $camera_arm
	var pitch_pivot = $camera_arm
	var camera = $camera_arm/vehicle_camera


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
		player.visible = false
		#hide_hint(self)

		# Kamera aktivieren
		#vehicle_camera.current = true

		# Spieler-Kamera deaktivieren
		#var player_camera = player.get_node("TwistPivot/PitchPivot/Camera3D")
		#if player_camera:
			#player_camera.current = false
