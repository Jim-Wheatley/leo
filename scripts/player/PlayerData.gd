class_name PlayerData extends Resource

# Player data resource for save/load functionality

@export var skills: Dictionary = {
	"painting": 0,
	"sketching": 0,
	"color_theory": 0,
	"crafting": 0,
	"gathering": 0,
	"observation": 0
}

@export var inventory: Array = []
@export var portfolio: Array = []
@export var completed_tasks: Array = []
@export var discovered_locations: Array = []
@export var master_relationship: int = 0

# Player position and scene info
@export var current_scene: String = "workshop"
@export var player_position: Vector2 = Vector2.ZERO

func _init():
	# Initialize with starting values
	skills = {
		"painting": 1,
		"sketching": 1,
		"color_theory": 1,
		"crafting": 1,
		"gathering": 1,
		"observation": 1
	}
	
	# Add starting materials for immediate workshop experience
	add_starting_materials()

func get_skill_level(skill_name: String) -> int:
	"""Get the current level of a specific skill"""
	return skills.get(skill_name, 0)

func increase_skill(skill_name: String, amount: int = 1):
	"""Increase a skill by the specified amount"""
	if skills.has(skill_name):
		skills[skill_name] += amount
		print("Skill increased: %s is now level %d" % [skill_name, skills[skill_name]])

func add_inventory_item(item: InventoryItem):
	"""Add an item to the inventory"""
	if not item:
		return
		
	# Check if item can be stacked with existing items
	for existing_item in inventory:
		if existing_item is InventoryItem and existing_item.item_id == item.item_id and existing_item.can_stack_with(item):
			existing_item.current_stack += item.current_stack
			return
	
	# Add as new item if no stacking occurred
	inventory.append(item)

func remove_inventory_item(item_id: String, amount: int = 1) -> bool:
	"""Remove items from inventory, returns true if successful"""
	for i in range(inventory.size()):
		var item = inventory[i]
		if item.item_id == item_id:
			if item.current_stack >= amount:
				item.current_stack -= amount
				if item.current_stack <= 0:
					inventory.remove_at(i)
				return true
			else:
				return false
	return false

func has_item(item_id: String, amount: int = 1) -> bool:
	"""Check if player has specified amount of an item"""
	var total_count = 0
	for item in inventory:
		if item.item_id == item_id:
			total_count += item.current_stack
	return total_count >= amount

func add_artwork(artwork: ArtworkData):
	"""Add completed artwork to portfolio"""
	if not artwork:
		return
	portfolio.append(artwork)
	print("Artwork added to portfolio: %s" % artwork.title)
	
	# Emit signal for achievement system
	if GameManager:
		var artwork_data = {
			"title": artwork.title,
			"quality_score": artwork.quality_score,
			"artwork_type": artwork.artwork_type
		}
		GameManager.artwork_completed.emit(artwork_data)

func complete_task(task_id: String):
	"""Mark a task as completed"""
	if not completed_tasks.has(task_id):
		completed_tasks.append(task_id)

func is_task_completed(task_id: String) -> bool:
	"""Check if a task has been completed"""
	return completed_tasks.has(task_id)

func discover_location(location_name: String):
	"""Mark a location as discovered"""
	if not discovered_locations.has(location_name):
		discovered_locations.append(location_name)
		print("New location discovered: %s" % location_name)

func to_dict() -> Dictionary:
	"""Convert player data to dictionary for saving"""
	return {
		"skills": skills,
		"inventory": _inventory_to_array(),
		"portfolio": _portfolio_to_array(),
		"completed_tasks": completed_tasks,
		"discovered_locations": discovered_locations,
		"master_relationship": master_relationship,
		"current_scene": current_scene,
		"player_position": {"x": player_position.x, "y": player_position.y}
	}

func from_dict(data: Dictionary):
	"""Load player data from dictionary"""
	skills = data.get("skills", skills)
	completed_tasks = data.get("completed_tasks", [])
	discovered_locations = data.get("discovered_locations", [])
	master_relationship = data.get("master_relationship", 0)
	current_scene = data.get("current_scene", "workshop")
	
	var pos_data = data.get("player_position", {"x": 0, "y": 0})
	player_position = Vector2(pos_data.x, pos_data.y)
	
	# Load inventory and portfolio from save data
	inventory.clear()
	portfolio.clear()
	
	# Load inventory items
	var inventory_data = data.get("inventory", [])
	for item_data in inventory_data:
		var item = InventoryItem.new()
		item.from_dict(item_data)
		inventory.append(item)
	
	# Load portfolio artworks
	var portfolio_data = data.get("portfolio", [])
	for artwork_data in portfolio_data:
		var artwork = ArtworkData.new()
		artwork.from_dict(artwork_data)
		portfolio.append(artwork)
	
	print("✅ Game data loaded - inventory: %d items, portfolio: %d artworks" % [inventory.size(), portfolio.size()])

func _inventory_to_array() -> Array:
	"""Convert inventory to array for saving"""
	var result = []
	for item in inventory:
		result.append(item.to_dict())
	return result

func _portfolio_to_array() -> Array:
	"""Convert portfolio to array for saving"""
	var result = []
	for artwork in portfolio:
		result.append(artwork.to_dict())
	return result

func add_starting_materials():
	"""Add basic materials for immediate workshop experience"""
	# Only add starting materials if inventory is empty (new game)
	if not inventory.is_empty():
		return
	
	# Basic pigments for paint creation (enough for 2-3 paints)
	var red_pigment = InventoryItem.create_pigment("Red")
	red_pigment.current_stack = 2
	add_inventory_item(red_pigment)
	
	var blue_pigment = InventoryItem.create_pigment("Blue")
	blue_pigment.current_stack = 2
	add_inventory_item(blue_pigment)
	
	var yellow_pigment = InventoryItem.create_pigment("Yellow")
	yellow_pigment.current_stack = 1
	add_inventory_item(yellow_pigment)
	
	# Binding agent for paint creation
	var binding_agent = InventoryItem.new("binding_agent", "Binding Agent", "Oil-based binding agent for paint creation", InventoryItem.ItemType.RAW_MATERIAL)
	binding_agent.stack_size = 10
	binding_agent.current_stack = 5
	add_inventory_item(binding_agent)
	
	# Canvas materials (enough for 2 canvases)
	var wood_frame = InventoryItem.new("wood_frame", "Wood Frame", "Wooden frame for canvas construction", InventoryItem.ItemType.RAW_MATERIAL)
	wood_frame.stack_size = 10
	wood_frame.current_stack = 4
	add_inventory_item(wood_frame)
	
	var canvas_fabric = InventoryItem.new("canvas_fabric", "Canvas Fabric", "Prepared fabric for canvas making", InventoryItem.ItemType.RAW_MATERIAL)
	canvas_fabric.stack_size = 10
	canvas_fabric.current_stack = 4
	add_inventory_item(canvas_fabric)
	
	# Pre-made small canvas for immediate use
	var small_canvas = InventoryItem.create_canvas("Small")
	add_inventory_item(small_canvas)
	
	# Pre-made red paint for immediate use
	var red_paint = InventoryItem.create_paint("Red")
	add_inventory_item(red_paint)