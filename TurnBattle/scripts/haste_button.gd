extends Button


func _on_pressed() -> void:
	# owner is BattleScene, i.e, BattleScene.set_status (?)
	owner.set_status("haste")
	owner.pop_out()
	owner.next_turn()
