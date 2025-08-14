extends MeshInstance3D

# Array mit optionen 
var option_nodes := []
var current_index := 0
var highlight_timer := 0.05 # sekunden zwischen den Wechseln
var timer := 0.0
var is_active = false # für das animieren 
var is_selecting = false

var last_selection_time := 0.0 # für selection delay
var selection_cooldown := 0.9  # Sekunden zwischen zwei Auswahlaktionen


@onready var drop_position := $baggage_pos
@onready var weight_label := $Label3D
@onready var optcontainer := $"../optionContainer"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	drop_position = get_node_or_null("baggage_pos")
	if drop_position == null:
		print("drop_position ist null!")
	weight_label.text = ("0.0 kg")
	optcontainer.visible = false
	set_process(true)
	
	option_nodes = [
		get_node_or_null("../optionContainer/plus1"),
		get_node_or_null("../optionContainer/plus2"),
		get_node_or_null("../optionContainer/minus2"),
		get_node_or_null("../optionContainer/minus3"),
		get_node_or_null("../optionContainer/minus5"),
		get_node_or_null("../optionContainer/minus3_2"),
		get_node_or_null("../optionContainer/minus2_2"),
		get_node_or_null("../optionContainer/plus2_2"),
		get_node_or_null("../optionContainer/plus1_2")
	]


func _unhandled_input(event: InputEvent) -> void:
	
	if event.is_action_pressed("start_game"):
		start_minigame()



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not is_active:
		return
		
	timer += delta
	if timer >= highlight_timer:
		timer = 0.0
		cycle_option()
	
	var now = Time.get_ticks_msec() / 1000.0
	if Input.is_action_just_pressed("test_button") and now - last_selection_time > selection_cooldown:
		last_selection_time = now
		select_option(current_index)

func get_drop_position():
	return drop_position.global_transform.origin + Vector3(0, 0, 0)

func set_label_text(text):
	weight_label.text = str(var_to_str(text), " kg")

func set_optcontainer_visible(visible: bool):
	if optcontainer:
		optcontainer.visible = visible


func start_minigame():
	is_active = true
	current_index = 0
	timer = 0.0

func cycle_option():
	for i in option_nodes.size():
		set_option_highlighted(option_nodes[i], i == current_index)

	current_index = (current_index + 1) % option_nodes.size()

func select_option(index):
	
	if is_selecting:
		print("returned")
		return
	is_selecting = true
	print("called")
	await get_tree().create_timer(selection_cooldown).timeout
	is_selecting = false
	is_active = false
	cycle_option() # zur syncronisation
	var node = option_nodes[index]
	var weight_change = node.get_meta("weight_change")  # z. B. -2 oder 0
	
	print("weight_change: ", weight_change)
	if weight_change != null:
		# Auf Koffer zugreifen und Gewicht anpassen
		#var luggage = get_node("/root/world/suitcase")  
		var luggage_list = get_tree().get_nodes_in_group("suitcase")
		var luggage = luggage_list[0]
		print("weigt vorher: ", luggage.weight)
		luggage.weight = max(luggage.weight + weight_change, 0)
		set_label_text(luggage.weight)
		print("weight nachher: ", luggage.weight)
	

func set_option_highlighted(node, is_selected):
	if node == null:
		print("⚠️ node ist null – wird übersprungen.")
		return

	if node is Label:
		node.self_modulate = Color(1, 1, 0) if is_selected else Color(1, 1, 1)
	elif node.has_method("set_emission_enabled"):
		node.set_emission_enabled(is_selected)
