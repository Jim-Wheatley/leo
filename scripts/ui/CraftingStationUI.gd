extends Control
class_name CraftingStationUI

# Enhanced crafting station UI with visual feedback and progress indicators

signal close_requested
signal crafting_started(recipe_name: String)
signal crafting_completed(result_item: InventoryItem)

@onready var station_title: Label = $MainPanel/VBoxContainer/Header/StationTitle
@onready var close_btn: Button = $MainPanel/VBoxContainer/Header/CloseBtn
@onready var materials_container: VBoxContainer = $MainPanel/VBoxContainer/ContentContainer/LeftPanel/MaterialsList/MaterialsContainer
@onready var recipes_container: VBoxContainer = $MainPanel/VBoxContainer/ContentContainer/RightPanel/RecipesList/RecipesContainer
@onready var progress_bar: ProgressBar = $MainPanel/VBoxContainer/ContentContainer/CenterPanel/CraftingArea/CraftingContainer/ProgressBar
@onready var status_label: Label = $MainPanel/VBoxContainer/ContentContainer/CenterPanel/CraftingArea/CraftingContainer/StatusLabel
@onready var craft_btn: Button = $MainPanel/VBoxContainer/ContentContainer/CenterPanel/CraftingArea/CraftingContainer/CraftBtn
@onready var skill_info: Label = $MainPanel/VBoxContainer/BottomPanel/SkillInfo
@onready var result_preview: Label = $MainPanel/VBoxContainer/BottomPanel/ResultPreview

var current_station: WorkstationBase = null
var selected_recipe: Dictionary = {}
var available_recipes: Array[Dictionary] = []
var crafting_in_progress: bool = false
var crafting_tween: Tween

func _ready():
	close_btn.pressed.connect(_on_close_pressed)
	craft_btn.pressed.connect(_on_craft_pressed)
	hide()

func show_crafting_station(station: WorkstationBase):
	"""Show the crafting UI for a specific station"""
	current_station = station
	station_title.text = station.station_name if station else "Crafting Station"
	
	load_available_recipes()
	update_materials_display()
	update_skill_display()
	
	show()

func hide_crafting_station():
	"""Hide the crafting station UI"""
	current_station = null
	selected_recipe.clear()
	hide()

func load_available_recipes():
	"""Load available recipes for the current station"""
	# Clear existing recipes
	for child in recipes_container.get_children():
		child.queue_free()
	
	available_recipes.clear()
	
	if not current_station:
		return
	
	# Get recipes from the station (this would be implemented in WorkstationBase)
	var recipes = get_station_recipes()
	
	for recipe in recipes:
		available_recipes.append(recipe)
		var recipe_button = create_recipe_button(recipe)
		recipes_container.add_child(recipe_button)

func get_station_recipes() -> Array[Dictionary]:
	"""Get recipes available for the current station type"""
	if not current_station:
		return []
	
	# This would ideally come from a data file or the station itself
	var station_type = current_station.get_script().get_global_name()
	
	match station_type:
		"PaintCreationStation":
			return [
				{
					"name": "Red Paint",
					"materials": {"Red Pigment": 1, "Oil": 1},
					"result": "Red Paint",
					"skill_required": 1,
					"crafting_time": 2.0
				},
				{
					"name": "Blue Paint",
					"materials": {"Blue Pigment": 1, "Oil": 1},
					"result": "Blue Paint",
					"skill_required": 1,
					"crafting_time": 2.0
				},
				{
					"name": "Yellow Paint",
					"materials": {"Yellow Pigment": 1, "Oil": 1},
					"result": "Yellow Paint",
					"skill_required": 1,
					"crafting_time": 2.0
				}
			]
		"CanvasMakingStation":
			return [
				{
					"name": "Small Canvas",
					"materials": {"Wood Frame": 1, "Canvas Fabric": 1},
					"result": "Small Canvas",
					"skill_required": 1,
					"crafting_time": 3.0
				},
				{
					"name": "Medium Canvas",
					"materials": {"Wood Frame": 2, "Canvas Fabric": 2},
					"result": "Medium Canvas",
					"skill_required": 3,
					"crafting_time": 4.0
				}
			]
		"ArtworkCreationStation":
			return [
				{
					"name": "Simple Painting",
					"materials": {"Paint": 2, "Small Canvas": 1},
					"result": "Simple Painting",
					"skill_required": 2,
					"crafting_time": 5.0
				}
			]
		_:
			return []

func create_recipe_button(recipe: Dictionary) -> Control:
	"""Create a button for a recipe"""
	var button = Button.new()
	button.text = recipe.name
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size.y = 40
	
	# Check if recipe can be crafted
	var can_craft = can_craft_recipe(recipe)
	button.disabled = not can_craft
	
	if not can_craft:
		button.modulate = Color(0.7, 0.7, 0.7)
		button.tooltip_text = get_recipe_requirements_text(recipe)
	
	button.pressed.connect(func(): select_recipe(recipe))
	
	return button

func can_craft_recipe(recipe: Dictionary) -> bool:
	"""Check if a recipe can be crafted"""
	if not GameManager or not GameManager.player_data:
		return false
	
	# Check skill requirement
	var required_skill = recipe.get("skill_required", 1)
	var current_skill = SkillManager.get_skill_level("crafting") if SkillManager else 1
	
	if current_skill < required_skill:
		return false
	
	# Check materials
	var player_inventory = GameManager.player_data.inventory
	var materials = recipe.get("materials", {})
	
	for material_name in materials.keys():
		var required_amount = materials[material_name]
		var available_amount = get_material_count(player_inventory, material_name)
		
		if available_amount < required_amount:
			return false
	
	return true

func get_material_count(inventory: Array, material_name: String) -> int:
	"""Get the count of a specific material in inventory"""
	var count = 0
	for item in inventory:
		if item.display_name == material_name:
			count += item.current_stack
	return count

func get_recipe_requirements_text(recipe: Dictionary) -> String:
	"""Get text describing recipe requirements"""
	var text = "Requirements:\n"
	
	var required_skill = recipe.get("skill_required", 1)
	var current_skill = SkillManager.get_skill_level("crafting") if SkillManager else 1
	
	text += "Crafting Level: %d (Current: %d)\n" % [required_skill, current_skill]
	
	var materials = recipe.get("materials", {})
	text += "Materials:\n"
	
	for material_name in materials.keys():
		var required = materials[material_name]
		var available = 0
		if GameManager and GameManager.player_data:
			available = get_material_count(GameManager.player_data.inventory, material_name)
		text += "• %s: %d/%d\n" % [material_name, available, required]
	
	return text

func select_recipe(recipe: Dictionary):
	"""Select a recipe for crafting"""
	selected_recipe = recipe
	update_materials_display()
	update_result_preview()
	
	craft_btn.disabled = not can_craft_recipe(recipe)
	status_label.text = "Recipe selected: %s" % recipe.name

func update_materials_display():
	"""Update the materials display"""
	# Clear existing materials
	for child in materials_container.get_children():
		child.queue_free()
	
	if selected_recipe.is_empty():
		var no_recipe_label = Label.new()
		no_recipe_label.text = "Select a recipe to see required materials"
		no_recipe_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		materials_container.add_child(no_recipe_label)
		return
	
	var materials = selected_recipe.get("materials", {})
	
	for material_name in materials.keys():
		var required_amount = materials[material_name]
		var material_panel = create_material_panel(material_name, required_amount)
		materials_container.add_child(material_panel)

func create_material_panel(material_name: String, required_amount: int) -> Control:
	"""Create a panel showing material requirements"""
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(0, 50)
	
	var hbox = HBoxContainer.new()
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hbox.offset_left = 10
	hbox.offset_top = 5
	hbox.offset_right = -10
	hbox.offset_bottom = -5
	panel.add_child(hbox)
	
	var name_label = Label.new()
	name_label.text = material_name
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(name_label)
	
	var available_amount = 0
	if GameManager and GameManager.player_data:
		available_amount = get_material_count(GameManager.player_data.inventory, material_name)
	
	var count_label = Label.new()
	count_label.text = "%d/%d" % [available_amount, required_amount]
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	
	# Color based on availability
	if available_amount >= required_amount:
		count_label.modulate = Color.GREEN
	else:
		count_label.modulate = Color.RED
	
	hbox.add_child(count_label)
	
	return panel

func update_skill_display():
	"""Update the skill information display"""
	if not SkillManager:
		skill_info.text = "Crafting Level: 1"
		return
	
	var crafting_level = SkillManager.get_skill_level("crafting")
	var crafting_exp = SkillManager.get_skill_experience("crafting")
	
	skill_info.text = "Crafting Level: %d (%d XP)" % [crafting_level, crafting_exp]

func update_result_preview():
	"""Update the result preview display"""
	if selected_recipe.is_empty():
		result_preview.text = "No recipe selected"
		return
	
	var quality = calculate_expected_quality()
	var quality_text = get_quality_text(quality)
	
	result_preview.text = "Expected Quality: %s" % quality_text

func calculate_expected_quality() -> float:
	"""Calculate expected quality based on skill level"""
	if not SkillManager or selected_recipe.is_empty():
		return 0.5
	
	var crafting_level = SkillManager.get_skill_level("crafting")
	var required_level = selected_recipe.get("skill_required", 1)
	
	# Base quality increases with skill level above requirement
	var base_quality = 0.5 + (crafting_level - required_level) * 0.1
	return clamp(base_quality, 0.1, 1.0)

func get_quality_text(quality: float) -> String:
	"""Convert quality value to text"""
	if quality >= 0.9:
		return "Masterwork"
	elif quality >= 0.7:
		return "Excellent"
	elif quality >= 0.5:
		return "Good"
	elif quality >= 0.3:
		return "Fair"
	else:
		return "Poor"

func _on_craft_pressed():
	"""Handle craft button press"""
	if selected_recipe.is_empty() or crafting_in_progress:
		return
	
	if not can_craft_recipe(selected_recipe):
		status_label.text = "Cannot craft: Missing requirements"
		return
	
	start_crafting()

func start_crafting():
	"""Start the crafting process"""
	crafting_in_progress = true
	craft_btn.disabled = true
	
	var crafting_time = selected_recipe.get("crafting_time", 3.0)
	status_label.text = "Crafting in progress..."
	
	# Animate progress bar
	progress_bar.value = 0.0
	crafting_tween = create_tween()
	crafting_tween.tween_property(progress_bar, "value", 1.0, crafting_time)
	crafting_tween.tween_callback(complete_crafting)
	
	crafting_started.emit(selected_recipe.name)

func complete_crafting():
	"""Complete the crafting process"""
	crafting_in_progress = false
	craft_btn.disabled = false
	progress_bar.value = 0.0
	
	# Consume materials
	consume_materials()
	
	# Create result item
	var result_item = create_result_item()
	
	# Add to inventory
	if GameManager and GameManager.player_data and result_item:
		GameManager.player_data.add_inventory_item(result_item)
	
	# Give experience
	if SkillManager:
		var exp_gain = selected_recipe.get("skill_required", 1) * 10
		SkillManager.add_skill_experience("crafting", exp_gain)
	
	status_label.text = "Crafting completed: %s" % selected_recipe.name
	
	# Update displays
	update_materials_display()
	update_skill_display()
	
	crafting_completed.emit(result_item)

func consume_materials():
	"""Consume materials from inventory"""
	if not GameManager or not GameManager.player_data:
		return
	
	var materials = selected_recipe.get("materials", {})
	var inventory = GameManager.player_data.inventory
	
	for material_name in materials.keys():
		var required_amount = materials[material_name]
		var consumed = 0
		
		# Find and consume materials
		for i in range(inventory.size() - 1, -1, -1):
			if consumed >= required_amount:
				break
			
			var item = inventory[i]
			if item.display_name == material_name:
				var to_consume = min(item.current_stack, required_amount - consumed)
				item.current_stack -= to_consume
				consumed += to_consume
				
				if item.current_stack <= 0:
					inventory.remove_at(i)

func create_result_item() -> InventoryItem:
	"""Create the result item from crafting"""
	var result_name = selected_recipe.get("result", "Unknown Item")
	var quality = calculate_expected_quality()
	
	# This would ideally use a proper item creation system
	var item = InventoryItem.new()
	item.display_name = result_name
	item.quality = quality
	item.current_stack = 1
	
	# Set item type based on result
	if result_name.ends_with("Paint"):
		item.item_type = InventoryItem.ItemType.PAINT
	elif result_name.ends_with("Canvas"):
		item.item_type = InventoryItem.ItemType.CANVAS
	elif result_name.ends_with("Painting"):
		item.item_type = InventoryItem.ItemType.ARTWORK
	else:
		item.item_type = InventoryItem.ItemType.RAW_MATERIAL
	
	return item

func _on_close_pressed():
	"""Handle close button press"""
	hide_crafting_station()
	close_requested.emit()