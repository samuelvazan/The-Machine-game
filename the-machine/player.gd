extends CharacterBody2D

@export var speed: float = 80.0
@export var jump_velocity: float = -300.0
@export var gravity: float = 1000.0


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
