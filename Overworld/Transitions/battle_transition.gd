extends Node2D


func _physics_process(delta):
	if Input.is_action_pressed("ui_page_up"):
		get_tree().change_scene_to_file("res://tactical_grid_movement/grid_movement.tscn")
	if Input.is_action_pressed("ui_page_down"):
		get_tree().change_scene_to_file("res://demo_turn_based_combat_/scenes/battle_scene2.tscn")
