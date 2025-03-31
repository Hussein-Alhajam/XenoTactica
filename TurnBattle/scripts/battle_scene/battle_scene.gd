extends Node2D

# signals
#signal arts_selected

# enums
enum TurnState { NEUTRAL, ATTACKED, MOVED, ENDED }
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
var active_character: Character = null

var turn_state = TurnState.NEUTRAL
var active_hud = ActiveHud.COMBAT

# temp variable for the temp controls UI
#var ui_controls := {}


func _ready():
	
	# add this node as a global reference
	Global.battle_scene = self
	
	# loop through and append all the player resources
	for player in player_group.get_children():
		players.append(player)

	for enemy in enemy_group.get_children():
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
		# character.queue). First character in this array is
		# the current character who has their turn

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
	active_character = sorted_array[0]["character"]


func sort_by_time(a, b):
	# use: custom sort function to sort the players 
		# in ascending order based on their "time"
	return a["time"] < b["time"]


func sort_and_display():
	# use: sorts and updates the turn order queue and 
		# update the # UI for turn order

	#print("sort and display")
	# call our sort and update functions defined above
	sort_combined_queue()
	update_timeline()
	
	# after sorting, if the first element in the queue
	# is a Player, then show the option to the player
	if active_character in players:
		#print("showing action")
		show_action_selection()


func pop_out():
	# use: removes current character from sorted_array queue
		# i.e., pops the 'speed' off queue of the current character
		# to update their turn order and call 
		# sort_and_display() to update the turn order queue
		# and the turn order UI

	# call the pop_out() function defined in character.gd
	active_character.pop_out()


func give_player_turn():
	show_action_selection()
	return


func give_enemy_turn():
	# temp - enemy has already moved
	#turn_state = TurnState.MOVED
	#vai wasr target_player = players.pick_random() # temp randomly select a player to be attacked
	# temp - enemy only uses normal attack
	#var damage = active_character.use_normal_attack()
	#deal_damage(damage, target_player)
	turn_state = TurnState.MOVED

	var enemy_unit := active_character as Character  # character.gd
	if enemy_unit == null:
		end_turn()
		return

	var closest_player : Character = get_closest_player()
	if closest_player == null:
		end_turn()
		return

	# Move enemy toward closest player using move_range
	if enemy_unit.has_method("move_towards_target"):
		await enemy_unit.move_towards_target(closest_player.global_position, enemy_unit.move_range)

	await get_tree().create_timer(0.3).timeout

	# Check all players to see if any are in range
	var attack_target: Character = null
	for player in players:
		if enemy_unit.global_position.distance_to(player.global_position) <= enemy_unit.attack_range * 80:
			attack_target = player
			break

	if attack_target:
		var choice = randi() % 4
		match choice:
			0: use_character_normal_attack(attack_target)
			1: use_character_art(attack_target, 0)
			2: use_character_art(attack_target, 1)
			3: use_character_special(attack_target)
	else:
		print("❌ Enemy couldn’t reach anyone in range.")
		end_turn()


func check_active_character_status():
	# check for special combo status
	# if there is a special combo active on current character
	if active_character.special_combo.size() > 0:
		# check the combo duration; if the duration is < 1, end the combo
		if active_character.special_combo[-1][1] < 1:
			#print("combo timed out")
			active_character.special_combo.clear()
		else:
			# else, simply do some 'dot' dmg based on stage of combo
			# and reduce the turn timer for combo
			#print("combo duraction (turns):")
			#print(active_character.special_combo[-1][1])
			active_character.special_combo[-1][1] = active_character.special_combo[-1][1] - 1
			active_character.get_attacked("", 20 * active_character.special_combo.size())

	# check for other statuses (none for now...)
	# e.g., if character has a dot status, get dot status dmg, active_character.get_attacked("", damage)
	
	# check for reaction status on active character
	# if reaction timer is less than 1 (status effect is over), then reset reaction status on character 
	if active_character.reaction_turn_timer < 1:
		active_character.reset_reaction_status()
	# if reaction is break, decrement reaction timer
	elif active_character.reaction_state == active_character.ReactionState.BREAK:
		active_character.reaction_turn_timer = active_character.reaction_turn_timer - 1
	# if reaction is topple or launch, decrement reaction timer and skip turn
	elif active_character.reaction_state == active_character.ReactionState.TOPPLE or active_character.reaction_state == active_character.ReactionState.LAUNCH:
		active_character.reaction_turn_timer = active_character.reaction_turn_timer - 1
		return "skip"


func next_turn():
	# use: pop the queue to get the next character's turn
		# i.e., ends the current turn and allows the next
		# character in the queue to go
	
	# check if either player or enemy array is empty (end battle if so)
	if players.is_empty():
		print("all players defeated")
		return
	if enemies.is_empty():
		print("all enemies defeated")
		return
	
	# check for statuses on character
	if check_active_character_status() == "skip":
		end_turn()

	# if the active char is Player, give control to player
	if active_character in players:
		give_player_turn()

	# otherwise, it's enemy's turn, handle with ai
	# in a way, attack and getting attacked are 'separate'
	# e.g., char does animation for attack, but doesn't actually 
	# 'hit', then player/enemy selects a char to be attacked
	else:
		give_enemy_turn()


func end_turn():
	$UI/ActionSelectionContainer.hide()
	active_character.can_be_selected = false
	turn_state = TurnState.NEUTRAL
	pop_out()
	sort_and_display() 
	next_turn()
	
# ---- functions to do with ui / hud changes ----

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


func show_action_selection():
	#print("show selection")
	$UI/ActionSelectionContainer.init_action_selection() # temp
	$UI/ActionSelectionContainer.show()
	#$UI/ActionSelectionContainer.get_child(0).grab_focus()

# ---- functions to do with attacking / turn actions ----


func can_attack():
	if turn_state == TurnState.ATTACKED or turn_state == TurnState.ENDED:
		#print("already attacked")
		return false
	return true


func deal_damage(damage: int, target_enemy: Character):
	# use: calls the attack() function for the 
		# first character in the queue (current turn)
		# and call the get_attacked function for the 
		# target of the attack

	# todo changes:
		# add: aoe param to 'hit' characters around target

	# check if attack has already been used this turn
		# somewhat redundant since player should not be 
		# able to select the 'attacks' button if already attacked
	if not can_attack():
		return

	if turn_state == TurnState.NEUTRAL:
		turn_state = TurnState.ATTACKED
	elif turn_state == TurnState.MOVED:
		turn_state = TurnState.ENDED
	
	# log: check correct damage
	#print(str(damage) + " raw damage from attack") 
	# perform attack and apply statuses
	target_enemy.get_attacked("", damage)

	await active_character.play_attack_animation("", get_tree())
	
	if turn_state == TurnState.ENDED: # bandaid fix...
		end_turn()


func apply_status_effect(effect: String, target_enemy: Character, damage: int = 0):
	#print("applying effect: " + effect)
	var status = target_enemy.add_effect(effect, 1)
	if status == "Smash":
		# if smash attack succeeds, apply damage of attack * 2 as Smash dmg
		target_enemy.get_attacked("", damage * 2)
		#---
		# when using art (use_character_art), return daamge and should also 
		# return effects from that art. Could alternatively create different method 
		# to handle effects altogether rather than passing new effects param to deal_damage()
		# in func apply_status_effect(effect, target_enemy):
			# target_enemy.add_status(effect, turns)
		#---


func use_character_normal_attack(target_enemy: Character):
	# use: calls the use_normal_attack() function for the
		# first (current turn) character in the queue 
	if can_attack():
		var damage = active_character.use_normal_attack()
		deal_damage(damage, target_enemy)


func use_character_art(target_enemy: Character, art_num: int):
	# use: calls the use_art() function for the 
		# first (current turn) character in the queue
	if can_attack():
		var damage = active_character.use_art(art_num)
		var effects = active_character.get_art_effects(art_num)
		if damage:
			# apply status effects (if any) to target
			for effect in effects:
				apply_status_effect(effect, target_enemy, damage)
			deal_damage(damage, target_enemy)
		else:
			update_action_log("Art is not charged")
			return


func use_character_special(target_enemy: Character):
	# use: calls the use_special() function for the
		# first (current turn) character in the queue 
	if can_attack():
		var special_charge = active_character.special_charge
		var damage = active_character.use_special()
		if damage:

			# check if special used is of higher level than current stage of special combo on target
			if special_charge > target_enemy.special_combo.size():
				# if so, advance combo
				var combo_result = target_enemy.add_special_combo(active_character.element)
				# check if last stage (stage 3) of combo was reached, if so, combo finished
				if combo_result == "Combo Finisher":
					print('Stage 3 combo reached')
					# deal a 'combo finisher' dmg
					target_enemy.get_attacked("", 100)

			deal_damage(damage, target_enemy)
		else:
			update_action_log("Special has no charge")
			return


#func set_status(status_type: String):
	## use: calls the set_status() function for the first 
		## character in the queue
#
	## i.e., self-applies 'haste'
	#active_character.set_status(status_type)
	#sort_and_display() # always call for change of speed

func get_closest_player() -> Character:
	var closest: Character = null
	var shortest_dist := INF

	for player in players:
		var dist = active_character.global_position.distance_to(player.global_position)
		if dist < shortest_dist:
			shortest_dist = dist
			closest = player

	return closest

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
		["art0", active_character.get_art_info(0)],
		["art1", active_character.get_art_info(1)],
		["art2", active_character.get_art_info(2)],
	]

	return arts_info


func get_character_special():
	var special_info = active_character.get_special_info()
	return special_info


func can_move() -> bool:
	return turn_state != TurnState.MOVED and turn_state != TurnState.ENDED
		#print("already moved")
		#return false
	#return true


func move_selected():
	if can_move():
		$UI/ActionSelectionContainer.hide()  # Hide menu
		active_character.can_be_selected = true
		active_character.select_unit()

		# Update state
		if turn_state == TurnState.NEUTRAL:
			turn_state = TurnState.MOVED
		elif turn_state == TurnState.ATTACKED:
			turn_state = TurnState.ENDED
		
func _on_movement_finished():
	$UI/ActionSelectionContainer.show()
	$UI/ActionSelectionContainer.init_action_selection()
	active_character.movement_finished.disconnect(_on_movement_finished)

	if turn_state == TurnState.ENDED:
		end_turn()

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
	end_turn()

const TurnStateEnum = TurnState
