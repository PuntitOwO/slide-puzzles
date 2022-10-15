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

## 
func show_game_pieces() -> void:
	match GameManager.current_game:
		GameManager.GAME_TYPE.TICTACTOE:
			$"%TicTacToe".show()
		2: #TODO: update game type
			$"%Checkers".show()
		3: #TODO: update game type
			$"%Chess".show()

func set_pieces_color() -> void:
	match GameManager.current_game:
		GameManager.GAME_TYPE.TICTACTOE:
			$"%X".modulate = GameManager.color_player_1
			$"%O".modulate = GameManager.color_player_2

func hide_game_pieces() -> void:
	match GameManager.current_game:
		GameManager.GAME_TYPE.TICTACTOE:
			$"%X".hide()
			$"%O".hide()
		# Checkers
		# Chess

func show_piece() -> void:
	has_piece = true
	match GameManager.current_game:
		GameManager.GAME_TYPE.TICTACTOE:
			match GameManager.current_turn:
				1: # X
					$"%X".show()
				2: # O
					$"%O".show()

func move_to(target_position: Vector2) -> void:
	var move_direction = position.direction_to(target_position)
	tween.interpolate_method(self, "snap_pixel", - move_direction * TILE_SIZE, Vector2.ZERO, 1, Tween.TRANS_EXPO, Tween.EASE_OUT)
	tween.start()
	yield(tween, "tween_started")
	position = target_position
	yield(tween, "tween_completed")
	emit_signal("move_complete")

func snap_pixel(pos: Vector2) -> void:
	pivot.position.x = int(pos.x) - int(pos.x) % PIXEL_SIZE
	pivot.position.y = int(pos.y) - int(pos.y) % PIXEL_SIZE

func bump() -> void:
	var first_color = pivot.modulate
	tween.interpolate_property(pivot, "modulate", pivot.modulate, Color.red, 0.333333, Tween.TRANS_EXPO)
	tween.interpolate_property(pivot, "modulate", pivot.modulate, first_color, 0.666667, Tween.TRANS_EXPO, Tween.EASE_IN_OUT, 0.333333)
	tween.start()
