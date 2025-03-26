#extends "res://demo_turn_based_combat_/scripts/character_sprite.gd"
extends CharacterBody2D
class_name PlayerUnit

const RangeShape = preload("res://Grid-Movement/Resources/RangeShape.gd").RangeShape

@export_enum("DIAMOND", "SQUARE", "CROSS", "TRIANGLE") var movement_shape: int = RangeShape.DIAMOND
@export_enum("DIAMOND", "SQUARE", "CROSS", "TRIANGLE") var attack_shape: int = RangeShape.DIAMOND

@export var character_data: Character
@export var pathfinder: PathFinding
@export var grid_manager: GridManager
@export var move_range: int = 3
@export var move_speed: float = 100.0
@export var attack_range: int = 1

var selected = false
var is_moving = false
var is_attacking = false
static var currently_selected_unit: PlayerUnit = null  # Keeps track of selected unit

func _ready():
	if grid_manager == null:
		grid_manager = get_tree().get_first_node_in_group("grid_manager")
	if pathfinder == null:
		pathfinder = get_tree().get_first_node_in_group("pathfinder")

	# ✅ Dynamically connect Area2D input event
	if $Area2D:
		$Area2D.connect("input_event", Callable(self, "_on_area2d_input_event"))

	print("✅ PlayerUnit ready.")
	if character_data:
		$Sprite2D.texture = character_data.texture

func _input(event):
	# Don't use normal click detection for selection anymore since Area2D handles it
	if is_moving or grid_manager == null or pathfinder == null:
		return

	# For canceling selection or attack
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		if is_attacking:
			cancel_attack_selection()
		elif selected:
			cancel_selection()
		return

	# For movement input
	if selected and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var mouse_pos = get_global_mouse_position()
		var clicked_tile = grid_manager.tile_map.local_to_map(mouse_pos)
		move_to_tile(clicked_tile)

func _on_area2d_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if not is_moving and not is_attacking:
			select_unit()

func select_unit():
	if currently_selected_unit != null and currently_selected_unit != self:
		return  # Another unit selected
	selected = true
	currently_selected_unit = self
	grid_manager.clear_highlight()
	var occupied_tiles = []
	for unit in get_tree().get_nodes_in_group("player_units"):
		if unit != self:
			var pos = grid_manager.tile_map.local_to_map(unit.global_position)
			occupied_tiles.append(pos)
	var unit_tile = grid_manager.tile_map.local_to_map(global_position)
	grid_manager.highlight_tiles(unit_tile, move_range, movement_shape)
	print("✅ Unit selected. Showing movement range.")

func cancel_selection():
	selected = false
	is_attacking = false
	currently_selected_unit = null
	grid_manager.clear_highlight()
	grid_manager.clear_attack_highlight()
	print("❌ Selection canceled.")

func cancel_attack_selection():
	is_attacking = false
	selected = false
	currently_selected_unit = null
	grid_manager.clear_attack_highlight()
	print("❌ Attack selection canceled.")

func move_to_tile(target_tile: Vector2i):
	if not selected or is_moving:
		return
	var occupied_tiles = []
	for unit in get_tree().get_nodes_in_group("player_units"):
		if unit != self:
			var unit_pos = grid_manager.tile_map.local_to_map(unit.global_position)
			if unit_pos == target_tile:
				print("❌ Tile occupied by another unit! Cannot move there.")
				return
			occupied_tiles.append(unit_pos)
	for enemy in get_tree().get_nodes_in_group("enemy_units"):
		var enemy_pos = grid_manager.tile_map.local_to_map(enemy.global_position)
		if enemy_pos == target_tile:
			print("❌ Tile occupied by ENEMY! Cannot move there.")
			return
		occupied_tiles.append(enemy_pos)
	# ✅ Mark these tiles as obstacles in pathfinder
	pathfinder.update_obstacles(occupied_tiles)
	
	var unit_tile = grid_manager.tile_map.local_to_map(global_position)
	var path = pathfinder.find_path(unit_tile, target_tile)
	if path.size() <= 1 or path.size() > move_range + 1:
		print("❌ Invalid move target.")
		return
	print("✅ Moving unit to", target_tile)
	grid_manager.clear_highlight()
	follow_path(path)

func follow_path(path: Array):
	is_moving = true
	for tile in path:
		var world_pos = grid_manager.tile_map.map_to_local(tile)
		while global_position.distance_to(world_pos) > 1.0:
			var direction = (world_pos - global_position).normalized()
			velocity = direction * move_speed
			move_and_slide()
			await get_tree().process_frame
	velocity = Vector2.ZERO
	is_moving = false
	selected = false
	print("✅ Reached:", path[-1])
	
	var occupied_tiles = []
	for unit in get_tree().get_nodes_in_group("player_units"):
		var unit_pos = grid_manager.tile_map.local_to_map(unit.global_position)
		occupied_tiles.append(unit_pos)
	pathfinder.update_obstacles(occupied_tiles)
	
	# After move, show attack range
	var unit_tile = grid_manager.tile_map.local_to_map(global_position)
	grid_manager.highlight_attack_tiles(unit_tile, attack_range, attack_shape)
	is_attacking = true
