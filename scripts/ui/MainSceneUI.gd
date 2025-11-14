extends Control

# UI controller for the main scene

@onready var save_btn: Button = $SaveLoadPanel/SaveBtn
@onready var load_btn: Button = $SaveLoadPanel/LoadBtn
@onready var skills_btn: Button = $SaveLoadPanel/SkillsBtn

var skills_window: Window = null

func _ready():
	# Connect button signals
	save_btn.pressed.connect(_on_save_pressed)
	load_btn.pressed.connect(_on_load_pressed)
	skills_btn.pressed.connect(_on_skills_pressed)
	
	# Add some initial test data if this is a fresh game
	_initialize_fresh_game_data()

func _input(event):
	# Handle keyboard shortcuts
	if event.is_action_pressed("ui_accept"): # F5 equivalent
		if Input.is_key_pressed(KEY_F5):
			_on_save_pressed()
	elif Input.is_key_pressed(KEY_F9):
		_on_load_pressed()
	elif Input.is_key_pressed(KEY_TAB):
		_on_skills_pressed()

func _on_save_pressed():
	"""Handle save button press"""
	var success = GameManager.save_game()
	if success:
		_show_message("Game Saved!")
	else:
		_show_message("Save Failed!")

func _on_load_pressed():
	"""Handle load button press"""
	var success = GameManager.load_game()
	if success:
		_show_message("Game Loaded!")
	else:
		_show_message("No Save File Found!")

func _show_message(message: String):
	"""Show a temporary message to the player"""
	# TODO: Add a proper UI notification system
	pass

func _on_skills_pressed():
	"""Handle skills button press"""
	if skills_window and is_instance_valid(skills_window):
		skills_window.queue_free()
		skills_window = null
	else:
		_open_skills_window()

func _open_skills_window():
	"""Open the skills progression window"""
	skills_window = Window.new()
	skills_window.title = "Skills & Techniques"
	skills_window.size = Vector2i(600, 500)
	skills_window.position = Vector2i(100, 100)
	
	# Create skills UI
	var skills_ui = create_skills_ui()
	skills_window.add_child(skills_ui)
	
	get_tree().root.add_child(skills_window)
	skills_window.close_requested.connect(_on_skills_window_closed)

func create_skills_ui() -> Control:
	"""Create the skills UI content"""
	var main_container = VBoxContainer.new()
	main_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main_container.add_theme_constant_override("separation", 10)
	
	# Title
	var title = Label.new()
	title.text = "Skills & Techniques"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	main_container.add_child(title)
	
	# Skills container
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var skills_container = VBoxContainer.new()
	scroll.add_child(skills_container)
	main_container.add_child(scroll)
	
	# Create skill displays
	for skill_name in SkillManager.skills:
		var skill_panel = create_skill_panel(skill_name)
		skills_container.add_child(skill_panel)
	
	# Techniques section
	var techniques_title = Label.new()
	techniques_title.text = "Unlocked Techniques"
	techniques_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	techniques_title.add_theme_font_size_override("font_size", 16)
	main_container.add_child(techniques_title)
	
	var techniques_label = Label.new()
	techniques_label.name = "techniques_label"
	techniques_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	update_techniques_text(techniques_label)
	main_container.add_child(techniques_label)
	
	return main_container

func create_skill_panel(skill_name: String) -> Control:
	"""Create a skill display panel"""
	var panel = VBoxContainer.new()
	
	# Header with name and level
	var header = HBoxContainer.new()
	var name_label = Label.new()
	name_label.text = skill_name.capitalize()
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var level_label = Label.new()
	level_label.text = "Level %d" % SkillManager.get_skill_level(skill_name)
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	
	header.add_child(name_label)
	header.add_child(level_label)
	
	# Progress bar
	var progress_bar = ProgressBar.new()
	progress_bar.min_value = 0.0
	progress_bar.max_value = 1.0
	progress_bar.value = SkillManager.get_skill_progress_percentage(skill_name)
	progress_bar.show_percentage = false
	
	# Experience text
	var exp_label = Label.new()
	var current_exp = SkillManager.get_skill_experience(skill_name)
	var exp_to_next = SkillManager.get_experience_to_next_level(skill_name)
	if exp_to_next > 0:
		exp_label.text = "%d exp (%d to next level)" % [current_exp, exp_to_next]
	else:
		exp_label.text = "%d exp (MAX LEVEL)" % current_exp
	exp_label.add_theme_font_size_override("font_size", 12)
	
	panel.add_child(header)
	panel.add_child(progress_bar)
	panel.add_child(exp_label)
	
	# Separator
	var separator = HSeparator.new()
	panel.add_child(separator)
	
	return panel

func update_techniques_text(label: Label):
	"""Update the techniques display text"""
	var techniques = SkillManager.get_all_unlocked_techniques()
	
	if techniques.is_empty():
		label.text = "No techniques unlocked yet. Gain skill levels to unlock new abilities!"
	else:
		var text = ""
		for technique in techniques:
			text += "• " + technique + "\n"
		label.text = text

func _on_skills_window_closed():
	"""Handle skills window being closed"""
	if skills_window:
		skills_window.queue_free()
		skills_window = null

func _initialize_fresh_game_data():
	"""Add some initial test data for a fresh game"""
	if not GameManager.player_data:
		return
		
	var player_data = GameManager.player_data
	
	# Only add data if this looks like a fresh game
	if player_data.inventory.is_empty() and player_data.portfolio.is_empty():
		# Add some basic starting items
		var red_pigment = InventoryItem.create_pigment("Red")
		var canvas = InventoryItem.create_canvas("Small")
		
		player_data.add_inventory_item(red_pigment)
		player_data.add_inventory_item(canvas)