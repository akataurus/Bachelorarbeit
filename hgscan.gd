# Dieses Script wird an alle Objekte gehängt, wo man einen Koffer ablegen 
# kann. z.B. Schalter oder Hgscanner
extends Node3D

@onready var drop_position := $baggage_pos
@onready var area := $luggage_stop

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	drop_position = get_node_or_null("baggage_pos")
	if drop_position == null:
		print("drop_position ist null!")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func get_drop_position():
	return drop_position.global_transform.origin + Vector3(0, 0, 0)

func _on_body_entered(body):
	print("📦 Irgendwas hat den Scanner-Exit betreten:", body.name)

func _on_luggage_stop_body_entered(body: Node3D) -> void:
	print("hier")
	if body.is_in_group("hand_luggage"):
		print("ja bisshc")
