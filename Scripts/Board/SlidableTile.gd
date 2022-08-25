extends 'TileTypes.gd'

const TILE_SIZE = 16

onready var tween = $Tween
onready var pivot = $Pivot

func move_to(target_position: Vector2) -> void:
	var move_direction = position.direction_to(target_position)
	tween.interpolate_property(pivot, "position", - move_direction * TILE_SIZE, Vector2.ZERO, 1, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT)
	tween.start()
	yield(tween, "tween_started")
	position = target_position
	yield(tween, "tween_completed")

func bump() -> void:
	var first_color = pivot.modulate
	tween.interpolate_property(pivot, "modulate", pivot.modulate, Color.red, 0.333333, Tween.TRANS_EXPO)
	tween.interpolate_property(pivot, "modulate", pivot.modulate, first_color, 0.666667, Tween.TRANS_EXPO, Tween.EASE_IN_OUT, 0.333333)
	tween.start()
