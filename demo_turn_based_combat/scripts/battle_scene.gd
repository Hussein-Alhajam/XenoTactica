extends Node2D

# signals
#signal arts_selected

# enums
enum TurnState { NEUTRAL, ATTACKED, MOVED, SKIPPED }

# constants
# static variables

# export variables
@export var player_group: Node2D # hold the 'Players' node
@export var enemy_group: Node2D # hold the 'Enemies' node
@export var timeline: HBoxContainer # hold the "Timeline' node
@export var combat_options: VBoxContainer # hold the 'CombatOptions' node
@export var enemy_button: PackedScene # variable to hold "EnemyButton'

# public variables
var sorted_array = [] # used for sorting the turn order (?)
var players: Array[Character] # used to hold the player resource
var enemies: Array[Character] # used to hold the enemy resource

var is_arts_selected: bool = false # should make into FSM

var turn_state = TurnState.NEUTRAL

# temp variable for the temp controls UI
var ui_controls := {}


func _ready():
	
	ui_controls = { # temp
		"up": $UI/UpContainer/UpText,
		"left": $UI/LeftContainer/LeftText,
		"down": $UI/DownContainer/DownText,
		"right": $UI/RightContainer/RightText,
		"log": $UI/ActionLog,
	}
	# add this node as a global reference
	Global.battle_scene = self
	
	# loop through and append all the player resources
	for player in player_group.get_children():
		player.character.init()
		players.append(player.character)

	for enemy in enemy_group.get_children():
		enemy.character.init()
		enemies.append(enemy.character)
		
		var button = enemy_button.instantiate()
		button.character = enemy.character
		%EnemySelection.add_child(button)

	sort_and_display() 
	
	# connect the signal 'next_turn' from 'EventBus'
	# to the function next_turn() from below
	# whenever attack() is called in character.gd,
		# signal gets emitted and next_turn() in here is called
	EventBus.next_turn.connect(next_turn)

	next_turn()

func _process(delta: float) -> void:
	# only give player controls if it is a player char's turn
	if sorted_array[0]["character"] in players:
		# show hud for controls
		# should 'hide' attack controls if turn_state.ATTACKED 
			# to better show player they can't attack
		if not is_arts_selected:
			# update the action selection
			# rearrange to have up: ar1, right: art2, down: art3
				# left: select arts
			ui_controls["up"].text = "Items"
			var special_name = sorted_array[0]["character"].get_special_name()
			ui_controls["left"].text = special_name
			#$UI/LeftContainer/LeftText.text = "Special " + str(sorted_array[0].special_charge)
			ui_controls["down"].text = "Arts"
			ui_controls["right"].text = "Attack"
			
			if Input.is_action_just_pressed("auto_attack"):
				# print some display, then call attack
				$UI/ActionLog.text = "Used Attack \nArts Charged by 1"
				# if using the priority queue for turn order,
				# and assuming controls are only available when current turn is a player,
				# (i.e., if we are in controls, first element in queue is a player)
				# make that player character charge their arts
				use_character_normal_attack()

			if Input.is_action_just_pressed("special"):
				use_character_special()

			if Input.is_action_just_pressed("items_selection"):
				$UI/ActionLog.text = "entered items selection \n (not implemented)"
			if Input.is_action_just_pressed("arts_selection"):
				#$UI/ActionLog.text = "entered arts selection"
				is_arts_selected = true

		else:
			# update the action selection
			# temp 'hard code-y' text updates
			
			#arts_selected.emit()
			# temp way to update text
			# alternatives: 1. use signal in global event_bus,
				# connect to combat_art and combat_special 
				# (need some init func in art, special, and character)
			var art0name = sorted_array[0]["character"].get_art_name(0)
			var art0charges = sorted_array[0]["character"].get_art_charges(0)
			var art1name = sorted_array[0]["character"].get_art_name(1)
			var art1charges = sorted_array[0]["character"].get_art_charges(1)
			var art2name = sorted_array[0]["character"].get_art_name(2)
			var art2charges = sorted_array[0]["character"].get_art_charges(2)
			
			ui_controls["up"].text = str(art1name) + " " + str(art1charges[0]) + "/" + str(art1charges[1])
			ui_controls["left"].text = str(art0name) + " " + str(art0charges[0]) + "/" + str(art0charges[1])
			ui_controls["right"].text = str(art2name) + " " + str(art2charges[0]) + "/" + str(art2charges[1])
			
			#str(sorted_array[0].arts_list[1].art_name) + " " + str(sorted_array[0].arts_list[1].current_charge) + "/" + str(sorted_array[0].arts_list[1].max_charge)
			#str(sorted_array[0].arts_list[0].art_name) + " " + str(sorted_array[0].arts_list[0].current_charge) + "/" + str(sorted_array[0].arts_list[0].max_charge)
			#str(sorted_array[0].arts_list[2].art_name) + " " + str(sorted_array[0].arts_list[2].current_charge) + "/" + str(sorted_array[0].arts_list[2].max_charge)
			ui_controls["down"].text = "Exit Arts"
			
			if Input.is_action_just_pressed("left_art"):
				use_character_art(0)

			if Input.is_action_just_pressed("up_art"):
				use_character_art(1)

			if Input.is_action_just_pressed("right_art"):
				use_character_art(2)

			if Input.is_action_just_pressed("arts_back"):
				#$ActionLog.text = "exited arts selection"
				is_arts_selected = false


func update_action_log(message: String):
	$UI/ActionLog.text = message


# functions for dealing with turn order (the character queue) 

func sort_combined_queue():
	# use: combines the 'speed' queue of each character in
		# players into player_array and each character in
		# enemies in enemy_array, then combines both combined
		# arrays into sorted_array. Array is then sorted
		# based on the 'time' key (i.e., the 'speed' value in
		# character.queue)

	var player_array = []
	for player in players: 
		for i in player.queue:
			# separate each element of queue, then pair them
			# with character, and append it to the new array (?)
			# i.e., store each player in their own dict 
			# with "character" = player and "time" = player.queue
			player_array.append({"character": player, "time": i})

	# do the same for enemies
	var enemy_array = []
	for enemy in enemies:
		for i in enemy.queue:
			enemy_array.append({"character": enemy, "time": i})

	sorted_array = player_array
	sorted_array.append_array(enemy_array) # join the player and enemy
	# used gdscript's built in 'sort_custom' function for lists
	# and pass it our custom sort defined below
	sorted_array.sort_custom(sort_by_time)
	#print(sorted_array)


func sort_by_time(a, b):
	# use: custom sort function to sort the players 
		# in ascending order based on their "time"
	return a["time"] < b["time"]


func update_timeline():
	# use: updates the UI to reflect the elements (characters)
	# in the turn order queue 

	var index: int = 0
	# loop through each slot ('TimelineSlot') in 'Timeline' node
	for slot in timeline.get_children():
		# set each slot's icon with respect to the 
		# character's icon in the sorted array
		slot.find_child("TextureRect").texture = sorted_array[index]["character"].icon
		index += 1


func sort_and_display():
	# use: sorts the turn order queue and update the 
	# UI for turn order

	# call our sort and update functions defined above
	sort_combined_queue()
	update_timeline()
	# after sorting, if the first element in the queue
	# is a Player, then show the option to the player
	#if sorted_array[0]["character"] in players:
		#show_combat_options()


func pop_out():
	# use: pops the 'speed' queue of the current character
		# to update their turn order and call 
		# sort_and_display() to update the turn order queue
		# and the UI for turn order

	# call the pop_out() function defined in character.gd
	sorted_array[0]["character"].pop_out()
	
	sort_and_display() # always call for any change of speed


func next_turn():
	# use: pop the queue to get the next character's turn
		# i.e., ends the current turn and allows the next
		# character in the queue to go

	# if the first element is Player, give control to player
	if sorted_array[0]["character"] in players:
		return # temp

	# otherwise, it's enemy's turn, handle with ai
	# in a way, attack and getting attacked are 'separate'
	# e.g., char does animation for attack, but doesn't actually 
	# 'hit', then player/enemy selects a char to be attacked
	
	give_enemy_turn()


# functions to do with attacking / turn actions

func deal_damage(damage: int): # add a character to be hit
	# changes:
		# add: call get_attacked() for character taking attack

	# (current) use: calls the attack() function for the 
		# first character in the queue (current turn)
	
	print(str(damage) + "damage dealt") # temp to check correct damage
	
	# call the attack() function defined in character.gd
	sorted_array[0]["character"].attack(get_tree())
	# determine who gets attacked (if player, let player
	# select; if enemy, random or some ai), then get_attacked
	#players.pick_random().get_attacked() # randomly select a player to be attacked
	pop_out()


func give_player_turn():
	pass


func give_enemy_turn():
	deal_damage(1)
	players.pick_random().get_attacked("", 1) # temp randomly select a player to be attacked


func use_character_normal_attack():
	# use: calls the use_normal_attack() function for the
		# first (current turn) character in the queue 
	var damage = sorted_array[0]["character"].use_normal_attack()
	deal_damage(damage)
	
	enemies.pick_random().get_attacked("", damage) # temp select enemy at random


func use_character_art(art_num: int):
	# use: calls the use_art() function for the 
		# first (current turn) character in the queue
	var damage = sorted_array[0]["character"].use_art(art_num)
	deal_damage(damage)
	
	enemies.pick_random().get_attacked("", damage) # temp select enemy at random


func use_character_special():
	# use: calls the use_special() function for the
		# first (current turn) character in the queue 
	var damage = sorted_array[0]["character"].use_special()
	deal_damage(damage)
	enemies.pick_random().get_attacked("", damage) # temp select enemy at random


func set_status(status_type: String):
	# use: calls the set_status() function for the first 
		# character in the queue

	# i.e., self-applies 'haste'
	sorted_array[0]["character"].set_status(status_type)
	sort_and_display() # always call for change of speed


func show_combat_options():
	# use: shows the CombatOptions node

	combat_options.show()
	combat_options.get_child(0).grab_focus()


func select_enemy():
	# use: shows the EnemySelection node

	# note: can get EnemySelection the same way as CombatOptions
	# tutorial I followed just showed these two ways
	%EnemySelection.show()
	%EnemySelection.get_child(0).grab_focus()
