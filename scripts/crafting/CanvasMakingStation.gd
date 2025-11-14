extends WorkstationBase
class_name CanvasMakingStation

# Canvas Making Station
# Allows players to create canvases of different sizes using wood and fabric

var canvas_recipes: Array = [
	{
		"result_id": "canvas_small",
		"result_name": "Small Canvas",
		"size": "Small",
		"materials": [
			{"item_id": "wood_frame", "amount": 1},
			{"item_id": "canvas_fabric", "amount": 1}
		]
	},
	{
		"result_id": "canvas_medium",
		"result_name": "Medium Canvas",
		"size": "Medium",
		"materials": [
			{"item_id": "wood_frame", "amount": 2},
			{"item_id": "canvas_fabric", "amount": 2}
		]
	},
	{
		"result_id": "canvas_large",
		"result_name": "Large Canvas",
		"size": "Large",
		"materials": [
			{"item_id": "wood_frame", "amount": 3},
			{"item_id": "canvas_fabric", "amount": 3}
		]
	}
]

func _ready():
	super._ready()
	station_name = "Canvas Making Station"
	required_skill = "crafting"
	min_skill_level = 1

func get_station_type() -> String:
	return "canvas_station"

func get_available_recipes() -> Array:
	return canvas_recipes

func show_crafting_ui():
	"""Show canvas creation interface"""
	print("🖼️ Canvas Making Station")
	print("Available canvas sizes:")
	
	for i in range(canvas_recipes.size()):
		var recipe = canvas_recipes[i]
		var materials_text = get_materials_text(recipe.materials)
		var can_craft = check_material_requirements(recipe.materials).has_materials
		var status = "✅" if can_craft else "❌"
		
		print("  %d. %s %s - Requires: %s" % [i + 1, status, recipe.result_name, materials_text])
	
	print("🔧 Auto-crafting first available canvas...")
	
	# Auto-craft for testing - in a full game this would have proper UI selection
	attempt_auto_craft()

func attempt_auto_craft():
	"""Attempt to craft an available canvas (cycles through options)"""
	# Find all craftable recipes
	var craftable_recipes = []
	for recipe in canvas_recipes:
		var check_result = check_material_requirements(recipe.materials)
		if check_result.has_materials:
			craftable_recipes.append(recipe)
	
	if craftable_recipes.is_empty():
		print("❌ No materials available for any canvas sizes")
		print("💡 You need wood frames and canvas fabric to create canvases")
		return
	
	# Use a random craftable recipe for variety
	var recipe = craftable_recipes[randi() % craftable_recipes.size()]
	print("🎯 Crafting: %s" % recipe.result_name)
	craft_canvas(recipe)

func craft_canvas(recipe: Dictionary):
	"""Craft canvas using the specified recipe"""
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
	
	# Create the canvas
	var canvas_item = create_canvas_item(recipe)
	complete_crafting(canvas_item)

func create_canvas_item(recipe: Dictionary) -> InventoryItem:
	"""Create a canvas item from recipe"""
	var canvas = InventoryItem.create_canvas(recipe.size)
	
	# Quality based on crafting skill
	var crafting_level = SkillManager.get_skill_level("crafting")
	canvas.quality = 0.7 + (crafting_level * 0.05)  # Quality improves with skill
	
	return canvas

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
		"wood_frame":
			return "Wood Frame"
		"canvas_fabric":
			return "Canvas Fabric"
		_:
			return item_id.capitalize().replace("_", " ")

# Test function to add some starting materials
func add_test_materials():
	"""Add some test materials to player inventory"""
	if GameManager.player_data:
		var wood_frame = InventoryItem.new("wood_frame", "Wood Frame", "Wooden frame for canvas", InventoryItem.ItemType.RAW_MATERIAL)
		wood_frame.stack_size = 10
		wood_frame.current_stack = 5
		
		var canvas_fabric = InventoryItem.new("canvas_fabric", "Canvas Fabric", "Prepared fabric for canvas", InventoryItem.ItemType.RAW_MATERIAL)
		canvas_fabric.stack_size = 10
		canvas_fabric.current_stack = 5
		
		GameManager.player_data.add_inventory_item(wood_frame)
		GameManager.player_data.add_inventory_item(canvas_fabric)
		
		print("✅ Added test materials to inventory")