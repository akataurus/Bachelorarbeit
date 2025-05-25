extends CharacterBody3D

@export var speed := 2.0

@onready var waiting = false # bewegt sich nicht wenn true

var path0: Array = []
var path_index := 0

func set_path(p: Array):
	path0 = p
	path_index = 0

func _physics_process(delta):
	if waiting:
		velocity = Vector3.ZERO
		move_and_slide()
		return
	
	if path_index >= path0.size():
		queue_free()
		return

	var direction = (path0[path_index] - global_transform.origin).normalized()
	direction.y = 0 
	var horizontal_direction = direction.normalized()
	velocity = direction * speed
	move_and_slide()
	
	# Rotation zur Bewegungsrichtung
	if horizontal_direction.length() > 0.01:
		var target_yaw = atan2(horizontal_direction.x, horizontal_direction.z)
		var current_yaw = rotation.y
		rotation.y = lerp_angle(current_yaw, target_yaw, 5 * delta)  # smooth turning

	if global_transform.origin.distance_to(path0[path_index]) < 0.1:
		print("Customer angekommen bei", path0[path_index])
		waiting = true
		path_index += 1
		
