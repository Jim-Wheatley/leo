extends Node

# Test script to verify starting materials system

func _ready():
	print("=== STARTING MATERIALS TEST ===")
	test_new_player_data()
	test_loaded_player_data()

func test_new_player_data():
	"""Test that new PlayerData gets starting materials"""
	print("\n🧪 Testing new PlayerData creation...")
	
	var new_player_data = PlayerData.new()
	
	print("Inventory size: %d" % new_player_data.inventory.size())
	
	if new_player_data.inventory.size() > 0:
		print("✅ Starting materials added successfully!")
		print("Materials included:")
		for item in new_player_data.inventory:
			print("  - %s x%d" % [item.display_name, item.current_stack])
	else:
		print("❌ No starting materials found!")

func test_loaded_player_data():
	"""Test that loaded PlayerData doesn't duplicate starting materials"""
	print("\n🧪 Testing loaded PlayerData...")
	
	# Create new player data
	var player_data = PlayerData.new()
	var original_count = player_data.inventory.size()
	
	# Simulate save/load cycle
	var save_dict = player_data.to_dict()
	var loaded_player_data = PlayerData.new()
	
	# Clear inventory before loading (simulating empty state before load)
	loaded_player_data.inventory.clear()
	loaded_player_data.from_dict(save_dict)
	
	var loaded_count = loaded_player_data.inventory.size()
	
	print("Original inventory: %d items" % original_count)
	print("Loaded inventory: %d items" % loaded_count)
	
	if loaded_count == original_count:
		print("✅ Save/load preserves inventory correctly!")
	else:
		print("❌ Save/load inventory mismatch!")

func test_artwork_creation_readiness():
	"""Test that starting materials allow immediate artwork creation"""
	print("\n🧪 Testing artwork creation readiness...")
	
	var player_data = PlayerData.new()
	
	# Check for required materials
	var has_canvas = false
	var has_paint = false
	
	for item in player_data.inventory:
		if item.item_type == InventoryItem.ItemType.CANVAS:
			has_canvas = true
		elif item.item_type == InventoryItem.ItemType.PAINT:
			has_paint = true
	
	print("Has canvas: %s" % ("✅" if has_canvas else "❌"))
	print("Has paint: %s" % ("✅" if has_paint else "❌"))
	
	if has_canvas and has_paint:
		print("✅ Player can create artwork immediately!")
	else:
		print("❌ Missing materials for immediate artwork creation!")

func _input(event):
	if event.is_action_pressed("ui_accept"):
		print("\n🔄 Re-running tests...")
		test_new_player_data()
		test_loaded_player_data()
		test_artwork_creation_readiness()