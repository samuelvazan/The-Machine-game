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

func wrap_i32(value: int) -> int:
	value &= 0xFFFFFFFF # Keep only the lowest 32 bits.

	if value >= 0x80000000:
		value -= 0x100000000 # Interpret the result as signed two's-complement.

	return value
func multiply_i32(a: int, b: int) -> int:
	return wrap_i32(a * b) # a and b are 32-bit, so their product safely fits inside GDScript's 64-bit int.
func abs_i32(value: int) -> int:
	if value < 0:
		return wrap_i32(-value)

	return value
func exponentiate(base: int, exponent: int) -> int:
	var result: int = 1

	while exponent > 0:
		if (exponent & 1) != 0:
			result = multiply_i32(result, base)

		base = multiply_i32(base, base)
		exponent >>= 1

	return result
func mix_bits(x: int) -> int:
	x = wrap_i32(x ^ (x >> 16))
	x = multiply_i32(x, 0x45D9F3B)
	x = wrap_i32(x ^ (x >> 16))
	x = multiply_i32(x, 0x45D9F3B)
	x = wrap_i32(x ^ (x >> 16))

	return x

func generate_tile(position: Vector2i) -> int:
	var px: int = wrap_i32(position.x)
	var py: int = wrap_i32(position.y)

	var frag_x: int = wrap_i32(-px + py)
	var frag_y: int = wrap_i32(px + py)

	var parity: int = wrap_i32(px + py) & 1
	frag_x = wrap_i32(frag_x + parity)

	var x: int = frag_x
	var y: int = frag_y

	var r: int = abs_i32(x) ^ abs_i32(y)

	var exponent: int = multiply_i32(multiply_i32(r, r), r) # Exactly r*r*r with 32-bit overflow after each multiplication.

	r = exponentiate(r, exponent)
	r = mix_bits(r)

	var xor_value: int = abs_i32(x) ^ abs_i32(y)
	r = multiply_i32(r, xor_value)

	if r < 1999999999:
		return AIR

	return GROUND


func generate() -> void:
	var chunk_origin := Vector2i(
		chunk_coord.x * sizeX,
		chunk_coord.y * sizeY
	)
	for y in range(sizeY):
		for x in range(sizeX):
			var local_position := Vector2i(x, y)
			var global_position := chunk_origin + local_position
			set_tile(local_position, generate_tile(global_position), false)
