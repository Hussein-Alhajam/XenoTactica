extends Node2D


@onready var label = $Label
var current_line = 0

func _ready():
	label.visible = false

func _on_interactive_zone_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		label.visible = false

func _on_interactive_zone_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		label.visible = true
