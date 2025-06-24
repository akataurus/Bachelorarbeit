# passenger script
extends "res://scripts/playable_scripts/player_base.gd"

@onready var area := $Area3D
@onready var boarding_card := $boarding_card
@onready var speech_bubble := $Label3D # für die worker um mit npcs zu reden
@onready var hint_label :=$CanvasLayer/Hint_label
var active_hints := {} # alle aktiven hints 

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()
	curr_character_model = $character
	
	if area:
		area.body_entered.connect(_on_body_entered)
		area.body_exited.connect(_on_body_exited)
	
	hint_label.visible = false # label ausblenden
	hint_label.self_modulate = Color(1, 0, 0)  # Rot (RGB)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	super._process(delta)
	
	if Input.is_action_just_pressed("show_bcard"):
		show_boarding_card()


func _on_body_entered(body):
	if body.is_in_group("schalter"):
		show_hint("Ausweis vorzeigen: R", self)
		# hier Ausweiskontrolle implementieren!

func _on_body_exited(body):
	if body.is_in_group("schalter"):
		hide_hint(self)


# Methoden für die hints
func show_hint(text: String, owner: Node):
	active_hints[owner] = text
	update_hint()

func hide_hint(owner: Node):
	active_hints.erase(owner)
	update_hint()

func update_hint():
	var combined = ""
	for hint in active_hints.values():
		combined += hint + "\n"
	hint_label.text = combined.strip_edges()
	hint_label.visible = active_hints.size() > 0
	
func show_boarding_card():
	if GameManager.is_checked_in:
		boarding_card.visible = true
		await get_tree().create_timer(5).timeout  # Delay in Sekunden
		boarding_card.visible = false
