extends CharacterBody2D

func _physics_process(delta):
	move_and_slide()
	
	if velocity.x > 0:
		$Sprite2D.flip_h = true
	else:
		$Sprite2D.flip_h = false
