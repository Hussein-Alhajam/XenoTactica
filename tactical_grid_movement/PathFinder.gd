extends Node
class_name PathFinder

@export var path_visualizer: Line2D  # Assign the Line2D in the Inspector
@export var grid_manager: GridManager
var astar_grid: AStarGrid2D
var tile_size: int = 80  # Dynamically updated from TileMap

func setup_astar(tile_map: TileMapLayer):
	if tile_map == null:
		print("❌ ERROR: No TileMap provided to PathFinder!")
		return
	astar_grid = AStarGrid2D.new()
	astar_grid.region = tile_map.get_used_rect()
	astar_grid.cell_size = Vector2(tile_size, tile_size)
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar_grid.update()
	# Mark unwalkable tiles
	for x in range(astar_grid.region.size.x):
		for y in range(astar_grid.region.size.y):
			var tile_position = Vector2i(x + astar_grid.region.position.x, y + astar_grid.region.position.y)
			var tile_data = tile_map.get_cell_tile_data(tile_position)  # Ensure correct layer access
			if tile_data == null or tile_data.get_custom_data("walkable") == false:
				astar_grid.set_point_solid(tile_position)

# 🔹 Finds a path between start and target
func find_path(start_tile: Vector2i, target_tile: Vector2i) -> Array:
	if astar_grid == null:
		print("❌ ERROR: AStarGrid2D not initialized!")
		return []
	if not is_in_bounds(start_tile) or not is_in_bounds(target_tile):
		print("❌ Path request out of bounds!")
		return []
	var path = astar_grid.get_id_path(start_tile, target_tile)

	# 🔹 Ensure path does not include the start tile in calculations
	if path.size() > 1:
		return path
	else:
		return []

# 🔹 Ensures a tile is inside the grid region bounds
func is_in_bounds(tile: Vector2i) -> bool:
	if astar_grid == null:
		return false
	var grid_rect = Rect2i(astar_grid.region.position, astar_grid.region.size)
	return grid_rect.has_point(tile)
# 🔹 Checks if a tile is walkable (not blocked)
func is_tile_walkable(tile: Vector2i) -> bool:
	if astar_grid == null or not is_in_bounds(tile):
		return false
	return not astar_grid.is_point_solid(tile)

func draw_path(path: Array):
	if path.is_empty():
		return
	var line := Line2D.new()
	line.width = 5
	line.default_color = Color(1, 1, 1, 1)  # White line
	# Clear previous lines
	for child in grid_manager.get_children():
		if child is Line2D:
			child.queue_free()
	# Add each tile's center to the path
	for tile in path:
		var world_position = grid_manager.tile_map.map_to_local(tile)
		var centered_position = world_position + Vector2(grid_manager.tile_size / 2, grid_manager.tile_size / 2)
		line.add_point(centered_position)
	grid_manager.add_child(line)
 # Center points

func clear_path():
	if path_visualizer:
		path_visualizer.clear_points()
