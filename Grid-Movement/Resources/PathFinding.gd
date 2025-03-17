extends Node
class_name PathFinding

@export var grid_manager: GridManager
@export var path_visualizer: Line2D
var astar_grid: AStarGrid2D
var tile_size: int = 80

func setup_astar(tile_map: TileMapLayer):
	if tile_map == null:
		print("❌ ERROR: No TileMapLayer provided to PathFinder!")
		return

	print("✅ Setting up AStarGrid2D...")
	astar_grid = AStarGrid2D.new()
	astar_grid.region = tile_map.get_used_rect()
	astar_grid.cell_size = Vector2(tile_size, tile_size)
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar_grid.update()

	# Mark unwalkable tiles
	for x in range(astar_grid.region.size.x):
		for y in range(astar_grid.region.size.y):
			var tile_position = Vector2i(x + astar_grid.region.position.x, y + astar_grid.region.position.y)
			var tile_data = tile_map.get_cell_tile_data(tile_position) # Layer 0 by default
			if tile_data == null or tile_data.get_custom_data("walkable") == false:
				astar_grid.set_point_solid(tile_position)

func is_in_bounds(tile: Vector2i) -> bool:
	return astar_grid and astar_grid.region.has_point(tile)

func is_tile_walkable(tile: Vector2i) -> bool:
	if astar_grid == null or not is_in_bounds(tile):
		return false
	return not astar_grid.is_point_solid(tile)

func find_path(start_tile: Vector2i, target_tile: Vector2i) -> Array:
	if astar_grid == null:
		print("❌ ERROR: AStarGrid2D not initialized!")
		return []

	if not is_in_bounds(start_tile) or not is_in_bounds(target_tile):
		return []

	var path = astar_grid.get_id_path(start_tile, target_tile)
	return path if path.size() > 1 else []

func draw_path(path: Array, tile_map: TileMapLayer):
	if path_visualizer == null:
		print("⚠️ No PathVisualizer assigned.")
		return
	path_visualizer.clear_points()

	for tile in path:
		var pos = tile_map.map_to_local(tile) + Vector2(tile_size / 2, tile_size / 2)
		path_visualizer.add_point(pos)

func clear_path():
	if path_visualizer:
		path_visualizer.clear_points()
