# this script is 'autoloaded' in settings, meaning it can be 
# accessed from every other script in the project
extends Node


func display_number(value: int, position: Vector2): # maybe pass a color param?
	#print("damage" + str(value))
	var number_label: Label = Label.new()
	number_label.global_position = position

	number_label.z_index = 5
	number_label.label_settings = LabelSettings.new()
	
	if value > 0: 
		number_label.text = "+" + str(value)
		number_label.label_settings.font_color = "#00FF00"
	else:
		number_label.text = str(value)
		number_label.label_settings.font_color = "#FF0000"
#	
	number_label.label_settings.font_size = 24
	number_label.label_settings.outline_color = "#000"
	number_label.label_settings.outline_size = 1
	
	call_deferred("add_child", number_label)
	
	await number_label.resized
	number_label	.pivot_offset = Vector2(number_label.size / 2)
	
	var tween = get_tree().create_tween()
	tween.set_parallel(true)
	tween.tween_property(
		number_label, "position:y", number_label.position.y - 24, 0.25
	).set_ease(Tween.EASE_OUT)
	tween.tween_property(
		number_label, "position:y", number_label.position.y, 0.5
	).set_ease(Tween.EASE_IN).set_delay(0.25)
	tween.tween_property(
		number_label, "scale", Vector2.ZERO, 0.25
	).set_ease(Tween.EASE_IN).set_delay(0.5)
	
	await tween.finished
	number_label.queue_free()
