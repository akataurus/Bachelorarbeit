# https://www.cgtrader.com/items/5849643/download-page
# Skript fürs Handgepäck. Das Handgepäck kann man auf den Hgscanner legen.
extends RigidBody3D

@export var pickup_distance := 3  # Maximale Distanz zum Aufheben

var player = null
var is_held = false  # Ob der Koffer aktuell getragen wird
var drop_target = null # speichert drop Ziel falls erkannt wird
var is_dropping = false # workaround für drop() und _on_body_exited()

var is_moving_on_belt = false 
var belt_direction := Vector3.BACK # Richtung der Bewegung
var belt_speed := 1.5 # Geschwindigkeit für Bewegung

var is_in_hgscan_range = false

@onready var scanner_exit := get_tree().root.find_child("luggage_stop", true, false)

@onready var area := $Area3D
@onready var hint := $CanvasLayer/Label


func _ready():
	
	await get_tree().create_timer(0.1).timeout  # Wartet 0.1 Sekunden
	if area and area is Area3D:
		area.body_entered.connect(_on_body_entered)
		area.body_exited.connect(_on_body_exited)
	if scanner_exit:
		scanner_exit.body_entered.connect(_on_scanner_exit_body_entered)
	else:
		print("Fehler: area ist null oder kein Area3D! (ready)")
	


func _process(delta):
	if is_moving_on_belt:
		position += belt_direction * belt_speed * delta
		return # keine Eingabe möglich wenn koffer in Bewegung
	

	if player and Input.is_action_just_pressed("hg_interact"):
		if is_held:
			drop()
		else:
			pick_up()
	

# für das stoppen des handgepäcks
func _on_scanner_exit_body_entered(body):
	if body.is_in_group("hand_luggage"):
		is_moving_on_belt = false
		if drop_target and drop_target.is_in_group("hgscan"):
			drop_target.get_parent().update_feedback()

func _on_body_entered(body):
	# Prüft, ob der Spieler in den Bereich tritt
	if body.is_in_group("player"):  
		player = body
		if is_held:
			if is_in_hgscan_range: 
				player.show_hint("Drop hand luggage on scanner: F", self)
			else:
				player.show_hint("Drop hand luggage: F", self)
		else:
			player.show_hint("Pick up hand luggage: F", self)
		
	elif body.is_in_group("hgscan"):
		drop_target = body
		is_in_hgscan_range = true


func _on_body_exited(body):
	if is_dropping: # ignoriere wegen drop
		return

	if body == player:
		player.hide_hint(self)
		# Überprüfe, ob der Spieler wirklich weit genug entfernt ist
		if body.global_transform.origin.distance_to(global_transform.origin) > pickup_distance:
			player = null
			


	if body == drop_target:
		if body.is_in_group("hgscan"):
			is_in_hgscan_range = false
		drop_target = null


func pick_up():
	if player and player.global_transform:
		if player.global_transform.origin.distance_to(global_transform.origin) < pickup_distance:
			is_held = true
			if drop_target and drop_target.is_in_group("waage"):
				drop_target.get_parent().set_optcontainer_visible(false) # minigame
			drop_target = null # reset beim aufheben
			
			# Physik einfrieren
			freeze = true  # Verhindert Bewegung
			linear_velocity = Vector3.ZERO
			angular_velocity = Vector3.ZERO
			
			reparent(player)  # Koffer wird zum Kind des Spielers
			global_transform = player.global_transform
			position += Vector3(0, 0, 1)  # Hebt den Koffer etwas an
	else:
		print("player ist null oder hat kein global_transform")


func drop():
	is_dropping = true
	is_held = false
	freeze = false # Physik wieder aktivieren
	
	if is_instance_valid(drop_target):
		var drop_position = drop_target.get_parent().get_drop_position()
		global_transform.origin = drop_position
		global_rotation = Vector3(deg_to_rad(90), 0, 0)
		# koffer wurde auf ziel abgelegt
		if drop_target.is_in_group("hgscan"):
			is_moving_on_belt = true
			
		
	reparent(get_tree().current_scene)  #Entfernt Koffer aus Spielerhierarchie
	is_dropping = false
