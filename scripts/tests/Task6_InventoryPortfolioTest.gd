extends Node2D

# Test script for Task 6: Inventory and Portfolio Management Systems

@onready var workshop = $Workshop
@onready var ui_manager = $Workshop/UI/UIManager

func _ready():
	print("=== TASK 6 INVENTORY & PORTFOLIO TEST ===")
	print("Testing inventory and portfolio UI systems")
	print("Controls:")
	print("  I - Open/Close Inventory")
	print("  P - Open/Close Portfolio") 
	print("  T - Add test materials")
	print("  R - Create test artwork")
	print("  ESC - Close current UI")

func _input(event):
	if event.is_action_pressed("ui_accept"):  # T key
		add_test_materials()
	elif event.is_action_pressed("ui_select"):  # R key (we'll map this)
		create_test_artwork()

func add_test_materials():
	"""Add comprehensive test materials to inventory"""
	print("\n🧪 Adding comprehensive test materials...")
	
	if not GameManager.player_data:
		print("❌ No player data available")
		return
	
	# Add various pigments
	var pigments = ["Red", "Blue", "Yellow", "Green"]
	for color in pigments:
		var pigment = InventoryItem.create_pigment(color)
		pigment.current_stack = 3
		GameManager.player_data.add_inventory_item(pigment)
	
	# Add binding agents
	var binding_agent = InventoryItem.new("binding_agent", "Binding Agent", "Oil-based binding agent for paint", InventoryItem.ItemType.RAW_MATERIAL)
	binding_agent.stack_size = 10
	binding_agent.current_stack = 8
	GameManager.player_data.add_inventory_item(binding_agent)
	
	# Add canvas materials
	var wood_frame = InventoryItem.new("wood_frame", "Wood Frame", "Wooden frame for canvas", InventoryItem.ItemType.RAW_MATERIAL)
	wood_frame.stack_size = 10
	wood_frame.current_stack = 6
	GameManager.player_data.add_inventory_item(wood_frame)
	
	var canvas_fabric = InventoryItem.new("canvas_fabric", "Canvas Fabric", "Prepared fabric for canvas", InventoryItem.ItemType.RAW_MATERIAL)
	canvas_fabric.stack_size = 10
	canvas_fabric.current_stack = 6
	GameManager.player_data.add_inventory_item(canvas_fabric)
	
	# Add some pre-made items
	var red_paint = InventoryItem.create_paint("Red")
	red_paint.quality = 0.8
	GameManager.player_data.add_inventory_item(red_paint)
	
	var small_canvas = InventoryItem.create_canvas("Small")
	small_canvas.quality = 0.9
	GameManager.player_data.add_inventory_item(small_canvas)
	
	# Add some tools
	var brush = InventoryItem.new("brush_fine", "Fine Brush", "A high-quality brush for detailed work", InventoryItem.ItemType.TOOL)
	brush.quality = 1.2
	GameManager.player_data.add_inventory_item(brush)
	
	print("✅ Test materials added!")
	print_inventory_summary()

func create_test_artwork():
	"""Create some test artworks for the portfolio"""
	print("\n🎨 Creating test artworks...")
	
	if not GameManager.player_data:
		print("❌ No player data available")
		return
	
	# Create a sketch
	var sketch = ArtworkData.create_sketch("Market Square", {
		"sketching": SkillManager.get_skill_level("sketching"),
		"observation": SkillManager.get_skill_level("observation")
	})
	GameManager.player_data.add_artwork(sketch)
	
	# Create a painting
	var painting = ArtworkData.create_painting("Sunset Over Florence", {
		"painting": SkillManager.get_skill_level("painting"),
		"color_theory": SkillManager.get_skill_level("color_theory")
	}, ["Red Paint", "Yellow Paint", "Medium Canvas"])
	GameManager.player_data.add_artwork(painting)
	
	# Create a study
	var study = ArtworkData.new()
	study.title = "Light Study - Morning Window"
	study.artwork_type = ArtworkData.ArtworkType.STUDY
	study.skill_level_at_creation = {
		"observation": SkillManager.get_skill_level("observation"),
		"sketching": SkillManager.get_skill_level("sketching")
	}
	study.materials_used = ["Charcoal", "Paper"]
	study.calculate_quality_from_skills(study.skill_level_at_creation, study.materials_used)
	GameManager.player_data.add_artwork(study)
	
	# Create a high-quality masterwork (simulate advanced skills)
	var masterwork = ArtworkData.new()
	masterwork.title = "Portrait of the Master Artist"
	masterwork.artwork_type = ArtworkData.ArtworkType.MASTERWORK
	masterwork.skill_level_at_creation = {
		"painting": 8,
		"color_theory": 7,
		"observation": 6
	}
	masterwork.materials_used = ["Fine Brushes", "Premium Paints", "Large Canvas"]
	masterwork.quality_score = 8.5
	masterwork.inspiration_source = "Master Artist"
	GameManager.player_data.add_artwork(masterwork)
	
	print("✅ Test artworks created!")
	print_portfolio_summary()

func print_inventory_summary():
	"""Print a summary of current inventory"""
	if not GameManager.player_data:
		return
	
	print("\n📦 Current Inventory Summary:")
	if GameManager.player_data.inventory.is_empty():
		print("  (Empty)")
		return
	
	# Group by type
	var by_type = {}
	for item in GameManager.player_data.inventory:
		var type_name = InventoryItem.ItemType.keys()[item.item_type]
		if not by_type.has(type_name):
			by_type[type_name] = []
		by_type[type_name].append(item)
	
	for type_name in by_type:
		print("  %s:" % type_name)
		for item in by_type[type_name]:
			print("    - %s x%d (Quality: %.1f)" % [item.display_name, item.current_stack, item.quality])

func print_portfolio_summary():
	"""Print a summary of current portfolio"""
	if not GameManager.player_data:
		return
	
	print("\n🎨 Current Portfolio Summary:")
	if GameManager.player_data.portfolio.is_empty():
		print("  (Empty)")
		return
	
	# Group by type
	var by_type = {}
	for artwork in GameManager.player_data.portfolio:
		var type_name = ArtworkData.ArtworkType.keys()[artwork.artwork_type]
		if not by_type.has(type_name):
			by_type[type_name] = []
		by_type[type_name].append(artwork)
	
	for type_name in by_type:
		print("  %s:" % type_name)
		for artwork in by_type[type_name]:
			print("    - %s (%s, Quality: %.1f)" % [artwork.title, artwork.get_quality_description(), artwork.quality_score])

func _on_ui_opened(ui_name: String):
	"""Called when a UI is opened"""
	print("📱 %s UI opened" % ui_name.capitalize())

func _on_ui_closed(ui_name: String):
	"""Called when a UI is closed"""
	print("📱 %s UI closed" % ui_name.capitalize())