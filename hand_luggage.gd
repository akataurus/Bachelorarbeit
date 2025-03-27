# https://www.cgtrader.com/items/5849643/download-page
# Skript fürs Handgepäck. Das Handgepäck kann man auf den Hgscanner legen.
extends Node3D

@export var pickup_distance := 3  # Maximale Distanz zum Aufheben

var player = null
var is_held = false  # Ob der Koffer aktuell getragen wird
var drop_target = null # speichert drop Ziel falls erkannt wird
var is_dropping = false # workaround für drop() und _on_body_exited()

var is_in_hgscan_range = false

@onready var area := $BP10_world/BP10_geo/Area3D
@onready var hint := $BP10_world/BP10_geo/CanvasLayer/Label


func _ready():
	print("📦 Suitcase ready: ", name, " in scene: ", get_tree().current_scene.name)
	for node in get_tree().get_nodes_in_group("suitcase"):
		print("🎒 Gefundener Koffer:", node.name)
	await get_tree().create_timer(0.1).timeout  # Wartet 0.1 Sekunden
	if area and area is Area3D:
		area.body_entered.connect(_on_body_entered)
		area.body_exited.connect(_on_body_exited)
	else:
		print("Fehler: area ist null oder kein Area3D! (ready)")
	
	hint.visible = false # label ausblenden
	hint.self_modulate = Color(1, 0, 0)  # Rot (RGB)

func _process(delta):
	if player and Input.is_action_just_pressed("hg_interact"):
		if is_held:
			drop()
		else:
			pick_up()
	# für hint
	if is_held:
		if is_in_hgscan_range: 
			hint.text = "Drop hand luggage on scanner: F"
		else:
			hint.text = "Drop hand luggage: F"
	else:
		hint.text = "Pick up hand luggage: F"


func _on_body_entered(body):
	# Prüft, ob der Spieler in den Bereich tritt
	if body.is_in_group("player"):  
		player = body
		hint.visible = true
		
	elif body.is_in_group("hgscan"):
		drop_target = body
		is_in_hgscan_range = true

func _on_body_exited(body):
	if is_dropping: # ignoriere wegen drop
		return
	
	if body == player:
		hint.visible = false
		# Überprüfe, ob der Spieler wirklich weit genug entfernt ist
		if body.global_transform.origin.distance_to(global_transform.origin) > pickup_distance:
			player = null
			hint.visible = false
	
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
			reparent(player)  # Koffer wird zum Kind des Spielers
			global_transform = player.global_transform
			position += Vector3(1, 0, 0)  # Hebt den Koffer etwas an
	else:
		print("player ist null oder hat kein global_transform")


func drop():
	is_dropping = true
	
	is_held = false
	if is_instance_valid(drop_target):
		var drop_position = drop_target.get_parent().get_drop_position()
		global_transform.origin = drop_position
		global_rotation = Vector3(deg_to_rad(90), 0, 0)
		# koffer wurde auf ziel abgelegt
	else: 
		position += Vector3(0, -1, 0) #Lässt Koffer auf Boden fallen
	# Gewicht prüfen
		
	reparent(get_tree().current_scene)  #Entfernt den Koffer aus der Spielerhierarchie
	
	is_dropping = false
