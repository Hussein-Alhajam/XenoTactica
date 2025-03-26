extends CharacterBody2D
class_name EnemyUnit

@export var character: Character

var queue: Array[float] = []
var speed: float = 100.0  # or set this via export from the Character data
var status := 1.0

func queue_reset():
	queue.clear()
	for i in range(4):
		if queue.is_empty():
			queue.append(speed * status)
		else:
			queue.append(queue[-1] + speed * status)

func pop_out():
	queue.pop_front()
	queue.append(queue[-1] + speed * status)

func get_attacked(type := "", damage := 0):
	character.health -= damage
	print(character.title, " took ", damage, " damage. Remaining HP: ", character.health)
	if character.health <= 0:
		print(character.title, " was defeated!")
		queue_free()
