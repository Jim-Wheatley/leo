extends Node2D

# Test script for Task 12: Comprehensive UI and HUD System

@onready var ui_manager: UIManager = $UIManager

var test_workstation: WorkstationBase

func _ready():
	print("=== Task 12: UI and HUD System Test ===")
	print("Testing comprehensive UI system with HUD, menus, and notifications")
	
	# Initialize test data
	initialize_test_data()
	
	# Create a test workstation for crafting UI
	create_test_workstation()
	
	print("\nUI System initialized successfully!")
	print("Use the controls shown on screen to test different UI components")

func _input(event):
	"""Handle test input"""
	if event.is_action_pressed("ui_accept"):  # T key
		if Input.is_key_pressed(KEY_1):
			test_skill_progression()
		elif Input.is_key_pressed(KEY_2):
			test_notifications()
		elif Input.is_key_pressed(KEY_3):
			test_inventory_operations()
		elif Input.is_key_pressed(KEY_4):
			test_portfolio_operations()
		elif Input.is_key_pressed(KEY_5):
			test_task_system_integration()
	elif event.is_action_pressed("interact"):  # Space key
		test_crafting_station_ui()

func initialize_test_data():
	"""Initialize test data for UI demonstration"""
	if not GameManager or not GameManager.player_data:
		print("⚠️ GameManager or player data not available")
		return
	
	var player_data = GameManager.player_data
	
	# Add some test inventory items
	var test_items = [
		create_test_item("Red Pigment", InventoryItem.ItemType.PIGMENT, 3),
		create_test_item("Blue Pigment", InventoryItem.ItemType.PIGMENT, 2),
		create_test_item("Canvas Fabric", InventoryItem.ItemType.RAW_MATERIAL, 5),
		create_test_item("Wood Frame", InventoryItem.ItemType.RAW_MATERIAL, 4),
		create_test_item("Red Paint", InventoryItem.ItemType.PAINT, 2),
		create_test_item("Small Canvas", InventoryItem.ItemType.CANVAS, 1)
	]
	
	for item in test_items:
		player_data.add_inventory_item(item)
	
	# Add some test artworks to portfolio
	var test_artworks = [
		create_test_artwork("First Sketch", ArtworkData.ArtworkType.SKETCH, 0.6),
		create_test_artwork("Practice Painting", ArtworkData.ArtworkType.PAINTING, 0.7),
		create_test_artwork("Color Study", ArtworkData.ArtworkType.STUDY, 0.8)
	]
	
	for artwork in test_artworks:
		player_data.add_artwork(artwork)
	
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

func create_test_workstation():
	"""Create a test workstation for crafting UI"""
	# Create a simple test workstation
	test_workstation = WorkstationBase.new()
	test_workstation.station_name = "Test Paint Station"

func test_skill_progression():
	"""Test skill progression and HUD updates"""
	print("\n🧪 Testing skill progression...")
	
	if not SkillManager:
		print("❌ SkillManager not available")
		return
	
	# Add experience to different skills
	var skills_to_test = ["painting", "sketching", "crafting", "gathering"]
	
	for skill in skills_to_test:
		var exp_gain = randi_range(50, 150)
		SkillManager.add_skill_experience(skill, exp_gain)
		print("Added %d experience to %s" % [exp_gain, skill])
	
	# Show notification
	if ui_manager and ui_manager.get_main_hud():
		ui_manager.show_notification("Skill progression test completed!", 3.0, "success")
	
	print("✅ Skill progression test completed")

func test_notifications():
	"""Test the notification system"""
	print("\n🧪 Testing notification system...")
	
	if not ui_manager or not ui_manager.get_main_hud():
		print("❌ UI Manager or HUD not available")
		return
	
	var notifications = [
		{"message": "This is an info notification", "type": "info"},
		{"message": "Success! Something good happened", "type": "success"},
		{"message": "Warning: Pay attention to this", "type": "warning"},
		{"message": "Error: Something went wrong", "type": "error"}
	]
	
	for i in range(notifications.size()):
		var notif = notifications[i]
		# Stagger the notifications
		await get_tree().create_timer(i * 0.5).timeout
		ui_manager.show_notification(notif.message, 4.0, notif.type)
		print("Showed %s notification" % notif.type)
	
	print("✅ Notification system test completed")

func test_inventory_operations():
	"""Test inventory UI operations"""
	print("\n🧪 Testing inventory operations...")
	
	if not ui_manager:
		print("❌ UI Manager not available")
		return
	
	# Open inventory
	ui_manager.open_inventory()
	print("Opened inventory UI")
	
	# Add a new item
	if GameManager and GameManager.player_data:
		var new_item = create_test_item("Test Item", InventoryItem.ItemType.RAW_MATERIAL, 1)
		GameManager.player_data.add_inventory_item(new_item)
		print("Added test item to inventory")
		
		# Refresh UI
		ui_manager.refresh_all_uis()
		print("Refreshed inventory display")
	
	ui_manager.show_notification("Inventory operations test completed!", 3.0, "success")
	print("✅ Inventory operations test completed")

func test_portfolio_operations():
	"""Test portfolio UI operations"""
	print("\n🧪 Testing portfolio operations...")
	
	if not ui_manager:
		print("❌ UI Manager not available")
		return
	
	# Open portfolio
	ui_manager.open_portfolio()
	print("Opened portfolio UI")
	
	# Add a new artwork
	if GameManager and GameManager.player_data:
		var new_artwork = create_test_artwork("Test Masterpiece", ArtworkData.ArtworkType.PAINTING, 0.9)
		GameManager.player_data.add_artwork(new_artwork)
		print("Added test artwork to portfolio")
		
		# Refresh UI
		ui_manager.refresh_all_uis()
		print("Refreshed portfolio display")
	
	ui_manager.show_notification("Portfolio operations test completed!", 3.0, "success")
	print("✅ Portfolio operations test completed")

func test_task_system_integration():
	"""Test task system integration with UI"""
	print("\n🧪 Testing task system integration...")
	
	if not TaskManager:
		print("❌ TaskManager not available")
		return
	
	# Create a test task
	var test_task = TaskData.new()
	test_task.title = "Test UI Integration"
	test_task.description = "This is a test task to verify UI integration"
	test_task.task_type = TaskData.TaskType.SKILL_PRACTICE
	test_task.required_skill_level = 1
	
	# Assign the task
	TaskManager.assign_task(test_task)
	print("Assigned test task")
	
	# The HUD should automatically update to show the new task
	ui_manager.show_notification("Task system integration test completed!", 3.0, "success")
	print("✅ Task system integration test completed")

func test_crafting_station_ui():
	"""Test the crafting station UI"""
	print("\n🧪 Testing crafting station UI...")
	
	if not ui_manager or not test_workstation:
		print("❌ UI Manager or test workstation not available")
		return
	
	# Show crafting station UI
	ui_manager.show_crafting_station(test_workstation)
	print("Opened crafting station UI")
	
	ui_manager.show_notification("Crafting station UI opened!", 3.0, "info")
	print("✅ Crafting station UI test completed")

func _on_ui_opened(ui_name: String):
	"""Handle UI opened events"""
	print("UI opened: %s" % ui_name)

func _on_ui_closed(ui_name: String):
	"""Handle UI closed events"""
	print("UI closed: %s" % ui_name)