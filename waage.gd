extends MeshInstance3D

@onready var drop_position := $baggage_pos
@onready var weight_label := $Label3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	drop_position = get_node_or_null("baggage_pos")
	if drop_position == null:
		print("drop_position ist null!")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func get_drop_position():
	return drop_position.global_transform.origin + Vector3(0, 0, 0)

func set_label_text(text):
	var newtext = str(var_to_str(text), " kg")
	weight_label.text = newtext
