extends Node2D

@onready var label: Label = $Label
@export var ToOverworld: String = "res://Overworld/over_world.tscn"

var in_range = false  # Tracks if the player is within the interactive zone

func _ready():
	label.visible = false

func _process(delta: float):
	# Only check input if the player is in range
	if in_range:
		# If the user pressed E or space (ui_accept or ui_interact)
		if Input.is_action_just_pressed("interact"):
			print("Starting tutorial battle now!")
			get_tree().change_scene_to_file(ToOverworld)

func _on_interactive_zone_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		label.visible = true
		in_range = true  # player is inside the zone

func _on_interactive_zone_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		label.visible = false
		in_range = false  # player left the zone
