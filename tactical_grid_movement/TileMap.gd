extends TileMapLayer
class_name Map

@export var grid_manager: GridManager

func is_tile_walkable(tile_position: Vector2i) -> bool:
	var tile_data = get_cell_tile_data(tile_position)
	
	if tile_data == null:
		return false  # No tile means it's out of bounds
	
	var walkable = tile_data.get_custom_data("walkable")
	
	return walkable != null and walkable

func mark_obstacle(tile_position: Vector2i):
	grid_manager.astar_grid.set_point_solid(tile_position)
