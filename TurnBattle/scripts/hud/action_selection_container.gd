extends Control

# signals
signal attack_selected(attack_type: String, target: Character)
#signal normal_attack_selected
#signal art0_selected
#signal art1_selected
#signal art2_selected
#signal special_selected
signal move_selected
signal end_turn_selected

# on player character turn:
	# arts = get_all_arts = ["Anchor Shot", "Sword Bash", "Double Spinning Edge"]

# reference to VBoxContainer
# action_vbox_list
@onready var action_vbox_list: VBoxContainer = $ActionSelectionList

var current_action_options = {}	# Stores available actions options
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
var selected_option_index: int = 0	# stores the selected option button, used for selecting option with keyboard
var pending_attack_type: String = ""	# stores the selected attack to be used on enemy


func _ready() -> void:
	show_actions("combat_actions")


func _process(delta: float) -> void:
	# temporarily trying the input maps
	if Input.is_action_just_pressed("action_select_up"):
		selected_option_index = (selected_option_index - 1) % action_vbox_list.get_child_count()
		action_vbox_list.get_child(selected_option_index).grab_focus()
	if Input.is_action_just_pressed("action_select_down"):
		selected_option_index = (selected_option_index + 1) % action_vbox_list.get_child_count()
		action_vbox_list.get_child(selected_option_index).grab_focus()
	if Input.is_action_just_pressed("action_select_confirm"):
		print("space pressed")
		action_vbox_list.get_child(selected_option_index).emit_signal("pressed")


func show_actions(actions: String):
	clear_action_options()
	current_action_options = action_options.get(actions)
	selected_option_index = 0

	# temp: want to create new scene for 'button'
	# maybe have button as root (or panel for deco?) and then 'main' text label 'sub' text label
	for action in current_action_options:
		var button = Button.new()
		#print(action.values()[0])
		button.text = action.values()[0]
		button.pressed.connect(func(): _on_action_selected(action.keys()[0]))
		action_vbox_list.add_child(button)
	
	# ensure a button is focused
	await get_tree().process_frame 
	if action_vbox_list.get_child_count() > 0:
		action_vbox_list.get_child(selected_option_index).grab_focus()


func show_enemy_selection():
	# show the enemies that can be selected to attack
	# all 'attack' type actions should use this
	clear_action_options()
	selected_option_index = 0
	
	var enemies: Array[Character]	# reference to enemies array from battle scene
	
	# pass signal name?
	# if select enemy, signal(enemey).emit()
	# if select back, show(actions
	enemies = owner.get_enemies() # can do var enemies = owner.get_enemies()
	
	# filter enemies?
		# use enemies.filter(func = can_target_enemy())
		# can_target_enemy(): if enemy outside range, return false
		# then check if enemies is empty after filtering
	
	for enemy in enemies:
		var button = Button.new()
		button.text = enemy.character_name
		button.pressed.connect(func(): _on_character_selected(enemy))
		action_vbox_list.add_child((button))
	
	var button = Button.new()
	button.text = "Back"
	button.pressed.connect(func(): _on_action_selected("attacks"))
	action_vbox_list.add_child(button)
	
	# ensure a button is focused
	await get_tree().process_frame 
	if action_vbox_list.get_child_count() > 0:
		action_vbox_list.get_child(selected_option_index).grab_focus()


func show_player_selection():
	# show the players that can be selected to target
	# all 'effect' type (e.g., heal) actions should use this
	clear_action_options()
	selected_option_index = 0
	
	var players: Array[Character]	# reference to players array in battle scene
	
	players = owner.get_players()
	
	for player in players:
		var button = Button.new()
		button.text = player.character_name
		button.pressed.connect(func(): _on_character_selected(player))
		action_vbox_list.add_child((button))
	
	var button = Button.new()
	button.text = "Back"
	button.pressed.connect(func(): _on_action_selected("attacks"))
	action_vbox_list.add_child(button)
	
	# ensure a button is focused
	await get_tree().process_frame 
	if action_vbox_list.get_child_count() > 0:
		action_vbox_list.get_child(selected_option_index).grab_focus()


func clear_action_options():
	for child in action_vbox_list.get_children():
		child.queue_free() # remove existing buttons


func show_arts_selection():
	# get the arts of the current character from the battle scene
	# want to extract art name, current charge, max charge, bonus attributes
	clear_action_options()
	selected_option_index = 0

	var arts_info = []
	arts_info = owner.get_character_arts()

	for art_info in arts_info:
		var button = Button.new()
		button.text = art_info[1].get("name") + " (" + str(art_info[1].get("current_charge")) + "/" + str(art_info[1].get("max_charge")) + ")"
		button.pressed.connect(func(): _on_action_selected(art_info[0]))
		action_vbox_list.add_child(button)
		
	var button = Button.new()
	button.text = "Back"
	button.pressed.connect(func(): _on_action_selected("attacks"))
	action_vbox_list.add_child(button)
	
	# ensure a button is focused
	await get_tree().process_frame 
	if action_vbox_list.get_child_count() > 0:
		action_vbox_list.get_child(selected_option_index).grab_focus()


func get_specials():
	# get the current character's special charge and special at that charge
	# want to extract special name, bonus effects?, and character's current special charge
	
	# for button layout, can do
		# main: Use Speical <special charge as I II III VI>
			# sub: <speical name>
	pass


func _on_action_selected(action: String):
	match action:
		"move":
			print("move action selected")
			move_selected.emit()
		"attacks":
			print("attacks selected")
			show_actions("attacks")
		"end_turn":
			print("turn ended")
		"back_to_combat_actions":
			print("actions back selected")
			show_actions("combat_actions")
		"normal_attack", "art0", "art1", "art2", "special":
			print(action + " used")
			pending_attack_type = action
			show_enemy_selection()
		"arts_selection":
			print("arts selected")
			# need to extract art details to determine attack or healing (and also info for display in label)
			#temp_set_arts()
			show_arts_selection()
			#show_actions("arts_selection")
		"back_to_attacks":
			print("art back selected")
			show_actions("attacks")


func _on_character_selected(character: Character):
	if pending_attack_type != "":
		attack_selected.emit(pending_attack_type, character)
		pending_attack_type = ""
		show_actions("combat_actions")
	else:
		print("somehow, no attack was selected before selecting enemy")
