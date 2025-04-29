extends CharacterBody3D

@export var speed := 2.0
@export var target_position:= Vector3(5,5,5)
@export var stop_distance := 0.7 # ab wann er "am Ziel" ist

func _physics_process(delta: float) -> void:
	var direction = (target_position - global_transform.origin).normalized()
	velocity = direction * speed
	move_and_slide()
	
	if global_transform.origin.distance_to(target_position) < 0.1:
		print("angekommen")
		queue_free()
	#if direction.length() > stop_distance:
		#direction = direction.normalized()
		#velocity = direction * speed
		#move_and_slide()
	#else:
		#print("queue free")
		#queue_free() # npc verschwind

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
