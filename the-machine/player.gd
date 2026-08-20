extends CharacterBody2D

@export var speed: float = 80.0
@export var jump_velocity: float = -300.0
@export var gravity: float = 1000.0
@onready var tile_manager: TileManager = $"../World/TileManager"

func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity.y += gravity * delta

	# Jump
	if Input.is_action_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	# Left/right movement
	var direction := Input.get_axis("move_left", "move_right")
	
	velocity.x *= 0.5
	if direction != 0.0:
		velocity.x += direction * speed

	# Move + collide
	move_and_slide()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var mouse_world_position := get_global_mouse_position()
			var tile_position := tile_manager.screenToTilemapCoords(mouse_world_position)

			tile_manager.Write(tile_position, -1, true) # -1 means empty.
