extends CharacterBody2D

# A dictionary that maps input map actions to direction vectors
const inputs = {
	"move_right": Vector2.RIGHT,
	"move_left": Vector2.LEFT,
	"move_down": Vector2.DOWN,
	"move_up": Vector2.UP
}

# Stores the grid size, which is 16 (same as one tile)
var grid_size = 80

# Reference to the RayCast2D node
@onready var raycast_2d: RayCast2D = $RayCast2D

# Calls the move function with the appropriate input key
# if any input map action is triggered
func _unhandled_input(event):
	for action in inputs.keys():
		if event.is_action_pressed(action):
			move(action)

# Updates the direction of the RayCast2D according to the input key
# and moves one grid if no collision is detected
func move(action):
	var destination = inputs[action] * grid_size
	raycast_2d.target_position = destination
	raycast_2d.force_raycast_update()
	if not raycast_2d.is_colliding():
		position += destination

func _process(_delta):
	if raycast_2d.is_colliding():
		var hit_object = raycast_2d.get_collider()
		if hit_object.is_in_group("enemies"):
			print("Enemy detected! Initiating battle...")
			initiate_battle(hit_object)
			
func initiate_battle(enemy):
	if enemy == null:
		return
	
	print("Switching to battle scene...")
	get_tree().change_scene_to_file("res://tactical_grid_movement/grid_movement.tscn")
