class_name InventoryItem extends Resource

# Base class for all inventory items

@export var item_id: String
@export var display_name: String
@export var description: String
@export var item_type: ItemType
@export var quality: float = 1.0
@export var stack_size: int = 1
@export var current_stack: int = 1
@export var icon_path: String = ""

enum ItemType {
	PIGMENT,
	PAINT,
	CANVAS,
	TOOL,
	RAW_MATERIAL,
	ARTWORK,
	MISC
}

func _init(id: String = "", name: String = "", desc: String = "", type: ItemType = ItemType.MISC):
	item_id = id
	display_name = name
	description = desc
	item_type = type

func can_stack_with(other: InventoryItem) -> bool:
	"""Check if this item can stack with another item"""
	return (item_id == other.item_id and 
			quality == other.quality and 
			current_stack < stack_size)

func get_total_value() -> float:
	"""Get the total value of this item stack"""
	return quality * current_stack

func to_dict() -> Dictionary:
	"""Convert item to dictionary for saving"""
	return {
		"item_id": item_id,
		"display_name": display_name,
		"description": description,
		"item_type": item_type,
		"quality": quality,
		"stack_size": stack_size,
		"current_stack": current_stack,
		"icon_path": icon_path
	}

func from_dict(data: Dictionary):
	"""Load item from dictionary"""
	item_id = data.get("item_id", "")
	display_name = data.get("display_name", "")
	description = data.get("description", "")
	item_type = data.get("item_type", ItemType.MISC)
	quality = data.get("quality", 1.0)
	stack_size = data.get("stack_size", 1)
	current_stack = data.get("current_stack", 1)
	icon_path = data.get("icon_path", "")

# Static factory methods for common items
static func create_pigment(color_name: String, quality_val: float = 1.0) -> InventoryItem:
	var item = InventoryItem.new()
	item.item_id = "pigment_" + color_name.to_lower()
	item.display_name = color_name + " Pigment"
	item.description = "Natural pigment with " + color_name.to_lower() + " color"
	item.item_type = ItemType.PIGMENT
	item.quality = quality_val
	item.stack_size = 10
	item.current_stack = 1
	return item

static func create_paint(color_name: String, quality_val: float = 1.0) -> InventoryItem:
	var item = InventoryItem.new()
	item.item_id = "paint_" + color_name.to_lower()
	item.display_name = color_name + " Paint"
	item.description = "Mixed paint ready for use"
	item.item_type = ItemType.PAINT
	item.quality = quality_val
	item.stack_size = 5
	item.current_stack = 1
	return item

static func create_canvas(size: String) -> InventoryItem:
	var item = InventoryItem.new()
	item.item_id = "canvas_" + size.to_lower()
	item.display_name = size + " Canvas"
	item.description = "Prepared canvas ready for painting"
	item.item_type = ItemType.CANVAS
	item.quality = 1.0
	item.stack_size = 3
	item.current_stack = 1
	return item
