extends Node

var last_player_position: Vector2 = Vector2.ZERO
var last_scene: String = ""  # Track which scene the player came from

func save_player_state(pos: Vector2, scene: String):
	last_player_position = pos
	last_scene = scene
	print("✅ Saved player state: Position =", last_player_position, "| Last Scene =", last_scene)

func get_saved_position() -> Vector2:
	return last_player_position

func get_last_scene() -> String:
	return last_scene
