extends CharacterBody2D
class_name BattleUnit

@export var move_range: int = 3  # Movement range
@export var attack_range: int = 1  # Attack range
@export var grid_manager: GridManager  # Assign in Inspector
@export var turn_manager: TurnManager  # Assign in Inspector

var selected = false  
var path = []

func _input(event):
	if not turn_manager.is_player_turn:
		return  # Prevents movement if it's not the player's turn

	if event is InputEventMouseButton and event.pressed:
		var mouse_pos = get_global_mouse_position()
		var clicked_tile = grid_manager.tile_map.local_to_map(mouse_pos)

		if selected:
			move_to_tile(clicked_tile)
		else:
			var unit_tile = grid_manager.tile_map.local_to_map(global_position)
			if unit_tile == clicked_tile:
				selected = true
				show_action_menu()
				grid_manager.highlight_tiles(unit_tile, move_range)
				print("✅ Unit selected. Showing movement range.")

func show_action_menu():
	print("📜 Displaying action menu: Move | Attack | Wait")

func move_to_tile(target_tile):
	if not selected:
		return

	var unit_tile = grid_manager.tile_map.local_to_map(global_position)
	
	path = grid_manager.get_walkable_tiles(unit_tile, move_range)

	if target_tile not in path:
		print("❌ Tile too far! Pick a closer tile.")
		return

	print("✅ Moving unit to", target_tile)
	selected = false
	follow_path(target_tile)

func follow_path(target_tile):
	var world_position = grid_manager.tile_map.map_to_local(target_tile)
	var tween = get_tree().create_tween()
	tween.tween_property(self, "global_position", world_position, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_callback(Callable(self, "end_turn"))

func end_turn():
	print("Unit turn ended.")
	grid_manager.clear_highlight()
	turn_manager.end_turn()
