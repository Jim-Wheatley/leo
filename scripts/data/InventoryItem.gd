class_name InventoryItem extends RefCounted

# Inventory item class for the game's item system

enum ItemType {
	PIGMENT,
	PAINT,
	CANVAS,
	TOOL,
	RAW_MATERIAL,
	ARTWORK
}

var item_id: String
var display_name: String
var description: String
var item_type: ItemType
var quality: float = 1.0
var stack_size: int = 1
var current_stack: int = 1

func _init(id: String = "", name: String = "", desc: String = "", type: ItemType = ItemType.RAW_MATERIAL):
	item_id = id
	display_name = name
	description = desc
	item_type = type
	current_stack = 1
	
	# Set default stack sizes based on type
	match item_type:
		ItemType.PIGMENT, ItemType.RAW_MATERIAL:
			stack_size = 10
		ItemType.PAINT:
			stack_size = 5
		ItemType.CANVAS, ItemType.TOOL, ItemType.ARTWORK:
			stack_size = 1

func can_stack_with(other: InventoryItem) -> bool:
	"""Check if this item can stack with another item"""
	if not other:
		return false
	
	return (item_id == other.item_id and 
			current_stack < stack_size and 
			other.current_stack < other.stack_size)

func to_dict() -> Dictionary:
	"""Convert item to dictionary for saving"""
	return {
		"item_id": item_id,
		"display_name": display_name,
		"description": description,
		"item_type": item_type,
		"quality": quality,
		"stack_size": stack_size,
		"current_stack": current_stack
	}

func from_dict(data: Dictionary):
	"""Load item from dictionary"""
	item_id = data.get("item_id", "")
	display_name = data.get("display_name", "")
	description = data.get("description", "")
	item_type = data.get("item_type", ItemType.RAW_MATERIAL)
	quality = data.get("quality", 1.0)
	stack_size = data.get("stack_size", 1)
	current_stack = data.get("current_stack", 1)

# Static factory methods for common items
static func create_pigment(color: String) -> InventoryItem:
	"""Create a pigment item"""
	var item = InventoryItem.new()
	item.item_id = "pigment_" + color.to_lower()
	item.display_name = color.capitalize() + " Pigment"
	item.description = "Natural " + color.to_lower() + " pigment for paint creation"
	item.item_type = ItemType.PIGMENT
	item.stack_size = 10
	item.current_stack = 1
	return item

static func create_paint(color: String) -> InventoryItem:
	"""Create a paint item"""
	var item = InventoryItem.new()
	item.item_id = "paint_" + color.to_lower()
	item.display_name = color.capitalize() + " Paint"
	item.description = "Ready-to-use " + color.to_lower() + " paint"
	item.item_type = ItemType.PAINT
	item.stack_size = 5
	item.current_stack = 1
	return item

static func create_canvas(size: String) -> InventoryItem:
	"""Create a canvas item"""
	var item = InventoryItem.new()
	item.item_id = "canvas_" + size.to_lower()
	item.display_name = size.capitalize() + " Canvas"
	item.description = "A " + size.to_lower() + " canvas ready for painting"
	item.item_type = ItemType.CANVAS
	item.stack_size = 1
	item.current_stack = 1
	return item