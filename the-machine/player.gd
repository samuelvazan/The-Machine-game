extends CharacterBody2D

@export var speed: float = 300.0
@export var jump_velocity: float = -500.0
@export var gravity: float = 1200.0


func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity.y += gravity * delta

	# Jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	# Left/right movement
	var direction := Input.get_axis("move_left", "move_right")

	if direction != 0.0:
		velocity.x = direction * speed
	else:
		velocity.x = 0.0

	# Move + collide
	move_and_slide()
