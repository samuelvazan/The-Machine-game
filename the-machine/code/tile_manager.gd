extends Node

@export var chunk_scene: PackedScene

# Size of one tile in pixels.
var tile_size: int = 8

# Width/height of one chunk in tiles.
var chunk_size: int = 128

# Distance measured in chunks.
# sqrt(2) ~= 1.414, so 1.5 keeps the whole 3x3 grid.
var unload_distance: float = 1.5

@onready var player: Node2D = $"../../Player"


var current_chunk: Vector2i


func _ready() -> void:
	current_chunk = get_player_chunk()

	# Generate the chunk beneath the player immediately.
	create_chunk(current_chunk, true)

	# Create the other 8 chunks.
	update_chunks()


func _process(_delta: float) -> void:
	var new_chunk := get_player_chunk()

	if new_chunk != current_chunk:
		current_chunk = new_chunk
		update_chunks()


func get_player_chunk() -> Vector2i:
	var chunk_pixel_size := tile_size * chunk_size

	var chunk_x := int(floor(
		player.global_position.x / float(chunk_pixel_size)
	))

	var chunk_y := int(floor(
		player.global_position.y / float(chunk_pixel_size)
	))

	return Vector2i(chunk_x, chunk_y)


func update_chunks() -> void:
	var chunks_to_create: Array[Vector2i] = []

	# Build the desired 3x3 grid.
	for y in range(-1, 2):
		for x in range(-1, 2):
			var chunk_position := (
				current_chunk
				+ Vector2i(x, y)
			)

			chunks_to_create.append(chunk_position)


	# Check currently loaded chunks.
	for child in get_children():

		if not child.has_meta("chunk_coord"):
			continue

		var chunk_coord: Vector2i = child.get_meta(
			"chunk_coord"
		)

		var distance := Vector2(chunk_coord).distance_to(
			Vector2(current_chunk)
		)

		# Remove chunks that are too far away.
		if distance > unload_distance:
			child.queue_free()

		# Don't create chunks that already exist.
		if chunk_coord in chunks_to_create:
			chunks_to_create.erase(chunk_coord)


	# Create all missing chunks.
	for chunk_coord in chunks_to_create:
		create_chunk(chunk_coord)


func create_chunk(
	chunk_coord: Vector2i,
	synchronous: bool = false
) -> void:

	var chunk := chunk_scene.instantiate() as Node2D

	if chunk == null:
		push_error("Chunk scene root must be a Node2D.")
		return

	var chunk_pixel_size := tile_size * chunk_size

	# Give Chunk.gd all its information BEFORE add_child().
	# add_child() causes _ready() to run.
	chunk.chunk_coord = chunk_coord
	chunk.chunk_size = chunk_size
	chunk.generate_synchronously = synchronous

	chunk.set_meta("chunk_coord", chunk_coord)

	chunk.position = Vector2(
		chunk_coord.x * chunk_pixel_size,
		chunk_coord.y * chunk_pixel_size
	)

	chunk.name = "Chunk_%d_%d" % [
		chunk_coord.x,
		chunk_coord.y
	]

	add_child(chunk)
