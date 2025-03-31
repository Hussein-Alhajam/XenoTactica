extends CharacterBody2D

class_name Character # name this CharacterStats?

# signals
signal movement_finished
# enums
enum ReactionState { NORMAL, BREAK, TOPPLE, LAUNCH }
# constants
# static variables
static var currently_selected_unit: Character = null
# export variables
@export var character_stats: CharacterStats # receives all 'unique traits' from this resource
# preload scene (so we don't have to set it in inspector manually)
@export var vfx_node: PackedScene = preload("res://TurnBattle/scenes/vfx.tscn") #?
@export var pathfinder: PathFinding
@export var grid_manager: GridManager
@export var move_range: int = 3
@export var move_speed: float = 300.0
@export var attack_range: int = 2
# other regular variables 
var tile_size = 80
var selected = false
var is_moving = false
var is_attacking = false
var can_be_selected := false  # This is controlled by the BattleScene when "Move" is selected
var character_name: String # name of character ('name' is taken by gdscript)
var icon: Texture2D # sprite used for the character's portrait
var max_health: int
var health: int
var strength: int 	# affects physical based damage
var ether: int 	# affects ether based attacks and healing
var defense: int # protects against physical attacks
var resistance: int # protects against ether attacks
var agility: int: # affects how often the character can act 
	# what does set do?
	set(value): 
		agility = value
		# formula to calculate speed
		# log curve so that early increases in agility give a lot of speed
		# but later increases give less 
		# note: log in gdscript is natural logarithm (ln), i.e., ln(e) = 1
		speed = 200.0 / (log(agility) + 2) - 25 
		queue_reset()
var element: String # fire/water/earth/wind/ice/electric/light/dark
var arts_list: Array[CombatArt]
var specials_list: Array[CombatSpecial]
var special_charge: int = 0
var reaction_turn_timer: int = 0
var reaction_state = ReactionState.NORMAL
var special_combo: Array # stores [ <element>, <turn timer> ] e.g., [ "fire", 1 ]
var speed: float 
var speed_bonus:float = 1.0 # changes the speed of the character
var queue: Array[float] # used to store this char's successive speed calculated from agility, should continually increase 

# onready variables
@onready var health_bar: ProgressBar = $HealthBar
@onready var damage_numbers_origin: Node2D = $DamageNumberOrigin

func _ready():
	character_name = character_stats.character_name
	icon = character_stats.icon
	max_health = character_stats.health
	health = character_stats.health
	strength = character_stats.strength
	ether = character_stats.ether
	defense = character_stats.defense
	resistance = character_stats.resistance
	agility = character_stats.agility
	element = character_stats.element
	arts_list = character_stats.arts_list
	specials_list = character_stats.specials_list
	
	$CharacterSprite.texture = character_stats.texture
	
	health_bar.init_health(health)
	
	# Ensure each character gets a unique copy of the arts
	var new_arts_list: Array[CombatArt] = []
	for art in arts_list:
		new_arts_list.append(art.duplicate(true))  # Deep copy
	arts_list = new_arts_list
	# same for specials
	var new_specials_list: Array[CombatSpecial] = []
	for special in specials_list:
		new_specials_list.append(special.duplicate(true))
	specials_list = new_specials_list

	queue_reset()
	
	if grid_manager == null:
		grid_manager = get_tree().get_first_node_in_group("grid_manager")
	if pathfinder == null:
		pathfinder = get_tree().get_first_node_in_group("pathfinder")
	if $Area2D:
		$Area2D.connect("input_event", Callable(self, "_on_area2d_input_event"))

	print("✅ PlayerUnit ready.")


func queue_reset():
	queue.clear()
	# add Arithmetic Progression of 4 terms
	# look this up
	for i in range(5):
		if queue.size() == 0:
			queue.append(speed * speed_bonus)
		else:
			queue.append(queue[-1]  + speed * speed_bonus)


func tween_movement(shift, tree):
	# used to 'shift' the character slightly when they attack
	var tween = tree.create_tween()
	tween.tween_property(self, "position", position + shift, 0.2)
	await tween.finished


func pop_out():
	# remove front node (current character to attack)
	# add next character to attack to end of queue
	queue.pop_front()
	queue.append(queue[-1] + speed * speed_bonus) # same as in queue_reset()


func add_vfx(type: String = ""):
	# function to instantiate and add vfx to the node
	var vfx = vfx_node.instantiate()
	add_child(vfx)
	# 'slash' is default animation (though i'm actually using a punching animation)
	if type == "":
		return
	vfx.find_child("AnimationPlayer").play(type)


func reset_reaction_status():
	reaction_state = ReactionState.NORMAL
	reaction_turn_timer = 0


func reset_all_status():
	reset_reaction_status()
	special_combo.clear()


func add_effect(effect_type: String, num_turns: int):
	#add_vfx(status_type)
	# if the status is "Haste" or "Slow", set status value accordingly
	#print("adding effect: " + effect_type)
	match effect_type:
		"Break":
			if reaction_state == ReactionState.NORMAL:
				reaction_state = ReactionState.BREAK
				reaction_turn_timer = num_turns
				print("added break for " + str(num_turns) + " turns")
		"Topple":
			if reaction_state == ReactionState.BREAK:
				reaction_state = ReactionState.TOPPLE
				reaction_turn_timer = num_turns
				print("added topple for " + str(num_turns) + " turns")
		"Launch":
			if reaction_state == ReactionState.TOPPLE:
				reaction_state = ReactionState.LAUNCH
				reaction_turn_timer = num_turns
				print("added launch for " + str(num_turns) + " turns")
		"Smash":
			if reaction_state == ReactionState.LAUNCH:
				print("smash used on launch")
				reset_reaction_status()
				return "Smash" # adding status was effective; apply smash dmg

		"haste":
			speed_bonus = 0.5
			# pop out the elements in the queue, except for first
			# (so that first will always go next and not be 'replaced')
			# game balance thing
			#print(queue)
			#for i in range(queue.size() - 1):
				#queue.pop_back()
			#print(queue)
			## append the new 'order'
			#for i in range(queue.size() - 1):
				#queue.append(queue[-1] + speed * status)
			#print(queue)
			#print("character.set_status called")


func add_special_combo(element: String):
	# if current special combo stage is none, or 1, add to it
	if special_combo.size() < 2:
		special_combo.append([element, 2])
	# if the current special stage is at 2, next will be stage 3 (the final stage) which ends the combo 
	elif special_combo.size() >= 2:
		special_combo.clear()
		return "Combo Finisher" #  combo is finished; deal combo finisher dmg


func _set_health(value: int):
	# update health
	health = min(health + value, max_health)
	print(character_name + ": " + str(health) + "hp")
	
	# update health bar
	health_bar.health = health
	
	# show 'damage' numbers (can be heal)
	DamageNumbers.display_number(value, damage_numbers_origin.global_position)
	# *lookup: position vs global_position
	
	# need some way of letting game know if this character dies
	# try: send signal with character reference,
	if health <= 0:
		kill_character()


func get_attacked(type = "", damage = 0):
	# add a 'hit' vfx on the character when attacked
	add_vfx(type)
	# reduce health 
	if damage > 0:
		damage = max(0, damage - defense)
		#print(str(damage) + " damage taken after defenses")
	_set_health(-damage)



func kill_character():
	print("killing character " + character_name)
	owner.kill_character(self) # emit signal with 'self' instead?
	queue_free()


# simply use this function to animate char,
# this allows every other 'attack' action to just call this
func play_attack_animation(animation, tree):
	# simple 'animation' for attacking
	var shift = Vector2(100, 0)
	# reverse the direction character moves if on left side
	# i.e., if character is on left side of screen, move right
	# vice versa for other side
	if position.x < get_viewport_rect().size.x / 2:
		shift = -shift
	# shift the character 'forward' then back
	await tween_movement(-shift, tree)
	await tween_movement(shift, tree)
	
	# emit the 'next_turn' signal from 'EventBus'
	#EventBus.next_turn.emit()	# pass the damage value


func use_normal_attack():
	# mechanic updates (damage, charge arts, accuracy, etc.)
	charge_arts(1)
	var damage = strength
	return damage


func charge_arts(num):
	for art in arts_list:
		art.charge_art(num) # can add 'art_charge_bonus' var and multiply with (for buffs)


func use_art(num):
	if arts_list[num].is_charged(): # should find better way to check...
		charge_arts(1) # charge other arts
		
		# calculate damage (or healing)
		var damage = arts_list[num].use_art() 
		if arts_list[num].attribute == "physical":
			damage = damage * strength
		elif arts_list[num].attribute == "ether":
			damage = damage * ether
		elif arts_list[num].attribute == "healing":
			damage = -damage * ether
			
		print(arts_list[num].art_name + " did " + str(damage) + " damage")
		
		charge_special(1) # charge special
		
		return damage

		#EventBus.next_turn.emit() # pass the damage value
	else: 
		return null


func get_art_effects(num: int):
	return arts_list[num].get_effects()


func is_max_special_charged(): # not needed?
	return special_charge >= 4


func charge_special(num):
	# charge special by num, cap to 4 (max charge is 4)
	special_charge = min(special_charge + num, 4)


func reset_special_charge():
	# reset the charge to 0
	special_charge = 0


func use_special():
	if special_charge > 0:
		# calculate damage
		var damage = specials_list[special_charge - 1].use_special()
		if specials_list[special_charge - 1].attribute == "physical":
			damage = damage * strength
		elif specials_list[special_charge - 1].attribute == "ether":
			damage = damage * ether
		print(specials_list[special_charge - 1].special_name + " did " + str(damage) + " damage")
		reset_special_charge()
		
		return damage
	else: 
		return null


func get_art_info(num):
	var art_info = {
		"name": arts_list[num].art_name,
		"attribute": arts_list[num].attribute,
		"effects": arts_list[num].get_effects(),
		"current_charge": arts_list[num].current_charge,
		"max_charge": arts_list[num].max_charge,
	}
	return art_info


func get_special_info():
	if special_charge > 0:
		var special_info = {
			"name": specials_list[special_charge - 1].special_name,
			"charge": special_charge,
			#"effects": special_list[special_charge - 1].get_effects()
		}
		return special_info
	else:
		return null


func _input(event):
	if is_moving or grid_manager == null or pathfinder == null:
		return

	if selected and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var mouse_pos = get_global_mouse_position()
		var clicked_tile = grid_manager.tile_map.local_to_map(mouse_pos)
		move_to_tile(clicked_tile)

func _on_area2d_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if not is_moving and not is_attacking:
			select_unit()

func select_unit():

	if not can_be_selected:
		print("❌ select_unit() blocked - can_be_selected is false for", name)
		return

	print("select_unit() started for", name)
	selected = true
	currently_selected_unit = self
	grid_manager.clear_highlight()

	var unit_tile = grid_manager.tile_map.local_to_map(global_position)
	print("🗺️ Unit tile:", unit_tile)
	grid_manager.highlight_tiles(unit_tile, move_range)

	print("Movement range shown for", name)


func move_to_tile(target_tile: Vector2i):
	if not selected or is_moving:
		return
	for unit in get_tree().get_nodes_in_group("player_units"):
		if unit != self and grid_manager.tile_map.local_to_map(unit.global_position) == target_tile:
			print("Tile occupied by another unit!")
			return

	var unit_tile = grid_manager.tile_map.local_to_map(global_position)
	var path = pathfinder.find_path(unit_tile, target_tile)
	if path.size() <= 1 or path.size() > move_range + 1:
		print("Invalid move target.")
		return
	grid_manager.clear_highlight()
	print("✅ Moving unit to", target_tile)
	follow_path(path)

func follow_path(path: Array):
	is_moving = true
	for tile in path:
		var world_pos = grid_manager.tile_map.map_to_local(tile)
		while global_position.distance_to(world_pos) > 1.0:
			velocity = (world_pos - global_position).normalized() * move_speed
			move_and_slide()
			await get_tree().process_frame
	velocity = Vector2.ZERO
	is_moving = false
	Global.battle_scene.show_action_selection()
	selected = false
	var tile = grid_manager.tile_map.local_to_map(global_position)
	emit_signal("movement_finished")  # Signal movement is done
	#grid_manager.highlight_attack_tiles(tile, attack_range)
	#is_attacking = true
	
func get_enemies_in_attack_range(enemies: Array[Character]) -> Array[Character]:
	var in_range: Array[Character] = []
	if not grid_manager:
		grid_manager = get_tree().get_first_node_in_group("grid_manager")
	if not grid_manager:
		push_error("No GridManager found.")
		return in_range

	var tile_map = grid_manager.tile_map
	if not tile_map:
		push_error("No TileMap in GridManager.")
		return in_range

	var current_tile = tile_map.local_to_map(global_position)
	var attack_tiles = grid_manager.get_tiles_in_range(current_tile, attack_range)

	for enemy in enemies:
		var enemy_tile = tile_map.local_to_map(enemy.global_position)
		if enemy_tile in attack_tiles:
			in_range.append(enemy)

	return in_range

func move_towards_target(target_position: Vector2, max_tiles := -1) -> void:
	if max_tiles == -1:
		max_tiles = move_range

	var my_tile = global_position / tile_size
	var target_tile = target_position / tile_size
	var direction = (target_tile - my_tile).normalized().round()

	var steps = min(my_tile.distance_to(target_tile), max_tiles)
	var step_vector = direction * steps * tile_size
	var final_position = global_position + step_vector

	is_moving = true
	while global_position.distance_to(final_position) > 1.0:
		var dir = (final_position - global_position).normalized()
		velocity = dir * move_speed
		move_and_slide()
		await get_tree().process_frame

	global_position = final_position
	velocity = Vector2.ZERO
	is_moving = false
