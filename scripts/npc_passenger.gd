extends CharacterBody3D

@export var speed := 2.0
@export var target_position:= Vector3(5,5,5)

func _physics_process(delta: float) -> void:
	var direction = (target_position - global_transform.origin).normalized()
	velocity = direction * speed
	move_and_slide()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
