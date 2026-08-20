class_name ChunkData #this script doesn't belong to any node
extends RefCounted


var sizeX: int
var sizeY: int
var tilemap: PackedInt32Array #tilemap
var dirty: bool = false


func _init(size_x: int, size_y: int, filling: int = 0) -> void:
	sizeX = size_x #define the GLOBAL variables sizeX and sizeY based on the LOCAL variables size_x and size_y
	sizeY = size_y
	tilemap.resize(sizeX * sizeY) #initialize the tiles list
	tilemap.fill(filling) #fill it with a bunch of tiles

func set_tile(position: Vector2i, tile: int, dirt: bool) -> void: #set tile in tilemap
	tilemap[position.x + position.y * sizeX] = tile
	if dirt: #some unimportant updates don't need to be saved.
		dirty = true

func read_tile(position: Vector2i) -> int: #index tile in tilemap
	return tilemap[position.x + position.y * sizeX]
