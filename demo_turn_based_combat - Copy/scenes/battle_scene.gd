extends Node2D

@export var player_group: Node2D # hold the 'Players' node
@export var enemy_group: Node2D # hold the 'Enemies' node
@export var timeline: HBoxContainer # hold the "Timeline' node
@export var combat_options: VBoxContainer # hold the 'CombatOptions' node
@export var enemy_button: PackedScene # variable to hold "EnemyButton'

var sorted_array = [] # used for sorting the turn order (?)
var players: Array[Character] # used to hold the player resource
var enemies: Array[Character] # used to hold the enemy resource


func _ready():
	# loop through and append all the player resources
	for player in player_group.get_children():
		players.append(player.character)

	for enemy in enemy_group.get_children():
		enemies.append(enemy.character)
		
		var button = enemy_button.instantiate()
		button.character = enemy.character
		%EnemySelection.add_child(button)

	sort_and_display() 
	# connect the signal 'next_attack' from 'EventBus'
	# to the function next_attack() from below
	# whenever attack() is called in character.gd,
		# signal gets emitted and next_attack() in here is called
	EventBus.next_attack.connect(next_attack)

	next_attack()

func sort_combined_queue():
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
	# custom sort function to sort the players in ascending
	# order based on their "time"
	return a["time"] < b["time"]


func update_timeline():
	var index: int = 0
	# loop through each slot ('TimelineSlot') in 'Timeline' node
	for slot in timeline.get_children():
		# set each slot's icon with respect to the 
		# character's icon in the sorted array
		slot.find_child("TextureRect").texture = sorted_array[index]["character"].icon
		index += 1


func sort_and_display():
	# call our sort and update functions defined above
	sort_combined_queue()
	update_timeline()
	# after sorting, if the first element in the queue
	# is a Player, then show the option to the player
	if sorted_array[0]["character"] in players:
		show_combat_options()


func pop_out():
	# call the pop_out() function defined in character.gd
	sorted_array[0]["character"].pop_out()
	# sort the queue and update the display order
	sort_and_display() # always call for any change of speed


func attack():
	# call the attack() function defined in character.gd
	sorted_array[0]["character"].attack(get_tree())


func next_attack():
	# if the first element is Player, return (don't want to auto attack)
	if sorted_array[0]["character"] in players:
		return
	# otherwise, it's enemy attack (have them 'auto' attack)
	# in a way, attack and getting attacked are 'separate'
	# e.g., enemy does animation for attack, but doesn't actually 'hit'
	# then code randomly selects a player to be attacked
	# side note: enemy does animation, then player get attacked
		# but in enemy_button.gd, enemy get attacked, then player char does animation
	attack()
	pop_out()
	players.pick_random().get_attacked() # randomly select a player to be attacked


func set_status(status_type: String):
	# calls set_status on first character in queue
	# i.e., self-applies 'haste'
	sorted_array[0]["character"].set_status(status_type)
	sort_and_display() # always call for change of speed


func show_combat_options():
	combat_options.show()
	combat_options.get_child(0).grab_focus()


func select_enemy():
	# note: can get EnemySelection the same way as CombatOptions
	# tutorial I followed just showed these two ways
	%EnemySelection.show()
	%EnemySelection.get_child(0).grab_focus()
