extends State
class_name Enemy_Chase

@export var enemy: CharacterBody2D
@export var move_speed := 150.0
@onready var tile_map = $"../Map"

@onready var player: CharacterBody2D = get_tree().get_first_node_in_group("player")
var astar_grid: AStarGrid2D
var path: Array = []
var target_position: Vector2
var is_moving: bool = false

func enter():
	if player == null:
		print("ERROR: Player not found in CHASE state!")
		return
	print("Enemy entered CHASE state, tracking player!")
	if tile_map == null:
		tile_map = enemy.get_parent().find_child("Map")  # Ensure the correct node name
	if tile_map == null:
		print("ERROR: tile_map is STILL NULL after assignment! Cannot set up AStar.")
		return  # Stop execution if tile_map is missing
	setup_astar()
	update_path()

func exit():
	print("Exiting Chase state")

func setup_astar():
	if tile_map == null:
		print("ERROR: tile_map is null! Cannot set up AStar.")
		return

	astar_grid = AStarGrid2D.new()
	astar_grid.region = tile_map.get_used_rect()
	astar_grid.cell_size = Vector2(80, 80)
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar_grid.update()

	# Mark unwalkable tiles
	for x in range(tile_map.get_used_rect().size.x):
		for y in range(tile_map.get_used_rect().size.y):
			var tile_position = Vector2i(x + astar_grid.region.position.x, y + astar_grid.region.position.y)
			var tile_data = tile_map.get_cell_tile_data(tile_position)

			if tile_data == null or tile_data.get_custom_data("walkable") == false:
				astar_grid.set_point_solid(tile_position)

func update_path():
	if player == null or tile_map == null or astar_grid == null:
		return

	var enemy_pos = tile_map.local_to_map(enemy.global_position)
	var player_pos = tile_map.local_to_map(player.global_position)
	path = astar_grid.get_id_path(enemy_pos, player_pos)

	if path.size() > 1:
		target_position = tile_map.map_to_local(path[1])  # Move towards next tile
		print("New path calculated to player:", path)

func Physics_Update(delta: float):
	if player == null:
		return

	if path.size() > 1:
		var direction = (target_position - enemy.global_position).normalized()
		enemy.velocity = direction * move_speed
		enemy.move_and_slide()
		if enemy.global_position.distance_to(target_position) < 25:
			update_path()  # Get next tile in path

	# If enemy reaches the player or is one tile away, switch to attack
	var enemy_grid_pos = tile_map.local_to_map(enemy.global_position)
	var player_grid_pos = tile_map.local_to_map(player.global_position)
	if enemy_grid_pos.distance_to(player_grid_pos) == 1:
		print("Enemy is one tile away! Switching to ATTACK state.")
		Transitioned.emit(self, "attack")

func _on_detection_zone_body_exited(body):
	if body.is_in_group("player"):
		print("Player left detection zone. Returning to IDLE.")
		Transitioned.emit(self, "idle")
