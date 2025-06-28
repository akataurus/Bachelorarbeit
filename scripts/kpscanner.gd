extends MeshInstance3D

var player = null

@onready var indicator = $indicator
@onready var indicator2 = $indicator2 # Rückseite des Scanners
@onready var scanner_area = $Area3D
@onready var npc_airport_worker = $"../npc_airport_worker"
@onready var npc_collision_shape = npc_airport_worker.get_node("CollisionShape3D")

@onready var speech_bubble = $"../npc_airport_worker".get_node("speech_bubble")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if GameManager.role != "passenger":
		#npc_airport_worker.visible = false 
		npc_collision_shape.disabled = true
		
	# Signal verbinden für _on_body_entered
	scanner_area.body_entered.connect(_on_body_entered) 
	
	await get_tree().process_frame
	speech_bubble.text = "You can go through now."
	speech_bubble.visible = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_body_entered(body):
	var is_scan_successful := randf() < 0.5 # Wahrscheinlichkeit für grünen scan
	
	var material = indicator.get_active_material(0)
	var material2 = indicator2.get_active_material(0)
	if material == null:
		print("⚠️ Kein Material gefunden!")
		return
	
	if body.is_in_group("player"):
		if is_scan_successful:
			speech_bubble.text = "Looks good, move on please."
			material.albedo_color = Color(0, 1, 0) # Grün
			material2.albedo_color = Color(0, 1, 0) 
			GameManager.is_bodyscan_checked = true
		else:
			speech_bubble.text = "Looks like you might have something on you. \n go to the manual body scan please."
			material.albedo_color = Color(1, 0, 0) # Rot
			material2.albedo_color = Color(1, 0, 0) # Rot
	
	await get_tree().create_timer(2).timeout 
	material.albedo_color = Color(1, 1, 1) # Weiß
	material2.albedo_color = Color(1, 1, 1) 


func _on_area_3d_2_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		speech_bubble.visible = true


func _on_area_3d_2_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		speech_bubble.visible = false
