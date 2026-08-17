extends Node2D

var chunk_coord: Vector2i = Vector2i.ZERO
var chunk_size: int = 128

@onready var tile_map: TileMapLayer = $TileMapLayer


func _ready() -> void:
	generate()
	print("Loaded chunk ", chunk_coord)

func is_prime(n: int) -> bool:
	var i := 2

	while i * i <= n:
		if n % i == 0:
			return false
		i += 1

	return n >= 2


func is_twin_prime(n: int) -> bool:
	return is_prime(n) and (is_prime(n - 2) or is_prime(n + 2))

func generate_tile(coord: Vector2i, offset: Vector3) -> bool:
	var frag_coord := Vector2i.ZERO
	var p := coord


	frag_coord = p

	frag_coord.x = -p.x + p.y
	frag_coord.y = p.x + p.y

	# Restore the missing checkerboard parity.
	frag_coord.x += (p.x + p.y) & 1

	var x := frag_coord.x + int(offset.x)
	var y := frag_coord.y + int(offset.y)


	var r := absi(x) ^ absi(y)

	return is_twin_prime(r)

func generate() -> void:
	tile_map.clear()

	for y in range(chunk_size):
		for x in range(chunk_size):
			var local_pos := Vector2i(x, y)
			var world_pos := chunk_coord * chunk_size + local_pos
			if generate_tile(world_pos, Vector3(0.0, 0.0, 1.0)):
				tile_map.set_cell(local_pos, 0, Vector2i(0.0, 0.0))
			# Generate terrain using world_pos here.
			# Then call tile_map.set_cell(...) if a tile should exist.
