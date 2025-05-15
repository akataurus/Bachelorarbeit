extends CharacterBody3D

@export var speed := 2.0
var path0: Array = []
var path_index := 0

func set_path(p: Array):
	path0 = p
	path_index = 0

func _physics_process(delta):
	if path_index >= path0.size():
		queue_free()
		return

	var direction = (path0[path_index] - global_transform.origin).normalized()
	velocity = direction * speed
	move_and_slide()

	if global_transform.origin.distance_to(path0[path_index]) < 0.1:
		print("Customer angekommen bei", path0[path_index])
		path_index += 1
