extends Node
class_name TurnManager

var units = []  # Player-controlled units
var enemies = []  # Enemy-controlled units
var current_turn_index = 0
var is_player_turn = true

func _ready():
	units = get_tree().get_nodes_in_group("player_units")
	enemies = get_tree().get_nodes_in_group("enemy_units")
	start_player_turn()

func start_player_turn():
	is_player_turn = true
	current_turn_index = 0
	print("✅ Player Turn Start!")

func start_enemy_turn():
	is_player_turn = false
	current_turn_index = 0
	print("🚨 Enemy Turn Start!")

	for enemy in enemies:
		enemy.take_turn()

	start_player_turn()

func end_turn():
	current_turn_index += 1

	if is_player_turn:
		if current_turn_index >= units.size():
			start_enemy_turn()
		else:
			print("Next player unit's turn!")
	else:
		if current_turn_index >= enemies.size():
			start_player_turn()
