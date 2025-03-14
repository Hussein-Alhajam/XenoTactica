extends Node2D
class_name GridManager

@export var tile_map: TileMapLayer  # Assign TileMap in Inspector
@export var pathfinder: PathFinder  # Assign PathFinder in Inspector
@export var tile_size: int = 80  # Default tile size, can be updated

var highlighted_tiles = []

func _ready():
	if tile_map and pathfinder:
		pathfinder.setup_astar(tile_map)
	else:
		print("❌ ERROR: TileMap or PathFinder not set in GridManager!")

func highlight_tiles(unit_tile: Vector2i, move_range: int):
	clear_highlight()
	var walkable_tiles = []
	for x in range(-move_range, move_range + 1):
		for y in range(-move_range, move_range + 1):
			var check_tile = unit_tile + Vector2i(x, y)
			# 🔹 Ensure the tile is within a proper diamond-shaped movement range
			if abs(x) + abs(y) > move_range:
				continue
			# 🔹 Ensure the tile is inside the grid and not an obstacle
<<<<<<< Updated upstream
			if not pathfinder.is_tile_walkable(check_tile):
=======
			if not GridManager.is_tile_walkable(check_tile):
>>>>>>> Stashed changes
				continue
			walkable_tiles.append(check_tile)
	for tile in walkable_tiles:
		var highlight_sprite = Sprite2D.new()
		highlight_sprite.texture = preload("res://tactical_grid_movement/Assets/0_tileset_unit_overlay.png")  # Blue tile
		highlight_sprite.global_position = tile_map.map_to_local(tile)
		add_child(highlight_sprite)

func clear_highlight():
	for child in get_children():
		if child is Sprite2D:
			child.queue_free()

func highlight_attack_tiles(unit_tile: Vector2i, attack_range: int):
	clear_attack_highlight()  # Remove previous attack range
	var attack_tiles = []
	for x in range(-attack_range, attack_range + 1):
		for y in range(-attack_range, attack_range + 1):
			var check_tile = unit_tile + Vector2i(x, y)
			# 🔹 Ensure tiles are adjacent within the valid attack range
			if abs(x) + abs(y) > attack_range:
				continue
			# 🔹 Ensure the tile is inside the grid and not blocked
			if not pathfinder.is_tile_walkable(check_tile):
				continue
			attack_tiles.append(check_tile)
	for tile in attack_tiles:
		var attack_sprite = Sprite2D.new()
		attack_sprite.texture = preload("res://tactical_grid_movement/Assets/1_tileset_unit_overlay.png")  # Red tile
		attack_sprite.global_position = tile_map.map_to_local(tile)
		add_child(attack_sprite)

func clear_attack_highlight():
	for child in get_children():
		if child is Sprite2D and child.texture == preload("res://tactical_grid_movement/Assets/1_tileset_unit_overlay.png"):
			child.queue_free()

func get_walkable_tiles(start_tile: Vector2i, move_range: int) -> Array:
	var walkable_tiles = []
	for x in range(-move_range, move_range + 1):
		for y in range(-move_range, move_range + 1):
			var check_tile = start_tile + Vector2i(x, y)
			# 🔹 Ensure the tile is within bounds
			if not pathfinder.is_in_bounds(check_tile):
				continue
			# 🔹 Ensure the tile is walkable (not an obstacle)
			if not pathfinder.is_tile_walkable(check_tile):
				continue
			# 🔹 Get path length to the tile
			var path = pathfinder.find_path(start_tile, check_tile)
			# 🔹 Ensure the tile is within move range (excluding start tile itself)
			if path.size() > 1 and path.size() <= move_range + 1:
				walkable_tiles.append(check_tile)
	return walkable_tiles

var path_visuals = []  # Stores the path visuals

func show_path(path: Array):
	clear_path()  # Clear previous path before drawing new one

	for tile in path:
		var path_sprite = Sprite2D.new()
		path_sprite.texture = preload("res://tactical_grid_movement/Assets/arrows.svg")  # Make sure this texture exists
		path_sprite.global_position = tile_map.map_to_local(tile)
		add_child(path_sprite)
		path_visuals.append(path_sprite)

func clear_path():
	for sprite in path_visuals:
		sprite.queue_free()
	path_visuals.clear()
