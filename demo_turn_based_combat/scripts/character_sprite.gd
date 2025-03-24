extends Sprite2D

class_name CharacterSprite
# variable used to hold Character class
@export var character: Character

var character_name: String # name of character (name is taken by gdscript)
var icon: Texture2D # sprite used for the character's portrait
#var texture: Texture2D # sprite used for the character

# preload scene (so we don't have to set it in inspector manually)
var vfx_node: PackedScene = preload("res://scenes/vfx.tscn")

var health: int
var strength: int
var ether: int
var defense: int
var resistance: int
var agility: int:
	# what does set do?
	set(value): 
		agility = value
		# formula to calculate speed
		# log curve so that early increases in agility give a lot of speed
		# but later increases give less 
		# note: log in gdscript is natural logarithm (ln), i.e., ln(e) = 1
		speed = 200.0 / (log(agility) + 2) - 25 
		queue_reset()
var element: String 
var arts_list: Array[CombatArt]
var specials_list: Array[CombatSpecial]

var speed: float 
var queue: Array[float] 

var status = 1 # int? used to store reference?
var special_charge: int = 0

# could use AutoLoad on a 'Global' script/class which has battle_scene
# in here func _ready(): Global.battle_scene = self
# then in other scripts, call Global.battle_scene.function()
var battle_scene: Node2D # used to store reference of main battle_scene Scene


func _ready():
	if character:
		# set reference
		character.node = self
		icon = character.icon
		# assigned texture to Sprite2D
		texture = character.texture
		character_name = character.title
		health = character.health
		strength = character.strength
		ether = character.ether
		defense = character.defense
		resistance = character.resistance
		agility = character.agility
		element = character.element
		arts_list = character.arts_list
		specials_list = character.specials_list
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


func get_attacked(type = "", damage = 0):
	# add a 'hit' vfx on the character when attacked
	add_vfx(type)
	# reduce health 
	health = health - damage
	print(character_name + ": " + str(health) + "hp")
	# need some way of letting game know if this character dies
	# try: send signal with character reference,
	
	if health < 0:
		kill_character()


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


func get_art_name(num):
	return arts_list	[num].art_name


func get_art_charges(num):
	return [arts_list[num].current_charge, arts_list[num].max_charge]


func get_special_name():
	if special_charge > 0:
		return specials_list[special_charge - 1].special_name
	else:
		return "no special charge"


# move 'functional' methods here?
func kill_character():
	print("tried killing character " + character.title)
	Global.battle_scene.kill_character(self)
	queue_free()
