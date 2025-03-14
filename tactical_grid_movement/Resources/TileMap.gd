extends TileMapLayer
<<<<<<< Updated upstream
var movement_data


## Get the movement cost of any single cell on the map
## We pass in the grid, so that we don't take in the data from tiles that have been placed outside the play area
func get_movement_costs(grid: Grid):
	var movement_costs = []
	for y in range(grid.size.y):
		movement_costs.append([])
		for x in range(grid.size.x):
			var tile = get_cell_source_id(Vector2i(x,y))
			var movement_cost = movement_data.get(tile)
			movement_costs[y].append(movement_cost)
	return movement_costs
=======
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
>>>>>>> Stashed changes
