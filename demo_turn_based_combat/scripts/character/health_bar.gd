extends ProgressBar


@onready var timer = $Timer
@onready var damage_bar = $DamageBar

# set is used to call the function (_set_health) whenever health
# is changed. Useful because we want to update health bar values
# each time health is changed
var health: int = 0 : set = _set_health


func _set_health(new_health):
	var previous_health = health
	health = min(max_value, new_health)
	value = health
	
	if health < 0:
		queue_free()
	
	if health < previous_health:
		timer.start()
	else:
		damage_bar.value = health


func init_health(new_health: int):
	max_value = new_health
	value = new_health
	health = new_health
	damage_bar.max_value = new_health
	damage_bar.value = new_health


func _on_timer_timeout() -> void:
	damage_bar.value = health
