extends 'TileTypes.gd'

signal move_complete

const TILE_SIZE = 16
const PIXEL_SIZE = 2

onready var tween = $Tween
onready var pivot = $Pivot
var has_piece = false

func _ready() -> void:
	show_game_pieces()
	set_pieces_color()

## Activates piece visibility according to game mode
func show_game_pieces() -> void:
	match GameManager.current_game:
		GameManager.GAME_TYPE.TICTACTOE:
			$"%TicTacToe".show()
		2: #TODO: update game type
			$"%Checkers".show()
		3: #TODO: update game type
			$"%Chess".show()

## Sets the color of each piece to the corresponding player color
func set_pieces_color() -> void:
	match GameManager.current_game:
		GameManager.GAME_TYPE.TICTACTOE:
			$"%X".modulate = GameManager.color_player_1
			$"%O".modulate = GameManager.color_player_2

## Deactivates piece visibility according to game mode
func hide_game_pieces() -> void:
	match GameManager.current_game:
		GameManager.GAME_TYPE.TICTACTOE:
			$"%X".hide()
			$"%O".hide()
		# Checkers
		# Chess

## Shows exact piece according to game mode
func show_piece() -> void:
	has_piece = true
	match GameManager.current_game:
		GameManager.GAME_TYPE.TICTACTOE:
			match GameManager.current_turn:
				1: # X
					$"%X".show()
				2: # O
					$"%O".show()

## Moves itself to target_position instantly and
## starts a Tween that moves the visual part of the tile
func move_to(target_position: Vector2) -> void:
	var move_direction = position.direction_to(target_position)
	tween.interpolate_method(self, "snap_pixel", - move_direction * TILE_SIZE, Vector2.ZERO, 1, Tween.TRANS_EXPO, Tween.EASE_OUT)
	tween.start()
	yield(tween, "tween_started")
	position = target_position
	yield(tween, "tween_completed")
	emit_signal("move_complete")

## Snaps given pos to virtual pixel grid position and sets it to pivot position
func snap_pixel(pos: Vector2) -> void:
	pivot.position.x = int(pos.x) - int(pos.x) % PIXEL_SIZE
	pivot.position.y = int(pos.y) - int(pos.y) % PIXEL_SIZE

## Colors the tile to red and back
func bump() -> void:
	var first_color = pivot.modulate
	tween.interpolate_property(pivot, "modulate", pivot.modulate, Color.red, 0.333333, Tween.TRANS_EXPO)
	tween.interpolate_property(pivot, "modulate", pivot.modulate, first_color, 0.666667, Tween.TRANS_EXPO, Tween.EASE_IN_OUT, 0.333333)
	tween.start()
