extends CharacterBody2D
class_name EnemyUnit

@export var pathfinder: PathFinding
@export var grid_manager: GridManager
@export var move_range: int = 3
@export var move_speed: float = 100.0
@export var attack_range: int = 1

var is_moving = false

func _ready():
	if grid_manager == null:
		grid_manager = get_tree().get_first_node_in_group("grid_manager")
	if pathfinder == null:
		pathfinder = get_tree().get_first_node_in_group("pathfinder")
	print("✅ EnemyUnit ready.")

func _process(_delta):
	if !is_moving:
		act()

func act():
	var my_tile = grid_manager.tile_map.local_to_map(global_position)
	var closest_player = null
	var shortest_path = []
	var min_distance = INF

	# Get occupied tiles: other enemies + player units
	var occupied_tiles = []
	for enemy in get_tree().get_nodes_in_group("enemy_units"):
		if enemy != self:
			var enemy_tile = grid_manager.tile_map.local_to_map(enemy.global_position)
			occupied_tiles.append(enemy_tile)

	for player in get_tree().get_nodes_in_group("player_units"):
		var player_tile = grid_manager.tile_map.local_to_map(player.global_position)
		occupied_tiles.append(player_tile)

	# Tell the pathfinder to treat them as obstacles
	pathfinder.update_obstacles(occupied_tiles)

	# Find closest player using updated pathfinder
	for player in get_tree().get_nodes_in_group("player_units"):
		var player_tile = grid_manager.tile_map.local_to_map(player.global_position)
		var path = pathfinder.find_path(my_tile, player_tile)
		print("🧭 Path from", my_tile, "to", player_tile, ":", path)
		if path.size() > 1 and path.size() < min_distance:
			closest_player = player
			shortest_path = path
			min_distance = path.size()

# Only proceed if a valid path was found
		if shortest_path.size() <= 1:
			print("❌ Path to player blocked or invalid.")
			return

# ✅ Now check if in range
		if shortest_path.size() <= attack_range + 1:
			print("🛑 Enemy is in range, can attack.")
			return


func follow_path(path: Array):
	is_moving = true
	for tile in path:
		var world_pos = grid_manager.tile_map.map_to_local(tile)
		while global_position.distance_to(world_pos) > 1.0:
			var direction = (world_pos - global_position).normalized()
			velocity = direction * move_speed
			move_and_slide()
			await get_tree().process_frame
		global_position = world_pos
	velocity = Vector2.ZERO
	await get_tree().create_timer(1.0).timeout
	is_moving = false
	print("✅ Enemy moved to:", path[-1])
