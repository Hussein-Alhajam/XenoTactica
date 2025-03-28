extends CharacterBody2D
class_name EnemyUnitBattle

var vfx_node: PackedScene = preload("res://demo_turn_based_combat_/TurnBattle/scenes/vfx.tscn")
@export var character: Character

var queue: Array[float] = []
var speed: float  # or set this via export from the Character data
var status := 1.0

func _ready():
	if character:
		speed = 200.0 / (log(character.agility) + 2) - 25
		print("Enemy", character.title, "agility:", character.agility, "calculated speed:", speed)
	else:
		speed = 100.0  # fallback
	print("✅ EnemyUnit _ready() called for", name)
	queue_reset()

func queue_reset():
	queue.clear()
	print("Resetting enemy queue for", name)
	for i in range(4):
		if queue.is_empty():
			queue.append(speed * status)
		else:
			queue.append(queue[-1] + speed * status)
	print("Queue now:", queue)

func attack(tree):
	var shift = Vector2(50, 0)
	if position.x < get_viewport_rect().size.x / 2:
		shift = -shift
	await tween_movement(-shift, tree)
	await tween_movement(shift, tree)
	EventBus.next_turn.emit()

func tween_movement(shift, tree):
	var tween = tree.create_tween()
	tween.tween_property(self, "position", position + shift, 0.2)
	await tween.finished

func pop_out():
	queue.pop_front()
	queue.append(queue[-1] + speed * status)

func get_attacked(type := "", damage := 0):
	add_vfx(type)
	character.health -= damage
	print(character.title, " took ", damage, " damage. Remaining HP: ", character.health)
	if character.health <= 0:
		print(character.title, " was defeated!")
		queue_free()
		
func add_vfx(type = ""):
	var vfx = vfx_node.instantiate()
	add_child(vfx)
	if type != "":
		vfx.find_child("AnimationPlayer").play(type)
