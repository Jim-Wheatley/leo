extends Node2D
class_name Florence

# Florence City Environment Script
# Manages the city scene, interactions, and transitions

@onready var player: CharacterBody2D = $Player
@onready var interaction_prompt: Label = $UI/HUD/InteractionPrompt
@onready var location_label: Label = $UI/HUD/LocationLabel

var current_interactable: Node = null
var sketching_system: SketchingSystem
var sketching_ui: SketchingUI

func _ready():
	# Initialize sketching system
	setup_sketching_system()
	
	# Connect interaction areas
	setup_interactions()
	
	# Initialize city state
	print("Florence city loaded - Renaissance streets await!")
	update_location_display("City Center")

func setup_interactions():
	"""Set up all interactive objects in Florence"""
	
	# Workshop building interaction (only workshop needs building interaction)
	var workshop_building = $Buildings/WorkshopBuilding
	setup_building_interaction(workshop_building, "workshop", "Enter Workshop")
	
	# Natural Areas exit point
	setup_natural_areas_exit()
	
	# Cathedral and Market are now sketchable only - no building interactions
	
	# Set up sketchable subjects
	setup_sketchable_subjects()

func setup_natural_areas_exit():
	"""Set up exit point to Natural Areas"""
	# Create exit area well below the Florence street
	var exit_area = Area2D.new()
	exit_area.name = "NaturalAreasExit"
	exit_area.position = Vector2(600, 1250)  # Much further down, well outside the city
	add_child(exit_area)
	
	# Add collision shape
	var collision_shape = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(60, 100)
	collision_shape.shape = shape
	exit_area.add_child(collision_shape)
	
	# Add visual indicator
	var label = Label.new()
	label.text = "🌿 To Natural Areas"
	label.position = Vector2(-60, -30)
	label.add_theme_color_override("font_color", Color.GREEN)
	label.add_theme_font_size_override("font_size", 16)
	exit_area.add_child(label)
	
	# Connect signals
	exit_area.body_entered.connect(_on_natural_areas_exit_entered)
	exit_area.body_exited.connect(_on_natural_areas_exit_exited)

func _on_natural_areas_exit_entered(body: Node2D):
	"""Called when player approaches Natural Areas exit"""
	if body == player:
		current_interactable = $NaturalAreasExit
		show_interaction_prompt("Travel to Natural Areas")
		update_location_display("South Gate - Path to Countryside")

func _on_natural_areas_exit_exited(body: Node2D):
	"""Called when player leaves Natural Areas exit"""
	if body == player and current_interactable == $NaturalAreasExit:
		current_interactable = null
		hide_interaction_prompt()
		update_location_display("City Center")

func setup_building_interaction(building: Node, building_type: String, prompt_text: String):
	"""Set up interaction for a building"""
	# Add interaction area to building
	var interaction_area = Area2D.new()
	interaction_area.name = "InteractionArea"
	building.add_child(interaction_area)
	
	var collision_shape = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(120, 120)  # Large interaction area for buildings
	collision_shape.shape = shape
	interaction_area.add_child(collision_shape)
	
	# Connect signals
	interaction_area.body_entered.connect(_on_building_entered.bind(building, building_type, prompt_text))
	interaction_area.body_exited.connect(_on_building_exited.bind(building, building_type))
	
	# Store building type as metadata
	building.set_meta("building_type", building_type)
	building.set_meta("prompt_text", prompt_text)

func _on_building_entered(body: Node2D, building: Node, building_type: String, prompt_text: String):
	"""Called when player enters building interaction area"""
	if body == player:
		current_interactable = building
		show_interaction_prompt(prompt_text)
		
		# Update location display based on proximity
		match building_type:
			"workshop":
				update_location_display("Near Master's Workshop")
			"cathedral":
				update_location_display("Cathedral District")
			"market":
				update_location_display("Market Square")

func _on_building_exited(body: Node2D, building: Node, building_type: String):
	"""Called when player exits building interaction area"""
	if body == player and current_interactable == building:
		current_interactable = null
		hide_interaction_prompt()
		update_location_display("City Center")

func show_interaction_prompt(text: String):
	"""Show the interaction prompt with given text"""
	interaction_prompt.text = "Press E to " + text
	interaction_prompt.visible = true

func hide_interaction_prompt():
	"""Hide the interaction prompt"""
	interaction_prompt.visible = false

func update_location_display(location: String):
	"""Update the location label"""
	location_label.text = "Florence - " + location

func _input(event):
	"""Handle input for interactions"""
	if event.is_action_pressed("interact") and current_interactable:
		handle_interaction()

func handle_interaction():
	"""Handle interaction with the current interactable object"""
	if not current_interactable:
		return
	
	# Check if it's the Natural Areas exit
	if current_interactable.name == "NaturalAreasExit":
		travel_to_natural_areas()
		return
	
	# Check if it's a sketchable subject
	if current_interactable.has_meta("sketchable") and current_interactable.get_meta("sketchable", false):
		start_sketching_subject(current_interactable)
		return
	
	# Handle building interactions
	var building_type = current_interactable.get_meta("building_type", "")
	
	match building_type:
		"workshop":
			enter_workshop()
		"cathedral":
			visit_cathedral()
		"market":
			visit_market()
		_:
			print("🏛️ You examine the building.")

func travel_to_natural_areas():
	"""Handle traveling to Natural Areas"""
	print("🌿 Traveling to the natural areas outside Florence...")
	GameManager.change_scene("natural_areas")

func start_sketching_subject(subject: Node):
	"""Start sketching a subject"""
	print("🎨 Attempting to start sketching: %s" % subject.get_meta("subject_name", "Unknown"))
	
	if not sketching_system:
		print("❌ No sketching system available!")
		return
	
	if sketching_system.start_sketching(subject):
		# Hide interaction prompt while sketching
		hide_interaction_prompt()
		print("✅ Successfully started sketching: %s" % subject.get_meta("subject_name", "Unknown"))
	else:
		print("❌ Failed to start sketching")

func enter_workshop():
	"""Handle entering the workshop"""
	print("🏠 Entering the master's workshop...")
	
	# Transition to workshop scene using scene file path
	get_tree().change_scene_to_file("res://scenes/environments/Workshop.tscn")

func visit_cathedral():
	"""Handle visiting the cathedral"""
	print("⛪ You visit the magnificent cathedral.")
	print("⛪ The soaring architecture inspires you.")
	print("⛪ This would be a perfect subject for sketching!")
	
	# TODO: Add sketching functionality in Task 8
	# For now, just provide atmospheric text

func visit_market():
	"""Handle visiting the market square"""
	print("🏪 You explore the bustling market square.")
	print("🏪 Merchants sell their wares while people go about their daily lives.")
	print("🏪 The variety of people and activities would make excellent sketching subjects!")
	
	# TODO: Add sketching functionality in Task 8
	# TODO: Add material purchasing in future tasks

func get_player_position() -> Vector2:
	"""Get the current player position"""
	if player:
		return player.global_position
	return Vector2.ZERO

func set_player_position(position: Vector2):
	"""Set the player position (useful for transitions)"""
	if player:
		player.global_position = position

func setup_sketching_system():
	"""Initialize the sketching system and UI"""
	print("🎨 Setting up sketching system...")
	
	# Create sketching system
	sketching_system = SketchingSystem.new()
	add_child(sketching_system)
	print("🎨 Sketching system created and added")
	
	# Create and setup sketching UI
	var sketching_ui_scene = preload("res://scenes/ui/SketchingUI.tscn")
	sketching_ui = sketching_ui_scene.instantiate()
	$UI.add_child(sketching_ui)
	sketching_ui.set_sketching_system(sketching_system)
	print("🎨 Sketching UI created and connected")

func setup_sketchable_subjects():
	"""Set up all sketchable subjects in Florence"""
	
	# Cathedral sketching
	var cathedral_sketch = $SketchableSubjects/CathedralSketch
	setup_sketchable_subject(cathedral_sketch, {
		"subject_id": "florence_cathedral",
		"subject_name": "Florence Cathedral",
		"subject_description": "The magnificent cathedral with its soaring architecture",
		"subject_type": "building",
		"architectural_style": "Gothic Renaissance",
		"complexity": "High",
		"difficulty": 2.0
	})
	
	# Market Square sketching
	var market_sketch = $SketchableSubjects/MarketSketch
	setup_sketchable_subject(market_sketch, {
		"subject_id": "market_square",
		"subject_name": "Market Square",
		"subject_description": "The bustling heart of Florence commerce",
		"subject_type": "scene",
		"scene_elements": ["Buildings", "People", "Market Stalls"],
		"lighting": "Daylight",
		"difficulty": 1.5
	})
	
	# Street Scene sketching
	var street_scene = $SketchableSubjects/StreetScene
	setup_sketchable_subject(street_scene, {
		"subject_id": "florence_street",
		"subject_name": "Florence Street",
		"subject_description": "A typical Renaissance street scene",
		"subject_type": "scene",
		"scene_elements": ["Cobblestones", "Buildings", "Architecture"],
		"lighting": "Daylight",
		"difficulty": 1.0
	})

func setup_sketchable_subject(subject: Area2D, metadata: Dictionary):
	"""Set up a sketchable subject with metadata and interactions"""
	# Mark as sketchable
	subject.set_meta("sketchable", true)
	
	# Set all metadata
	for key in metadata:
		subject.set_meta(key, metadata[key])
	
	# Connect interaction signals
	subject.body_entered.connect(_on_sketchable_entered.bind(subject))
	subject.body_exited.connect(_on_sketchable_exited.bind(subject))
	
	# Initially hide the highlight
	var sprite = subject.get_child(0)  # Assuming first child is the sprite
	if sprite:
		sprite.visible = false

func _on_sketchable_entered(body: Node2D, subject: Area2D):
	"""Called when player enters a sketchable subject area"""
	if body == player:
		print("🎨 Player entered sketchable area: %s" % subject.get_meta("subject_name", "Unknown"))
		
		# Show highlight
		var sprite = subject.get_child(0)
		if sprite:
			sprite.visible = true
			print("🎨 Highlight shown for subject")
		
		# Update interaction if no other interaction is active
		if not current_interactable or current_interactable == subject:
			current_interactable = subject
			var subject_name = subject.get_meta("subject_name", "Subject")
			show_interaction_prompt("Sketch " + subject_name)
			print("🎨 Interaction prompt set: Sketch %s" % subject_name)
		else:
			print("🎨 Another interaction is active: %s" % current_interactable)

func _on_sketchable_exited(body: Node2D, subject: Area2D):
	"""Called when player exits a sketchable subject area"""
	if body == player:
		# Hide highlight
		var sprite = subject.get_child(0)
		if sprite:
			sprite.visible = false
		
		# Clear interaction if this was the active one
		if current_interactable == subject:
			current_interactable = null
			hide_interaction_prompt()

func _process(_delta):
	"""Update city state each frame"""
	# Update interaction prompt position to follow player
	if interaction_prompt.visible and player:
		var screen_pos = get_viewport().get_camera_2d().get_screen_center_position()
		interaction_prompt.position = Vector2(screen_pos.x - 100, screen_pos.y - 100)
