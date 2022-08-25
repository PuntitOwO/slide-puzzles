extends TileMap

enum CELL_TYPES { TRUE_EMPTY = -1, DECORATION = 0, SLIDABLE = 1, EMPTY = 2, NON_SLIDABLE = 3}

func _ready() -> void:
	for child in get_children():
		set_cellv(world_to_map(child.position), child.type)

func get_cell_node(cell : Vector2, type : int) -> Node2D:
	for child in get_children():
		if child.type != type:
			continue
		if world_to_map(child.position) == cell:
			return child
	return null

func request_move(tile : Node2D, direction : Vector2) -> Vector2:
	var cell_start = world_to_map(tile.position)
	var cell_target = cell_start + direction
	
	var cell_target_tile_id = get_cellv(cell_target)
	match cell_target_tile_id:
		CELL_TYPES.EMPTY:
			set_cellv(cell_target, tile.type)
			set_cellv(cell_start, CELL_TYPES.EMPTY)
			return map_to_world(cell_target) + cell_size/2
	return Vector2.INF

