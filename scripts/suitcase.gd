# source: https://www.cgtrader.com/items/2877263/download-page
extends RigidBody3D

@export var pickup_distance := 3  # Maximale Distanz zum Aufheben

var player = null
var is_held = false  # Ob der Koffer aktuell getragen wird
var drop_target = null # speichert drop Ziel falls erkannt wird
var is_dropping = false # workaround für drop() und _on_body_exited()

var is_in_counter_range = false # jewels für hint
var is_in_scale_range = false

var weight: float = 0.0 # gewicht des Koffers
var weight_limit = 20.0 # kein Koffer darf weight_limit überschreiten

var is_moving_on_belt = false 
var belt_direction := Vector3.BACK # Richtung der Bewegung
var belt_speed := 2 # Geschwindigkeit für Bewegung

@onready var area := $Area3D
@onready var hint := $CanvasLayer/pickup_hint


@onready var scanner_exit := get_tree().root.find_child("suitcase_stop", true, false)

func _ready():
	await get_tree().create_timer(0.1).timeout  # Wartet 0.1 Sekunden
	if area and area is Area3D:
		area.body_entered.connect(_on_body_entered)
		area.body_exited.connect(_on_body_exited)
	if scanner_exit and scanner_exit is Area3D:
		scanner_exit.body_entered.connect(_on_counter_exit_body_entered)
	else:
		print("Fehler: area ist null oder kein Area3D! (ready)")
	
	randomize()
	weight = snapped(randf_range(10.0, 30.0), 0.01) # zwei Nachkommastellen


func _process(delta):
	if is_moving_on_belt:
		linear_velocity += belt_direction * belt_speed * delta
		return # keine Eingabe möglich wenn koffer in Bewegung
	
	if player and Input.is_action_just_pressed("interact"):
		if is_held:
			drop()
		else:
			pick_up()
	# für hint
	if player:	
		if is_held:
			if is_in_counter_range:
				player.show_hint("Drop luggage on counter: E", self)
				#hint.text = "Drop luggage on counter: E"
			elif is_in_scale_range:
				player.show_hint("Drop luggage on scale: E", self)
			else:
				player.show_hint("Drop luggage: E", self)
		else:
			if is_in_scale_range:
				player.show_hint("Start minigame: G\nSelect: Space\nPick up luggage: E", self)
			else:
				player.show_hint("Pick up luggage: E", self)


func _on_counter_exit_body_entered(body):
	if body == self:
		is_moving_on_belt = false
		if drop_target and drop_target.get_parent().has_method("update_feedback"):
			drop_target.get_parent().update_feedback(weight < weight_limit)


func _on_body_entered(body):
	# Prüft, ob der Spieler in den Bereich tritt
	if body.is_in_group("player"):  
		player = body
	# Prüft, ob der Koffer sich in Schalternähe befindet
	elif body.is_in_group("schalter"):  
		drop_target = body
		is_in_counter_range = true
		
	elif body.is_in_group("waage"):
		drop_target = body
		is_in_scale_range = true


func _on_body_exited(body):
	if is_dropping: # ignoriere wegen drop
		return
	
	if body == player and player:
		player.hide_hint(self)
		# Überprüfe, ob der Spieler wirklich weit genug entfernt ist
		if body.global_transform.origin.distance_to(global_transform.origin) > pickup_distance:
			player = null
		if drop_target and drop_target.is_in_group("waage"):
			drop_target.get_parent().set_optcontainer_visible(false) # minigame
	
	if body == drop_target:
		
		if body.is_in_group("schalter"):
			is_in_counter_range = false
		if body.is_in_group("waage"):
			is_in_scale_range = false
			drop_target.get_parent().set_label_text(0.0)
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
			position += Vector3(1, 1, 0)  # Hebt den Koffer etwas an
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
	
		#bewegung aktivieren
		#drop_target.get_parent().update_feedback(weight < weight_limit)
		if drop_target.is_in_group("schalter"):
			is_moving_on_belt = true
		
	if is_in_scale_range:
		drop_target.get_parent().set_label_text(weight)
		drop_target.get_parent().set_optcontainer_visible(true) # minigame
		
	reparent(get_tree().current_scene)  #Entfernt den Koffer aus der Spielerhierarchie
	
	is_dropping = false
