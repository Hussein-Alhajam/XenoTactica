extends Node
class_name PathFinding

@export var grid_manager: GridManager
var astar_grid: AStarGrid2D
var tile_size: int = 80
var static_obstacles = []

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
				static_obstacles.append(tile_position)

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

func update_obstacles(occupied_tiles: Array):
	for x in range(astar_grid.region.size.x):
		for y in range(astar_grid.region.size.y):
			var tile_position = Vector2i(x + astar_grid.region.position.x, y + astar_grid.region.position.y)
			astar_grid.set_point_solid(tile_position, false)  # Make it walkable
	for tile in static_obstacles:
		astar_grid.set_point_solid(tile, true)
	for tile in occupied_tiles:
		astar_grid.set_point_solid(tile, true)
