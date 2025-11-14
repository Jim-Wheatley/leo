extends Node2D

# Test script for Task 5: Crafting Systems

@onready var workshop = $Workshop

func _ready():
	print("=== TASK 5 CRAFTING TEST ===")
	print("Testing crafting systems implementation")
	print("Press T to add test materials to inventory")
	print("Interact with workstations to test crafting")

func _input(event):
	if event.is_action_pressed("ui_accept"):  # T key
		add_test_materials()

func add_test_materials():
	"""Add test materials to player inventory for testing"""
	print("\n🧪 Adding test materials to inventory...")
	
	# Add materials for paint creation
	var paint_station = workshop.get_paint_station()
	if paint_station and paint_station.has_method("add_test_materials"):
		paint_station.add_test_materials()
	
	# Add materials for canvas creation
	var canvas_station = workshop.get_canvas_station()
	if canvas_station and canvas_station.has_method("add_test_materials"):
		canvas_station.add_test_materials()
	
	# Add materials for artwork creation
	var artwork_station = workshop.get_artwork_station()
	if artwork_station and artwork_station.has_method("add_test_materials"):
		artwork_station.add_test_materials()
	
	print("✅ Test materials added! Try interacting with the workstations.")
	print_inventory_summary()

func print_inventory_summary():
	"""Print a summary of current inventory"""
	if not GameManager.player_data:
		print("❌ No player data available")
		return
	
	print("\n📦 Current Inventory:")
	if GameManager.player_data.inventory.is_empty():
		print("  (Empty)")
	else:
		for item in GameManager.player_data.inventory:
			print("  - %s x%d (Quality: %.1f)" % [item.display_name, item.current_stack, item.quality])
	
	print("\n🎨 Current Portfolio:")
	if GameManager.player_data.portfolio.is_empty():
		print("  (Empty)")
	else:
		for artwork in GameManager.player_data.portfolio:
			print("  - %s (%s, Quality: %.1f)" % [artwork.title, artwork.get_quality_description(), artwork.quality_score])