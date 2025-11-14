extends Node

# Game Manager Singleton
# Handles game state, scene transitions, and save/load functionality

signal scene_changed(scene_name: String)
signal player_data_loaded()

var current_scene: Node = null
var player_data: PlayerData

# Scene paths
const SCENES = {
	"main": "res://scenes/Main.tscn",
	"workshop": "res://scenes/environments/Workshop.tscn",
	"florence": "res://scenes/environments/Florence.tscn",
	"natural_areas": "res://scenes/environments/NaturalAreas.tscn"
}

func _ready():
	# Set up the scene tree
	var root = get_tree().root
	current_scene = root.get_child(root.get_child_count() - 1)
	
	# Initialize player data (delayed to ensure classes are loaded)
	call_deferred("_initialize_player_data")

func _initialize_player_data():
	player_data = PlayerData.new()

func change_scene(scene_name: String):
	"""Change to a different scene"""
	if not SCENES.has(scene_name):
		print("Error: Scene '%s' not found in SCENES dictionary" % scene_name)
		return
	
	call_deferred("_deferred_change_scene", SCENES[scene_name])

func _deferred_change_scene(path: String):
	"""Deferred scene change to avoid issues during processing"""
	# Use Godot's built-in scene changing to avoid free() issues
	get_tree().change_scene_to_file(path)
	
	# Update current_scene reference
	await get_tree().process_frame  # Wait for scene to load
	current_scene = get_tree().current_scene
	
	# Extract scene name from path for signal
	var scene_name = path.get_file().get_basename()
	scene_changed.emit(scene_name)

func save_game():
	"""Save the current game state"""
	if not player_data:
		print("Error: No player data to save")
		return false
	
	# Update player position from current player in scene
	_update_player_position_from_scene()
	
	var save_file = FileAccess.open("user://savegame.save", FileAccess.WRITE)
	if save_file == null:
		print("Error: Could not open save file for writing")
		return false
	
	var save_data = {
		"player_data": player_data.to_dict(),
		"current_scene": current_scene.scene_file_path if current_scene else "",
		"save_version": "1.0",
		"save_timestamp": Time.get_datetime_string_from_system()
	}
	
	var json_string = JSON.stringify(save_data)
	save_file.store_string(json_string)
	save_file.close()
	print("Game saved successfully at: %s" % save_data.save_timestamp)
	return true

func _update_player_position_from_scene():
	"""Update the player position in PlayerData from the current scene"""
	if current_scene:
		var player = current_scene.find_child("Player")
		if player:
			player_data.player_position = player.global_position

func load_game():
	"""Load the saved game state"""
	if not FileAccess.file_exists("user://savegame.save"):
		print("No save file found")
		return false
	
	var save_file = FileAccess.open("user://savegame.save", FileAccess.READ)
	if save_file == null:
		print("Error: Could not open save file for reading")
		return false
	
	var save_data_text = save_file.get_as_text()
	save_file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(save_data_text)
	
	if parse_result != OK:
		print("Error: Could not parse save file")
		return false
	
	var save_data = json.data
	var loaded_position = Vector2.ZERO
	
	# Load player data
	if save_data.has("player_data"):
		player_data.from_dict(save_data["player_data"])
		# Store the loaded position separately to prevent it from being overwritten
		loaded_position = player_data.player_position
	
	# Load scene if specified
	if save_data.has("current_scene") and save_data["current_scene"] != "":
		call_deferred("_deferred_change_scene", save_data["current_scene"])
	
	# Notify that player data has been loaded (after a frame to ensure scene is ready)
	call_deferred("_emit_player_data_loaded", loaded_position)
	
	print("Game loaded successfully")
	return true

func _emit_player_data_loaded(loaded_pos: Vector2):
	"""Emit the player data loaded signal with the loaded position"""
	player_data_loaded.emit()
	# Directly set the player position in the scene
	if current_scene:
		var player = current_scene.find_child("Player")
		if player:
			# Set the restoring flag BEFORE setting position
			player.restoring_position = true
			player.global_position = loaded_pos
			player_data.player_position = loaded_pos
			# Keep the flag active for a few frames to prevent overwrites
			await get_tree().process_frame
			await get_tree().process_frame
			await get_tree().process_frame
			player.restoring_position = false

func get_player_data() -> PlayerData:
	"""Get the current player data"""
	return player_data

func add_item_to_inventory(item_id: String, quantity: int = 1) -> bool:
	"""Add an item to the player's inventory"""
	if not player_data:
		print("Error: No player data available")
		return false
	
	# Create the inventory item
	var item = InventoryItem.new()
	item.item_id = item_id
	item.display_name = _get_item_display_name(item_id)
	item.description = _get_item_description(item_id)
	item.item_type = _get_item_type(item_id)
	item.current_stack = quantity
	
	# Try to stack with existing items
	for existing_item in player_data.inventory:
		if existing_item.item_id == item_id and existing_item.current_stack < existing_item.stack_size:
			var space_available = existing_item.stack_size - existing_item.current_stack
			var amount_to_add = min(quantity, space_available)
			existing_item.current_stack += amount_to_add
			quantity -= amount_to_add
			
			if quantity <= 0:
				return true
	
	# Add new item if there's still quantity left
	if quantity > 0:
		item.current_stack = quantity
		player_data.inventory.append(item)
	
	return true

func _get_item_display_name(item_id: String) -> String:
	"""Get the display name for an item"""
	var names = {
		"clay": "Clay",
		"mineral_ore": "Mineral Ore",
		"rare_ochre": "Rare Ochre",
		"red_ochre": "Red Ochre",
		"yellow_ochre": "Yellow Ochre",
		"lapis_lazuli": "Lapis Lazuli",
		"cinnabar": "Cinnabar",
		"malachite": "Malachite",
		"azurite": "Azurite"
	}
	return names.get(item_id, item_id.capitalize())

func _get_item_description(item_id: String) -> String:
	"""Get the description for an item"""
	var descriptions = {
		"clay": "Common clay suitable for basic pigment creation",
		"mineral_ore": "Raw mineral ore that can be processed into pigments",
		"rare_ochre": "High-quality ochre with rich color properties",
		"red_ochre": "Natural red pigment from iron-rich clay",
		"yellow_ochre": "Natural yellow pigment from iron-rich clay",
		"lapis_lazuli": "Precious blue stone used to create ultramarine",
		"cinnabar": "Rare red mineral used for vermillion pigment",
		"malachite": "Green copper mineral for vibrant green pigments",
		"azurite": "Blue copper mineral for deep blue pigments"
	}
	return descriptions.get(item_id, "A gathered material")

func _get_item_type(item_id: String) -> InventoryItem.ItemType:
	"""Get the item type for an item"""
	var rare_materials = ["rare_ochre", "lapis_lazuli", "cinnabar", "malachite", "azurite"]
	if item_id in rare_materials:
		return InventoryItem.ItemType.PIGMENT
	elif item_id in ["clay", "mineral_ore", "red_ochre", "yellow_ochre"]:
		return InventoryItem.ItemType.RAW_MATERIAL
	else:
		return InventoryItem.ItemType.RAW_MATERIAL

func quit_game():
	"""Quit the game with cleanup"""
	save_game()
	get_tree().quit()

# Achievement and Tutorial support methods
signal artwork_completed(artwork_data: Dictionary)
signal task_completed(task_id: String)

func get_artwork_count() -> int:
	"""Get the number of completed artworks"""
	if player_data and player_data.portfolio:
		return player_data.portfolio.size()
	return 0

func get_completed_task_count() -> int:
	"""Get the number of completed tasks"""
	if player_data and player_data.completed_tasks:
		return player_data.completed_tasks.size()
	return 0

func save_achievement_data(data: Dictionary):
	"""Save achievement data"""
	var save_file = FileAccess.open("user://achievements.save", FileAccess.WRITE)
	if save_file:
		save_file.store_string(JSON.stringify(data))
		save_file.close()

func load_achievement_data() -> Dictionary:
	"""Load achievement data"""
	if not FileAccess.file_exists("user://achievements.save"):
		return {}
	
	var save_file = FileAccess.open("user://achievements.save", FileAccess.READ)
	if save_file:
		var json = JSON.new()
		var parse_result = json.parse(save_file.get_as_text())
		save_file.close()
		if parse_result == OK:
			return json.data
	return {}

func save_tutorial_data(data: Dictionary):
	"""Save tutorial progress data"""
	var save_file = FileAccess.open("user://tutorial.save", FileAccess.WRITE)
	if save_file:
		save_file.store_string(JSON.stringify(data))
		save_file.close()

func load_tutorial_data() -> Dictionary:
	"""Load tutorial progress data"""
	if not FileAccess.file_exists("user://tutorial.save"):
		return {}
	
	var save_file = FileAccess.open("user://tutorial.save", FileAccess.READ)
	if save_file:
		var json = JSON.new()
		var parse_result = json.parse(save_file.get_as_text())
		save_file.close()
		if parse_result == OK:
			return json.data
	return {}
