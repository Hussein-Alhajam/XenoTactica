extends CharacterBody2D

class_name Character # name this CharacterStats?

# onready variables
@onready var health_bar: ProgressBar = $HealthBar
@onready var damage_numbers_origin: Node2D = $DamageNumberOrigin

# export variables
@export var character_stats: CharacterStats # receives all 'unique traits' from this resource
# preload scene (so we don't have to set it in inspector manually)
@export var vfx_node: PackedScene = preload("res://TurnBattle/scenes/vfx.tscn") #?
@export var pathfinder: PathFinding
@export var grid_manager: GridManager
@export var move_range: int = 3
@export var move_speed: float = 100.0
@export var attack_range: int = 1
var selected = false
var is_moving = false
var is_attacking = false
static var currently_selected_unit: Character = null
# public variables 
var character_name: String # name of character ('name' is taken by gdscript)
# textures (remove and assign to CharacterSprite node instead?)
var icon: Texture2D # sprite used for the character's portrait
# stats
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
# abilities
var arts_list: Array[CombatArt]
var specials_list: Array[CombatSpecial]

var speed: float 
var queue: Array[float] # used to store this char's successive speed calculated from agility, should continually increase 
var status = 1 # int? used to store reference?

var special_charge: int = 0

# could use AutoLoad on a 'Global' script/class which has battle_scene
# in here func _ready(): Global.battle_scene = self
# then in other scripts, call Global.battle_scene.function()
var battle_scene: Node2D # used to store reference of main battle_scene Scene


func _ready():
	character_name = character_stats.character_name
	icon = character_stats.icon
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
	for i in range(4):
		if queue.size() == 0:
			queue.append(speed * status)
		else:
			queue.append(queue[-1]  + speed * status) # ?


func tween_movement(shift, tree):
	# used to 'shift' the character slightly when they attack
	var tween = tree.create_tween()
	tween.tween_property(self, "position", position + shift, 0.2)
	await tween.finished


func pop_out():
	# remove front node (current character to attack)
	# add next character to attack to end of queue
	queue.pop_front()
	queue.append(queue[-1] + speed * status) # same as in queue_reset()


func add_vfx(type: String = ""):
	# function to instantiate and add vfx to the node
	var vfx = vfx_node.instantiate()
	add_child(vfx)
	# 'slash' is default animation (though i'm actually using a punching animation)
	if type == "":
		return
	vfx.find_child("AnimationPlayer").play(type)


func set_status(status_type: String):
	add_vfx(status_type)
	# if the status is "Haste" or "Slow", set status value accordingly
	match status_type:
		"haste":
			status = 0.5
		"slow":
			status = 2
	
	# pop out the elements in the queue, except for first
	# (so that first will always go next and not be 'replaced')
	# game balance thing
	print(queue)
	for i in range(3):
		queue.pop_back()
	print(queue)
	# append the new 'order'
	for i in range(3):
		queue.append(queue[-1] + speed * status)
	print(queue)
	print("character.set_status called")


func _set_health(value: int):
	# update health
	health = health + value
	print(character_name + ": " + str(health) + "hp")
	
	# update health bar
	health_bar.health = health
	
	# show 'damage' numbers (can be heal)
	DamageNumbers.display_number(value, damage_numbers_origin.global_position, "#FF0000")
	# *lookup: position vs global_position
	
	# need some way of letting game know if this character dies
	# try: send signal with character reference,
	if health <= 0:
		kill_character()


func get_attacked(type = "", damage = 0):
	# add a 'hit' vfx on the character when attacked
	add_vfx(type)
	# reduce health 
	_set_health(-damage)


func kill_character():
	print("tried killing character " + character_name)
	Global.battle_scene.kill_character(self) # emit signal with 'self' instead?
	queue_free()


# simply use this function to 'deal' dmg, animate char, 
# and have oppenent 'react' to dmg ? this allows every other 'attack' 
# action to just call this to apply the dmg (reduce duplicate code)
func attack(tree):
	# change name to play_attack_animation? maybe add 
		# parameter to function to accept animation

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
	EventBus.next_turn.emit()	# pass the damage value


func use_normal_attack():
	#print(title + ": " + arts_list[0].art_name + " charge:" + str(arts_list[0].current_charge))
	# mechanic updates (damage, charge arts, accuracy, etc.)
	charge_arts(1)
	# calculate damage of attack
	var damage = max(strength, ether) # temp: use higher of strength or ether
	return damage


func charge_arts(num):
	for art in arts_list:
		art.charge_art(num)


func use_art(num):
	if arts_list[num].is_charged(): # should find better way to check...
		charge_arts(1) # charge other arts
		
		# calculate damage
		var damage = arts_list[num].use_art() 
		damage = damage * max(strength, ether)
		print("art did " + str(damage) + " damage")
		
		charge_special(1) # charge special
		
		return damage

		#EventBus.next_turn.emit() # pass the damage value
	else: 
		return null


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
		damage = damage * max(strength, ether)
		print("special did " + str(damage) + " damage")
		reset_special_charge()
		
		return damage
	else: 
		return null


func get_art_info(num):
	var art_info = {
		"name": arts_list[num].art_name,
		"effects": arts_list[num].get_effects(),
		"current_charge": arts_list[num].current_charge,
		"max_charge": arts_list[num].max_charge,
	}
	return art_info


func get_special_info():
	if special_charge > 0:
		var special_info = {
			"name": specials_list[special_charge - 1].special_name,
		}
	else:
		return "no special charge"


func _input(event):
	if is_moving or grid_manager == null or pathfinder == null:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		if is_attacking:
			cancel_attack_selection()
		elif selected:
			cancel_selection()
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
	if currently_selected_unit != null and currently_selected_unit != self:
		return
	selected = true
	currently_selected_unit = self
	grid_manager.clear_highlight()
	var unit_tile = grid_manager.tile_map.local_to_map(global_position)
	grid_manager.highlight_tiles(unit_tile, move_range)
	print("✅ Unit selected. Showing movement range.")

func cancel_selection():
	selected = false
	is_attacking = false
	currently_selected_unit = null
	grid_manager.clear_highlight()
	grid_manager.clear_attack_highlight()
	print("❌ Selection canceled.")

func cancel_attack_selection():
	is_attacking = false
	selected = false
	currently_selected_unit = null
	grid_manager.clear_attack_highlight()
	print("❌ Attack selection canceled.")

func move_to_tile(target_tile: Vector2i):
	if not selected or is_moving:
		return
	for unit in get_tree().get_nodes_in_group("player_units"):
		if unit != self and grid_manager.tile_map.local_to_map(unit.global_position) == target_tile:
			print("❌ Tile occupied by another unit!")
			return

	var unit_tile = grid_manager.tile_map.local_to_map(global_position)
	var path = pathfinder.find_path(unit_tile, target_tile)
	if path.size() <= 1 or path.size() > move_range + 1:
		print("❌ Invalid move target.")
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
	selected = false
	var tile = grid_manager.tile_map.local_to_map(global_position)
	grid_manager.highlight_attack_tiles(tile, attack_range)
	is_attacking = true
