extends State
class_name Enemy_Idle

@export var enemy: CharacterBody2D
@export var move_speed := 55.0
@onready var  tile_map = $"../Map"
@onready var detection_zone: Area2D = $"../../detection_zone"
@onready var cooldown_timer: Timer = $"../../DetectionCooldownTimer"

@onready var player: CharacterBody2D = get_tree().get_first_node_in_group("player")
var move_direction: Vector2
var wander_time: float
var astar_grid: AStarGrid2D
var is_moving: bool = false

func _ready():
	setup_astar()
	if detection_zone:
		detection_zone.connect("body_entered", Callable(self, "_on_detection_zone_body_entered"))
		detection_zone.connect("body_exited", Callable(self, "_on_detection_zone_body_exited"))

func setup_astar():
	if tile_map == null:
		print("ERROR: tile_map is null! Cannot set up AStar.")
		return

	astar_grid = AStarGrid2D.new()
	astar_grid.region = tile_map.get_used_rect()
	astar_grid.cell_size = Vector2(80, 80)
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar_grid.update()

	# Mark unwalkable tiles
	for x in range(tile_map.get_used_rect().size.x):
		for y in range(tile_map.get_used_rect().size.y):
			var tile_position = Vector2i(x + astar_grid.region.position.x, y + astar_grid.region.position.y)
			var tile_data = tile_map.get_cell_tile_data(tile_position)

			if tile_data == null or tile_data.get_custom_data("walkable") == false:
				astar_grid.set_point_solid(tile_position)

func randomize_wander():
	# Ensure movement stays within valid grid directions (Up, Down, Left, Right)
	var directions = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	move_direction = directions[randi() % directions.size()]
	wander_time = randf_range(1, 2)
	calculate_random_grid_move()

func calculate_random_grid_move():
	if tile_map == null:
		return

	# Convert enemy position to grid coordinates
	var enemy_pos = tile_map.local_to_map(enemy.global_position)
	var next_tile = enemy_pos + move_direction

	# Check if next tile is walkable
	if astar_grid.is_point_solid(next_tile):
		print("Tile is occupied, choosing a new direction.")
		randomize_wander()
		return

	# Convert back to world position
	enemy.global_position = tile_map.map_to_local(next_tile)
	is_moving = true

func enter():
	if player == null:
		print("ERROR: Player not found!")
		return
	else:
		print("Enemy in IDLE. Wandering until player is detected.")

	if detection_zone:
		detection_zone.monitoring = false
		detection_zone.set_deferred("monitorable", false)

	# ⏱ Start timer to re-enable it
	if cooldown_timer:
		cooldown_timer.start()
		cooldown_timer.connect("timeout", Callable(self, "_on_detection_reenable"), CONNECT_ONE_SHOT)

	randomize_wander()

func _on_detection_reenable():
	if detection_zone:
		detection_zone.monitoring = true
		detection_zone.set_deferred("monitorable", true)
		print("Detection zone re-enabled.")

func exit():
	print("Exiting IDLE state")

func Update(delta: float):
	if wander_time > 0:
		wander_time -= delta
	else:
		randomize_wander()

func Physics_Update(delta: float):
	if enemy == null:
		print("ERROR: Enemy reference is null!")
		return

	# Move in grid-aligned directions
	enemy.velocity = move_direction * move_speed
	if enemy.is_on_ceiling() or enemy.is_on_floor() or enemy.is_on_wall():
		randomize_wander()
		enemy.move_and_slide()
func _on_detection_zone_body_entered(body):
	if body.is_in_group("player"):
		print("Player detected! Switching to CHASE state.")
		Transitioned.emit(self, "chase")

func _on_detection_zone_body_exited(body):
	if body.is_in_group("player"):
		print("Player left detection zone. Staying in IDLE.")
