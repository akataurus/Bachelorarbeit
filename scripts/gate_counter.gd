extends Node3D

@onready var airline_worker := $airline_worker
@onready var worker_shape := $airline_worker/CollisionShape3D
@onready var speech_bubble := $"airline_worker".get_node("speech_bubble")
@onready var anim_player := $airline_worker/Walking/AnimationPlayer

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
	if anim_player.current_animation != "happy_idle":
		anim_player.play("happy_idle")


func boarding_card_dialogue():
	print("boarding card dialogue called")
	print("GameManager.is_checked_in: ", GameManager.is_checked_in)
	print("GameManager.is_hgscan_checked: ", GameManager.is_hgscan_checked)
	print("GameManager.is_bodyscan_checked: ", GameManager.is_bodyscan_checked)
	print("GameManager.is_checked_in: ", GameManager.is_checked_in)
	if !GameManager.is_checked_in:
		speech_bubble.text = "Oh no, you are not checked in yet! \n Please go to the counter and check in."
	elif !GameManager.is_hgscan_checked:
		speech_bubble.text = "Oh no, you need to get your hand luggage checked first!"
	elif !GameManager.is_bodyscan_checked:
		speech_bubble.text = "Oh no, you need to go through the bodyscan first!"
	elif GameManager.is_checked_in and GameManager.is_hgscan_checked and GameManager.is_bodyscan_checked:
		speech_bubble.text = "Thanks! You can go through to the plane now."
		GameManager.is_boarded = true

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		speech_bubble.visible = true

func _on_area_3d_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		speech_bubble.visible = false
