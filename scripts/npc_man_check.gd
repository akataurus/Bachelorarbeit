# skript des npcs der am man sec check arbeitet
extends RigidBody3D

var path: Array[Vector3] = []
var current_index := 0
var speed := 2.0
var is_walking := false
var player_reference: Node3D

# aufgerufen von man_check.gd
func start_walk_path(p: Array[Vector3]):
	path = p
	current_index = 0
	is_walking = true
# aufgerufen von man_check.gd
func set_player(player: Node3D):
	player_reference = player


func _physics_process(delta: float) -> void:
	if !is_walking or path.is_empty():
		return
	
	var target = path[current_index]
	var direction = target - global_position
	direction.y = 0
	
	if direction.length() < 0.1:
		current_index += 1
		if current_index >= path.size():
			is_walking = false
			linear_velocity = Vector3.ZERO
			look_at_player(player_reference)
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
	var to_player = (player.global_position - global_position).normalized()
	var target_yaw = atan2(to_player.x, to_player.z)
	rotation.y = target_yaw
