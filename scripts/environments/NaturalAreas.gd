extends Node2D

# Natural Areas scene for material gathering
# Contains clay deposits, mineral veins, and other harvestable resources

@onready var gathering_nodes = $GatheringNodes
@onready var player_spawn = $PlayerSpawn
@onready var exit_to_florence = $ExitToFlorence

var player: CharacterBody2D

func _ready():
	# Set up exit area
	if exit_to_florence:
		exit_to_florence.body_entered.connect(_on_exit_area_entered)
		
		# Add collision shape for exit area
		var collision_shape = exit_to_florence.get_node("CollisionShape2D")
		if collision_shape and not collision_shape.shape:
			var shape = RectangleShape2D.new()
			shape.size = Vector2(50, 50)
			collision_shape.shape = shape
	
	# Initialize gathering nodes
	_initialize_gathering_nodes()
	
	# Spawn player if not already present
	_spawn_player()

func _initialize_gathering_nodes():
	"""Initialize all gathering nodes in the scene"""
	for node in gathering_nodes.get_children():
		if node is GatheringNode:
			# Connect signals for feedback
			node.resource_gathered.connect(_on_resource_gathered)
			node.resource_depleted.connect(_on_resource_depleted.bind(node))

func _spawn_player():
	"""Spawn the player at the designated spawn point"""
	# Check if player already exists in scene
	player = get_tree().get_first_node_in_group("player")
	
	if not player:
		# Load player scene and add to this scene
		var player_scene = preload("res://scenes/Player.tscn")
		if player_scene:
			player = player_scene.instantiate()
			add_child(player)
			player.add_to_group("player")
			
			# Make sure player is visible by adding a simple texture
			var sprite = player.get_node("Sprite2D")
			if sprite and not sprite.texture:
				var texture = ImageTexture.new()
				var image = Image.create(20, 30, false, Image.FORMAT_RGB8)
				image.fill(Color.BLUE)  # Blue player character
				texture.set_image(image)
				sprite.texture = texture
	
	if player and player_spawn:
		player.global_position = player_spawn.global_position
		print("🧑 Player spawned at: ", player.global_position)

func _on_exit_area_entered(body):
	"""Handle player exiting to Florence"""
	if body.has_method("get_facing_direction"):  # Check if it's the player
		print("🏛️ Returning to Florence...")
		GameManager.change_scene("florence")

func _on_resource_gathered(item_id: String, quantity: int):
	"""Handle resource gathering feedback"""
	print("Gathered ", quantity, " ", item_id)
	# Could show UI feedback here

func _on_resource_depleted(node: GatheringNode):
	"""Handle resource depletion feedback"""
	print("Resource depleted: ", node.resource_name)
	# Could show visual/audio feedback here

func save_scene_data() -> Dictionary:
	"""Save the state of all gathering nodes"""
	var scene_data = {}
	
	for i in range(gathering_nodes.get_child_count()):
		var node = gathering_nodes.get_child(i)
		if node is GatheringNode:
			scene_data[node.name] = node.save_data()
	
	return scene_data

func load_scene_data(data: Dictionary):
	"""Load the state of all gathering nodes"""
	for node_name in data.keys():
		var node = gathering_nodes.get_node_or_null(node_name)
		if node and node is GatheringNode:
			node.load_data(data[node_name])

func get_available_resources() -> Array:
	"""Get list of all available resources in the area"""
	var resources = []
	
	for node in gathering_nodes.get_children():
		if node is GatheringNode and node.can_gather():
			resources.append({
				"name": node.resource_name,
				"type": node.resource_id,
				"remaining": node.current_resources,
				"position": node.global_position
			})
	
	return resources