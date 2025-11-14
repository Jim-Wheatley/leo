extends Node2D
class_name WorkstationBase

# Base class for all crafting workstations
# Provides common functionality for skill requirements, resource consumption, and UI management

signal crafting_started(station_type: String)
signal crafting_completed(station_type: String, result: InventoryItem)
signal crafting_failed(station_type: String, reason: String)

@export var station_name: String = "Workstation"
@export var required_skill: String = "crafting"
@export var min_skill_level: int = 1

var is_crafting: bool = false
var crafting_ui: Control = null

func _ready():
	print("%s workstation initialized" % station_name)

func can_use_station() -> bool:
	"""Check if player meets requirements to use this station"""
	var player_skill_level = SkillManager.get_skill_level(required_skill)
	return player_skill_level >= min_skill_level

func get_skill_requirement_text() -> String:
	"""Get text describing skill requirements"""
	return "Requires %s level %d" % [required_skill.capitalize(), min_skill_level]

func start_crafting():
	"""Begin the crafting process - override in subclasses"""
	if is_crafting:
		print("Already crafting at this station")
		return
	
	if not can_use_station():
		var requirement_text = get_skill_requirement_text()
		crafting_failed.emit(get_station_type(), "Insufficient skill: " + requirement_text)
		print("❌ Cannot use station: " + requirement_text)
		return
	
	is_crafting = true
	crafting_started.emit(get_station_type())
	print("🔨 Starting crafting at %s..." % station_name)

func complete_crafting(result: InventoryItem):
	"""Complete the crafting process with a result"""
	if not is_crafting:
		return
	
	is_crafting = false
	
	if result:
		# Add to player inventory
		if GameManager.player_data:
			GameManager.player_data.add_inventory_item(result)
		
		# Award skill experience
		award_crafting_experience()
		
		# Notify task system about crafted item
		var item_type = get_item_type_for_task_system(result)
		TaskManager.on_item_crafted(item_type, result.item_id)
		
		# Play success sound and visual effects
		if AudioManager:
			AudioManager.play_crafting_success()
		if VFXManager:
			VFXManager.create_crafting_success_effect(global_position)
		
		crafting_completed.emit(get_station_type(), result)
		print("✅ Crafting completed: %s" % result.display_name)
	else:
		crafting_failed.emit(get_station_type(), "Crafting failed")
		print("❌ Crafting failed")

func get_item_type_for_task_system(item: InventoryItem) -> String:
	"""Get the item type string for task system notifications"""
	match item.item_type:
		InventoryItem.ItemType.PAINT:
			return "paint"
		InventoryItem.ItemType.CANVAS:
			return "canvas"
		InventoryItem.ItemType.PIGMENT:
			return "pigment"
		InventoryItem.ItemType.TOOL:
			return "tool"
		_:
			return "item"

func cancel_crafting():
	"""Cancel the current crafting process"""
	if is_crafting:
		is_crafting = false
		print("🚫 Crafting cancelled")

func award_crafting_experience():
	"""Award experience for successful crafting"""
	var base_exp = 5
	var skill_bonus = SkillManager.get_skill_level(required_skill)
	var total_exp = base_exp + skill_bonus
	
	SkillManager.add_experience(required_skill, total_exp, "Crafting at " + station_name)

func get_station_type() -> String:
	"""Get the station type identifier - override in subclasses"""
	return "base_station"

func show_crafting_ui():
	"""Show the crafting UI - override in subclasses"""
	print("Opening %s interface..." % station_name)

func hide_crafting_ui():
	"""Hide the crafting UI"""
	if crafting_ui and crafting_ui.visible:
		crafting_ui.visible = false

func check_material_requirements(required_materials: Array) -> Dictionary:
	"""Check if player has required materials"""
	var result = {
		"has_materials": true,
		"missing_items": []
	}
	
	if not GameManager.player_data:
		result.has_materials = false
		result.missing_items = required_materials
		return result
	
	for material in required_materials:
		var item_id = material.get("item_id", "")
		var amount = material.get("amount", 1)
		
		if not GameManager.player_data.has_item(item_id, amount):
			result.has_materials = false
			result.missing_items.append(material)
	
	return result

func consume_materials(materials: Array) -> bool:
	"""Consume materials from player inventory"""
	if not GameManager.player_data:
		return false
	
	# Check if we have all materials first
	var check_result = check_material_requirements(materials)
	if not check_result.has_materials:
		return false
	
	# Consume the materials
	for material in materials:
		var item_id = material.get("item_id", "")
		var amount = material.get("amount", 1)
		GameManager.player_data.remove_inventory_item(item_id, amount)
	
	return true

func get_available_recipes() -> Array:
	"""Get list of available recipes for this station - override in subclasses"""
	return []