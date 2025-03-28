# redundant class from tutorial
extends Button


func _on_pressed() -> void:
	# ? owner is BattleScene as it is the root node
	# so this is essentially calling battle_scene.select_enemy()
	owner.select_enemy() # show enemy selection
	# ? parent is CombatOptions
	get_parent().hide() # hide the combat options
