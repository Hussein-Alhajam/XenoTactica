extends State
class_name Enemy_Chase

@export var enemy: CharacterBody2D
@export var move_speed := 100.0

var player: CharacterBody2D

func Enter():
	player = get_tree().get_first_node_in_group("player")  # Get player reference

		

func Physics_Update(delta: float):
	var direction = (player.global_position - enemy.global_position)
	
	if direction.length()>25:
		enemy.velocity = direction.normalized() * move_speed
	else:
		enemy.velocity = Vector2()
	
	if direction.length()>50:
		Transitioned.emit(self, "idle")
	if direction.length()>5:
		Transitioned.emit(self, "attack")
