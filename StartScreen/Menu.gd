extends Control

func _ready():
	$CanvasLayer/Start.pressed.connect(_on_start_pressed)
	$CanvasLayer/Load.pressed.connect(_on_load_pressed)
	$CanvasLayer/Quit.pressed.connect(_on_quit_pressed)

func _on_start_pressed():
	# Replace with your tutorial/overworld scene path
	get_tree().change_scene_to_file("res://Overworld/over_world.tscn")

func _on_load_pressed():
	# You can load saved data here (basic version for now)
	print("Load Game pressed (functionality coming soon)")

func _on_quit_pressed():
	get_tree().quit()
