extends Resource

class_name Character

@export var title: String # name of character (name is taken by gdscript)
@export var icon: Texture2D # sprite used for the character's portrait
@export var texture: Texture2D # sprite used for the character
@export var agility: int:
	# what does set do?
	set(value): 
		agility = value
		# formula to calculate speed
		# log curve so that early increases in agility give a lot of speed
		# but later increases give less 
		# note: log in gdscript is natural logarithm (ln), i.e., ln(e) = 1
		speed = 200.0 / (log(agility) + 2) - 25 
		queue_reset()
# preload scene (so we don't have to set it in inspector manually)
@export var vfx_node: PackedScene = preload("res://demo_turn_based_combat_/scenes/vfx.tscn")

var speed: float 
var queue: Array[float] # used to store successive speed / duration?
var status = 1 # int? used to store reference?
var node # ? used to store reference


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


func get_attacked(type = ""):
	# add a 'hit' vfx on the character when attacked
	add_vfx(type)
	# add health reduction later


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
