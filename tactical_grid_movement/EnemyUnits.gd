extends CharacterBody2D
class_name EnemyUnit

@export var move_range: int = 3
@export var attack_range: int = 1
@export var grid_manager: GridManager
@export var turn_manager: TurnManager

var player_units = []
var is_moving = false

func _ready():
	player_units = get_tree().get_nodes_in_group("player_units")

func take_turn():
	print("🚨 Enemy Turn: Thinking...")

	var closest_player = find_closest_player()
	if closest_player:
		move_towards(closest_player)

func find_closest_player():
	var closest = null
	var closest_distance = INF

	for unit in player_units:
		var distance = global_position.distance_to(unit.global_position)
		if distance < closest_distance:
			closest_distance = distance
			closest = unit

	return closest

func move_towards(target):
	var enemy_tile = grid_manager.tile_map.local_to_map(global_position)
	var player_tile = grid_manager.tile_map.local_to_map(target.global_position)
	
	var path = grid_manager.get_walkable_tiles(enemy_tile, move_range)

	if player_tile in path:
		attack(target)
		return
	
	if path.size() > 1:
		var next_tile = path[0]
		move_to_tile(next_tile)

func move_to_tile(target_tile):
	if is_moving:
		return
	is_moving = true

	var world_position = grid_manager.tile_map.map_to_local(target_tile)
	
	var tween = get_tree().create_tween()
	tween.tween_property(self, "global_position", world_position, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_callback(Callable(self, "end_turn"))

func attack(target):
	print("💥 Enemy attacks", target.name)
	target.take_damage(10)
	end_turn()

func end_turn():
	is_moving = false
	turn_manager.end_turn()
