extends State
class_name Enemy_Attack

@export var enemy: CharacterBody2D
@onready var area2D: Area2D = enemy.get_node("battle_transition")
@export var attack_speed := 3000.0  # Speed of movement during attack
@onready var tile_map = $"../Map"

@onready var player: CharacterBody2D = get_tree().get_first_node_in_group("player")
var is_attacking: bool = false
var attack_tween: Tween

func enter():
	await get_tree().process_frame  # 🚀 Ensure the scene tree is fully loaded
	var tree = get_tree()

	if tree == null:
		print("❌ ERROR: SceneTree is NULL!")
		return

	if player == null:
		print("⚠️ WARNING: Player not found in ATTACK state! Avoiding crash, returning to CHASE.")
		Transitioned.emit(self, "chase")
		return

	if tile_map == null:
		tile_map = enemy.get_parent().find_child("Map")  # Ensure the correct node name
	if tile_map == null:
		print("ERROR: tile_map is STILL NULL after assignment! Cannot perform attack movement.")
		Transitioned.emit(self, "chase")
		return
	
	print("✅ Enemy entered ATTACK state! Moving toward player.")
	force_move_to_player()

func exit():
	print("Exiting Attack state")
	if attack_tween and attack_tween.is_running():
		attack_tween.kill()  # 🚀 Prevents movement bugs if the tween is interrupted

func force_move_to_player():
	if is_attacking:
		return
	is_attacking = true

	# Get the player's grid position and move the enemy exactly there
	var player_grid_pos = tile_map.local_to_map(player.global_position)
	var target_position = tile_map.map_to_local(player_grid_pos)

	attack_tween = get_tree().create_tween()
	attack_tween.tween_property(enemy, "global_position", target_position, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	attack_tween.tween_callback(Callable(self, "on_attack_finished"))

func on_attack_finished():
	is_attacking = false
	print("🛑 Enemy reached player's last known position! Checking collision...")

	await get_tree().process_frame  # 🚀 Ensures player position updates before checking collision

	if area2D == null:
		print("❌ ERROR: area2D is NULL!")
		Transitioned.emit(self, "chase")
		return

	print("🔍 Checking Area2D for overlapping bodies...")

	var detected_bodies = area2D.get_overlapping_bodies()

	if detected_bodies.size() > 0:
		for body in detected_bodies:
			print("🔍 Detected:", body.name, " | Groups:", body.get_groups())

			if body.is_in_group("player"):  
				print("✅ Collision confirmed with player! Transitioning to battle scene.")

				# 🚀 Disable state machine before scene transition
				if enemy.has_node("StateMachine"):
					enemy.get_node("StateMachine").set_process(false)

				# 🚀 STOP THE ENEMY BEFORE SWITCHING SCENE
				enemy.set_process(false)  
				enemy.set_physics_process(false)  
				enemy.visible = false  # Hide enemy before battle starts

				# 🚀 Transition to battle scene
				body.save_and_transition("res://demo_turn_based_combat_/scenes/battle_scene.tscn")
				return

	# 🚀 If no collision, return to chase
	print("⚠️ No valid player collision detected. Returning to chase.")
	Transitioned.emit(self, "chase")


func Physics_Update(delta: float):
	pass
