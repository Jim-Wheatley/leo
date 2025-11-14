extends Node2D

# Test script for Task 10: Artwork Creation System

@onready var player: CharacterBody2D = $Player
@onready var artwork_station: StaticBody2D = $ArtworkStation
@onready var interaction_prompt: Label = $UI/HUD/InteractionPrompt
@onready var inventory_ui: Control = $UI/InventoryUI
@onready var portfolio_ui: Control = $UI/PortfolioUI

var artwork_creation_station: ArtworkCreationStation
var current_interactable: Node = null
var inventory_ui_instance: InventoryUI = null
var portfolio_ui_instance: PortfolioUI = null

func _ready():
	print("=== TASK 10 ARTWORK CREATION TEST ===")
	print("Testing comprehensive artwork creation system")
	print("Press T to add test materials")
	print("Press E near station to create artwork")
	print("Press I to view inventory")
	print("Press P to view portfolio")
	
	setup_artwork_station()
	setup_ui_systems()
	setup_interactions()

func setup_artwork_station():
	"""Set up the artwork creation station"""
	# Create and attach the artwork creation station script
	artwork_creation_station = ArtworkCreationStation.new()
	artwork_station.add_child(artwork_creation_station)
	
	# Connect station signals
	if artwork_creation_station.has_signal("crafting_completed"):
		artwork_creation_station.crafting_completed.connect(_on_artwork_created)
	if artwork_creation_station.has_signal("crafting_failed"):
		artwork_creation_station.crafting_failed.connect(_on_artwork_creation_failed)

func setup_ui_systems():
	"""Set up inventory and portfolio UI systems"""
	# Create inventory UI
	var inventory_scene = preload("res://scenes/ui/InventoryUI.tscn")
	if inventory_scene:
		inventory_ui_instance = inventory_scene.instantiate()
		inventory_ui.add_child(inventory_ui_instance)
		inventory_ui_instance.close_requested.connect(_on_inventory_closed)
	
	# Create portfolio UI
	var portfolio_scene = preload("res://scenes/ui/PortfolioUI.tscn")
	if portfolio_scene:
		portfolio_ui_instance = portfolio_scene.instantiate()
		portfolio_ui.add_child(portfolio_ui_instance)
		portfolio_ui_instance.close_requested.connect(_on_portfolio_closed)

func setup_interactions():
	"""Set up interaction areas"""
	# Add interaction area to artwork station
	var interaction_area = Area2D.new()
	interaction_area.name = "InteractionArea"
	artwork_station.add_child(interaction_area)
	
	var collision_shape = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(120, 120)
	collision_shape.shape = shape
	interaction_area.add_child(collision_shape)
	
	# Connect signals
	interaction_area.body_entered.connect(_on_station_entered)
	interaction_area.body_exited.connect(_on_station_exited)

func _input(event):
	"""Handle input events"""
	if event.is_action_pressed("ui_accept"):  # T key
		add_test_materials()
	elif event.is_action_pressed("interact") and current_interactable:  # E key
		handle_interaction()
	elif event.is_action_pressed("ui_select"):  # I key (inventory)
		toggle_inventory()
	elif event.is_action_pressed("ui_cancel"):  # P key (portfolio)
		toggle_portfolio()

func add_test_materials():
	"""Add comprehensive test materials for artwork creation"""
	print("\n🧪 Adding comprehensive test materials...")
	
	if not GameManager.player_data:
		print("❌ No player data available")
		return
	
	# Clear existing inventory for clean test
	GameManager.player_data.inventory.clear()
	
	# Add various canvases
	var canvas_sizes = ["Small", "Medium", "Large"]
	for size in canvas_sizes:
		var canvas = InventoryItem.create_canvas(size)
		canvas.current_stack = 2
		GameManager.player_data.add_inventory_item(canvas)
	
	# Add various paints
	var paint_colors = ["Red", "Blue", "Yellow", "Green", "Purple", "Orange"]
	for color in paint_colors:
		var paint = InventoryItem.create_paint(color)
		paint.current_stack = 3
		GameManager.player_data.add_inventory_item(paint)
	
	# Add some sketches for inspiration
	add_test_sketches()
	
	# Set player skills to reasonable levels for testing
	SkillManager.set_skill_level("painting", 3)
	SkillManager.set_skill_level("color_theory", 2)
	SkillManager.set_skill_level("crafting", 2)
	
	print("✅ Test materials added!")
	print_inventory_summary()

func add_test_sketches():
	"""Add test sketches to portfolio for inspiration"""
	var sketch_subjects = ["Cathedral", "Market Square", "River Bridge", "Noble Portrait"]
	
	for subject in sketch_subjects:
		var sketch = ArtworkData.create_sketch(subject, {
			"sketching": 3,
			"observation": 2
		})
		# Vary quality for testing
		sketch.quality_score = randf_range(2.0, 6.0)
		GameManager.player_data.add_artwork(sketch)
	
	print("✅ Test sketches added to portfolio!")

func handle_interaction():
	"""Handle interaction with the artwork station"""
	if current_interactable == artwork_station:
		create_artwork_interactive()

func create_artwork_interactive():
	"""Interactive artwork creation with player choices"""
	print("\n🎨 === ARTWORK CREATION STATION ===")
	
	# Check available materials
	var available_canvases = get_available_canvases()
	var available_paints = get_available_paints()
	var available_sketches = get_available_sketches()
	
	if available_canvases.is_empty():
		print("❌ No canvases available! You need a canvas to create artwork.")
		return
	
	if available_paints.is_empty():
		print("❌ No paints available! You need paint to create artwork.")
		return
	
	print("📋 Available Materials:")
	print("  Canvases: %s" % ", ".join(available_canvases))
	print("  Paints: %s" % ", ".join(available_paints))
	
	if available_sketches.is_empty():
		print("  Inspiration: None (artwork quality will be lower)")
	else:
		print("  Inspiration: %s" % ", ".join(available_sketches))
	
	# For testing, create artwork with random materials
	create_test_artwork(available_canvases, available_paints, available_sketches)

func create_test_artwork(canvases: Array, paints: Array, sketches: Array):
	"""Create artwork with available materials for testing"""
	# Select random materials
	var canvas_size = canvases[randi() % canvases.size()]
	var paint_color = paints[randi() % paints.size()]
	var inspiration = ""
	
	if not sketches.is_empty():
		inspiration = sketches[randi() % sketches.size()]
	
	print("\n🎨 Creating artwork with:")
	print("  Canvas: %s" % canvas_size)
	print("  Paint: %s" % paint_color)
	if inspiration != "":
		print("  Inspiration: %s" % inspiration)
	else:
		print("  Inspiration: None")
	
	# Use the artwork creation station
	if artwork_creation_station:
		artwork_creation_station.create_artwork(canvas_size, paint_color, inspiration)

func get_available_canvases() -> Array:
	"""Get list of available canvas sizes"""
	var canvases = []
	if GameManager.player_data:
		for item in GameManager.player_data.inventory:
			if item.item_type == InventoryItem.ItemType.CANVAS:
				var size = item.display_name.replace(" Canvas", "")
				if not canvases.has(size):
					canvases.append(size)
	return canvases

func get_available_paints() -> Array:
	"""Get list of available paint colors"""
	var paints = []
	if GameManager.player_data:
		for item in GameManager.player_data.inventory:
			if item.item_type == InventoryItem.ItemType.PAINT:
				var color = item.display_name.replace(" Paint", "")
				if not paints.has(color):
					paints.append(color)
	return paints

func get_available_sketches() -> Array:
	"""Get list of available sketches for inspiration"""
	var sketches = []
	if GameManager.player_data:
		for artwork in GameManager.player_data.portfolio:
			if artwork.artwork_type == ArtworkData.ArtworkType.SKETCH:
				var subject = artwork.title.replace("Sketch of ", "")
				if not sketches.has(subject):
					sketches.append(subject)
	return sketches

func print_inventory_summary():
	"""Print current inventory contents"""
	print("\n📦 Current Inventory:")
	if not GameManager.player_data or GameManager.player_data.inventory.is_empty():
		print("  (Empty)")
		return
	
	for item in GameManager.player_data.inventory:
		print("  - %s x%d (Quality: %.1f)" % [item.display_name, item.current_stack, item.quality])

func print_portfolio_summary():
	"""Print current portfolio contents"""
	print("\n🎨 Current Portfolio:")
	if not GameManager.player_data or GameManager.player_data.portfolio.is_empty():
		print("  (Empty)")
		return
	
	for artwork in GameManager.player_data.portfolio:
		print("  - %s (%s, Quality: %.1f)" % [
			artwork.title, 
			artwork.get_quality_description(), 
			artwork.quality_score
		])

func toggle_inventory():
	"""Toggle inventory UI visibility"""
	if inventory_ui_instance:
		if inventory_ui.visible:
			inventory_ui.visible = false
		else:
			inventory_ui_instance.refresh_inventory()
			inventory_ui.visible = true

func toggle_portfolio():
	"""Toggle portfolio UI visibility"""
	if portfolio_ui_instance:
		if portfolio_ui.visible:
			portfolio_ui.visible = false
		else:
			portfolio_ui_instance.show_portfolio()
			portfolio_ui.visible = true

func _on_station_entered(body: Node2D):
	"""Called when player enters station interaction area"""
	if body == player:
		current_interactable = artwork_station
		interaction_prompt.text = "Press E to Create Artwork"
		interaction_prompt.visible = true

func _on_station_exited(body: Node2D):
	"""Called when player exits station interaction area"""
	if body == player and current_interactable == artwork_station:
		current_interactable = null
		interaction_prompt.visible = false

func _on_artwork_created(station_type: String, result: String):
	"""Called when artwork creation is completed"""
	print("✅ Artwork creation completed: %s" % result)
	print_portfolio_summary()

func _on_artwork_creation_failed(station_type: String, reason: String):
	"""Called when artwork creation fails"""
	print("❌ Artwork creation failed: %s" % reason)

func _on_inventory_closed():
	"""Called when inventory UI is closed"""
	inventory_ui.visible = false

func _on_portfolio_closed():
	"""Called when portfolio UI is closed"""
	portfolio_ui.visible = false

# Test functions for comprehensive testing
func test_artwork_quality_calculation():
	"""Test artwork quality calculation with different skill levels"""
	print("\n🧪 Testing artwork quality calculation...")
	
	var test_skills = [
		{"painting": 1, "color_theory": 1, "crafting": 1},
		{"painting": 5, "color_theory": 3, "crafting": 2},
		{"painting": 10, "color_theory": 8, "crafting": 6}
	]
	
	for i in range(test_skills.size()):
		var skills = test_skills[i]
		var artwork = ArtworkData.new()
		artwork.calculate_quality_from_skills(skills, ["Red Paint", "Medium Canvas"])
		print("  Skill set %d: Quality %.1f (%s)" % [
			i + 1, 
			artwork.quality_score, 
			artwork.get_quality_description()
		])

func test_material_consumption():
	"""Test that materials are properly consumed during artwork creation"""
	print("\n🧪 Testing material consumption...")
	
	# Record initial inventory
	var initial_canvas_count = count_item_type(InventoryItem.ItemType.CANVAS)
	var initial_paint_count = count_item_type(InventoryItem.ItemType.PAINT)
	
	print("  Before creation - Canvases: %d, Paints: %d" % [initial_canvas_count, initial_paint_count])
	
	# Create artwork
	if artwork_creation_station:
		artwork_creation_station.attempt_auto_create_artwork()
	
	# Check inventory after
	var final_canvas_count = count_item_type(InventoryItem.ItemType.CANVAS)
	var final_paint_count = count_item_type(InventoryItem.ItemType.PAINT)
	
	print("  After creation - Canvases: %d, Paints: %d" % [final_canvas_count, final_paint_count])
	print("  Materials consumed: %s" % (initial_canvas_count > final_canvas_count and initial_paint_count > final_paint_count))

func count_item_type(item_type: InventoryItem.ItemType) -> int:
	"""Count total items of a specific type in inventory"""
	var count = 0
	if GameManager.player_data:
		for item in GameManager.player_data.inventory:
			if item.item_type == item_type:
				count += item.current_stack
	return count