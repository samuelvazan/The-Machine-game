class_name TileManager
extends Node

@onready var player: Node2D = $"../../Player"

const chunkScene := preload("res://chunk.tscn")

const ChunkSizeX: int = 128
const ChunkSizeY: int = 128
var chunks := {}
var vchunks := {}
var tileSize : int = 8

func createChunk(position: Vector2i) -> void:
	chunks[position] = ChunkData.new(ChunkSizeX, ChunkSizeY)
func deleteChunk(position: Vector2i) -> void:
	if chunks.has(position):
		chunks.erase(position)
func createvchunk(position: Vector2i) -> void:
	vchunks[position] = chunkScene.new(ChunkSizeX, ChunkSizeY)
func deletevchunk(position: Vector2i) -> void:
	if vchunks.has(position):
		vchunks.erase(position)


func modifyChunk(chunkPos: Vector2i, tilePos: Vector2i, value: int, dirty: bool) -> void:
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
func Read(position: Vector2i) -> int:
	var chunk_pos = getChunkCoord(position)
	var local_pos = getLocalCoord(position)
	return readChunk(chunk_pos, local_pos)

func screenToTilemapCoords(position: Vector2) -> Vector2i:
	return Vector2i(
	floori(position.x / tileSize),
	floori(position.y / tileSize) )

func FindMostNeededChunk() -> Vector2i:
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
	return Vector2i.ZERO #just Godot doesn't flag this as 'not all path return'.
func DeleteChunksInRadius(radius: int) -> void:
	var rootCoord := getChunkCoord(screenToTilemapCoords(player.global_position)) #calculate player pos
	for chunk_pos in chunks.keys(): #go over every position in chunks dictionary (key=position, value=chunk_data)
		var offset: Vector2i = chunk_pos - rootCoord
		if max(absi(offset.x), absi(offset.y)) > radius: #if exceeds radius, delete chunk data
			chunks.erase(chunk_pos)
