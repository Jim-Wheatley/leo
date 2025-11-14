extends WorkstationBase
class_name PaintCreationStation

# Paint Creation Station
# Allows players to mix pigments with binding agents to create paint

var paint_recipes: Array = [
	{
		"result_id": "paint_red",
		"result_name": "Red Paint",
		"materials": [
			{"item_id": "pigment_red", "amount": 1},
			{"item_id": "binding_agent", "amount": 1}
		]
	},
	{
		"result_id": "paint_blue",
		"result_name": "Blue Paint", 
		"materials": [
			{"item_id": "pigment_blue", "amount": 1},
			{"item_id": "binding_agent", "amount": 1}
		]
	},
	{
		"result_id": "paint_yellow",
		"result_name": "Yellow Paint",
		"materials": [
			{"item_id": "pigment_yellow", "amount": 1},
			{"item_id": "binding_agent", "amount": 1}
		]
	},
	{
		"result_id": "paint_green",
		"result_name": "Green Paint",
		"materials": [
			{"item_id": "pigment_green", "amount": 1},
			{"item_id": "binding_agent", "amount": 1}
		]
	}
]

func _ready():
	super._ready()
	station_name = "Paint Creation Station"
	required_skill = "crafting"
	min_skill_level = 1

func get_station_type() -> String:
	return "paint_station"

func get_available_recipes() -> Array:
	"""Get available paint recipes"""
	return paint_recipes

func show_crafting_ui():
	"""Show paint creation interface"""
	print("🎨 Paint Creation Station")
	print("Available paint recipes:")
	
	for i in range(paint_recipes.size()):
		var recipe = paint_recipes[i]
		var materials_text = get_materials_text(recipe.materials)
		var can_craft = check_material_requirements(recipe.materials).has_materials
		var status = "✅" if can_craft else "❌"
		
		print("  %d. %s %s - Requires: %s" % [i + 1, status, recipe.result_name, materials_text])
	
	print("🔧 Auto-crafting first available recipe...")
	
	# Auto-craft for testing - in a full game this would have proper UI selection
	attempt_auto_craft()

func attempt_auto_craft():
	"""Attempt to craft an available recipe (cycles through options)"""
	# Find all craftable recipes
	var craftable_recipes = []
	for recipe in paint_recipes:
		var check_result = check_material_requirements(recipe.materials)
		if check_result.has_materials:
			craftable_recipes.append(recipe)
	
	if craftable_recipes.is_empty():
		print("❌ No materials available for any paint recipes")
		print("💡 You need pigments and binding agents to create paint")
		return
	
	# Use a random craftable recipe for variety
	var recipe = craftable_recipes[randi() % craftable_recipes.size()]
	print("🎯 Crafting: %s" % recipe.result_name)
	craft_paint(recipe)

func craft_paint(recipe: Dictionary):
	"""Craft paint using the specified recipe"""
	start_crafting()
	
	if not is_crafting:
		return
	
	# Check materials again
	var check_result = check_material_requirements(recipe.materials)
	if not check_result.has_materials:
		var missing_text = get_missing_materials_text(check_result.missing_items)
		crafting_failed.emit(get_station_type(), "Missing materials: " + missing_text)
		is_crafting = false
		return
	
	# Consume materials
	if not consume_materials(recipe.materials):
		crafting_failed.emit(get_station_type(), "Failed to consume materials")
		is_crafting = false
		return
	
	# Create the paint
	var paint_item = create_paint_item(recipe)
	complete_crafting(paint_item)

func create_paint_item(recipe: Dictionary) -> InventoryItem:
	"""Create a paint item from recipe"""
	var color_name = recipe.result_name.replace(" Paint", "")
	var paint = InventoryItem.create_paint(color_name)
	
	# Quality based on crafting skill
	var crafting_level = SkillManager.get_skill_level("crafting")
	paint.quality = 0.5 + (crafting_level * 0.1)  # Quality improves with skill
	
	return paint

func get_materials_text(materials: Array) -> String:
	"""Get formatted text for materials list"""
	var text_parts = []
	for material in materials:
		var name = get_material_display_name(material.item_id)
		text_parts.append("%s x%d" % [name, material.amount])
	return ", ".join(text_parts)

func get_missing_materials_text(missing_materials: Array) -> String:
	"""Get formatted text for missing materials"""
	return get_materials_text(missing_materials)

func get_material_display_name(item_id: String) -> String:
	"""Get display name for material item ID"""
	match item_id:
		"pigment_red":
			return "Red Pigment"
		"pigment_blue":
			return "Blue Pigment"
		"pigment_yellow":
			return "Yellow Pigment"
		"pigment_green":
			return "Green Pigment"
		"binding_agent":
			return "Binding Agent"
		_:
			return item_id.capitalize().replace("_", " ")

# Test function to add some starting materials
func add_test_materials():
	"""Add some test materials to player inventory"""
	if GameManager.player_data:
		var red_pigment = InventoryItem.create_pigment("Red")
		var blue_pigment = InventoryItem.create_pigment("Blue")
		var green_pigment = InventoryItem.create_pigment("Green")
		var binding_agent = InventoryItem.new("binding_agent", "Binding Agent", "Oil-based binding agent for paint", InventoryItem.ItemType.RAW_MATERIAL)
		binding_agent.stack_size = 10
		binding_agent.current_stack = 5
		
		GameManager.player_data.add_inventory_item(red_pigment)
		GameManager.player_data.add_inventory_item(blue_pigment)
		GameManager.player_data.add_inventory_item(green_pigment)
		GameManager.player_data.add_inventory_item(binding_agent)
		
		print("✅ Added test materials to inventory")