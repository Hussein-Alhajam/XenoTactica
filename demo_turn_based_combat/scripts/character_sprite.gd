extends Sprite2D

# variable used to hold Character class
@export var character: Character


func _ready():
	if character:
		# set reference
		character.node = self
		# assigned texture to Sprite2D
		texture = character.texture


# move 'functional' methods here?
func kill_character():
	print("tried killing character " + character.title)
	#queue_free()
