extends State
class_name Enemy_Attack

@export var enemy: CharacterBody2D
@export var attack_range := 10.0

var player: CharacterBody2D = null

func Enter():
	player = get_tree().get_first_node_in_group("player")  # Get player reference
	print("Enemy entered ATTACK state")

func Update(delta: float):
	if player:
		var distance = enemy.global_position.distance_to(player.global_position)
		if distance > attack_range:
			Transitioned.emit(self, "chase")  # Go back to chasing if player moves away

func Physics_Update(delta: float):
	if player:
		var direction = (player.global_position - enemy.global_position).normalized()
		enemy.velocity = direction * attack_range  # Simulates lunging attack
		enemy.move_and_slide()
		
		# Check if enemy collides with player to trigger battle
		if enemy.global_position.distance_to(player.global_position) < 5:
			trigger_battle()

func trigger_battle():
	print("Enemy attacks player! Transitioning to battle scene.")
	get_tree().change_scene_to_file("res://demo_turn_based_combat_/scenes/battle_scene.tscn")

func _on_detection_zone_body_exited(body):
	if body == player:
		player = null
		Transitioned.emit(self, "idle")
