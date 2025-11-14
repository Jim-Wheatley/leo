extends Camera2D

# Simple camera that follows the player

var player: Node2D

func _ready():
	# Find the player
	player = get_node("../Player")

func _process(delta):
	if player:
		global_position = player.global_position