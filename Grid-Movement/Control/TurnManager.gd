extends Node
class_name TurnManager

var active_unit: Node = null  # reference to a player/enemy unit
var has_moved: bool = false
var has_attacked: bool = false
var last_action: String = ""  # "attack", "art", "special", "item"

func begin_turn(unit: Node):
	active_unit = unit
	has_moved = false
	has_attacked = false
	last_action = ""
	print("New turn for:", unit.name)

func end_turn():
	print("✅ Turn ended for:", active_unit.name)
	active_unit = null
	has_moved = false
	has_attacked = false
	last_action = ""

func set_moved():
	has_moved = true
	print(active_unit.name, "has moved.")

func set_attacked(action_type: String):
	has_attacked = true
	last_action = action_type
	print(active_unit.name, "used:", action_type)

func can_move() -> bool:
	return not has_moved

func can_attack() -> bool:
	return not has_attacked

func is_turn_active() -> bool:
	return active_unit != null
