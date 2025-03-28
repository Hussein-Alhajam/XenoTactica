extends Control

# reference to VBoxContainer
# action_vbox_list
@onready var action_list: VBoxContainer = $ActionSelectionList

var rng = RandomNumberGenerator.new()

# on player character turn:
	# arts = get_all_arts = ["Anchor Shot", "Sword Bash", "Double Spinning Edge"]
var arts = ["Anchor Shot", "Sword Bash", "Double Spinning Edge"]

# what type? Stores available actions options
var current_action_options = {}
var action_options = {
	# each 'action option' is a list of {action: display text}
	"combat_actions": [{"move": "Move"}, {"attacks": "Attacks"},
		{"end_turn": "End Turn"}],
	"attacks": [{"normal_attack": "Normal Attack"},
		{"arts_selection": "Arts Selection"}, 
		{"special": "Special"}, {"back_to_combat_actions": "Back"}],
	"arts_selection": [{"art0": "art1"}, {"art1": "art2"}, 
		{"art2": "art3"}, {"back_to_attacks": "Back"}],
}

var selected_option_index: int = 0


func _ready() -> void:
	show_actions("combat_actions")


func _process(delta: float) -> void:
	# temporarily trying the input maps
	if Input.is_action_just_pressed("action_select_up"):
		selected_option_index = (selected_option_index - 1) % action_list.get_child_count()
		action_list.get_child(selected_option_index).grab_focus()
	if Input.is_action_just_pressed("action_select_down"):
		selected_option_index = (selected_option_index + 1) % action_list.get_child_count()
		action_list.get_child(selected_option_index).grab_focus()
	if Input.is_action_just_pressed("action_select_confirm"):
		print("space pressed")
		action_list.get_child(selected_option_index).emit_signal("pressed")


func temp_set_arts():
	# using this to temporarily set the name (display text) for
		# arts when arts is selected
	var my_rng = rng.randf_range(0, 1)
	if my_rng > 0.5:
		action_options["arts_selection"] = [{"art0": "arts[0]"}, 
			{"art1": "arts[1]"}, {"art2": "arts[2]"}, 
			{"back_to_attacks": "Back"}]
	else:
		action_options["arts_selection"] = [{"art0": "Anchor Shot"}, 
			{"art1": "Sword Bash"}, {"art2": "Double Spinning Edge"}, 
			{"back_to_attacks": "Back"}]


func show_actions(actions: String):
	clear_action_options()
	current_action_options = action_options.get(actions)
	
	selected_option_index = 0

	for action in current_action_options:
		var button = Button.new()
		#print(action.values()[0])
		button.text = action.values()[0]
		button.pressed.connect(func(): _on_action_selected(action.keys()[0]))
		action_list.add_child(button)
	
	# ensure a button is focused
	await get_tree().process_frame 
	if action_list.get_child_count() > 0:
		action_list.get_child(selected_option_index).grab_focus()


func clear_action_options():
	for child in action_list.get_children():
		child.queue_free() # remove existing buttons


func _on_action_selected(action: String):
	match action:
		"move":
			print("move action selected")
		"attacks":
			print("attacks selected")
			show_actions("attacks")
		"end_turn":
			print("turn ended")
		"back_to_combat_actions":
			print("actions back selected")
			show_actions("combat_actions")
		"normal_attack":
			print("normal attack")
		"arts_selection":
			print("arts selected")
			temp_set_arts()
			show_actions("arts_selection")
		"art0":
			print("art0 used")
		"art1":
			print("art1 used")
		"art2":
			print("art2 used")
		"special":
			print("*special selected")
		"back_to_attacks":
			print("art back selected")
			show_actions("attacks")
