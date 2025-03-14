extends CharacterBody2D
class_name PlayerUnit

@export var pathfinder: PathFinder
@export var grid_manager: GridManager
@export var move_range: int = 3
@export var move_speed: float = 100.0
@export var attack_range: int = 1 

var selected = false
var is_moving = false
static var currently_selected_unit: PlayerUnit = null
var is_attacking: bool = false

func _ready():
	if grid_manager == null:
		grid_manager = get_tree().get_first_node_in_group("grid_manager")
	if pathfinder == null:
		pathfinder = get_tree().get_first_node_in_group("pathfinder")
	if grid_manager == null or pathfinder == null:
		print("❌ ERROR: GridManager or PathFinder not found!")

func _input(event):
	if is_moving or grid_manager == null or pathfinder == null:
		return

	if event is InputEventMouseMotion and selected:
		var mouse_pos = get_global_mouse_position()
		var hovered_tile = grid_manager.tile_map.local_to_map(mouse_pos)
		if pathfinder.is_tile_walkable(hovered_tile):
			var unit_tile = grid_manager.tile_map.local_to_map(global_position)
			var path = pathfinder.find_path(unit_tile, hovered_tile)
			if path.size() > 1 and path.size() <= move_range + 1:
				pathfinder.draw_path(path)

	if event is InputEventMouseButton and event.pressed:
		var mouse_pos = get_global_mouse_position()
		var clicked_tile = grid_manager.tile_map.local_to_map(mouse_pos)

		# 🔹 Cancel attack if right-clicked (only if in attack mode)
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if is_attacking:
				cancel_attack_selection()
				return
			elif selected:
				cancel_selection()
				return

		# 🔹 Prevent re-selecting units during attack mode
		if is_attacking:
			return  

		if selected:
			move_to_tile(clicked_tile)
		else:
			if currently_selected_unit != null and currently_selected_unit != self:
				return
			var unit_tile = grid_manager.tile_map.local_to_map(global_position)
			if unit_tile == clicked_tile:
				select_unit()

func select_unit():
	selected = true
	currently_selected_unit = self
	grid_manager.clear_highlight()
	var unit_tile = grid_manager.tile_map.local_to_map(global_position)
	grid_manager.highlight_tiles(unit_tile, move_range)
	print("✅ Unit selected. Showing movement range.")

func cancel_selection():
	selected = false
	is_attacking = false
	currently_selected_unit = null
	grid_manager.clear_highlight()
	grid_manager.clear_attack_highlight()
	pathfinder.clear_path()
	print("❌ Selection canceled.")

func cancel_attack_selection():
	is_attacking = false
	selected = false
	currently_selected_unit = null
	grid_manager.clear_attack_highlight()
	pathfinder.clear_path()
	print("❌ Attack selection canceled. Ready for new unit.")

func move_to_tile(target):
	if not selected or is_moving:
		return
	var unit_tile = grid_manager.tile_map.local_to_map(global_position)
	var path = pathfinder.find_path(unit_tile, target)
	if path.size() <= 1 or path.size() > move_range + 1:
		print("❌ Tile is outside movement range! Choose a valid tile.")
		return
	pathfinder.clear_path()
	print("✅ Moving unit to", target)
	follow_path(path)

func follow_path(path: Array):
	if path.is_empty():
		print("❌ Path is empty, cannot move.")
		return
	is_moving = true
	for tile in path:
		var world_position = grid_manager.tile_map.map_to_local(tile) + Vector2(grid_manager.tile_size / 2, grid_manager.tile_size / 2)
		while global_position.distance_to(world_position) > 1.0:
			var direction = (world_position - global_position).normalized()
			velocity = direction * move_speed
			move_and_slide()
			await get_tree().process_frame
	velocity = Vector2.ZERO
	is_moving = false
	print("✅ Reached target tile:", path[-1])
	selected = false 
	var unit_tile = grid_manager.tile_map.local_to_map(global_position)
	grid_manager.clear_highlight()
	grid_manager.highlight_attack_tiles(unit_tile, attack_range)
	is_attacking = true

func preview_path(target_tile: Vector2i):
	if not selected or is_moving:
		return
	var unit_tile = grid_manager.tile_map.local_to_map(global_position)
	var path = pathfinder.find_path(unit_tile, target_tile)
	# 🔹 Only show the path if it's valid and within range
	if path.size() > 1 and path.size() <= move_range + 1:
		grid_manager.show_path(path)
	else:
		grid_manager.clear_path()
