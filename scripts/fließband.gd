extends Node3D

@onready var conveyor_area = $Area3D2
var direction := Vector3.FORWARD # z.B. Vector3.FORWARD = Vector3(0, 0, -1)
var force_strength := 1.0

func _ready():
	conveyor_area.body_entered.connect(_on_body_entered)
	conveyor_area.body_exited.connect(_on_body_exited)

var bodies_on_belt: Array = []

func _on_body_entered(body):
	if body is RigidBody3D and not bodies_on_belt.has(body):
		bodies_on_belt.append(body)

func _on_body_exited(body):
	bodies_on_belt.erase(body)

func _physics_process(delta):
	for body in bodies_on_belt:
		if is_instance_valid(body):
			# Lokale Richtung in Weltkoordinaten
			var global_dir = global_transform.basis * direction
			body.apply_central_force(global_dir.normalized() * force_strength)
