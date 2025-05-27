extends Node3D

@onready var airline_worker := $airline_worker
@onready var worker_shape := $airline_worker/CollisionShape3D
@onready var speech_bubble := $"airline_worker".get_node("speech_bubble")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if GameManager.role != "passenger":
		airline_worker.visible = false
		worker_shape.disabled = true
	
	speech_bubble.text = "Welcome to the gate! \n Please show your boarding ticket."
	speech_bubble.visible = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("show_bcard"):
		boarding_card_dialogue()



func boarding_card_dialogue():
	if !GameManager.is_checked_in:
		speech_bubble.text = "Oh no, you are not checked in yet! \n Please go to the counter and check in."
	if GameManager.is_checked_in and !GameManager.is_sec_checked:
		speech_bubble.text = "Oh no, you weren't at the security check! \n Please go there first."
	if GameManager.is_checked_in and GameManager.is_sec_checked:
		speech_bubble.text = "Thanks! You can go on board now."

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		speech_bubble.visible = true

func _on_area_3d_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		speech_bubble.visible = false
