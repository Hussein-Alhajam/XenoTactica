extends Node
class_name PathFinder

@export var path_visualizer: Line2D
@export var grid_manager: GridManager
var astar_grid: AStarGrid2D
var tile_size: int = 80  

func setup_astar(tile_map: TileMapLayer):
	if tile_map == null:
		print("❌ ERROR: No TileMap provided to PathFinder!")
		return
	astar_grid = AStarGrid2D.new()
	astar_grid.region = tile_map.get_used_rect()
	astar_grid.cell_size = Vector2(tile_size, tile_size)
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar_grid.update()
	for x in range(astar_grid.region.size.x):
		for y in range(astar_grid.region.size.y):
			var tile_position = Vector2i(x + astar_grid.region.position.x, y + astar_grid.region.position.y)
			var tile_data = tile_map.get_cell_tile_data(tile_position)
			if tile_data == null or tile_data.get_custom_data("walkable") == false:
				astar_grid.set_point_solid(tile_position)

func draw_path(path: Array):
	if path.is_empty():
		return
	var line := Line2D.new()
	line.width = 5
	line.default_color = Color(1, 1, 1, 1)
	for child in grid_manager.get_children():
		if child is Line2D:
			child.queue_free()
	for tile in path:
		var world_position = grid_manager.tile_map.map_to_local(tile) + Vector2(grid_manager.tile_size / 2, grid_manager.tile_size / 2)
		line.add_point(world_position)
	grid_manager.add_child(line)

func clear_path():
	for child in grid_manager.get_children():
		if child is Line2D:
			child.queue_free()
