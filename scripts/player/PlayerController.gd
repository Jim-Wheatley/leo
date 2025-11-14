extends CharacterBody2D

# Player Controller for 2D movement and interactions
# Handles 8-directional movement with smooth camera following

@export var speed: float = 200.0
@export var acceleration: float = 1000.0
@export var friction: float = 1000.0

@onready var camera: Camera2D = $Camera2D
@onready var interaction_area: Area2D = $InteractionArea

var input_vector: Vector2 = Vector2.ZERO
var current_interaction_target: Node = null

func _ready():
	# Set up camera
	if camera:
		camera.enabled = true
		# Smooth camera following
		camera.position_smoothing_enabled = true
		camera.position_smoothing_speed = 5.0

func _physics_process(delta):
	handle_input()
	handle_movement(delta)

func handle_input():
	"""Handle player input for movement"""
	input_vector = Vector2.ZERO
	
	# 8-directional movement
	if Input.is_action_pressed("move_right"):
		input_vector.x += 1
	if Input.is_action_pressed("move_left"):
		input_vector.x -= 1
	if Input.is_action_pressed("move_down"):
		input_vector.y += 1
	if Input.is_action_pressed("move_up"):
		input_vector.y -= 1
	
	# Normalize diagonal movement
	input_vector = input_vector.normalized()

func handle_movement(delta):
	"""Handle player movement with acceleration and friction"""
	if input_vector != Vector2.ZERO:
		# Apply acceleration
		velocity = velocity.move_toward(input_vector * speed, acceleration * delta)
	else:
		# Apply friction
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	
	# Move the player
	move_and_slide()

func _input(event):
	"""Handle input events"""
	if event.is_action_pressed("interact"):
		if current_interaction_target:
			interact_with_target()

func interact_with_target():
	"""Interact with the current target"""
	if not current_interaction_target:
		return
	
	# Handle Master Artist interactions
	if current_interaction_target.has_method("interact_with_player"):
		current_interaction_target.interact_with_player()
		return
	
	# Handle gathering resource interactions
	if current_interaction_target.has_method("gather_resource"):
		var result = current_interaction_target.gather_resource()
		if result.success:
			var message = "Gathered: "
			for item in result.items:
				message += item + " "
			if result.rare_found:
				message += "(Rare material found!)"
			print(message)
		else:
			print(result.message)
		return
	
	# Handle other interaction types
	if current_interaction_target.has_method("interact"):
		current_interaction_target.interact()
		return

func set_interaction_target(target: Node):
	"""Set the current interaction target"""
	current_interaction_target = target
	# Could show interaction prompt here

func clear_interaction_target(target: Node):
	"""Clear the interaction target if it matches"""
	if current_interaction_target == target:
		current_interaction_target = null

func get_facing_direction() -> Vector2:
	"""Get the direction the player is facing based on movement"""
	if velocity.length() > 0:
		return velocity.normalized()
	else:
		return Vector2.DOWN  # Default facing direction
