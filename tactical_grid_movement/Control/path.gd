extends Node2D

@onready var unit = $"../Unit"

func _process(delta):
	queue_redraw()

func _draw():
	if unit.current_point_path.is_empty():
		return
	
	draw_polyline(unit.current_point_path, Color.RED)
