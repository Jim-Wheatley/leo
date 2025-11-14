extends Node2D

# UI Integration Test - Tests the complete UI system

@onready var ui_manager: UIManager = $UIManager

func _ready():
	print("=== UI Integration Test ===")
	print("Testing complete UI system integration...")
	
	# Wait a moment for everything to initialize
	await get_tree().create_timer(0.5).timeout
	
	# Initialize test data
	initialize_test_data()
	
	# Test basic UI functionality
	test_ui_initialization()
	
	print("UI Integration Test ready!")
	print("Use the controls shown on screen to test the UI system")

func _input(event):
	"""Handle test input"""
	if event.is_action_pressed("ui_accept"):  # T key
		if Input.is_key_pressed(KEY_1):
			test_notifications()
		elif Input.is_key_pressed(KEY_2):
			test_skill_progression()

func initialize_test_data():
	"""Initialize test data for the UI system"""
	if not GameManager or not GameManager.player_data:
		print("⚠️ GameManager or player data not available")
		return
	
	var player_data = GameManager.player_data
	
	# Add some test inventory items if empty
	if player_data.inventory.is_empty():
		var test_items = [
			create_test_item("Red Pigment", InventoryItem.ItemType.PIGMENT, 3),
			create_test_item("Blue Paint", InventoryItem.ItemType.PAINT, 2),
			create_test_item("Small Canvas", InventoryItem.ItemType.CANVAS, 1)
		]
		
		for item in test_items:
			player_data.add_inventory_item(item)
	
	# Add some test artworks if empty
	if player_data.portfolio.is_empty():
		var test_artwork = create_test_artwork("Test Sketch", ArtworkData.ArtworkType.SKETCH, 0.7)
		player_data.add_artwork(test_artwork)
	
	print("✅ Test data initialized")

func create_test_item(name: String, type: InventoryItem.ItemType, stack: int) -> InventoryItem:
	"""Create a test inventory item"""
	var item = InventoryItem.new()
	item.display_name = name
	item.item_type = type
	item.current_stack = stack
	item.quality = randf_range(0.5, 1.0)
	return item

func create_test_artwork(title: String, type: ArtworkData.ArtworkType, quality: float) -> ArtworkData:
	"""Create a test artwork"""
	var artwork = ArtworkData.new()
	artwork.title = title
	artwork.artwork_type = type
	artwork.quality_score = quality
	artwork.creation_date = Time.get_datetime_string_from_system()
	artwork.materials_used = ["Paint", "Canvas"]
	return artwork

func test_ui_initialization():
	"""Test that the UI system initialized properly"""
	print("\n🧪 Testing UI initialization...")
	
	if ui_manager:
		print("✅ UI Manager found")
		
		var main_hud = ui_manager.get_main_hud()
		if main_hud:
			print("✅ Main HUD initialized")
		else:
			print("❌ Main HUD not found")
		
		var inventory_ui = ui_manager.get_inventory_ui()
		if inventory_ui:
			print("✅ Inventory UI initialized")
		else:
			print("❌ Inventory UI not found")
		
		var portfolio_ui = ui_manager.get_portfolio_ui()
		if portfolio_ui:
			print("✅ Portfolio UI initialized")
		else:
			print("❌ Portfolio UI not found")
		
		var skill_tree_ui = ui_manager.get_skill_tree_ui()
		if skill_tree_ui:
			print("✅ Skill Tree UI initialized")
		else:
			print("❌ Skill Tree UI not found")
		
		var pause_menu = ui_manager.get_pause_menu()
		if pause_menu:
			print("✅ Pause Menu initialized")
		else:
			print("❌ Pause Menu not found")
		
	else:
		print("❌ UI Manager not found!")
	
	print("✅ UI initialization test completed")

func test_notifications():
	"""Test the notification system"""
	print("\n🧪 Testing notifications...")
	
	if not ui_manager:
		print("❌ UI Manager not available")
		return
	
	var notifications = [
		{"message": "Test notification 1", "type": "info"},
		{"message": "Success notification!", "type": "success"},
		{"message": "Warning notification", "type": "warning"},
		{"message": "Error notification", "type": "error"}
	]
	
	for i in range(notifications.size()):
		var notif = notifications[i]
		await get_tree().create_timer(i * 0.8).timeout
		ui_manager.show_notification(notif.message, 3.0, notif.type)
		print("Showed %s notification: %s" % [notif.type, notif.message])
	
	print("✅ Notification test completed")

func test_skill_progression():
	"""Test skill progression and HUD updates"""
	print("\n🧪 Testing skill progression...")
	
	if not SkillManager:
		print("❌ SkillManager not available")
		return
	
	var skills_to_test = ["painting", "sketching", "crafting"]
	
	for skill in skills_to_test:
		var exp_gain = randi_range(50, 100)
		SkillManager.add_skill_experience(skill, exp_gain)
		print("Added %d experience to %s" % [exp_gain, skill])
		await get_tree().create_timer(0.5).timeout
	
	if ui_manager:
		ui_manager.show_notification("Skill progression test completed!", 3.0, "success")
	
	print("✅ Skill progression test completed")