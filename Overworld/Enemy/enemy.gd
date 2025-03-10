extends CharacterBody2D

@export var move_speed := 100.0
@export var raycast: RayCast2D

func _physics_process(delta):
	if velocity.length() > 0:
		$Sprite2D.flip_h = velocity.x < 0
# Check if RayCast detects an obstacle
	if raycast and raycast.is_colliding():
		print("Obstacle detected! Adjusting movement.")
		velocity = Vector2.ZERO  # Stop movement if an obstacle is detected
	move_and_slide()
