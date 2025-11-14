extends Node
class_name UIManager

# Comprehensive UI Manager for handling all UI systems

signal ui_opened(ui_name: String)
signal ui_closed(ui_name: String)

# UI Components
var main_hud: MainHUD
var inventory_ui: InventoryUI
var portfolio_ui: PortfolioUI
var skill_tree_ui: SkillTreeUI
var pause_menu: PauseMenu
var crafting_station_ui: CraftingStationUI
var tutorial_ui: Control
var achievement_notification: Control
var achievement_list_ui: Control

var current_open_ui: Control = null
var ui_container: Node  # Can be Control or Window (root)

func _ready():
	# Add to group for easy finding
	add_to_group("ui_manager")
	
	# Make sure we're in the tree before proceeding
	if not is_inside_tree():
		await tree_entered
	
	# Wait for the scene tree to be fully ready
	if get_tree():
		await get_tree().process_frame
	
	# Set up UI container
	setup_ui_container()
	# Load UI scenes
	setup_ui_scenes()
	
	# Wait another frame to ensure everything is in the tree
	if get_tree():
		await get_tree().process_frame

func setup_ui_container():
	"""Set up the main UI container"""
	# Create a CanvasLayer for UI elements
	var canvas_layer = CanvasLayer.new()
	canvas_layer.name = "UIManagerLayer"
	canvas_layer.layer = 100  # High layer to be on top
	get_tree().root.add_child(canvas_layer)
	
	# Create a Control container inside the CanvasLayer
	var control_container = Control.new()
	control_container.name = "UIContainer"
	control_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	control_container.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Don't block input by default
	canvas_layer.add_child(control_container)
	
	ui_container = control_container

func setup_ui_scenes():
	"""Set up all UI scenes"""
	if not ui_container:
		return
	
	# Load Main HUD (optional - may not exist in test scenes)
	if ResourceLoader.exists("res://scenes/ui/MainHUD.tscn"):
		var hud_scene = load("res://scenes/ui/MainHUD.tscn")
		if hud_scene:
			main_hud = hud_scene.instantiate()
			ui_container.add_child(main_hud)
	
	# Load inventory UI (optional)
	if ResourceLoader.exists("res://scenes/ui/InventoryUI.tscn"):
		var inventory_scene = load("res://scenes/ui/InventoryUI.tscn")
		if inventory_scene:
			inventory_ui = inventory_scene.instantiate()
			ui_container.add_child(inventory_ui)
	
	# Load portfolio UI (optional)
	if ResourceLoader.exists("res://scenes/ui/PortfolioUI.tscn"):
		var portfolio_scene = load("res://scenes/ui/PortfolioUI.tscn")
		if portfolio_scene:
			portfolio_ui = portfolio_scene.instantiate()
			ui_container.add_child(portfolio_ui)
	
	# Load skill tree UI (optional)
	if ResourceLoader.exists("res://scenes/ui/SkillTreeUI.tscn"):
		var skill_tree_scene = load("res://scenes/ui/SkillTreeUI.tscn")
		if skill_tree_scene:
			skill_tree_ui = skill_tree_scene.instantiate()
			ui_container.add_child(skill_tree_ui)
	
	# Load pause menu (optional)
	if ResourceLoader.exists("res://scenes/ui/PauseMenu.tscn"):
		var pause_menu_scene = load("res://scenes/ui/PauseMenu.tscn")
		if pause_menu_scene:
			pause_menu = pause_menu_scene.instantiate()
			ui_container.add_child(pause_menu)
	
	# Load crafting station UI (optional)
	if ResourceLoader.exists("res://scenes/ui/CraftingStationUI.tscn"):
		var crafting_scene = load("res://scenes/ui/CraftingStationUI.tscn")
		if crafting_scene:
			crafting_station_ui = crafting_scene.instantiate()
			ui_container.add_child(crafting_station_ui)
	
	# Load tutorial UI (required for Task 13)
	if ResourceLoader.exists("res://scenes/ui/TutorialUI.tscn"):
		var tutorial_scene = load("res://scenes/ui/TutorialUI.tscn")
		if tutorial_scene:
			tutorial_ui = tutorial_scene.instantiate()
			ui_container.add_child(tutorial_ui)
	
	# Load achievement notification (required for Task 13)
	if ResourceLoader.exists("res://scenes/ui/AchievementNotification.tscn"):
		var achievement_notif_scene = load("res://scenes/ui/AchievementNotification.tscn")
		if achievement_notif_scene:
			achievement_notification = achievement_notif_scene.instantiate()
			ui_container.add_child(achievement_notification)
	
	# Load achievement list UI (required for Task 13)
	if ResourceLoader.exists("res://scenes/ui/AchievementListUI.tscn"):
		var achievement_list_scene = load("res://scenes/ui/AchievementListUI.tscn")
		if achievement_list_scene:
			achievement_list_ui = achievement_list_scene.instantiate()
			ui_container.add_child(achievement_list_ui)
	
	# Connect HUD signals (if HUD exists)
	if main_hud:
		main_hud.inventory_requested.connect(toggle_inventory)
		main_hud.portfolio_requested.connect(toggle_portfolio)
		main_hud.skills_requested.connect(toggle_skill_tree)
		main_hud.menu_requested.connect(toggle_pause_menu)
	
	# Connect UI signals (if UIs exist)
	if inventory_ui:
		inventory_ui.item_selected.connect(_on_inventory_item_selected)
		inventory_ui.close_requested.connect(_on_inventory_close_requested)
	
	if portfolio_ui:
		portfolio_ui.artwork_selected.connect(_on_portfolio_artwork_selected)
		portfolio_ui.close_requested.connect(_on_portfolio_close_requested)
	
	if skill_tree_ui:
		skill_tree_ui.close_requested.connect(_on_skill_tree_close_requested)
	
	if pause_menu:
		pause_menu.resume_requested.connect(_on_pause_menu_resume)
		pause_menu.skills_requested.connect(toggle_skill_tree)
		pause_menu.inventory_requested.connect(toggle_inventory)
		pause_menu.portfolio_requested.connect(toggle_portfolio)
		pause_menu.achievements_requested.connect(toggle_achievement_list)
	
	if crafting_station_ui:
		crafting_station_ui.close_requested.connect(_on_crafting_station_close_requested)
		crafting_station_ui.crafting_completed.connect(_on_crafting_completed)
	
	if achievement_list_ui:
		achievement_list_ui.close_requested.connect(_on_achievement_list_close_requested)

func _input(event):
	"""Handle global UI input"""
	# Let the HUD handle most input, but provide fallbacks
	if event.is_action_pressed("ui_cancel"):
		if is_any_ui_open():
			close_current_ui()
		else:
			toggle_pause_menu()

# Inventory Management
func toggle_inventory():
	"""Toggle the inventory UI"""
	if inventory_ui.visible:
		close_inventory()
	else:
		open_inventory()

func open_inventory():
	"""Open the inventory UI"""
	close_current_ui()  # Close any other open UI
	inventory_ui.show_inventory()
	current_open_ui = inventory_ui
	ui_opened.emit("inventory")

func close_inventory():
	"""Close the inventory UI"""
	if not inventory_ui:
		return
	if not inventory_ui.visible:
		return
	inventory_ui.hide_inventory()
	if current_open_ui == inventory_ui:
		current_open_ui = null
	ui_closed.emit("inventory")

# Portfolio Management
func toggle_portfolio():
	"""Toggle the portfolio UI"""
	if portfolio_ui.visible:
		close_portfolio()
	else:
		open_portfolio()

func open_portfolio():
	"""Open the portfolio UI"""
	close_current_ui()
	portfolio_ui.show_portfolio()
	current_open_ui = portfolio_ui
	ui_opened.emit("portfolio")

func close_portfolio():
	"""Close the portfolio UI"""
	if not portfolio_ui:
		return
	if not portfolio_ui.visible:
		return
	portfolio_ui.hide_portfolio()
	if current_open_ui == portfolio_ui:
		current_open_ui = null
	ui_closed.emit("portfolio")

# Skill Tree Management
func toggle_skill_tree():
	"""Toggle the skill tree UI"""
	if skill_tree_ui.visible:
		close_skill_tree()
	else:
		open_skill_tree()

func open_skill_tree():
	"""Open the skill tree UI"""
	close_current_ui()
	skill_tree_ui.show_skill_tree()
	current_open_ui = skill_tree_ui
	ui_opened.emit("skill_tree")

func close_skill_tree():
	"""Close the skill tree UI"""
	if not skill_tree_ui:
		return
	if not skill_tree_ui.visible:
		return
	skill_tree_ui.hide_skill_tree()
	if current_open_ui == skill_tree_ui:
		current_open_ui = null
	ui_closed.emit("skill_tree")

# Pause Menu Management
func toggle_pause_menu():
	"""Toggle the pause menu"""
	if pause_menu.visible:
		close_pause_menu()
	else:
		open_pause_menu()

func open_pause_menu():
	"""Open the pause menu"""
	close_current_ui()
	pause_menu.show_pause_menu()
	current_open_ui = pause_menu
	ui_opened.emit("pause_menu")

func close_pause_menu():
	"""Close the pause menu"""
	if not pause_menu:
		return
	if not pause_menu.visible:
		return
	pause_menu.hide_pause_menu()
	if current_open_ui == pause_menu:
		current_open_ui = null
	ui_closed.emit("pause_menu")

# Crafting Station Management
func show_crafting_station(station: WorkstationBase):
	"""Show the crafting station UI"""
	close_current_ui()
	crafting_station_ui.show_crafting_station(station)
	current_open_ui = crafting_station_ui
	ui_opened.emit("crafting_station")

func close_crafting_station():
	"""Close the crafting station UI"""
	if not crafting_station_ui:
		return
	if not crafting_station_ui.visible:
		return
	crafting_station_ui.hide_crafting_station()
	if current_open_ui == crafting_station_ui:
		current_open_ui = null
	ui_closed.emit("crafting_station")

# General UI Management
func close_current_ui():
	"""Close whatever UI is currently open"""
	if current_open_ui == inventory_ui:
		close_inventory()
	elif current_open_ui == portfolio_ui:
		close_portfolio()
	elif current_open_ui == skill_tree_ui:
		close_skill_tree()
	elif current_open_ui == pause_menu:
		close_pause_menu()
	elif current_open_ui == crafting_station_ui:
		close_crafting_station()
	elif current_open_ui == achievement_list_ui:
		close_achievement_list()

func is_any_ui_open() -> bool:
	"""Check if any UI is currently open"""
	return current_open_ui != null

func is_game_paused() -> bool:
	"""Check if the game is paused"""
	return pause_menu.visible

# Signal Handlers
func _on_inventory_item_selected(item: InventoryItem):
	"""Called when an inventory item is selected"""
	pass

func _on_portfolio_artwork_selected(artwork: ArtworkData):
	"""Called when a portfolio artwork is selected"""
	pass

func _on_inventory_close_requested():
	"""Called when inventory requests to be closed"""
	close_inventory()

func _on_portfolio_close_requested():
	"""Called when portfolio requests to be closed"""
	close_portfolio()

func _on_skill_tree_close_requested():
	"""Called when skill tree requests to be closed"""
	close_skill_tree()

func _on_pause_menu_resume():
	"""Called when pause menu requests resume"""
	close_pause_menu()

func _on_crafting_station_close_requested():
	"""Called when crafting station requests to be closed"""
	close_crafting_station()

func _on_crafting_completed(result_item: InventoryItem):
	"""Called when crafting is completed"""
	if main_hud:
		main_hud.show_notification("Crafted: %s" % result_item.display_name, 3.0, "success")

func _on_achievement_list_close_requested():
	"""Called when achievement list requests to be closed"""
	close_achievement_list()

# Utility Functions
func refresh_all_uis():
	"""Refresh all UI displays"""
	if inventory_ui and inventory_ui.visible:
		inventory_ui.refresh_inventory()
	if portfolio_ui and portfolio_ui.visible:
		portfolio_ui.refresh_portfolio()
	if skill_tree_ui and skill_tree_ui.visible:
		skill_tree_ui.refresh_all_displays()
	if main_hud:
		main_hud.update_all_skill_displays()

func show_notification(message: String, duration: float = 3.0, type: String = "info"):
	"""Show a notification through the HUD"""
	if main_hud:
		main_hud.show_notification(message, duration, type)

func set_hud_visible(visible: bool):
	"""Show or hide the main HUD"""
	if main_hud:
		main_hud.set_hud_visible(visible)

# Getters
func get_main_hud() -> MainHUD:
	"""Get the main HUD instance"""
	return main_hud

func get_inventory_ui() -> InventoryUI:
	"""Get the inventory UI instance"""
	return inventory_ui

func get_portfolio_ui() -> PortfolioUI:
	"""Get the portfolio UI instance"""
	return portfolio_ui

func get_skill_tree_ui() -> SkillTreeUI:
	"""Get the skill tree UI instance"""
	return skill_tree_ui

func get_pause_menu() -> PauseMenu:
	"""Get the pause menu instance"""
	return pause_menu

func get_crafting_station_ui() -> CraftingStationUI:
	"""Get the crafting station UI instance"""
	return crafting_station_ui

# Tutorial Management
func show_tutorial(title: String, message: String, highlight_target: String = ""):
	"""Show a tutorial message"""
	if tutorial_ui and tutorial_ui.has_method("show_tutorial"):
		tutorial_ui.show_tutorial(title, message, highlight_target)

func hide_tutorial():
	"""Hide the tutorial UI"""
	if tutorial_ui and tutorial_ui.has_method("hide_tutorial"):
		tutorial_ui.hide_tutorial()

# Achievement Management
func show_achievement_notification(title: String, description: String):
	"""Show an achievement notification"""
	if achievement_notification and achievement_notification.has_method("queue_notification"):
		achievement_notification.queue_notification(title, description)

func toggle_achievement_list():
	"""Toggle the achievement list UI"""
	if not achievement_list_ui:
		return
	
	if achievement_list_ui.visible:
		close_achievement_list()
	else:
		open_achievement_list()

func open_achievement_list():
	"""Open the achievement list UI"""
	if not achievement_list_ui:
		return
	
	close_current_ui()
	if achievement_list_ui.has_method("open_achievements"):
		achievement_list_ui.open_achievements()
	else:
		achievement_list_ui.show()
	current_open_ui = achievement_list_ui
	ui_opened.emit("achievement_list")

func close_achievement_list():
	"""Close the achievement list UI"""
	if not achievement_list_ui:
		return
	
	if not achievement_list_ui.visible:
		return
	
	achievement_list_ui.hide()
	if current_open_ui == achievement_list_ui:
		current_open_ui = null
	ui_closed.emit("achievement_list")
