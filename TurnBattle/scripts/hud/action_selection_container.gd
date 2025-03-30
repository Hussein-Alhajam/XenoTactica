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
	"attacks": [
		{"normal_attack": "Normal Attack"},
		{"arts_selection": "Arts Selection"}, 
		{"special": "Special"},
		{"back_to_combat_actions": "Back"}],
}
var selected_option_index: int = 0	# stores the selected option button, used for selecting option with keyboard
var pending_attack_type: String = ""	# stores the selected attack to be used on enemy


func _ready() -> void:
	init_action_selection()


func _process(delta: float) -> void:
	# temporarily trying the input maps
	if Input.is_action_just_pressed("action_select_up"):
		selected_option_index = (selected_option_index - 1) % action_vbox_list.get_child_count()
		action_vbox_list.get_child(selected_option_index).grab_focus()
	if Input.is_action_just_pressed("action_select_down"):
		selected_option_index = (selected_option_index + 1) % action_vbox_list.get_child_count()
		action_vbox_list.get_child(selected_option_index).grab_focus()
	if Input.is_action_just_pressed("action_select_confirm"):
		if not action_vbox_list.get_child(selected_option_index).disabled:
			action_vbox_list.get_child(selected_option_index).emit_signal("pressed")
 

func init_action_selection():
	# ...?
	#todo: fix ui so move and attacks buttons are properly disabled
	show_actions("combat_actions")


func is_action_available(action: String, art_info = null):
	# use: check if the button's action is available
		# i.e., if move and/or attack is already used this turn
		# or if art is charged
	match action:
		"move":
			return owner.can_move()
		"attacks":
			return owner.can_attack()
		"art":
			if not art_info:
				print("did not provide valid art info")
				return false
			if art_info[1].get("current_charge") < art_info[1].get("max_charge"):
				return false
			return true
	return true


func show_actions(actions: String):
	clear_action_options()
	current_action_options = action_options.get(actions)
	selected_option_index = 0
	var is_disabled = false

	# temp: want to create new scene for 'button'
	# maybe have button as root (or panel for deco?) and then 'main' text label 'sub' text label
	for action in current_action_options:
		if action.keys()[0] == "special":
			show_special_button()
		else:
			# check if action is avaiable 
			is_disabled = not is_action_available(action.keys()[0])
			add_button_to_list(
				action.values()[0],
				func(): _on_action_selected(action.keys()[0]),
				is_disabled
			)

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
	enemies = owner.get_enemies() # can do var enemies = owner.get_enemies()
	
	# todo: filter enemies using grid movement range
		# can use enemies.filter(func = can_target_enemy())
		# can_target_enemy(): if enemy outside range, return false
		# then check if enemies is empty after filtering
	
	for enemy in enemies:
		add_button_to_list(
			enemy.character_name,
			func(): _on_character_selected(enemy),
			false
		)
	add_button_to_list(
		"Back",
		func(): _on_action_selected("attacks"),
		false
	)

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
		add_button_to_list(
			player.character_name,
			func(): _on_character_selected(player),
			false
		)
	add_button_to_list(
		"Back",
		func(): _on_action_selected("attacks"),
		false
	)

	# ensure a button is focused
	await get_tree().process_frame 
	if action_vbox_list.get_child_count() > 0:
		action_vbox_list.get_child(selected_option_index).grab_focus()


func show_arts_selection():
	is_action_available("")
	# get the arts of the current character from the battle scene
	# want to extract art name, current charge, max charge, bonus attributes
	clear_action_options()
	selected_option_index = 0
	var is_disabled = false
	var arts_info = []
	arts_info = owner.get_character_arts()

	for art_info in arts_info:
		# check if art is available (i.e., is charged)
		if art_info[1].get("current_charge") < art_info[1].get("max_charge"):
			# if no, disable button
			is_disabled = not is_action_available("art", art_info)
		add_button_to_list(
			art_info[1].get("name") + " ("
			+ str(art_info[1].get("current_charge")) + "/"
			+ str(art_info[1].get("max_charge")) + ")",
			func(): _on_action_selected(art_info[0]),
			is_disabled
		)
	add_button_to_list(
		"Back",
		func(): _on_action_selected("attacks"),
		false
	)

	# ensure a button is focused
	await get_tree().process_frame 
	if action_vbox_list.get_child_count() > 0:
		action_vbox_list.get_child(selected_option_index).grab_focus()


func show_special_button():
	# get the current character's special charge and special at that charge
	# want to extract special name, bonus effects?, and character's current special charge
	
	# for button layout, can do
		# main: Use Speical <special charge as I II III VI>
			# sub: <speical name>
	
	var is_disabled = false
	var special_info = owner.get_character_special()
	var charge_as_rn: String = ""
	
	# if special has charge (valid special returned)
	if special_info:
		# add active Special button
		match special_info["charge"]:
			1: charge_as_rn = "I"
			2: charge_as_rn = "II"
			3: charge_as_rn = "III"
			4: charge_as_rn = "IV"
		add_button_to_list(
			"Special: " + charge_as_rn,
			func(): _on_action_selected("special"),
			false
		)
		# add after better buttons: sub text = special_info["name"]
	else: # else, no special charge (None returned)
		# add disabled button
		add_button_to_list("Special: 0", func(): _on_action_selected("special"), true)
	
	pass


func add_button_to_list(main_text: String, function: Callable, is_disabled: bool): # sub_text: String
	# helper function to add a button to the list 
	var button = Button.new()
	button.text = main_text
	button.pressed.connect(func(): function.call())
	if is_disabled:
		button.disabled = true
	action_vbox_list.add_child(button)


func move_selection(direction: int):
	pass


func clear_action_options():
	for child in action_vbox_list.get_children():
		child.queue_free() # remove existing buttons


func _on_action_selected(action: String):
	match action:
		"move":
			#print("move action selected")
			move_selected.emit()
		"attacks":
			#print("attacks selected")
			show_actions("attacks")
		"end_turn":
			print("turn ended")
		"back_to_combat_actions":
			#print("actions back selected")
			show_actions("combat_actions")
		"normal_attack", "art0", "art1", "art2", "special":
			#print(action + " used")
			pending_attack_type = action
			show_enemy_selection()
		"arts_selection":
			#print("arts selected")
			# need to extract art details to determine attack or healing (and also info for display in label)
			show_arts_selection()
		"back_to_attacks":
			#print("art back selected")
			show_actions("attacks")


func _on_character_selected(character: Character):
	if pending_attack_type != "":
		attack_selected.emit(pending_attack_type, character)
		pending_attack_type = ""
		init_action_selection()
		#hide()
	else:
		print("somehow, no attack was selected before selecting enemy")
