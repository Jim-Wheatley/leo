extends Node

# Script to initialize some test data for testing save/load functionality

func _ready():
	# Wait a frame to ensure GameManager is ready
	await get_tree().process_frame
	
	# Only initialize test data if this is a fresh game (no existing data)
	if GameManager.player_data and _is_fresh_game():
		_add_test_data()

func _is_fresh_game() -> bool:
	"""Check if this is a fresh game (no saved data loaded)"""
	var player_data = GameManager.player_data
	# If player has no skills above starting level, it's probably a fresh game
	return (player_data.skills["painting"] <= 1 and 
			player_data.skills["sketching"] <= 1 and 
			player_data.inventory.is_empty() and 
			player_data.portfolio.is_empty())

func _add_test_data():
	"""Add some test data to verify save/load functionality"""
	var player_data = GameManager.player_data
	
	# Add some test experience through SkillManager
	SkillManager.add_experience("painting", 50, "Initial practice")
	SkillManager.add_experience("sketching", 75, "Initial sketching")
	SkillManager.add_experience("gathering", 25, "Initial gathering")
	
	# Add some test inventory items
	var red_pigment = InventoryItem.create_pigment("Red")
	red_pigment.quality = 1.2  # Set quality after creation
	var blue_pigment = InventoryItem.create_pigment("Blue")
	blue_pigment.quality = 0.8  # Set quality after creation
	var canvas = InventoryItem.create_canvas("Small")
	
	player_data.add_inventory_item(red_pigment)
	player_data.add_inventory_item(blue_pigment)
	player_data.add_inventory_item(canvas)
	
	# Add a test artwork
	var test_sketch = ArtworkData.create_sketch("Practice Study", player_data.skills)
	player_data.add_artwork(test_sketch)
	
	print("Test data initialized - Skills, inventory, and portfolio populated")
