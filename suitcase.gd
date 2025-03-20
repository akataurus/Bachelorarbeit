extends Node3D

@export var pickup_distance := 1.5  # Maximale Distanz zum Aufheben

var player = null
var is_held = false  # Ob der Koffer aktuell getragen wird
var drop_target = null # speichert Schalter falls erkannt wird

@onready var area := $Suitcase/Area3D
@onready var hint := $CanvasLayer/pickup_hint

func _ready():
	await get_tree().create_timer(0.1).timeout  # Wartet 0.1 Sekunden
	if area and area is Area3D:
		area.body_entered.connect(_on_body_entered)
		area.body_exited.connect(_on_body_exited)
	else:
		print("Fehler: area ist null oder kein Area3D! (ready)")
	
	hint.visible = false # label ausblenden
	# Ändere die Textfarbe direkt mit self_modulate
	hint.self_modulate = Color(1, 0, 0)  # Rot (RGB)


func _on_body_entered(body):
	print("_on_body_entered: ", body.name)
	if body.is_in_group("player"):  # Prüft, ob der Spieler in den Bereich tritt
		print("spieler in range")
		player = body
		hint.visible = true
		
	elif body.is_in_group("schalter"):  # Prüft, ob der Koffer sich in Schalternähe befindet
		print("📦 Schalter erkannt, kann Koffer darauf ablegen")
		drop_target = body.get_parent()

func _on_body_exited(body):
	if body == player:
		# Überprüfe, ob der Spieler wirklich weit genug entfernt ist
		if body.global_transform.origin.distance_to(global_transform.origin) > pickup_distance:
			player = null
			print("body exited")
			hint.visible = false
			
	#elif body == drop_target:
	#	if body.global_transform.origin.distance_to(global_transform.origin) > pickup_distance:
	#		drop_target = null
	#		print("schalterbereich verlassen")

func _process(delta):
	if player and Input.is_action_just_pressed("interact"):
		if is_held:
			drop()
		else:
			pick_up()

func pick_up():
	if player and player.global_transform:
		if player.global_transform.origin.distance_to(global_transform.origin) < pickup_distance:
			is_held = true
			reparent(player)  # Koffer wird zum Kind des Spielers
			global_transform = player.global_transform
			position += Vector3(1, 0, 0)  # Hebt den Koffer etwas an
			hint.text = "Drop luggage: E"
	else:
		print("player ist null oder hat kein global_transform")

func drop():
	is_held = false
	reparent(get_tree().current_scene)  # Entfernt den Koffer aus der Spielerhierarchie
	print("drop_target (drop): ", drop_target)
	if drop_target:
		var drop_position = drop_target.get_drop_position()
		global_transform.origin = drop_position
		global_rotation = Vector3(deg_to_rad(90), 0, 0)  # Koffer um 90° nach vorne kippen
		print("koffer auf schalter gelegt")
		
	else: 
		position += Vector3(0, -1, 0)  # Lässt den Koffer wieder auf den Boden fallen
	
	hint.text = "Pick up luggage: E"
