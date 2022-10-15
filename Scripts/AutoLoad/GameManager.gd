extends Node

enum GAME_TYPE { NONE = -1, TICTACTOE = 1 } # CHECKERS = 2, CHESS = 3}

export (Color) var color_player_1 = Color.red
export (Color) var color_player_2 = Color.blue

export (GAME_TYPE) var current_game = GAME_TYPE.NONE
export (int) var current_turn = -1

func start_game(type: int) -> void:
	current_game = type
	current_turn = 1
