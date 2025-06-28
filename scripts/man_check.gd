# skript für den manuellen security check
extends Node3D

var game_started := false

@onready var speech_bubble = $npc_airport_worker.get_node("speech_bubble")

func _ready() -> void:
	await get_tree().process_frame
	game_started = true # damit beim spawn nicht getriggert wird
	
	speech_bubble.text = "Hello, please stand on this spot."
	speech_bubble.visible = false

	var mesh_instance = $spot
	var material = mesh_instance.get_active_material(0)
	material.albedo_color = Color(0, 0, 0) # schwarz 
	
	

# große area
func _on_area_3d_body_entered(body: Node3D) -> void:
	if !game_started:
		return #ignorieren beim spawn
	
	if body.is_in_group("player"):
		speech_bubble.visible = true


func _on_area_3d_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		speech_bubble.visible = false

# kleine area vom spot
func _on_area_3d_2_body_entered(body: Node3D) -> void:
	if !body.is_in_group("player"):
		return
	
	speech_bubble.text = "Okay, stand still now."
	await get_tree().create_timer(2).timeout
	
	var path_markers := $npc_walk_path.get_children()
	var path: Array[Vector3] = []
	
	for marker in path_markers:
		if marker is Marker3D:
			path.append(marker.global_transform.origin)
	
	var npc = $npc_airport_worker
	npc.set_player(self)
	npc.start_walk_path(path as Array[Vector3])

func man_scan_result():
	var roll := randf() # Zahl zwischen 0 und 1
	if roll < 0.05:
		speech_bubble.text = "Illegal Stuff found! Go to the Police!"
	if roll < 0.20:
		speech_bubble.text = "Forbidden Stuff found! \n Please put them in the bin."
	else:
		speech_bubble.text = "Okay, all good. Proceed to the gate."
