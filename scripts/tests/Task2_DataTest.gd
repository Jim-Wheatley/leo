extends Control

# Test script for Task 2: Data Systems and Save/Load

@onready var status_label: Label = $VBoxContainer/StatusLabel
@onready var data_label: Label = $VBoxContainer/DataLabel

@onready var add_item_btn: Button = $VBoxContainer/AddItemBtn
@onready var add_skill_btn: Button = $VBoxContainer/AddSkillBtn
@onready var create_artwork_btn: Button = $VBoxContainer/CreateArtworkBtn
@onready var save_btn: Button = $VBoxContainer/SaveBtn
@onready var load_btn: Button = $VBoxContainer/LoadBtn

func _ready():
	# Connect button signals
	add_item_btn.pressed.connect(_on_add_item_pressed)
	add_skill_btn.pressed.connect(_on_add_skill_pressed)
	create_artwork_btn.pressed.connect(_on_create_artwork_pressed)
	save_btn.pressed.connect(_on_save_pressed)
	load_btn.pressed.connect(_on_load_pressed)
	
	# Initialize GameManager if needed
	if not GameManager.player_data:
		GameManager._initialize_player_data()
	
	_update_display()

func _on_add_item_pressed():
	"""Test adding items to inventory"""
	var test_pigment = InventoryItem.create_pigment("Red", 1.5)
	GameManager.player_data.add_inventory_item(test_pigment)
	
	var test_canvas = InventoryItem.create_canvas("Medium")
	GameManager.player_data.add_inventory_item(test_canvas)
	
	status_label.text = "Status: Added Red Pigment and Medium Canvas"
	_update_display()

func _on_add_skill_pressed():
	"""Test skill progression"""
	GameManager.player_data.increase_skill("painting", 1)
	GameManager.player_data.increase_skill("sketching", 1)
	
	status_label.text = "Status: Increased painting and sketching skills"
	_update_display()

func _on_create_artwork_pressed():
	"""Test artwork creation"""
	var test_sketch = ArtworkData.create_sketch("Florence Cathedral", GameManager.player_data.skills)
	GameManager.player_data.add_artwork(test_sketch)
	
	var materials = ["red_paint", "medium_canvas"]
	var test_painting = ArtworkData.create_painting("Sunset over Arno", GameManager.player_data.skills, materials)
	GameManager.player_data.add_artwork(test_painting)
	
	status_label.text = "Status: Created test sketch and painting"
	_update_display()

func _on_save_pressed():
	"""Test save functionality"""
	var success = GameManager.save_game()
	if success:
		status_label.text = "Status: Game saved successfully!"
	else:
		status_label.text = "Status: Save failed!"

func _on_load_pressed():
	"""Test load functionality"""
	var success = GameManager.load_game()
	if success:
		status_label.text = "Status: Game loaded successfully!"
		_update_display()
	else:
		status_label.text = "Status: Load failed or no save file found!"

func _update_display():
	"""Update the data display"""
	if not GameManager.player_data:
		data_label.text = "No player data available"
		return
	
	var player_data = GameManager.player_data
	var display_text = ""
	
	# Show skills
	display_text += "SKILLS:\n"
	for skill_name in player_data.skills:
		display_text += "  %s: %d\n" % [skill_name.capitalize(), player_data.skills[skill_name]]
	
	# Show inventory
	display_text += "\nINVENTORY (%d items):\n" % player_data.inventory.size()
	for item in player_data.inventory:
		display_text += "  %s x%d (Quality: %.1f)\n" % [item.display_name, item.current_stack, item.quality]
	
	# Show portfolio
	display_text += "\nPORTFOLIO (%d artworks):\n" % player_data.portfolio.size()
	for artwork in player_data.portfolio:
		display_text += "  %s (Quality: %.1f)\n" % [artwork.title, artwork.quality_score]
	
	data_label.text = display_text