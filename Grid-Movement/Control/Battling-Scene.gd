extends Node2D
class_name BattleScene


enum TurnState { NEUTRAL, ATTACKED, MOVED, SKIPPED }
enum ActiveHud { COMBAT, SETTINGS_OPTIONS, TITLE_MENU }

@export var player_group: Node2D # hold the 'Players' node
@export var enemy_group: Node2D # hold the 'Enemies' node
@export var timeline: HBoxContainer
@export var combat_options: VBoxContainer
@export var enemy_button: PackedScene

var sorted_array = [] # [{ "character": unit, "time": value }, ...]
var is_arts_selected: bool = false
var turn_state = TurnState.NEUTRAL
var active_hud = ActiveHud.COMBAT
var ui_controls := {}

func _ready():
	Global.battle_scene = self

	ui_controls = {
		"up": $UI/UpContainer/UpText,
		"left": $UI/LeftContainer/LeftText,
		"down": $UI/DownContainer/DownText,
		"right": $UI/RightContainer/RightText,
		"log": $UI/ActionLog,
	}

	initialize_characters()
	sort_and_display()

	EventBus.next_turn.connect(next_turn)
	next_turn()


func initialize_characters():
	# Get characters via group, instead of scene node references
	for player in get_tree().get_nodes_in_group("player_units"):
		player.queue = player.queue if "queue" in player else [0] # fallback if missing
		player.append(player)
	
	for enemy in get_tree().get_nodes_in_group("enemy_units"):
		enemy.queue = enemy.queue if "queue" in enemy else [0]
		enemy.append(enemy)
		
		#var button = enemy_button.instantiate()
		#button.character = enemy.character
		#%EnemySelection.add_child(button)

func _process(_delta):
	var current = sorted_array[0]["character"]
	if current.is_in_group("player_units"):
		handle_player_controls(current)

func handle_player_controls(player):
	if is_arts_selected:
		var art0 = player.get_art_name(0)
		var art1 = player.get_art_name(1)
		var art2 = player.get_art_name(2)
		ui_controls["left"].text = "%s %s/%s" % [art0, player.get_art_charges(0)[0], player.get_art_charges(0)[1]]
		ui_controls["up"].text   = "%s %s/%s" % [art1, player.get_art_charges(1)[0], player.get_art_charges(1)[1]]
		ui_controls["right"].text = "%s %s/%s" % [art2, player.get_art_charges(2)[0], player.get_art_charges(2)[1]]
		ui_controls["down"].text = "Exit Arts"

		if Input.is_action_just_pressed("left_art"):
			use_character_art(0)
		elif Input.is_action_just_pressed("up_art"):
			use_character_art(1)
		elif Input.is_action_just_pressed("right_art"):
			use_character_art(2)
		elif Input.is_action_just_pressed("arts_back"):
			is_arts_selected = false
	else:
		ui_controls["up"].text = "Items"
		ui_controls["left"].text = player.get_special_name()
		ui_controls["down"].text = "Arts"
		ui_controls["right"].text = "Attack"

		if Input.is_action_just_pressed("auto_attack"):
			update_action_log("Used Attack \nArts Charged by 1")
			use_character_normal_attack()
		elif Input.is_action_just_pressed("special"):
			use_character_special()
		elif Input.is_action_just_pressed("items_selection"):
			update_action_log("Items not implemented")
		elif Input.is_action_just_pressed("arts_selection"):
			is_arts_selected = true

func update_action_log(message: String):
	$UI/ActionLog.text = message

func sort_combined_queue():
	var combined = []

	print("Collecting player units:")
	for player in get_tree().get_nodes_in_group("player_units"):
		print("   -", player.name, "Queue:", player.queue)
		for time in player.queue:
			combined.append({ "character": player, "time": time })

	print("Collecting enemy units:")
	for enemy in get_tree().get_nodes_in_group("enemy_units"):
		print("   -", enemy.name, "Queue:", enemy.queue)
		for time in enemy.queue:
			combined.append({ "character": enemy, "time": time })

	sorted_array = combined
	sorted_array.sort_custom(sort_by_time)

	print("Sorted turn order:")
	for entry in sorted_array:
		print("   •", entry["character"].name, "| time:", entry["time"])


func sort_by_time(a, b):
	return a["time"] < b["time"]

func update_timeline():
	var index = 0
	for slot in timeline.get_children():
		if index < sorted_array.size():
			slot.find_child("TextureRect").texture = sorted_array[index]["character"].character.icon
			index += 1

func sort_and_display():
	sort_combined_queue()
	update_timeline()

func next_turn():
	var current = sorted_array[0]["character"]
	if current.is_in_group("enemy_units"):
		give_enemy_turn()
	else:
		print("✅ Player turn for", current.name)

func pop_out():
	sorted_array[0]["character"].pop_out()
	sort_and_display()

func deal_damage(damage: int):
	var current = sorted_array[0]["character"]
	current.attack(get_tree())  # attack anim, etc.
	pop_out()

func give_enemy_turn():
	deal_damage(1)
	var players = get_tree().get_nodes_in_group("player_units")
	if players.size() > 0:
		players.pick_random().get_attacked("", 1)

func use_character_normal_attack():
	var current = sorted_array[0]["character"]
	var damage = current.use_normal_attack()
	deal_damage(damage)
	get_tree().get_nodes_in_group("enemy_units").pick_random().get_attacked("", damage)

func use_character_art(art_num: int):
	# use: calls the use_art() function for the 
		# first (current turn) character in the queue
	var damage = sorted_array[0]["character"].use_art(art_num)
	if damage:
		deal_damage(damage)
		get_tree().get_nodes_in_group("enemy_units").pick_random().get_attacked("", damage)	
		is_arts_selected = false
	else:
		update_action_log("Art is not charged")
		return

func use_character_special():
	var current = sorted_array[0]["character"]
	var damage = current.use_special()
	if damage:
		deal_damage(damage)
		get_tree().get_nodes_in_group("enemy_units").pick_random().get_attacked("", damage)
	else:
		update_action_log("Special not charged.")

func kill_character(character):
	if character.is_in_group("player_units"):
		character.remove_from_group("player_units")
	elif character.is_in_group("enemy_units"):
		character.remove_from_group("enemy_units")
	sort_and_display()
