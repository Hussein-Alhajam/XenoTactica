extends State
class_name Enemy_Disabled

@export var enemy: CharacterBody2D
@onready var detection_zone: Area2D = $"../../detection_zone"

var disable_duration := 2.5  # seconds to stay disabled
var timer := 0.0

func enter():
	print("Enemy temporarily disabled!")
	if detection_zone:
		detection_zone.monitoring = false  # disable detection
		detection_zone.set_deferred("monitorable", false)

	timer = disable_duration
	if enemy.has_method("stop_movement"):
		enemy.stop_movement()
	
	if enemy.has_method("set_disabled_visual"):
		enemy.set_disabled_visual(true)


func exit():
	if detection_zone:
		detection_zone.monitoring = true
		detection_zone.set_deferred("monitorable", true)
	if enemy.has_method("set_disabled_visual"):
		enemy.set_disabled_visual(false)
	print("Enemy reactivated.")

func Update(delta: float):
	timer -= delta
	if timer <= 0:
		Transitioned.emit(self, "idle")
