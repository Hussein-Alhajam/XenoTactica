extends Node2D


func _physics_process(delta):
	if Input.is_action_pressed("ui_home"):
		get_tree().change_scene_to_file("res://tactical_grid_movement/grid_movement.tscn")
