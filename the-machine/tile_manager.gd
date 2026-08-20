class_name TileManager
extends Node

@onready var player: CharacterBody2D = $"../../Player"

const chunkScene : PackedScene = preload("res://chunk.tscn")

var generation_queue: Array[Vector2i] = [] #generation queue for asynchronous chunk loading
var generation_tasks := {}
const MAX_GENERATING_CHUNKS: int = 2
const ChunkSizeX: int = 128
const ChunkSizeY: int = 128
var chunks := {}
var vchunks := {}
var tileSize : int = 8
const CHUNK_GENERATION_TIME: float = 1.0

func createChunk(position: Vector2i) -> void:
	chunks[position] = ChunkData.new(Vector2i(position), ChunkSizeX, ChunkSizeY)
	generation_queue.append(position)
func deleteChunk(position: Vector2i) -> void:
	if not chunks.has(position):
		return
	if chunks[position].generating:
		return
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
	if chunks.has(chunk_pos) and chunks[chunk_pos].ready:
		return readChunk(chunk_pos, local_pos)
	else:
		return(-1)

func screenToTilemapCoords(position: Vector2) -> Vector2i:
	return Vector2i(
	floori(position.x / tileSize),
	floori(position.y / tileSize) )

func findMostNeededChunk(termination: int) -> Variant:
	var rootCoord := getChunkCoord(screenToTilemapCoords(player.global_position))

	var chunk_height_pixels: float = ChunkSizeY * tileSize
	var velocity_y: float = maxf(player.velocity.y, 0.0) # Only care about downward velocity.
	var gravity: float = player.gravity

	var fall_distance: float = (
		velocity_y * CHUNK_GENERATION_TIME
		+ 0.5 * gravity * CHUNK_GENERATION_TIME * CHUNK_GENERATION_TIME
	)

	var chunk_offset: int = ceili(fall_distance / chunk_height_pixels) + 1 # +1 safety chunk.
	rootCoord.y += chunk_offset
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
			deleteChunk(chunk_pos)
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

func startQueuedGenerations() -> void:
	while generation_tasks.size() < MAX_GENERATING_CHUNKS and not generation_queue.is_empty():
		var position: Vector2i = generation_queue.pop_front() #take *one* of the positions from the to-be-generated queue
		if not chunks.has(position): #continue skips to the end of the function. If the chunk exists, we don't wanna execute
			continue
		var chunk_data: ChunkData = chunks[position] #save the chunk data to a var
		chunk_data.generating = true #set generating flag to true
		var task_id: int = WorkerThreadPool.add_task(chunk_data.generate) #Assign an ID to the generated chunk
		chunk_data.generation_task_id = task_id #start generating i think
		generation_tasks[position] = task_id #something... it just works.
func finishCompletedGenerations() -> void:
	for position in generation_tasks.keys():
		var task_id: int = generation_tasks[position]

		if not WorkerThreadPool.is_task_completed(task_id): #if the task is completed, continue, else quit function (no pun intended)
			continue

		WorkerThreadPool.wait_for_task_completion(task_id)

		generation_tasks.erase(position)

		if not chunks.has(position):
			continue

		var chunk_data: ChunkData = chunks[position]

		chunk_data.generating = false
		chunk_data.generation_task_id = -1
		chunk_data.ready = true

func loadWorld() -> void:
	finishCompletedGenerations() #finish chunk generation that was finished
	var position = findMostNeededChunk(5) #find the most needed chunk that needs to be spawned
	if position != null: #check if there is a chunk that matches the aforementioned constraint
		createChunk(position) #create the simulationChunk (not the visual vchunk)
	startQueuedGenerations() #generate
	deleteChunksInRadius(7) #delete unneccessary chunks exceeding +-7 tiles
	deleteVChunks() #delete unneccessary visual chunks that aren't in a 3x3 box around the player
	addAllVChunks() #add 3x3 visual chunks around the player that have a simulation chunk for them

func _process(delta: float) -> void:
	loadWorld()
