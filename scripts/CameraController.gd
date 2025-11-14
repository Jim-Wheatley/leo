extends Camera2D

# Simple camera controller that follows the player

@export var follow_speed: float = 5.0
@export var offset_smoothing: float = 10.0

var target: Node2D = null

func _ready():
	# Find the player in the scene
	target = get_node("../Player")
	if target:
		global_position = target.global_position

func _process(delta):
	if target:
		# Smoothly follow the target
		var target_position = target.global_position
		global_position = global_position.lerp(target_position, follow_speed * delta)