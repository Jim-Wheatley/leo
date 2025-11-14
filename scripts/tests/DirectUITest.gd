extends Control

# Direct UI Test - Load InventoryUI directly without UIManager

@onready var inventory_ui: InventoryUI = $InventoryUI

func _ready():
	print("=== DIRECT UI TEST ===")
	print("Testing InventoryUI loaded directly (not through UIManager)")
	
	if inventory_ui:
		print("✅ InventoryUI loaded successfully")
		inventory_ui.visible = true
		inventory_ui.refresh_inventory()
		print("✅ InventoryUI made visible and refreshed")
		
		# Add some test items
		add_test_items()
	else:
		print("❌ InventoryUI not found!")

func add_test_items():
	"""Add some test items to see in the inventory"""
	if not GameManager.player_data:
		print("⚠️ No GameManager.player_data - creating temporary items display")
		return
	
	# Add a few test items
	var red_paint = InventoryItem.create_paint("Red")
	var blue_paint = InventoryItem.create_paint("Blue")
	var small_canvas = InventoryItem.create_canvas("Small")
	
	GameManager.player_data.add_inventory_item(red_paint)
	GameManager.player_data.add_inventory_item(blue_paint)
	GameManager.player_data.add_inventory_item(small_canvas)
	
	print("✅ Added test items to inventory")
	inventory_ui.refresh_inventory()

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		print("ESC pressed - closing test")
		get_tree().quit()