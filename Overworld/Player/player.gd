extends CharacterBody2D

#@export var speed = 400
# Reference to the RayCast2D node
@onready var raycast_2d: RayCast2D = $RayCast2D
# Stores the grid size, which is 80 (same as one tile)
var grid_size = 80
# A dictionary that maps input map actions to direction vectors
const inputs = {
	"move_right": Vector2.RIGHT,
	"move_left": Vector2.LEFT,
	"move_down": Vector2.DOWN,
	"move_up": Vector2.UP
}
# Calls the move function with the appropriate input key
# if any input map action is triggered
func _unhandled_input(event):
	for action in inputs.keys():
		if event.is_action_pressed(action):
			move_and_slide(action)

# Updates the direction of the RayCast2D according to the input key
# and moves one grid if no collision is detected
func move(action):
	var destination = inputs[action] * grid_size
	raycast_2d.target_position = destination
	raycast_2d.force_raycast_update()
	if not raycast_2d.is_colliding():
		position += destination

func save_and_transition(next_scene: String):
	GameState.save_player_state(global_position, get_tree().current_scene.scene_file_path)
	print("🔹 Player state saved. Transitioning to:", next_scene)
	
	# Call Overworld's transition function if it exists
	var overworld = get_tree().get_first_node_in_group("overworld")
	if overworld:
		overworld.transition_to_scene(next_scene)
	else:
		get_tree().change_scene_to_file(next_scene)
		

#func get_input():
#	var input_direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
#	velocity = input_direction * speed

#func _physics_process(delta):
#	get_input()
#	move_and_slide()
