extends Node2D

# Workshop Environment Script
# Manages the workshop scene, interactions, and environment state

@onready var player: CharacterBody2D = $Player
@onready var master_artist: CharacterBody2D = $MasterArtist
@onready var interaction_prompt: Label = $InteractionPrompt
@onready var main_hud: MainHUD = $MainHUD

# UI Components
var inventory_ui: Control = null
var portfolio_ui: Control = null
var skill_tree_ui: Control = null
var pause_menu: Control = null

var current_interactable: Node = null
var _interaction_exit_timer: Timer = null

func _ready():
	# Set up collision layers
	setup_collision_layers()
	
	# Connect interaction areas
	setup_interactions()
	
	# Initialize UI system
	setup_ui_system()
	
	# Initialize audio
	setup_audio()
	
	# Initialize workshop state
	print("Workshop loaded - Renaissance art studio ready!")
	
	# Show helpful message about starting materials
	show_starting_materials_message()

func setup_collision_layers():
	"""Set up collision layers for proper interaction detection"""
	# Set player to collision layer 1
	if player:
		player.collision_layer = 1
		player.collision_mask = 2  # Can collide with environment (layer 2)
	
	# Make Master Artist non-solid so player can get close
	if master_artist:
		master_artist.collision_layer = 4  # Different layer from environment
		master_artist.collision_mask = 0   # Master doesn't need to collide with anything
		
		# Ensure the master artist's interaction area can detect the player
		var interaction_area = master_artist.get_node_or_null("InteractionArea")
		if interaction_area:
			interaction_area.collision_layer = 0  # Area doesn't emit collisions
			interaction_area.collision_mask = 1   # Only detect player (layer 1)

func setup_interactions():
	"""Set up all interactive objects in the workshop"""
	
	# Master Artist interaction
	var master_interaction_area = master_artist.get_node_or_null("InteractionArea")
	if master_interaction_area:
		master_interaction_area.body_entered.connect(_on_master_interaction_entered)
		master_interaction_area.body_exited.connect(_on_master_interaction_exited)
		
		# Check if it has a collision shape and add one if missing
		var collision_shape = master_interaction_area.get_node_or_null("InteractionShape")
		if not collision_shape:
			# Add collision shape manually
			var new_collision_shape = CollisionShape2D.new()
			new_collision_shape.name = "InteractionShape"
			var shape = RectangleShape2D.new()
			shape.size = Vector2(100, 100)
			new_collision_shape.shape = shape
			master_interaction_area.add_child(new_collision_shape)
		
		# Ensure existing collision shape is large enough
		var existing_shape = master_interaction_area.get_node_or_null("InteractionShape")
		if existing_shape and existing_shape.shape:
			if existing_shape.shape is RectangleShape2D:
				var rect_shape = existing_shape.shape as RectangleShape2D
				if rect_shape.size.x < 100 or rect_shape.size.y < 100:
					rect_shape.size = Vector2(120, 120)
			elif existing_shape.shape is CircleShape2D:
				var circle_shape = existing_shape.shape as CircleShape2D
				if circle_shape.radius < 60:
					circle_shape.radius = 60
		
		# Configure Area2D for detection only (not solid)
		master_interaction_area.collision_layer = 0
		master_interaction_area.collision_mask = 1
		master_interaction_area.monitoring = true
		# Make the area monitorable so body_entered/exited are reliable
		master_interaction_area.monitorable = true
		master_interaction_area.set_collision_layer_value(1, false)
		master_interaction_area.set_collision_mask_value(1, true)
	else:
		print("❌ Master Artist InteractionArea not found!")
	
	# Paint Station interaction
	var paint_station = $WorkstationNodes/PaintStation
	setup_workstation_interaction(paint_station, "paint_station")
	
	# Canvas Station interaction
	var canvas_station = $WorkstationNodes/CanvasStation
	setup_workstation_interaction(canvas_station, "canvas_station")
	
	# Artwork Station interaction
	var artwork_station = $WorkstationNodes/ArtworkStation
	setup_workstation_interaction(artwork_station, "artwork_station")
	
	# Exit Door interaction
	var exit_door = $ExitDoor
	setup_exit_door_interaction(exit_door)

func setup_workstation_interaction(workstation: Node, station_type: String):
	"""Set up interaction for a workstation"""
	# Add interaction area to workstation
	var interaction_area = Area2D.new()
	interaction_area.name = "InteractionArea"
	workstation.add_child(interaction_area)
	
	var collision_shape = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(60, 60)  # Larger interaction area
	collision_shape.shape = shape
	interaction_area.add_child(collision_shape)
	
	# Connect signals with proper parameter order
	interaction_area.body_entered.connect(_on_workstation_entered.bind(workstation, station_type))
	interaction_area.body_exited.connect(_on_workstation_exited.bind(workstation, station_type))
	
	# Store station type as metadata
	workstation.set_meta("station_type", station_type)

func setup_exit_door_interaction(exit_door: Node):
	"""Set up interaction for the exit door"""
	# Add interaction area to exit door
	var interaction_area = Area2D.new()
	interaction_area.name = "InteractionArea"
	exit_door.add_child(interaction_area)
	
	var collision_shape = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(80, 100)  # Large interaction area for door
	collision_shape.shape = shape
	interaction_area.add_child(collision_shape)
	
	# Connect signals
	interaction_area.body_entered.connect(_on_exit_door_entered)
	interaction_area.body_exited.connect(_on_exit_door_exited)
	
	# Store door type as metadata
	exit_door.set_meta("interaction_type", "exit_door")

func _on_master_interaction_entered(body: Node2D):
	"""Called when player enters master artist interaction area"""
	if body == player:
		# Cancel any pending exit grace timer (player re-entered quickly)
		if _interaction_exit_timer and _interaction_exit_timer.is_connected("timeout", Callable(self, "_on_interaction_exit_timeout")):
			_interaction_exit_timer.disconnect("timeout", Callable(self, "_on_interaction_exit_timeout"))
			_interaction_exit_timer = null

		current_interactable = master_artist
		show_interaction_prompt("Talk to Master Artist")

func _on_master_interaction_exited(body: Node2D):
	"""Called when player exits master artist interaction area"""
	if body == player and current_interactable == master_artist:
		# Start a short grace period before clearing the interactable so
		# a slightly late button press still registers.
		var grace_seconds = 0.25
		# Use a one-shot Timer to delay clearing
		_interaction_exit_timer = Timer.new()
		_interaction_exit_timer.one_shot = true
		_interaction_exit_timer.wait_time = grace_seconds
		add_child(_interaction_exit_timer)
		_interaction_exit_timer.start()
		_interaction_exit_timer.timeout.connect(_on_interaction_exit_timeout)

		# Keep the prompt visible during the grace period
		# (it will be hidden in the timeout handler if still outside)

func _on_exit_door_entered(body: Node2D):
	"""Called when player enters exit door interaction area"""
	if body == player:
		current_interactable = $ExitDoor
		show_interaction_prompt("Exit to Florence")

func _on_exit_door_exited(body: Node2D):
	"""Called when player exits exit door interaction area"""
	if body == player and current_interactable == $ExitDoor:
		current_interactable = null
		hide_interaction_prompt()

func _on_workstation_entered(body: Node2D, workstation: Node, station_type: String):
	"""Called when player enters workstation interaction area"""
	if body == player:
		current_interactable = workstation
		var prompt_text = get_workstation_prompt(station_type)
		show_interaction_prompt(prompt_text)

func _on_workstation_exited(body: Node2D, workstation: Node, station_type: String):
	"""Called when player exits workstation interaction area"""
	if body == player and current_interactable == workstation:
		current_interactable = null
		hide_interaction_prompt()

func get_workstation_prompt(station_type: String) -> String:
	"""Get the appropriate prompt text for a workstation"""
	match station_type:
		"paint_station":
			return "Use Paint Creation Station"
		"canvas_station":
			return "Use Canvas Making Station"
		"artwork_station":
			return "Use Artwork Creation Station"
		_:
			return "Interact with Station"

func show_interaction_prompt(text: String):
	"""Show the interaction prompt with given text"""
	interaction_prompt.text = "Press E to " + text
	interaction_prompt.visible = true

func hide_interaction_prompt():
	"""Hide the interaction prompt"""
	interaction_prompt.visible = false

func _input(event):
	"""Handle input for interactions"""
	# Debug: F9 triggers achievement reset + sample notifications
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F9:
		if AchievementManager:
			AchievementManager.debug_reset_and_trigger_samples()
			print("Workshop: triggered AchievementManager.debug_reset_and_trigger_samples() via F9")
		else:
			print("Workshop: AchievementManager autoload not found")

	if event.is_action_pressed("interact") and current_interactable:
		handle_interaction()
	
	# Test UI system with number keys
	if event.is_action_pressed("ui_accept"):  # T key
		if Input.is_key_pressed(KEY_1):
			test_ui_system()
		else:
			add_debug_materials()
	elif event.is_action_pressed("ui_select"):  # R key  
		create_debug_artwork()

func test_ui_system():
	"""Test the UI system functionality"""
	print("\n🧪 Testing HUD System...")
	
	if main_hud:
		print("✅ Main HUD found")
		main_hud.show_notification("HUD System Test - Notification Working!", 3.0, "success")
		
		await get_tree().create_timer(2.0).timeout
		main_hud.show_notification("HUD Test Complete!", 3.0, "info")
	else:
		print("❌ Main HUD not found!")
	
	print("🧪 HUD System test completed\n")

func handle_interaction():
	"""Handle interaction with the current interactable object"""
	if not current_interactable:
		return
	
	# Play interaction sound
	if AudioManager:
		AudioManager.play_ui_click()
	
	if current_interactable == master_artist:
		# Double-check proximity to master (safeguard against race conditions)
		if player and master_artist and player.global_position.distance_to(master_artist.global_position) <= 140:
			interact_with_master()
		else:
			print("Workshop: interaction ignored — player too far from master")
	elif current_interactable.has_meta("station_type"):
		var station_type = current_interactable.get_meta("station_type")
		interact_with_workstation(station_type)
	elif current_interactable.has_meta("interaction_type"):
		var interaction_type = current_interactable.get_meta("interaction_type")
		if interaction_type == "exit_door":
			exit_to_florence()

func interact_with_master():
	"""Handle interaction with the master artist"""
	if master_artist.has_method("interact_with_player"):
		# Use the new task system interaction
		master_artist.interact_with_player()
	else:
		# Fallback to old system
		var master_script = master_artist.get_script()
		if master_script and master_artist.has_method("get_dialogue"):
			var dialogue = master_artist.get_dialogue()
			print("🎨 Master Artist: '" + dialogue + "'")
			
			# Also provide progress feedback
			if master_artist.has_method("check_player_progress"):
				var progress_feedback = master_artist.check_player_progress()
				print("🎨 Master Artist: '" + progress_feedback + "'")
		else:
			print("🎨 Master Artist: 'Welcome to my workshop, young apprentice!'")
			print("🎨 Master Artist: 'Practice your skills at the workstations to improve.'")

func interact_with_workstation(station_type: String):
	"""Handle interaction with a workstation"""
	match station_type:
		"paint_station":
			var paint_station = get_paint_station()
			if paint_station:
				paint_station.show_crafting_ui()
			else:
				print("🎨 Paint creation station is not available")
			
		"canvas_station":
			var canvas_station = get_canvas_station()
			if canvas_station:
				canvas_station.show_crafting_ui()
			else:
				print("🎨 Canvas making station is not available")
			
		"artwork_station":
			var artwork_station = get_artwork_station()
			if artwork_station:
				artwork_station.show_crafting_ui()
			else:
				print("🎨 Artwork creation station is not available")
			
		_:
			print("🎨 You interact with the workstation.")
	
	# Also show notification through HUD
	if main_hud:
		main_hud.show_notification("Interacting with %s" % station_type.replace("_", " ").capitalize(), 2.0, "info")

func get_paint_station() -> PaintCreationStation:
	"""Get the paint creation station"""
	var station = $WorkstationNodes/PaintStation
	if station and station.has_method("show_crafting_ui"):
		return station
	return null

func get_canvas_station() -> CanvasMakingStation:
	"""Get the canvas making station"""
	var station = $WorkstationNodes/CanvasStation
	if station and station.has_method("show_crafting_ui"):
		return station
	return null

func get_artwork_station() -> ArtworkCreationStation:
	"""Get the artwork creation station"""
	var station = $WorkstationNodes.get_node_or_null("ArtworkStation")
	if station and station.has_method("show_crafting_ui"):
		return station
	return null

func _process(_delta):
	"""Update workshop state each frame"""
	# Update interaction prompt position to follow player
	if interaction_prompt.visible and player:
		var screen_pos = get_viewport().get_camera_2d().get_screen_center_position()
		interaction_prompt.position = Vector2(screen_pos.x - 100, screen_pos.y - 100)

func _on_interaction_exit_timeout():
	"""Called after a short grace when the player leaves an interaction area."""
	if current_interactable == master_artist:
		current_interactable = null
		hide_interaction_prompt()

	# Clean up the timer node
	if _interaction_exit_timer:
		_interaction_exit_timer.queue_free()
		_interaction_exit_timer = null

func add_debug_materials():
	"""Add test materials for debugging/testing (T key)"""
	print("\n🧪 Adding debug materials...")
	
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
	
	print("✅ Debug materials added! Press I to view inventory")

func create_debug_artwork():
	"""Create test artworks for debugging/testing (R key)"""
	print("\n🎨 Creating debug artworks...")
	
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
	
	print("✅ Debug artworks created! Press P to view portfolio")

func setup_audio():
	"""Set up audio for the workshop"""
	if AudioManager:
		# Play workshop background music
		AudioManager.play_music("workshop_theme", 2.0)
		print("🎵 Workshop music started")

func setup_ui_system():
	"""Set up the UI system for the workshop"""
	if main_hud:
		# Connect to HUD signals
		main_hud.inventory_requested.connect(_on_inventory_requested)
		main_hud.portfolio_requested.connect(_on_portfolio_requested)
		main_hud.skills_requested.connect(_on_skills_requested)
		main_hud.menu_requested.connect(_on_menu_requested)
		
		# Load UI scenes
		load_ui_scenes()
		
		print("✅ UI System initialized")

func load_ui_scenes():
	"""Load the UI scene files"""
	# Create a dedicated CanvasLayer for UI panels (higher than MainHUD)
	var ui_layer = CanvasLayer.new()
	ui_layer.name = "UIPanelLayer"
	ui_layer.layer = 10  # Higher than MainHUD (which is layer 0)
	
	# Add the layer to the scene tree
	if main_hud:
		# Add as sibling to MainHUD so it's on top
		main_hud.get_parent().add_child(ui_layer)
	else:
		# Fallback: add to workshop
		add_child(ui_layer)
	
	# Create a Control container inside the CanvasLayer
	var ui_container = Control.new()
	ui_container.name = "UIPanelContainer"
	ui_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui_container.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Don't block, let children handle input
	ui_layer.add_child(ui_container)
	
	print("✅ Created UI Panel Layer (layer 10) with container")
	
	if not ui_container:
		print("❌ Failed to create UI container!")
		return
	
	# Load Inventory UI
	var inventory_scene = load("res://scenes/ui/InventoryUI.tscn")
	if inventory_scene:
		inventory_ui = inventory_scene.instantiate()
		inventory_ui.hide()
		ui_container.add_child(inventory_ui)  # Add to container, not layer
		if inventory_ui.has_signal("close_requested"):
			inventory_ui.close_requested.connect(_on_inventory_closed)
	
	# Load Portfolio UI
	var portfolio_scene = load("res://scenes/ui/PortfolioUI.tscn")
	if portfolio_scene:
		portfolio_ui = portfolio_scene.instantiate()
		portfolio_ui.hide()
		ui_container.add_child(portfolio_ui)  # Add to container, not layer
		if portfolio_ui.has_signal("close_requested"):
			portfolio_ui.close_requested.connect(_on_portfolio_closed)
	
	# Load Skill Tree UI
	var skill_tree_scene = load("res://scenes/ui/SkillTreeUI.tscn")
	if skill_tree_scene:
		skill_tree_ui = skill_tree_scene.instantiate()
		skill_tree_ui.hide()
		ui_container.add_child(skill_tree_ui)  # Add to container, not layer
		if skill_tree_ui.has_signal("close_requested"):
			skill_tree_ui.close_requested.connect(_on_skill_tree_closed)
	
	# Load Pause Menu
	var pause_menu_scene = load("res://scenes/ui/PauseMenu.tscn")
	if pause_menu_scene:
		pause_menu = pause_menu_scene.instantiate()
		pause_menu.hide()
		ui_container.add_child(pause_menu)  # Add to container, not layer
		if pause_menu.has_signal("resume_requested"):
			pause_menu.resume_requested.connect(_on_pause_menu_closed)
		if pause_menu.has_signal("skills_requested"):
			pause_menu.skills_requested.connect(_on_skills_requested)
		if pause_menu.has_signal("inventory_requested"):
			pause_menu.inventory_requested.connect(_on_inventory_requested)
		if pause_menu.has_signal("portfolio_requested"):
			pause_menu.portfolio_requested.connect(_on_portfolio_requested)
		if pause_menu.has_signal("achievements_requested"):
			pause_menu.achievements_requested.connect(_on_achievements_requested)
	
	# Load Achievement Notification (Task 13)
	var achievement_notif_scene = load("res://scenes/ui/AchievementNotification.tscn")
	if achievement_notif_scene:
		var achievement_notification = achievement_notif_scene.instantiate()
		ui_container.add_child(achievement_notification)  # Add to container, not layer
		print("✅ Achievement Notification UI loaded")
	
	# Load Achievement List UI (Task 13)
	var achievement_list_scene = load("res://scenes/ui/AchievementListUI.tscn")
	if achievement_list_scene:
		var achievement_list_ui = achievement_list_scene.instantiate()
		ui_container.add_child(achievement_list_ui)  # Add to container, not layer
		print("✅ Achievement List UI loaded")

func _on_inventory_requested():
	"""Handle inventory button press"""
	if inventory_ui:
		if inventory_ui.visible:
			if inventory_ui.has_method("hide_inventory"):
				inventory_ui.hide_inventory()
			else:
				inventory_ui.hide()
		else:
			close_all_uis()
			if inventory_ui.has_method("show_inventory"):
				inventory_ui.show_inventory()
			else:
				inventory_ui.show()

func _on_portfolio_requested():
	"""Handle portfolio button press"""
	if portfolio_ui:
		if portfolio_ui.visible:
			if portfolio_ui.has_method("hide_portfolio"):
				portfolio_ui.hide_portfolio()
			else:
				portfolio_ui.hide()
		else:
			close_all_uis()
			if portfolio_ui.has_method("show_portfolio"):
				portfolio_ui.show_portfolio()
			else:
				portfolio_ui.show()

func _on_skills_requested():
	"""Handle skills button press"""
	if skill_tree_ui:
		if skill_tree_ui.visible:
			if skill_tree_ui.has_method("hide_skill_tree"):
				skill_tree_ui.hide_skill_tree()
			else:
				skill_tree_ui.hide()
		else:
			# Close other UIs
			close_all_uis()
			if skill_tree_ui.has_method("show_skill_tree"):
				skill_tree_ui.show_skill_tree()
			else:
				skill_tree_ui.show()
	else:
		print("📊 Skill Tree UI not loaded")

func _on_menu_requested():
	"""Handle menu button press"""
	if pause_menu:
		if pause_menu.visible:
			if pause_menu.has_method("hide_pause_menu"):
				pause_menu.hide_pause_menu()
			else:
				pause_menu.hide()
		else:
			close_all_uis()
			if pause_menu.has_method("show_pause_menu"):
				pause_menu.show_pause_menu()
			else:
				pause_menu.show()

func close_all_uis():
	"""Close all open UI windows"""
	if inventory_ui and inventory_ui.visible:
		inventory_ui.hide()
	if portfolio_ui and portfolio_ui.visible:
		portfolio_ui.hide()
	if skill_tree_ui and skill_tree_ui.visible:
		skill_tree_ui.hide()
	if pause_menu and pause_menu.visible:
		pause_menu.hide()
		if pause_menu.has_method("hide_pause_menu"):
			pause_menu.hide_pause_menu()

func _on_inventory_closed():
	"""Handle inventory close"""
	if inventory_ui:
		inventory_ui.hide()

func _on_portfolio_closed():
	"""Handle portfolio close"""
	if portfolio_ui:
		portfolio_ui.hide()

func _on_skill_tree_closed():
	"""Handle skill tree close"""
	if skill_tree_ui:
		skill_tree_ui.hide()

func _on_pause_menu_closed():
	"""Handle pause menu close"""
	if pause_menu:
		pause_menu.hide()
		if pause_menu.has_method("hide_pause_menu"):
			pause_menu.hide_pause_menu()

func _on_achievements_requested():
	"""Handle achievements button press from pause menu"""
	# Close pause menu first
	if pause_menu:
		pause_menu.hide()
	
	# Find and show achievement list UI
	var achievement_list = get_tree().root.find_child("AchievementListUI", true, false)
	if achievement_list:
		if achievement_list.has_method("open_achievements"):
			achievement_list.open_achievements()
		else:
			achievement_list.show()
		
		# Connect close signal if not already connected
		if achievement_list.has_signal("close_requested") and not achievement_list.is_connected("close_requested", _on_achievements_closed):
			achievement_list.close_requested.connect(_on_achievements_closed)
	else:
		print("❌ Achievement List UI not found")

func _on_achievements_closed():
	"""Handle achievement list close"""
	var achievement_list = get_tree().root.find_child("AchievementListUI", true, false)
	if achievement_list:
		achievement_list.hide()

func show_starting_materials_message():
	"""Show helpful message about starting materials"""
	if GameManager.player_data and not GameManager.player_data.inventory.is_empty():
		print("\n🎨 === MASTER'S WORKSHOP ===")
		print("Welcome, apprentice! I've prepared some basic materials for you:")
		print("• Small Canvas and Red Paint - ready to create your first artwork!")
		print("• Pigments and materials - craft more supplies at the stations")
		print("• Try the Artwork Creation Station to make your first painting")
		print("• Press I to view your inventory, P to view your portfolio")
		print("• Press K to view your skills, ESC for pause menu")
		print("=============================\n")
		
		# Show welcome notification through HUD
		if main_hud:
			await get_tree().create_timer(1.0).timeout  # Wait a moment for HUD to initialize
			main_hud.show_notification("Welcome to the Master's Workshop!", 4.0, "info")

func exit_to_florence():
	"""Handle exiting the workshop to Florence"""
	print("🚪 Leaving the workshop for Florence...")
	
	# Transition to Florence scene using scene file path
	get_tree().change_scene_to_file("res://scenes/environments/Florence.tscn")
