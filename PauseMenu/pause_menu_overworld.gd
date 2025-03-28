extends CanvasLayer


func _ready():
	visible = false

func _input(event):
	if event.is_action_pressed("pause"):
		visible = true
		get_tree().paused = true

func _on_resume_pressed():
	print("⬆️ Resume button clicked")
	get_tree().paused = false
	visible = false
func _on_settings_pressed():
	print("⚙️ Settings button clicked (not implemented yet)")

func _on_quit_pressed():
	print("❌ Quit button clicked")	
	get_tree().paused = false
	visible = false
	get_tree().change_scene_to_file("res://StartScreen/StartMenu.tscn")
