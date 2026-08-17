extends Node2D

var chunk_coord: Vector2i = Vector2i.ZERO
var chunk_size: int = 128

# TileManager sets this to true only for the initial chunk
# underneath the player.
var generate_synchronously: bool = false

@onready var tile_map: TileMapLayer = $TileMapLayer


var generation_task: int = -1
var generated_cells: Array[Vector2i] = []

var result_mutex := Mutex.new()
var generation_finished := false


func _ready() -> void:
	if generate_synchronously:
		var cells := calculate_chunk(chunk_coord, chunk_size)
		apply_cells(cells)

		# Make sure collision/tile internals exist immediately.
		tile_map.update_internals()

		print("Loaded center chunk ", chunk_coord)

	else:
		var coord_copy := chunk_coord
		var size_copy := chunk_size

		generation_task = WorkerThreadPool.add_task(
			generate_in_thread.bind(coord_copy, size_copy)
		)


func _process(_delta: float) -> void:
	if generation_task == -1:
		return

	result_mutex.lock()
	var finished := generation_finished
	result_mutex.unlock()

	if not finished:
		return

	# The worker is finished, so this won't stall.
	WorkerThreadPool.wait_for_task_completion(generation_task)
	generation_task = -1

	result_mutex.lock()
	var cells := generated_cells.duplicate()
	result_mutex.unlock()

	# TileMapLayer changes happen on the MAIN thread.
	apply_cells(cells)

	print("Loaded chunk ", chunk_coord)


func generate_in_thread(
	coord: Vector2i,
	size: int
) -> void:

	var cells := calculate_chunk(coord, size)

	result_mutex.lock()

	generated_cells = cells
	generation_finished = true

	result_mutex.unlock()


func calculate_chunk(
	coord: Vector2i,
	size: int
) -> Array[Vector2i]:

	var cells: Array[Vector2i] = []

	# These caches exist only while generating this chunk.
	var prime_cache: Dictionary = {}
	var twin_prime_cache: Dictionary = {}

	for y in range(size):
		for x in range(size):
			var local_pos := Vector2i(x, y)
			var world_pos := coord * size + local_pos

			if generate_tile(
				world_pos,
				Vector3(0.0, 0.0, 1.0),
				prime_cache,
				twin_prime_cache
			):
				cells.append(local_pos)

	return cells


func is_prime(
	n: int,
	cache: Dictionary
) -> bool:

	if cache.has(n):
		return cache[n]

	# Your original algorithm.
	var i := 2

	while i * i <= n:
		if n % i == 0:
			cache[n] = false
			return false

		i += 1

	var result := n >= 2

	cache[n] = result

	return result


func is_twin_prime(
	n: int,
	prime_cache: Dictionary,
	twin_prime_cache: Dictionary
) -> bool:

	if twin_prime_cache.has(n):
		return twin_prime_cache[n]

	var result := (
		is_prime(n, prime_cache)
		and (
			is_prime(n - 2, prime_cache)
			or is_prime(n + 2, prime_cache)
		)
	)

	twin_prime_cache[n] = result

	return result


func generate_tile(
	coord: Vector2i,
	offset: Vector3,
	prime_cache: Dictionary,
	twin_prime_cache: Dictionary
) -> bool:

	var p := coord
	var frag_coord := Vector2i.ZERO

	frag_coord.x = -p.x + p.y
	frag_coord.y = p.x + p.y

	# Restore checkerboard parity.
	frag_coord.x += (p.x + p.y) & 1

	var x := frag_coord.x + int(offset.x)
	var y := frag_coord.y + int(offset.y)

	var r := absi(x) ^ absi(y)

	return is_twin_prime(
		r,
		prime_cache,
		twin_prime_cache
	)


func apply_cells(cells: Array[Vector2i]) -> void:
	tile_map.clear()

	for local_pos in cells:
		tile_map.set_cell(
			local_pos,
			0,
			Vector2i(0, 0)
		)


func _exit_tree() -> void:
	# Don't destroy this Chunk while its worker is still using it.
	if generation_task != -1:
		WorkerThreadPool.wait_for_task_completion(generation_task)
		generation_task = -1
