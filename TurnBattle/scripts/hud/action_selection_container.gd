extends Control

# signals
signal attack_selected(attack_type: String, target: Character)
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
		action_vbox_list.get_child(selected_option_index).button.grab_focus()
	if Input.is_action_just_pressed("action_select_down"):
		selected_option_index = (selected_option_index + 1) % action_vbox_list.get_child_count()
		action_vbox_list.get_child(selected_option_index).button.grab_focus()
	if Input.is_action_just_pressed("action_select_confirm"):
		if not action_vbox_list.get_child(selected_option_index).button.disabled:
			action_vbox_list.get_child(selected_option_index).button.emit_signal("pressed")
 

func init_action_selection():
	#todo: fix ui so move and attacks buttons are properly disabled
	show_actions("combat_actions")
	show()

	## Disable buttons based on turn state
	#var turn_state = owner.turn_state
	#for child in action_vbox_list.get_children():
		#match child.text:
			#"Move":
				#child.disabled = turn_state == owner.TurnState.MOVED or turn_state == owner.TurnState.ENDED
			#"Attacks":
				#child.disabled = turn_state == owner.TurnState.ATTACKED or turn_state == owner.TurnState.ENDED
			#"End Turn":
				#child.disabled = false  # Always enabled



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


func focus_first_button():
	# helper function to grab focus for first button on list
	await get_tree().process_frame 
	if action_vbox_list.get_child_count() > 0:
		action_vbox_list.get_child(selected_option_index).button.grab_focus()


func show_actions(actions: String):
	clear_action_options()
	current_action_options = action_options.get(actions)
	selected_option_index = 0
	var is_disabled = false
#
	#if actions == "move_selected":
		#add_button_to_list(
			#"Back",
			#"",
			#func(): _on_action_selected("back_to_combat_actions"),
			#false
		#)
		#focus_first_button()
		#return

	for action in current_action_options:
		if action.keys()[0] == "special":
			show_special_button()
		else:
			# check if action is avaiable 
			is_disabled = not is_action_available(action.keys()[0])
			add_button_to_list(
				action.values()[0],
				"",
				func(): _on_action_selected(action.keys()[0]),
				is_disabled
			)

	# ensure a button is focused
	focus_first_button()


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
			"",
			func(): _on_character_selected(enemy),
			false
		)
	add_button_to_list(
		"Back",
		"",
		func(): _on_action_selected("attacks"),
		false
	)


	# ensure a button is focused
	focus_first_button()


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
			"",
			func(): _on_character_selected(player),
			false
		)
	add_button_to_list(
		"Back",
		"",
		func(): _on_action_selected("attacks"),
		false
	)

	# ensure a button is focused
	focus_first_button()


func show_arts_selection():
	is_action_available("")
	# get the arts of the current character from the battle scene
	# want to extract art name, current charge, max charge, bonus attributes
	clear_action_options()
	selected_option_index = 0
	var is_disabled = false
	var arts_info = []
	var art_effects_as_string = ""
	arts_info = owner.get_character_arts()

	for art_info in arts_info:
		# check if art is available (i.e., is charged)
		is_disabled = not is_action_available("art", art_info)
		art_effects_as_string = ""
		for effect in art_info[1].get("effects"):
			if art_effects_as_string == "":
				art_effects_as_string = effect
			else:
				art_effects_as_string = (art_effects_as_string 
					+ " / " + effect)
		add_button_to_list(
			art_info[1].get("name") + " ("
			+ str(art_info[1].get("current_charge")) + "/"
			+ str(art_info[1].get("max_charge")) + ")",
			art_effects_as_string,
			func(): _on_art_selected(art_info[0], art_info[1].get("attribute")),
			is_disabled
		)
	add_button_to_list(
		"Back",
		"",
		func(): _on_action_selected("attacks"),
		false
	)

	# ensure a button is focused
	focus_first_button()


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
		match special_info.get("charge"):
			1: charge_as_rn = "I"
			2: charge_as_rn = "II"
			3: charge_as_rn = "III"
			4: charge_as_rn = "IV"
		add_button_to_list(
			"Special: " + charge_as_rn,
			special_info.get("name"),
			func(): _on_action_selected("special"),
			false
		)
	else: # else, no special charge (None returned)
		# add disabled button
		add_button_to_list(
			"Special: 0", 
			"",
			func(): _on_action_selected("special"),
			 true
		)


func add_button_to_list(main_text: String, sub_text: String, function: Callable, is_disabled: bool): # sub_text: String
	# helper function to add a button to the list 
	var action_button = preload("res://TurnBattle/scenes/action_button.tscn").instantiate()
	action_vbox_list.add_child(action_button)
	action_button.setup(main_text, sub_text)
	#button.text = main_text
	action_button.button.pressed.connect(func(): function.call())
	if is_disabled:
		action_button.button.disabled = true

	#await action_button.ready


func clear_action_options():
	for child in action_vbox_list.get_children():
		child.queue_free() # remove existing buttons


func _on_action_selected(action: String):
	match action:
		"move":
			#print("move action selected")
			#show_actions("move_selected")
			move_selected.emit()
		"attacks":
			#print("attacks selected")
			show_actions("attacks")
		"end_turn":
			#print("turn ended")
			end_turn_selected.emit()
		"back_to_combat_actions":
			#print("actions back selected")
			show_actions("combat_actions")
		"normal_attack", "art0", "art1", "art2", "special":
			#print(action + " used")
			pending_attack_type = action
			show_enemy_selection()
		"arts_selection":
			#print("arts selected")
			show_arts_selection()
		"back_to_attacks":
			#print("art back selected")
			show_actions("attacks")


func _on_art_selected(action: String, attribute: String):
	if attribute == "healing":
		pending_attack_type = action
		show_player_selection()
	else:
		pending_attack_type = action
		show_enemy_selection()


func _on_character_selected(character: Character):
	if pending_attack_type != "":
		#hide()
		attack_selected.emit(pending_attack_type, character)
		pending_attack_type = ""
		#init_action_selection()
		show_actions("combat_actions")
	else:
		print("somehow, no attack was selected before selecting enemy")
