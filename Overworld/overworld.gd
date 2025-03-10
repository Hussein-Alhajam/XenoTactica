extends Node2D

func _ready():
	var saved_position = GameState.get_saved_position()
	if saved_position != Vector2.ZERO:
		restore_player_position(saved_position)
	else:
		print("🔹 No saved position found. Using default spawn.")

func restore_player_position(position: Vector2):
	if has_node("Player"):
		$Player.global_position = position
		print("✅ Player position restored to:", position)
	else:
		print("❌ ERROR: Player node not found in Overworld!")
