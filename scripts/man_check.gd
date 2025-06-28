# skript für den manuellen security check

extends Node3D

@onready var area := $Area3D

func _ready() -> void:
	area.monitoring = false 
	await get_tree().create_timer(0.1).timeout
	area.monitoring = true

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		print("testi hehe")
