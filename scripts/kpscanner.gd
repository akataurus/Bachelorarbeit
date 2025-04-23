extends MeshInstance3D

var player = null

@onready var indicator = $indicator
@onready var indicator2 = $indicator2 # Rückseite des Scanners
@onready var scanner_area = $Area3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Signal verbinden für _on_body_entered
	scanner_area.body_entered.connect(_on_body_entered) 

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
			material.albedo_color = Color(0, 1, 0) # Grün
			material2.albedo_color = Color(0, 1, 0) 
		else:
			material.albedo_color = Color(1, 0, 0) # Rot
			material2.albedo_color = Color(1, 0, 0) # Rot
	
	await get_tree().create_timer(2).timeout 
	material.albedo_color = Color(1, 1, 1) # Weiß
	material2.albedo_color = Color(1, 1, 1) 
