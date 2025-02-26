extends Sprite2D

# variable used to hold Character class
@export var character: Character


func _ready():
	if character:
		# set reference
		character.node = self
		# assigned texture to Sprite2D
		texture = character.texture
