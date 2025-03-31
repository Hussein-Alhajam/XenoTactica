extends CanvasLayer

func _ready():
	visible = false

func _input(event):
	if event.is_action_pressed("pause"):
		print("✅ ESC pressed (pause` triggered)")
		get_tree().paused = true
		visible = true

func _on_resume_pressed():
	get_tree().paused = false
	visible = false
	
func _on_settings_pressed():
	print("⚙️ Settings clicked (not implemented yet)")
	
func _on_flee_pressed():
	get_tree().paused = false
	visible = false
	print("🏃‍♀️ Player fled!")
	get_tree().change_scene_to_file("res://Overworld/over_world.tscn")
