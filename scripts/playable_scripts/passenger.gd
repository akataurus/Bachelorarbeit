# passenger script
# 3d modell source:
# https://www.fab.com/listings/4efdac7d-818f-4efd-aef3-aa6f3987ad1e
extends "res://scripts/playable_scripts/player_base.gd"

@onready var area := $Area3D
@onready var boarding_card := $boarding_card
@onready var speech_bubble := $Label3D # für die worker um mit npcs zu reden
@onready var hint_label := $CanvasLayer/Hint_label
var active_hints := {} # alle aktiven hints 
@onready var anim_player := $Sketchfab_Scene/AnimationPlayer

# Debug-Flag um intensive Ausgaben zu kontrollieren
var debug_mode := false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()
	twist_pivot = get_node("TwistPivot")
	pitch_pivot = get_node("TwistPivot/PitchPivot")
	camera = get_node("TwistPivot/PitchPivot/Camera3D")
	
	curr_character_model = $Sketchfab_Scene
	
	if area:
		area.body_entered.connect(_on_body_entered)
		area.body_exited.connect(_on_body_exited)
	
	hint_label.visible = false # label ausblenden
	hint_label.self_modulate = Color(1, 0, 0)  # Rot (RGB)
	
	boarding_card.visible = false
	ready_completed = true


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if twist_pivot == null or pitch_pivot == null:
		print("WARNUNG: Pivot-Nodes sind null, überspringe Basis-_process")
	
	super._process(delta)
	
	# Boarding Card anzeigen
	if Input.is_action_just_pressed("show_bcard"):
		show_boarding_card()
	
	# Animation basierend auf Bewegung
	if input_vector.length() > 0.1:
		if anim_player.current_animation != "walking":
			anim_player.play("walking")
	else:
		if anim_player.current_animation != "t_pose":
			anim_player.play("t_pose")

# KORRIGIERT: Funktionsnamen mit Unterstrichen
func _on_body_entered(body):
	if body.is_in_group("schalter"):
		show_hint("Ausweis vorzeigen: R", self)
		# hier Ausweiskontrolle implementieren!
	if body.is_in_group("gate_counter"):
		show_hint("Show boarding card: Right click", self)
	
func _on_body_exited(body):
	if body.is_in_group("schalter"):
		hide_hint(self)
	if body.is_in_group("gate_counter"):
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
