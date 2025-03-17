extends Node2D
class_name GridManager

@export var tile_map: TileMapLayer
@export var pathfinder: PathFinding
@export var tile_size: int = 80

var highlighted_tiles = []
var highlighted_attack_tiles = []

func _ready():
	if tile_map and pathfinder:
		print("✅ GridManager ready.")
		pathfinder.setup_astar(tile_map)
	else:
		print("❌ ERROR: TileMapLayer or PathFinder missing!")

func highlight_tiles(unit_tile: Vector2i, move_range: int):
	clear_highlight()
	var walkable_tiles = []
	for x in range(-move_range, move_range + 1):
		for y in range(-move_range, move_range + 1):
			var check_tile = unit_tile + Vector2i(x, y)
			if abs(x) + abs(y) > move_range:
				continue
			if not pathfinder.is_tile_walkable(check_tile):
				continue
			walkable_tiles.append(check_tile)

	for tile in walkable_tiles:
		if tile == unit_tile:
			continue
		var highlight_sprite = Sprite2D.new()
		highlight_sprite.texture = preload("res://Grid-Movement/Assets/0_tileset_unit_overlay.png")
		highlight_sprite.global_position = tile_map.map_to_local(tile)
		highlight_sprite.visible = true
		highlight_sprite.z_index = 1
		highlight_sprite.modulate = Color(1, 1, 1, 0.8)
		add_child(highlight_sprite)
		highlighted_tiles.append(highlight_sprite)

func clear_highlight():
	for sprite in highlighted_tiles:
		sprite.queue_free()
	highlighted_tiles.clear()

func highlight_attack_tiles(unit_tile: Vector2i, attack_range: int):
	clear_attack_highlight()
	
	for x in range(-attack_range, attack_range + 1):
		for y in range(-attack_range, attack_range + 1):
			var check_tile = unit_tile + Vector2i(x, y)
			
			# Skip the unit's own tile
			if check_tile == unit_tile:
				continue

			# Ensure valid diamond-shaped range
			if abs(x) + abs(y) > attack_range:
				continue

			# Ensure tile is walkable (optional, can be removed if you want to highlight enemies too)
			if not pathfinder.is_tile_walkable(check_tile):
				continue

			var attack_sprite = Sprite2D.new()
			attack_sprite.texture = preload("res://Grid-Movement/Assets/1_tileset_unit_overlay.png")
			# Centering sprite
			attack_sprite.global_position = tile_map.map_to_local(check_tile)
			attack_sprite.z_index = 1
			attack_sprite.modulate = Color(1, 1, 1, 0.8)
			add_child(attack_sprite)
			highlighted_attack_tiles.append(attack_sprite)

func clear_attack_highlight():
	for sprite in highlighted_attack_tiles:
		sprite.queue_free()
	highlighted_attack_tiles.clear()
