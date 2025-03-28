extends CharacterBody2D
class_name PlayerUnitBattle

var vfx_node: PackedScene = preload("res://demo_turn_based_combat_/TurnBattle/scenes/vfx.tscn")
@export var character: Character  # Your custom Character resource
@export var pathfinder: PathFinding
@export var grid_manager: GridManager
@export var move_range: int = 3
@export var move_speed: float = 100.0
@export var attack_range: int = 1

# UI & sprite
@onready var sprite: Sprite2D = $Sprite2D
var character_name: String
var icon: Texture2D

# Combat stats
var health: int
var strength: int
var ether: int
var defense: int
var resistance: int
var agility: int:
	set(value):
		agility = value
		speed = 200.0 / (log(agility) + 2) - 25
		queue_reset()

var element: String
var arts_list: Array[CombatArt]
var specials_list: Array[CombatSpecial]
var special_charge: int = 0
var status = 1
var speed: float
var queue: Array[float] = []

# Movement and turn states
var selected = false
var is_moving = false
var is_attacking = false
static var currently_selected_unit: PlayerUnitBattle = null

func _ready():
	if character:
		# Stats setup
		character.node = self
		icon = character.icon
		character_name = character.title
		sprite.texture = character.texture
		health = character.health
		strength = character.strength
		ether = character.ether
		defense = character.defense
		resistance = character.resistance
		agility = character.agility
		element = character.element

		arts_list = []
		for art in character.arts_list:
			arts_list.append(art.duplicate(true))

		specials_list = []
		for special in character.specials_list:
			specials_list.append(special.duplicate(true))

		queue_reset()

	if grid_manager == null:
		grid_manager = get_tree().get_first_node_in_group("grid_manager")
	if pathfinder == null:
		pathfinder = get_tree().get_first_node_in_group("pathfinder")
	if $Area2D:
		$Area2D.connect("input_event", Callable(self, "_on_area2d_input_event"))

	print("✅ PlayerUnit ready.")

# ------------------- Grid Movement --------------------

func _input(event):
	if is_moving or grid_manager == null or pathfinder == null:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		if is_attacking:
			cancel_attack_selection()
		elif selected:
			cancel_selection()
		return

	if selected and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var mouse_pos = get_global_mouse_position()
		var clicked_tile = grid_manager.tile_map.local_to_map(mouse_pos)
		move_to_tile(clicked_tile)

func _on_area2d_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if not is_moving and not is_attacking:
			select_unit()

func select_unit():
	if currently_selected_unit != null and currently_selected_unit != self:
		return
	selected = true
	currently_selected_unit = self
	grid_manager.clear_highlight()
	var unit_tile = grid_manager.tile_map.local_to_map(global_position)
	grid_manager.highlight_tiles(unit_tile, move_range)
	print("✅ Unit selected. Showing movement range.")

func cancel_selection():
	selected = false
	is_attacking = false
	currently_selected_unit = null
	grid_manager.clear_highlight()
	grid_manager.clear_attack_highlight()
	print("❌ Selection canceled.")

func cancel_attack_selection():
	is_attacking = false
	selected = false
	currently_selected_unit = null
	grid_manager.clear_attack_highlight()
	print("❌ Attack selection canceled.")

func move_to_tile(target_tile: Vector2i):
	if not selected or is_moving:
		return
	for unit in get_tree().get_nodes_in_group("player_units"):
		if unit != self and grid_manager.tile_map.local_to_map(unit.global_position) == target_tile:
			print("❌ Tile occupied by another unit!")
			return

	var unit_tile = grid_manager.tile_map.local_to_map(global_position)
	var path = pathfinder.find_path(unit_tile, target_tile)
	if path.size() <= 1 or path.size() > move_range + 1:
		print("❌ Invalid move target.")
		return
	grid_manager.clear_highlight()
	print("✅ Moving unit to", target_tile)
	follow_path(path)

func follow_path(path: Array):
	is_moving = true
	for tile in path:
		var world_pos = grid_manager.tile_map.map_to_local(tile)
		while global_position.distance_to(world_pos) > 1.0:
			velocity = (world_pos - global_position).normalized() * move_speed
			move_and_slide()
			await get_tree().process_frame
	velocity = Vector2.ZERO
	is_moving = false
	selected = false
	var tile = grid_manager.tile_map.local_to_map(global_position)
	grid_manager.highlight_attack_tiles(tile, attack_range)
	is_attacking = true

# ------------------- Combat Functions --------------------

func queue_reset():
	queue.clear()
	for i in range(4):
		queue.append(speed * status if i == 0 else queue[-1] + speed * status)

func pop_out():
	queue.pop_front()
	queue.append(queue[-1] + speed * status)

func get_attacked(type = "", damage = 0):
	add_vfx("slash")
	health -= damage
	print(character_name + ": " + str(health) + "hp")
	if health < 0:
		kill_character()

func attack(tree):
	var shift = Vector2(100, 0)
	if position.x < get_viewport_rect().size.x / 2:
		shift = -shift
	await tween_movement(-shift, tree)
	await tween_movement(shift, tree)
	EventBus.next_turn.emit()

func tween_movement(shift, tree):
	var tween = tree.create_tween()
	tween.tween_property(self, "position", position + shift, 0.2)
	await tween.finished

func use_normal_attack():
	charge_arts(1)
	return max(strength, ether)

func charge_arts(num):
	for art in arts_list:
		art.charge_art(num)

func use_art(num):
	if arts_list[num].is_charged():
		charge_arts(1)
		charge_special(1)
		return arts_list[num].use_art() * max(strength, ether)
	return null

func charge_special(num):
	special_charge = min(special_charge + num, 4)

func use_special():
	if special_charge > 0:
		var damage = specials_list[special_charge - 1].use_special() * max(strength, ether)
		reset_special_charge()
		return damage
	return null

func reset_special_charge():
	special_charge = 0

func set_status(status_type: String):
	add_vfx(status_type)
	match status_type:
		"haste":
			status = 0.5
		"slow":
			status = 2
	queue.resize(1)
	for i in range(3):
		queue.append(queue[-1] + speed * status)

func kill_character():
	print("☠️", character.title, "has been defeated.")
	Global.battle_scene.kill_character(self)
	queue_free()

func get_art_name(num): return arts_list[num].art_name
func get_art_charges(num): return [arts_list[num].current_charge, arts_list[num].max_charge]
func get_special_name(): return specials_list[special_charge - 1].special_name if special_charge > 0 else "No special"
func add_vfx(type = ""):
	var vfx = vfx_node.instantiate()
	add_child(vfx)
	if type != "":
		vfx.find_child("AnimationPlayer").play(type)
