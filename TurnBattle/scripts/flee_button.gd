extends Button


func _on_pressed() -> void:
		#owner.set_status("flee")
		get_tree().change_scene_to_file("res://Overworld/over_world.tscn")
