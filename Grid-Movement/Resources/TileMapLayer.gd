extends TileMapLayer
class_name Map

@export var grid_manager: GridManager

func is_tile_walkable(tile_position: Vector2i) -> bool:
	# Ensure tile exists in bounds first
	if not get_used_rect().has_point(tile_position):
		return false  # Out of bounds
	
	var tile_data = get_cell_tile_data(tile_position)
	if tile_data == null:
		return false  # Empty space, non-walkable
	
	var walkable = tile_data.get_custom_data("walkable")
	return walkable == true

func mark_obstacle(tile_position: Vector2i):
	if grid_manager and grid_manager.pathfinder and grid_manager.pathfinder.astar_grid:
		grid_manager.pathfinder.astar_grid.set_point_solid(tile_position)
