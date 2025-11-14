extends Control
class_name InventoryUI

# Inventory UI for displaying and managing player items

signal item_selected(item: InventoryItem)
signal item_used(item: InventoryItem)
signal close_requested()

@onready var item_grid: GridContainer = $VBoxContainer/ScrollContainer/ItemGrid
@onready var item_info_panel: Control = $VBoxContainer/ItemInfoPanel
@onready var item_name_label: Label = $VBoxContainer/ItemInfoPanel/VBoxContainer/ItemNameLabel
@onready var item_description_label: Label = $VBoxContainer/ItemInfoPanel/VBoxContainer/ItemDescriptionLabel
@onready var item_details_label: Label = $VBoxContainer/ItemInfoPanel/VBoxContainer/ItemDetailsLabel
@onready var use_button: Button = $VBoxContainer/ItemInfoPanel/VBoxContainer/UseButton


var selected_item: InventoryItem = null
var item_buttons: Array[Button] = []

func _ready():
	if use_button:
		use_button.pressed.connect(_on_use_pressed)
	
	# Hide item info panel initially
	item_info_panel.visible = false
	
	# Set up grid
	item_grid.columns = 6
	
	# Initially hidden
	visible = false

func show_inventory():
	"""Show the inventory UI and refresh items"""
	visible = true
	refresh_inventory()

func hide_inventory():
	"""Hide the inventory UI"""
	visible = false
	clear_selection()

func refresh_inventory():
	"""Refresh the inventory display with current items"""
	clear_item_grid()
	
	if not GameManager.player_data:
		return
	
	# Group items by type for better organization
	var grouped_items = group_items_by_type(GameManager.player_data.inventory)
	
	# Add items to grid
	for item_type in grouped_items:
		for item in grouped_items[item_type]:
			add_item_to_grid(item)

func group_items_by_type(items: Array) -> Dictionary:
	"""Group items by their type for organized display"""
	var groups = {}
	
	for item in items:
		var type_name = InventoryItem.ItemType.keys()[item.item_type]
		if not groups.has(type_name):
			groups[type_name] = []
		groups[type_name].append(item)
	
	return groups

func clear_item_grid():
	"""Clear all items from the grid"""
	for button in item_buttons:
		button.queue_free()
	item_buttons.clear()

func add_item_to_grid(item: InventoryItem):
	"""Add an item button to the grid"""
	var item_button = Button.new()
	item_button.custom_minimum_size = Vector2(80, 80)
	item_button.text = get_item_display_text(item)
	item_button.tooltip_text = item.description
	
	# Style based on item type
	style_item_button(item_button, item)
	
	# Connect signal
	item_button.pressed.connect(_on_item_selected.bind(item))
	
	item_grid.add_child(item_button)
	item_buttons.append(item_button)

func get_item_display_text(item: InventoryItem) -> String:
	"""Get display text for item button"""
	var name = item.display_name
	if name.length() > 10:
		name = name.substr(0, 8) + "..."
	
	if item.current_stack > 1:
		return "%s\nx%d" % [name, item.current_stack]
	else:
		return name

func style_item_button(button: Button, item: InventoryItem):
	"""Apply styling to item button based on type"""
	var style = StyleBoxFlat.new()
	
	# Color based on item type
	match item.item_type:
		InventoryItem.ItemType.PIGMENT:
			style.bg_color = Color(0.8, 0.4, 0.2, 0.8)  # Brown
		InventoryItem.ItemType.PAINT:
			style.bg_color = Color(0.2, 0.6, 0.8, 0.8)  # Blue
		InventoryItem.ItemType.CANVAS:
			style.bg_color = Color(0.9, 0.9, 0.8, 0.8)  # Light
		InventoryItem.ItemType.RAW_MATERIAL:
			style.bg_color = Color(0.6, 0.6, 0.6, 0.8)  # Gray
		InventoryItem.ItemType.TOOL:
			style.bg_color = Color(0.8, 0.8, 0.2, 0.8)  # Yellow
		_:
			style.bg_color = Color(0.5, 0.5, 0.5, 0.8)  # Default gray
	
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	
	button.add_theme_stylebox_override("normal", style)

func _on_item_selected(item: InventoryItem):
	"""Called when an item is selected"""
	selected_item = item
	show_item_info(item)
	item_selected.emit(item)

func show_item_info(item: InventoryItem):
	"""Show detailed information about the selected item"""
	item_info_panel.visible = true
	
	item_name_label.text = item.display_name
	item_description_label.text = item.description
	
	# Build details text
	var details = []
	details.append("Type: %s" % InventoryItem.ItemType.keys()[item.item_type])
	details.append("Quality: %.1f" % item.quality)
	details.append("Stack: %d/%d" % [item.current_stack, item.stack_size])
	
	item_details_label.text = "\n".join(details)
	
	# Show/hide use button based on item type
	use_button.visible = can_use_item(item)

func can_use_item(item: InventoryItem) -> bool:
	"""Check if an item can be used directly"""
	# For now, most items are used in crafting rather than directly
	# Could be expanded for consumable items, tools, etc.
	return false

func clear_selection():
	"""Clear the current item selection"""
	selected_item = null
	item_info_panel.visible = false

func _on_use_pressed():
	"""Called when use button is pressed"""
	if selected_item:
		item_used.emit(selected_item)

func _input(event):
	"""Handle input events - ESC to close"""
	if visible and event.is_action_pressed("ui_cancel"):
		close_requested.emit()
		hide_inventory()
		get_viewport().set_input_as_handled()

func get_item_count(item_id: String) -> int:
	"""Get the total count of a specific item"""
	if not GameManager.player_data:
		return 0
	
	var total = 0
	for item in GameManager.player_data.inventory:
		if item.item_id == item_id:
			total += item.current_stack
	
	return total
