extends CharacterBody3D

@export var speed := 2.0
@export var target_position: Vector3

var path0 := [Vector3(10, 0, 0), Vector3(0, 5, 0), Vector3(5, 0, 0)]
var path_index = 0

func _physics_process(delta: float) -> void:
	if path_index >= path0.size():
		queue_free()
		return
	
	var direction = (path0[path_index] - global_transform.origin).normalized()
	velocity = direction * speed
	move_and_slide()
	
	if global_transform.origin.distance_to(path0[path_index]) < 0.1:
		print("angekommen")
		path_index = path_index +1
		#queue_free() # npc verschwindet
	

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
