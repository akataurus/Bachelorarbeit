extends CharacterBody3D

@export var speed := 2.0
@export var target_position: Vector3

var paths := [
	[Vector3(10, 0, 0), Vector3(0, 0, 5), Vector3(5, 0, 0)],
	[Vector3(0, 0, 10), Vector3(3, 0, 7), Vector3(5, 0, 3)],
	[Vector3(-5, 0, 5), Vector3(0, 0, 0), Vector3(5, 0, -5)]
] # some paths, where passengers move along

var path0 := []
var path_index := 0

func _ready():
	randomize()
	path0 = paths[randi() % paths.size()]  # Zufälligen Pfad auswählen

func _physics_process(delta):
	if path_index >= path0.size():
		queue_free()
		return
	
	var direction = (path0[path_index] - global_transform.origin).normalized()
	velocity = direction * speed
	move_and_slide()
	direction.y = 0 # y-anteil manuell rausnehmen
	var horizontal_direction = direction.normalized()
	
	# Rotation zur Bewegungsrichtung
	if horizontal_direction.length() > 0.01:
		var target_yaw = atan2(horizontal_direction.x, horizontal_direction.z)
		var current_yaw = rotation.y
		rotation.y = lerp_angle(current_yaw, target_yaw, 5 * delta)
	
	# Ziel erreicht?
	if global_transform.origin.distance_to(path0[path_index]) < 0.1:
		print("npc angekommen bei", path0[path_index])
		path_index += 1
