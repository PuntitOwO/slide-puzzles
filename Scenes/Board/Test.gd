extends Node2D

enum INPUT_MODE { TILE, PIECE, BUTTON, PAUSE } 
export (INPUT_MODE) var input_mode = INPUT_MODE.TILE

enum DIRECTION_ANGLE { UP = 0, RIGHT = 90, DOWN = 180, LEFT = 270 }

var mouse_position_start : Vector2 = Vector2.INF

export (bool) var mouse_mode = false

var is_tile_selected := false
var tile_selected : Node2D = null
var tile_direction : Vector2 = Vector2.ZERO

onready var tile_cursor = $Cursor
onready var button_cursor = $Cursor2
onready var slidable_tile = $SlidableTile
onready var direction_sprites = $Cursor/Direction
onready var invalid_direction_sprite = $Cursor/Direction/InvalidDirectionSprite
onready var valid_direction_sprite = $Cursor/Direction/ValidDirectionSprite

func _ready() -> void:
	reset_tile_selected()

func _process(delta: float) -> void:
	match input_mode:
		INPUT_MODE.TILE:
			if mouse_mode:
				_process_tile_mouse(delta)
			else:
				_process_tile_keys(delta)

func _process_tile_mouse(_delta:float) -> void:
	if Input.is_action_just_pressed("select"):
		mouse_position_start = get_local_mouse_position()
	if Input.is_action_just_released("select") and mouse_position_start != Vector2.INF:
		var mouse_position_end : Vector2 = get_local_mouse_position()
		var direction : Vector2 = mouse_position_end - mouse_position_start
		direction = choose_direction(direction)
		var target_node_cell : Vector2 = slidable_tile.world_to_map(mouse_position_start)
		var target_node : Node2D = slidable_tile.get_cell_node( target_node_cell, slidable_tile.CELL_TYPES.SLIDABLE )
		
		# Some sanity checks
		if not is_instance_valid(target_node):
#			print_debug(name + ": not valid instance - ", target_node)
			return
		if not target_node.has_method("move_to"):
			print_debug("Node " + target_node.name + " has no move_to method - ", target_node)
			return
		
		var target_position = $SlidableTile.request_move( target_node, direction )
		if target_position != Vector2.INF:
			target_node.move_to(target_position)
		else:
			target_node.bump()
		mouse_position_start = Vector2.INF

func reset_tile_selected() -> void:
	is_tile_selected = false
	tile_selected = null
	tile_direction = Vector2.ZERO
	invalid_direction_sprite.hide()
	valid_direction_sprite.hide()

func _process_tile_keys(_delta: float) -> void:
	
	# This behavior doesn't depend on is_tile_selected
	if Input.is_action_just_pressed("ui_change_mode"):
		input_mode = INPUT_MODE.PIECE
		reset_tile_selected()
		return
	
	if is_tile_selected:
		# Only when a valid tile is selected
		# Safety check
		if not is_instance_valid(tile_selected):
			reset_tile_selected()
			return
		
		# To cancel current selection
		if Input.is_action_just_pressed("ui_cancel"):
			reset_tile_selected()
			return
		
		# To confirm selected movement
		if Input.is_action_just_pressed("ui_accept") and tile_direction != Vector2.ZERO:
			# Check if is a valid move
			var target_position = slidable_tile.request_move(tile_selected, tile_direction)
			if target_position != Vector2.INF:
				valid_direction_sprite.hide()
				set_process(false)
				yield(tile_selected.move_to(target_position), "completed")
				set_process(true)
				reset_tile_selected()
				print("finished")
			else:
				tile_selected.bump()
			return
		
		# To select direction
		var input = get_just_pressed_vector("ui_left", "ui_right", "ui_up", "ui_down")
		match input:
			Vector2.ZERO:
				return
			Vector2.UP:
				direction_sprites.rotation_degrees = DIRECTION_ANGLE.UP
			Vector2.DOWN:
				direction_sprites.rotation_degrees = DIRECTION_ANGLE.DOWN
			Vector2.LEFT:
				direction_sprites.rotation_degrees = DIRECTION_ANGLE.LEFT
			Vector2.RIGHT:
				direction_sprites.rotation_degrees = DIRECTION_ANGLE.RIGHT
		
		tile_direction = input
		
		var target_cell = slidable_tile.world_to_map(tile_cursor.position) + input
		if slidable_tile.get_cellv(target_cell) == slidable_tile.CELL_TYPES.EMPTY:
			# Valid tile
			invalid_direction_sprite.hide()
			valid_direction_sprite.show()
		else:
			valid_direction_sprite.hide()
			invalid_direction_sprite.show()
		
	else:
		# Only when no tile is selected
		
		# To select current tile (under cursor)
		if Input.is_action_just_pressed("ui_accept"):
			var target_cell = slidable_tile.world_to_map(tile_cursor.position)
			var target_node = slidable_tile.get_cell_node(target_cell, slidable_tile.CELL_TYPES.SLIDABLE)
			if is_instance_valid(target_node):
				is_tile_selected = true
				tile_selected = target_node
			return
		
		# To move cursor
		var input = get_just_pressed_vector("ui_left", "ui_right", "ui_up", "ui_down")
		if input == Vector2.ZERO:
			return
		var target_cell = slidable_tile.world_to_map(tile_cursor.position) + input
		if slidable_tile.get_cellv(target_cell) != slidable_tile.CELL_TYPES.DECORATION:
			# Valid tile
			var target_pos = slidable_tile.map_to_world(target_cell) + slidable_tile.cell_size / 2
			tile_cursor.position = target_pos

func get_just_pressed_vector(negative_x : String, positive_x : String, negative_y : String, positive_y : String) -> Vector2:
	if Input.is_action_just_pressed(negative_x):
		return Vector2.LEFT
	if Input.is_action_just_pressed(positive_x):
		return Vector2.RIGHT
	if Input.is_action_just_pressed(negative_y):
		return Vector2.UP
	if Input.is_action_just_pressed(positive_y):
		return Vector2.DOWN
	return Vector2.ZERO

## Returns Vector2.LEFT, RIGTH, DOWN or UP depending on the max component value of the given vector.
## choose_direction(Vector2(5, 6)) -> Vector2.DOWN
## choose_direction(Vector2.ZERO) -> Vector2.ZERO
func choose_direction(direction : Vector2) -> Vector2:
	if is_zero_approx(direction.length()):
		return Vector2.ZERO
	if abs(direction.x) > abs(direction.y):
		direction = Vector2.RIGHT * sign(direction.x)
	else:
		direction = Vector2.DOWN * sign(direction.y)
	return direction
