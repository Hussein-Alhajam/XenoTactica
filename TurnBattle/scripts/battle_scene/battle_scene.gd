extends Node2D

# signals
#signal arts_selected

# enums
enum TurnState { NEUTRAL, ATTACKED, MOVED, SKIPPED }
enum ActiveHud { COMBAT, SETTINGS_OPTIONS, TITLE_MENU }

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
var players: Array[Character] # used to hold Player 'scene' nodes
var enemies: Array[Character] # used to hold Enemy 'scene' nodes

var is_arts_selected: bool = false # should make into FSM

var turn_state = TurnState.NEUTRAL
var active_hud = ActiveHud.COMBAT

# temp variable for the temp controls UI
var ui_controls := {}


func _ready():
	
	# add this node as a global reference
	Global.battle_scene = self
	
	# loop through and append all the player resources
	for player in player_group.get_children():
		#player.character.init()
		players.append(player)

	for enemy in enemy_group.get_children():
		#enemy.character.init()
		enemies.append(enemy)

	sort_and_display() 
	
	# connect the signal 'next_turn' from 'EventBus'
	# to the function next_turn() from below
	# whenever attack() is called in character.gd,
		# signal gets emitted and next_turn() in here is called
	EventBus.next_turn.connect(next_turn)

	next_turn()

func _process(delta: float) -> void:
	pass


func update_action_log(message: String):
	$UI/ActionLog.text = message


# ----functions for dealing with turn order (the character queue)----

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
		#show_action_selection?


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
	# temp - enemy only uses normal attack
	var damage = sorted_array[0]["character"].use_normal_attack()
	deal_damage(damage)
	players.pick_random().get_attacked("", damage) # temp randomly select a player to be attacked


func use_character_normal_attack(target_enemy: Character):
	# use: calls the use_normal_attack() function for the
		# first (current turn) character in the queue 
	var damage = sorted_array[0]["character"].use_normal_attack()
	deal_damage(damage)
	
	target_enemy.get_attacked("", damage)


func use_character_art(target_enemy: Character, art_num: int):
	# use: calls the use_art() function for the 
		# first (current turn) character in the queue
	var damage = sorted_array[0]["character"].use_art(art_num)
	if damage:
		deal_damage(damage)
		target_enemy.get_attacked("", damage)
	else:
		update_action_log("Art is not charged")
		return


func use_character_special(target_enemy: Character):
	# use: calls the use_special() function for the
		# first (current turn) character in the queue 
	var damage = sorted_array[0]["character"].use_special()
	if damage:
		deal_damage(damage)
		target_enemy.get_attacked("", damage)
	else:
		update_action_log("Special has no charge")
		return


func set_status(status_type: String):
	# use: calls the set_status() function for the first 
		# character in the queue

	# i.e., self-applies 'haste'
	sorted_array[0]["character"].set_status(status_type)
	sort_and_display() # always call for change of speed


func kill_character(character: Character):
	if character in players:
		players.erase(character)
		print(players)
	if character in enemies:
		enemies.erase(character)
		print(enemies)
	sort_and_display()


func get_enemies():
	return enemies


func get_players():
	return players


func get_character_arts():
	var arts_info = [
		["art0", sorted_array[0]["character"].get_art_info(0)],
		["art1", sorted_array[0]["character"].get_art_info(1)],
		["art2", sorted_array[0]["character"].get_art_info(2)],
	]

	return arts_info


func move_selected():
	sorted_array[0]["character"].select_unit()


# ---- functions connected to signals from action select menu ----

func _on_action_selection_container_move_selected() -> void:
	move_selected()


func _on_action_selection_container_attack_selected(attack_type: String, target: Character) -> void:
	match attack_type:
		"normal_attack":
			use_character_normal_attack(target)
		"art0":
			use_character_art(target, 0)
		"art1":
			use_character_art(target, 1)
		"art2":
			use_character_art(target, 2)
		"special":
			use_character_special(target)


func _on_action_selection_container_end_turn_selected() -> void:
	pass # Replace with function body.
