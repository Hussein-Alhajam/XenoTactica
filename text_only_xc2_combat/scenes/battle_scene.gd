extends Node2D

@export var player_group: Node2D

var is_arts_selected # make into FSM

var sorted_array = []
var players: Array[Character]


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for player in player_group.get_children():
		player.character.battle_scene = self
		player.character.pass_battle_scene()
		players.append(player.character)
	# temp
	sorted_array = players
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not is_arts_selected:
		# update the action selection
		$HUD/UpText.text = "Items"
		$HUD/LeftText.text = "Special " + str(sorted_array[0].special_charge)
		$HUD/DownText.text = "Arts"
		$HUD/RightText.text = "Attack"
		
		if Input.is_action_just_pressed("attack"):
			$ActionLog.text = "Used Attack \n Arts Charged by 1"
			# if using the priority queue for turn order,
			# and assuming controls are only available when current turn is a player,
			# (i.e., if we are in controls, first element in queue is a player)
			# make that player character charge their arts
			sorted_array[0].charge_arts(1)
		if Input.is_action_just_pressed("special"):
			sorted_array[0].use_special()
			
		if Input.is_action_just_pressed("items_selection"):
			$ActionLog.text = "entered items selection \n (not implemented)"
		if Input.is_action_just_pressed("arts_selection"):
			$ActionLog.text = "entered arts selection"
			is_arts_selected = true

	else:
		# update the action selection
		# temp 'hard code-y' text updates
		$HUD/UpText.text = str(sorted_array[0].arts_list[1].art_name) + " " + str(sorted_array[0].arts_list[1].current_charge) + "/" + str(sorted_array[0].arts_list[1].max_charge)
		$HUD/LeftText.text = str(sorted_array[0].arts_list[0].art_name) + " " + str(sorted_array[0].arts_list[0].current_charge) + "/" + str(sorted_array[0].arts_list[0].max_charge)
		$HUD/DownText.text = "Exit Arts"
		$HUD/RightText.text = str(sorted_array[0].arts_list[2].art_name) + " " + str(sorted_array[0].arts_list[2].current_charge) + "/" + str(sorted_array[0].arts_list[2].max_charge)

		if Input.is_action_just_pressed("left_art"):
			sorted_array[0].use_art(0)

		if Input.is_action_just_pressed("up_art"):
			sorted_array[0].use_art(1)

		if Input.is_action_just_pressed("right_art"):
			sorted_array[0].use_art(2)

		if Input.is_action_just_pressed("arts_back"):
			$ActionLog.text = "exited arts selection"
			is_arts_selected = false


func update_action_log(message: String):
	$ActionLog.text = message
