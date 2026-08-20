extends Node2D

var chunk_coord: Vector2i
var chunk_size: int

@onready var tile_map: TileMapLayer = $TileMapLayer

const EMPTY_TILE: int = -1

func update_tile(position: Vector2i, tile: int) -> void:
	if tile == EMPTY_TILE:
		tile_map.erase_cell(position)
	else:
		tile_map.set_cell(position, 0, Vector2i(0, 0))
