extends Node2D

@export var move_speed: float = 2

@onready var  tile_map = $"../Map"
@onready var player = $"../Player"
@onready var sprite = $Sprite2D
@onready var area2d = $Area2D
var astar_grid: AStarGrid2D
var is_moving: bool

func _ready():
	astar_grid=AStarGrid2D.new()
	astar_grid.region = tile_map.get_used_rect()
	astar_grid.cell_size =  Vector2(80,80)
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar_grid.update()
	
	var region_size = astar_grid.region.size
	var region_position = astar_grid.region.position
	
	for x in tile_map.get_used_rect().size.x:
		for y in tile_map.get_used_rect().size.y:
			var tile_position = Vector2i(
				x + region_position.x,
				y + region_position.y
			)
			
			var tile_data = tile_map.get_cell_tile_data(tile_position)
			
			if tile_data == null or tile_data.get_custom_data("walkable")== false:
				astar_grid.set_point_solid(tile_position)

func _process(_delta):
	if is_moving:
		return
		
	move()
func is_adjacent_to_player() -> bool:
	var enemy_tile = tile_map.local_to_map(global_position)
	var player_tile = tile_map.local_to_map(player.global_position)
	return enemy_tile.distance_to(player_tile) == 1  # adjust as needed

func move():
	var enemies = get_tree().get_nodes_in_group("enemies")
	var occupied_positions = []
	for enemy in enemies:
		if enemy == self:
			continue
		occupied_positions.append(tile_map.local_to_map(enemy.global_position))
	for occupied_position in occupied_positions:
		astar_grid.set_point_solid(occupied_position)        
	var path = astar_grid.get_id_path(
			tile_map.local_to_map(global_position),
			tile_map.local_to_map(player.global_position)
			)
	for occupied_position in occupied_positions:
		astar_grid.set_point_solid(occupied_position, false)
		
	path.pop_front()
	if is_adjacent_to_player():
		var tween = get_tree().create_tween()
		tween.tween_property(self, "global_position", player.global_position, 0.5)
		tween.tween_callback(Callable(self, "_on_final_move_complete"))
		return
	
	if path.is_empty():
		print("cannot find path")
		return
		
	if path.size() == 1:
		print("I am at my target")
		return
		
	var original_position = Vector2(global_position)
	global_position = tile_map.map_to_local(path[0])
	sprite.global_position = original_position
	area2d.global_position = sprite.global_position
	
	is_moving = true

	
func _physics_process(delta):
	if is_moving:
		sprite.global_position = sprite.global_position.move_toward(global_position, move_speed)
		area2d.global_position = sprite.global_position
		
		if sprite.global_position != global_position:
			return
		
	is_moving = false
