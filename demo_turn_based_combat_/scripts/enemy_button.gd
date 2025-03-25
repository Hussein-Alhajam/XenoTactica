extends Button

# variable to hold a Character
@export var character: Character:
	set(value): # set text of the button to character's title (name)
		character = value
		text = value.title


func _on_pressed() -> void:
	character.get_attacked()
	get_parent().hide() # hide the EnemyButton
	# owner is BattleScene as this will be a child of
	# EnemySelection in BattleScene (EnemySelection will actually
	# have multiple of this as children)
	get_parent().owner.deal_damage(1) 
	#get_parent().owner.pop_out()
