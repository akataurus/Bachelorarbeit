extends RigidBody3D

var path: Array[Vector3] = []
var current_index := 0
var speed := 2.0
var is_walking := false
var player_reference: Node3D
var is_paused = false

# aufgerufen von hgscan.gd
func start_walk_path(p: Array[Vector3]):
	path = p
	current_index = 0
	is_walking = true
	
func set_player(player: Node3D):
	player_reference = player

func _physics_process(delta: float) -> void:
	if is_walking:
		if is_paused:
			$speech_bubble.visible = true
		else:
			$speech_bubble.visible = false
	
	
	if !is_walking or path.is_empty() or is_paused:
		return
	
	var target = path[current_index]
	var direction = target - global_position
	direction.y = 0
	
	if direction.length() < 0.1:
		# --- Pausiere am 3. Marker (Index 2) ---
		if current_index == 2:
			is_paused = true
			linear_velocity = Vector3.ZERO
			$speech_bubble.text = "Inspecting your hand luggage..."
			$speech_bubble.visible = true
			await get_tree().create_timer(3).timeout
			$speech_bubble.visible = false
			is_paused = false
			current_index += 1
			return
		
		current_index += 1
		if current_index >= path.size():
			is_walking = false
			linear_velocity = Vector3.ZERO
			look_at_player(player_reference)
			$"../Cube".man_scan_result()
			$speech_bubble.visible = true
			return
	else:
		var move_dir = direction.normalized()
		linear_velocity.x = move_dir.x * speed
		linear_velocity.z = move_dir.z * speed
		linear_velocity.y = 0
		# NPC drehen
		var yaw = atan2(move_dir.x, move_dir.z) + PI
		rotation.y = lerp_angle(rotation.y, yaw, 5 * delta)

func look_at_player(player: Node3D):
	rotation.y = deg_to_rad(-180)
