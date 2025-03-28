extends Node2D
class_name GridManager

@export var tile_map: TileMapLayer
@export var pathfinder: PathFinding
@export var overlay_container: Node2D
@export var tile_size: int = 80

const RangeShape = preload("res://Grid-Movement/Resources/RangeShape.gd").RangeShape

var highlighted_tiles = []
var highlighted_attack_tiles = []

func _ready():
	if tile_map and pathfinder:
		print("✅ GridManager ready.")
		pathfinder.setup_astar(tile_map)
	else:
		print("❌ ERROR: TileMapLayer or PathFinder missing!")

func _is_in_shape(x: int, y: int, range: int, shape: int) -> bool:
	match shape:
		RangeShape.DIAMOND:
			return abs(x) + abs(y) <= range
		RangeShape.SQUARE:
			return abs(x) <= range and abs(y) <= range
		RangeShape.CROSS:
			return (abs(x) <= range and y == 0) or (abs(y) <= range and x == 0)
		RangeShape.TRIANGLE:
			return y >= 0 and abs(x) + y <= range
	return false

func highlight_tiles(unit_tile: Vector2i, move_range: int, shape: int = RangeShape.DIAMOND):
	clear_highlight()
	var walkable_tiles = []

	var occupied_tiles = []
	for unit in get_tree().get_nodes_in_group("player_units"):
		if unit != null and unit != self:
			occupied_tiles.append(tile_map.local_to_map(unit.global_position))
	for enemy in get_tree().get_nodes_in_group("enemy_units"):
		occupied_tiles.append(tile_map.local_to_map(enemy.global_position))

	pathfinder.update_obstacles(occupied_tiles)

	for x in range(-move_range, move_range + 1):
		for y in range(-move_range, move_range + 1):
			if not _is_in_shape(x, y, move_range, shape):
				continue

			var check_tile = unit_tile + Vector2i(x, y)

			if not pathfinder.is_tile_walkable(check_tile):
				continue

			var path = pathfinder.find_path(unit_tile, check_tile)
			if path.size() <= 1 or path.size() > move_range + 1:
				continue

			if check_tile in occupied_tiles:
				continue

			walkable_tiles.append(check_tile)

	print("Highlighting", walkable_tiles.size(), "tiles")

	for tile in walkable_tiles:
		if tile == unit_tile:
			continue
		var highlight_sprite = Sprite2D.new()
		highlight_sprite.texture = preload("res://Grid-Movement/Assets/0_tileset_unit_overlay.png")
		highlight_sprite.global_position = tile_map.map_to_local(tile)
		highlight_sprite.visible = true
		highlight_sprite.z_index = 10
		highlight_sprite.modulate = Color(1, 1, 1, 1)
		overlay_container.add_child(highlight_sprite)
		highlighted_tiles.append(highlight_sprite)

func clear_highlight():
	for child in overlay_container.get_children():
		if child is Sprite2D:
			child.queue_free()
	highlighted_tiles.clear()

func highlight_attack_tiles(unit_tile: Vector2i, attack_range: int, shape: int = RangeShape.DIAMOND):
	clear_attack_highlight()

	for x in range(-attack_range, attack_range + 1):
		for y in range(-attack_range, attack_range + 1):
			if not _is_in_shape(x, y, attack_range, shape):
				continue

			var check_tile = unit_tile + Vector2i(x, y)

			if check_tile == unit_tile:
				continue

			if not pathfinder.is_tile_walkable(check_tile):
				continue

			var attack_sprite = Sprite2D.new()
			attack_sprite.texture = preload("res://Grid-Movement/Assets/1_tileset_unit_overlay.png")
			attack_sprite.global_position = tile_map.map_to_local(check_tile)
			attack_sprite.z_index = 10
			attack_sprite.modulate = Color(1, 1, 1, 0.8)
			overlay_container.add_child(attack_sprite)
			highlighted_attack_tiles.append(attack_sprite)

func clear_attack_highlight():
	for child in overlay_container.get_children():
		if child is Sprite2D:
			child.queue_free()
	highlighted_attack_tiles.clear()
