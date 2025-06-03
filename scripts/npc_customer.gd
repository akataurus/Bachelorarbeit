extends CharacterBody3D

@export var speed := 2.0
var path := []
var current_path_index := 0
var waiting = false
const wait_at_index := 5


func _ready():
	call_deferred("_post_ready")
	print("NPC ready, CollisionShape vorhanden?: ", $CollisionShape3D)

# wegen timing issues
func _post_ready(): 
	pass

# von world.gd aufgerufen
func set_path(p: Array):
	path = p
	current_path_index = 0
	waiting = false

# von einem worker aufgerufen
func resume_from_wait():
	waiting = false
	
func _physics_process(delta):
	if path.is_empty() or waiting:
		return
	
	var target_pos = path[current_path_index]
	var direction = target_pos - global_position
	direction.y = 0

	# Wenn nah genug -> anhalten
	if direction.length() < 0.1:
		current_path_index += 1
		if current_path_index == wait_at_index:
			waiting = true
			print("wartet am Schalter")
			return
		if current_path_index >= path.size():
			waiting = true
			velocity = Vector3.ZERO
			print("npc hat ende erreicht")
			return
	else:
		velocity = direction.normalized() * speed

	move_and_slide()

	# Rotation zur Bewegungsrichtung
	if velocity.length() > 0.01:
		var target_yaw = atan2(velocity.x, velocity.z)
		var current_yaw = rotation.y
		rotation.y = lerp_angle(current_yaw, target_yaw, 5 * delta)
