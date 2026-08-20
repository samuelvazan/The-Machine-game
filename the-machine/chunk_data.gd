class_name ChunkData
extends RefCounted

var sizeX: int
var sizeY: int
var chunk_coord: Vector2i #global coordinate of the chunk

var tilemap: PackedInt32Array #initialize tilemap
var dirty: bool = false
var ready: bool = false #whether the chunk was fully pre-loaded and ready to be visualized
var generating: bool = false #whether we're generating the tilemap
var generation_task_id: int = -1


func _init(position: Vector2i, size_x: int, size_y: int, filling: int = -1) -> void: #when instantiating, these arguments must be passed.
	chunk_coord = position
	sizeX = size_x
	sizeY = size_y
	tilemap.resize(sizeX * sizeY)
	tilemap.fill(filling)

func set_tile(position: Vector2i, tile: int, dirt: bool) -> void:
	tilemap[position.x + position.y * sizeX] = tile

	if dirt:
		dirty = true

func read_tile(position: Vector2i) -> int:
	return tilemap[position.x + position.y * sizeX]

func Write(position: Vector2i, tile: int) -> void:
	var chunk_origin := Vector2i(chunk_coord.x * sizeX, chunk_coord.y * sizeY)
	var local_position := position - chunk_origin # Convert global tile coordinates to local chunk coordinates.

	if local_position.x < 0 or local_position.x >= sizeX:
		return
	if local_position.y < 0 or local_position.y >= sizeY:
		return

	set_tile(local_position, tile, false) # Generation should not mark the chunk as dirty.


const AIR: int = -1
const GROUND: int = 0

func is_prime(n: int) -> bool:
	if n < 2:
		return false

	var i: int = 2
	while i * i <= n:
		if n % i == 0:
			return false
		i += 1

	return true


func is_twin_prime(n: int) -> bool:
	return is_prime(n) and (is_prime(n - 2) or is_prime(n + 2))


func generate_tile(x: int, y: int) -> int:
	var frag_x: int = -x + y
	var frag_y: int = x + y

	frag_x += (x + y) & 1 # Restore the missing checkerboard parity.

	var r: int = absi(frag_x) ^ absi(frag_y)

	return GROUND if is_twin_prime(r) else AIR

func generate() -> void:
	var chunk_origin := Vector2i(
		chunk_coord.x * sizeX,
		chunk_coord.y * sizeY
	)
	for y in range(sizeY):
		for x in range(sizeX):
			var local_position := Vector2i(x, y)
			var global_position := chunk_origin + local_position
			set_tile(local_position, generate_tile(global_position.x, global_position.y), false)
