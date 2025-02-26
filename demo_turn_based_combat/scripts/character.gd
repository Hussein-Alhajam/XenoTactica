extends Resource

class_name Character

@export var title: String # name of character (name is taken by gdscript)
@export_group("Textures and Sound")
@export var icon: Texture2D # sprite used for the character's portrait
@export var texture: Texture2D # sprite used for the character
# preload scene (so we don't have to set it in inspector manually)
@export var vfx_node: PackedScene = preload("res://scenes/vfx.tscn")

@export_group("Stats")
@export var health: int
@export var strength: int 	# the 'general' damage that the character does ,
								# affects (phys) attacks, arts, special
@export var ether: int 	# basically strength but for 'magic, 
							# affects ether based attacks and healing
@export var defense: int # protects against physical attacks
@export var resistance: int # protects against ether attacks
@export var agility: int: # affects how often the character can act 
	# what does set do?
	set(value): 
		agility = value
		# formula to calculate speed
		# log curve so that early increases in agility give a lot of speed
		# but later increases give less 
		# note: log in gdscript is natural logarithm (ln), i.e., ln(e) = 1
		speed = 200.0 / (log(agility) + 2) - 25 
		queue_reset()
@export var element: String # fire/water/earth/wind/ice/electric/light/dark

@export_group("Abilities")
@export var arts_list: Array[CombatArt]
@export var specials_list: Array[CombatSpecial]

var speed: float 
var queue: Array[float] # used to store successive speed / duration?
var status = 1 # int? used to store reference?
var node # used to store reference of character_sprite (Sprite2D) node

var special_charge: int = 0
# could use AutoLoad on a 'Global' script/class which has battle_scene
# in here func _ready(): Global.battle_scene = self
# then in other scripts, call Global.battle_scene.function()
var battle_scene: Node2D # used to store reference of main battle_scene Scene


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
	tween.tween_property(node, "position", node.position + shift, 0.2)
	await tween.finished


func pop_out():
	# remove front node (current character to attack)
	# add next character to attack to end of queue
	queue.pop_front()
	queue.append(queue[-1] + speed * status) # same as in queue_reset()


func add_vfx(type: String = ""):
	# function to instantiate and add vfx to the node
	var vfx = vfx_node.instantiate()
	node.add_child(vfx)
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
	for i in range(3): # not sure how this works (why use 4 in queue_reset()?)
		queue.pop_back()
	print(queue)
	# append the new 'order'
	for i in range(3):
		queue.append(queue[-1] + speed * status)
	print(queue)


func get_attacked(type = ""):
	# add a 'hit' vfx on the character when attacked
	add_vfx(type)
	# add health reduction later


# simply use this function to 'deal' dmg, animate char, 
# and have oppenent 'react' to dmg ? this allows every other 'attack' 
# action to just call this to apply the dmg (reduce duplicate code)
func attack(tree):
	var shift = Vector2(100, 0)
	# reverse the direction character moves if on left side
	# i.e., if character is on left side of screen, move right
	# vice versa for other side
	if node.position.x < node.get_viewport_rect().size.x / 2:
		shift = -shift

	# shift the character 'forward' then back
	await tween_movement(-shift, tree)
	await tween_movement(shift, tree)

	# emit the 'next_attack' signal from 'EventBus'
	EventBus.next_attack.emit()


func charge_arts(num):
	for art in arts_list:
		art.charge_art(num)


func use_art(num):
	if arts_list[num].is_charged(): # should find better way to check...
		charge_arts(1)
		arts_list[num].use_art() #... maybe could have this return bool?
		charge_special(1)


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
		specials_list[special_charge - 1].use_special()
		reset_special_charge()
	else: 
		Global.battle_scene.update_action_log("Special has no charge")
