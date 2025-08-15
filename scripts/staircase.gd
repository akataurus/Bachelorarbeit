# Staircase Skript
extends Node3D

@onready var npc_airline_worker := $Player
@onready var speech_bubble := $Player/speech_bubble

func _ready() -> void:
	speech_bubble.text = "Welcome, have a nice flight!"
	speech_bubble.visible = false

func _process(delta: float) -> void:
	if !GameManager.is_checked_in:
		speech_bubble.text = "Oh no, you are not checked in yet! \n Please go to the counter and check in."
	elif !GameManager.is_hgscan_checked:
		speech_bubble.text = "Oh no, you need to get your hand luggage checked first!"
	elif !GameManager.is_bodyscan_checked:
		speech_bubble.text = "Oh no, you need to go through the bodyscan first!"
	elif !GameManager.is_boarded:
		speech_bubble.text = "Please got to the gate first!"
	elif GameManager.is_checked_in and GameManager.is_hgscan_checked and GameManager.is_bodyscan_checked and GameManager.is_boarded:
		speech_bubble.text = "Thanks! You can go through to the plane now."


func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") and body != npc_airline_worker:
		speech_bubble.visible = true

func _on_area_3d_body_exited(body: Node3D) -> void:
	if body.is_in_group("player") and body != npc_airline_worker:
		speech_bubble.visible = false


func _on_finish_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		if GameManager.is_checked_in and GameManager.is_hgscan_checked and GameManager.is_bodyscan_checked and GameManager.is_boarded:
			get_tree().change_scene_to_file("res://scenes/UI/end_screen.tscn")
