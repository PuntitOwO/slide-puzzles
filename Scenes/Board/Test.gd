extends Node2D

# TODO: documentation
signal turn_finished

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

func _init() -> void:
	GameManager.start_game(GameManager.GAME_TYPE.TICTACTOE)

func _ready() -> void:
	reset_tile_selected()

## Dispatch process func depending on input mode and mouse mode, which will be no longer supported
func _process(_delta: float) -> void:
	match input_mode:
		INPUT_MODE.TILE:
			if mouse_mode:
				_process_tile_mouse()
			else:
				_process_tile_keys()
		INPUT_MODE.PIECE:
			_process_piece_keys()

# TODO: delet dis, mouse input is no more
func _process_tile_mouse() -> void:
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

## Process keyboard input in PIECE input mode
## Moves cursor and calls piece position func
func _process_piece_keys() -> void:
	# To change input mode
	if Input.is_action_just_pressed("ui_change_mode"):
		input_mode = INPUT_MODE.TILE
		return
	
	# To place a piece (under cursor)
	if Input.is_action_just_pressed("ui_accept"):
		var target_cell = slidable_tile.world_to_map(tile_cursor.position)
		var target_node = slidable_tile.get_cell_node(target_cell, slidable_tile.CELL_TYPES.SLIDABLE)
		if is_instance_valid(target_node):
			put_piece(target_node)
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

## Checks if tile has visible piece
## calls show piece and emits turn finished if not visible already
func put_piece(node) -> void:
	if not node.has_piece:
		node.show_piece()
		emit_signal("turn_finished")
	else:
		print("Ya hay una pieza aquí")

## Resets tile selection related vars to their default values
func reset_tile_selected() -> void:
	is_tile_selected = false
	tile_selected = null
	tile_direction = Vector2.ZERO
	invalid_direction_sprite.hide()
	valid_direction_sprite.hide()

## Process keyboard input in TILE input mode
## Moves cursor, selects a tile, selects movement direction and calls tile movement func
## Relies in is_tile_selected, tile_selected and tile_direction vars to store state
func _process_tile_keys() -> void:
	# To change input mode
	# This behavior doesn't depend on is_tile_selected
	if Input.is_action_just_pressed("ui_change_mode"):
		input_mode = INPUT_MODE.PIECE
		reset_tile_selected()
		return
	
	# When a tile is selected, player can select movement direction, confirm movement or cancel it
	if is_tile_selected:
		# Only when a valid tile is selected
		# Safety check
		if not is_instance_valid(tile_selected):
			reset_tile_selected() # this will execute is_tile_selected = false
			return
		
		# To cancel current selection
		if Input.is_action_just_pressed("ui_cancel"):
			reset_tile_selected()
			return
		
		# To confirm selected movement
		if Input.is_action_just_pressed("ui_accept") and tile_direction != Vector2.ZERO:
			# Check if is a valid move
			var target_position = slidable_tile.request_move(tile_selected, tile_direction)
			# when requested move is invalid, target_position is Vector2.INF
			if target_position != Vector2.INF:
				# Hide cursor arrows
				valid_direction_sprite.hide()
				# Stop processing until movement is finished
				set_process(false)
				yield(tile_selected.move_to(target_position), "completed")
				set_process(true)
				# Reset tile selection status vars
				reset_tile_selected()
				# Emit turn finished signal
				emit_signal("turn_finished")
			else:
				tile_selected.bump()
			return
		
		# To select movement direction
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
		
		# Check movement validity and show corresponding direction sprite
		var target_cell = slidable_tile.world_to_map(tile_cursor.position) + input
		if slidable_tile.get_cellv(target_cell) == slidable_tile.CELL_TYPES.EMPTY:
			# Valid tile: empty
			invalid_direction_sprite.hide()
			valid_direction_sprite.show()
		else:
			# Invalid tile: board border or another tile
			valid_direction_sprite.hide()
			invalid_direction_sprite.show()
	
	else: # No tile selected
		
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
			var target_pos = slidable_tile.map_to_world(target_cell) + slidable_tile.cell_size / 2
			tile_cursor.position = target_pos

## Returns Vector2.LEFT, RIGHT, DOWN, UP or ZERO depending on what action was just pressed
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
