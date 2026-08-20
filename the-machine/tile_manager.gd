class_name TileManager
extends Node

@onready var player: Node2D = $"../../Player"

const chunkScene : PackedScene = preload("res://chunk.tscn")

const ChunkSizeX: int = 128
const ChunkSizeY: int = 128
var chunks := {}
var vchunks := {}
var tileSize : int = 8

func createChunk(position: Vector2i) -> void:
	chunks[position] = ChunkData.new(Vector2i(position), ChunkSizeX, ChunkSizeY)
	chunks[position].generate()
func deleteChunk(position: Vector2i) -> void:
	if chunks.has(position):
		chunks.erase(position)
func createvchunk(position: Vector2i) -> void:
	if chunks.has(position):
		if chunks[position].ready:
			var vchunk = chunkScene.instantiate()
			vchunk.chunk_coord = position
			vchunk.chunk_size = ChunkSizeX
			vchunk.position = Vector2(position.x * ChunkSizeX * tileSize, position.y * ChunkSizeY * tileSize)
			add_child(vchunk)
			vchunks[position] = vchunk
			loadvchunk(position)
func deletevchunk(position: Vector2i) -> void:
	if vchunks.has(position):
		vchunks[position].queue_free()
		vchunks.erase(position)
func loadvchunk(position: Vector2i) -> void:
	var chunk_data = chunks[position]
	var vchunk = vchunks[position]
	for y in range(ChunkSizeY):
		for x in range(ChunkSizeX):
			var local_pos := Vector2i(x, y)
			var tile: int = chunk_data.read_tile(local_pos)
			vchunk.update_tile(local_pos, tile)

func modifyChunk(chunkPos: Vector2i, tilePos: Vector2i, value: int, dirty: bool) -> void:
	if chunks.has(chunkPos):
		chunks[chunkPos].set_tile(tilePos, value, dirty)
func readChunk(chunkPos: Vector2i, tilePos: Vector2i) -> int:
	return chunks[chunkPos].read_tile(tilePos)

func getChunkCoord(position: Vector2) -> Vector2i:
	return Vector2i(
		floori(float(position.x) / ChunkSizeX),
		floori(float(position.y) / ChunkSizeY)
	)
func getLocalCoord(position: Vector2i) -> Vector2i:
	return Vector2i(
		posmod(position.x, ChunkSizeX),
		posmod(position.y, ChunkSizeY)
	)

func Write(position: Vector2i, tile: int, dirty: bool) -> void:
	var chunk_pos = getChunkCoord(position)
	var local_pos = getLocalCoord(position)
	modifyChunk(chunk_pos, local_pos, tile, dirty)
	if vchunks.has(chunk_pos): #update the visual chunk, _if_ loaded.
		vchunks[chunk_pos].update_tile(local_pos, tile)
func Read(position: Vector2i) -> int:
	var chunk_pos = getChunkCoord(position)
	var local_pos = getLocalCoord(position)
	if chunks.has(chunk_pos):
		return readChunk(chunk_pos, local_pos)
	else:
		return(-1)

func screenToTilemapCoords(position: Vector2) -> Vector2i:
	return Vector2i(
	floori(position.x / tileSize),
	floori(position.y / tileSize) )

func findMostNeededChunk(termination: int) -> Variant:
	var rootCoord := getChunkCoord(screenToTilemapCoords(player.global_position)) #calculate player pos
	var radius := 0
	while true:
		for y in range(-radius, radius + 1):
			for x in range(-radius, radius + 1):
				if max(absi(x), absi(y)) != radius:
					continue #only check the current outer 'ring'
				var coord := rootCoord + Vector2i(x, y)
				if not chunks.has(coord):
					return coord
		radius += 1
		if radius > termination:
			return null
	return Vector2i.ZERO #just so Godot doesn't flag this as 'not all path return'.
func deleteChunksInRadius(radius: int) -> void:
	var rootCoord := getChunkCoord(screenToTilemapCoords(player.global_position)) #calculate player pos
	for chunk_pos in chunks.keys(): #go over every position in chunks dictionary (key=position, value=chunk_data)
		var offset: Vector2i = chunk_pos - rootCoord
		if max(absi(offset.x), absi(offset.y)) > radius: #if exceeds radius, delete chunk data
			chunks.erase(chunk_pos)
func deleteVChunks() -> void:
	var rootCoord := getChunkCoord(screenToTilemapCoords(player.global_position)) #calculate player pos
	for chunk_pos in vchunks.keys(): #go over all visual chunks, see if some of them aren't in 3x3 radius
		var offset: Vector2i = chunk_pos - rootCoord
		if max(absi(offset.x), absi(offset.y)) > 1: #3 surrounding chunks go from -1 to 0 to 1, anything else delete.
			deletevchunk(chunk_pos)
func addAllVChunks() -> void:
	var rootCoord := getChunkCoord(screenToTilemapCoords(player.global_position)) #calculate player pos
	for x in range(-1, 2, 1):
		for y in range(-1, 2, 1):
			if not vchunks.has(Vector2i(x+rootCoord.x, y+rootCoord.y)):
				createvchunk(Vector2i(x+rootCoord.x, y+rootCoord.y))

func loadWorld() -> void:
	var position = findMostNeededChunk(5) #(5+1+5)^2 tiles
	if not position == null:
		createChunk(position)
	deleteChunksInRadius(7) #delete all chunks exceeding 10 + 5
	deleteVChunks() #delete unneccessary visual chunks
	addAllVChunks() #add all neccessary visual chunks

func _process(delta: float) -> void:
	loadWorld()
