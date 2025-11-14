extends Control
class_name PauseMenu

# Pause menu and settings system

signal resume_requested
signal skills_requested
signal inventory_requested
signal portfolio_requested
signal achievements_requested
signal settings_requested
signal save_requested
signal load_requested
signal main_menu_requested
signal quit_requested

@onready var resume_btn: Button = $MenuPanel/VBoxContainer/ResumeBtn
@onready var skills_btn: Button = $MenuPanel/VBoxContainer/SkillsBtn
@onready var inventory_btn: Button = $MenuPanel/VBoxContainer/InventoryBtn
@onready var portfolio_btn: Button = $MenuPanel/VBoxContainer/PortfolioBtn
@onready var achievements_btn: Button = $MenuPanel/VBoxContainer/AchievementsBtn
@onready var settings_btn: Button = $MenuPanel/VBoxContainer/SettingsBtn
@onready var save_btn: Button = $MenuPanel/VBoxContainer/SaveBtn
@onready var load_btn: Button = $MenuPanel/VBoxContainer/LoadBtn
@onready var main_menu_btn: Button = $MenuPanel/VBoxContainer/MainMenuBtn
@onready var quit_btn: Button = $MenuPanel/VBoxContainer/QuitBtn

var settings_window: Window = null

func _ready():
	# Allow processing even when game is paused (so buttons work)
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Connect button signals
	resume_btn.pressed.connect(_on_resume_pressed)
	skills_btn.pressed.connect(_on_skills_pressed)
	inventory_btn.pressed.connect(_on_inventory_pressed)
	portfolio_btn.pressed.connect(_on_portfolio_pressed)
	achievements_btn.pressed.connect(_on_achievements_pressed)
	settings_btn.pressed.connect(_on_settings_pressed)
	save_btn.pressed.connect(_on_save_pressed)
	load_btn.pressed.connect(_on_load_pressed)
	main_menu_btn.pressed.connect(_on_main_menu_pressed)
	quit_btn.pressed.connect(_on_quit_pressed)
	
	# Hide initially
	hide()

func show_pause_menu():
	"""Show the pause menu and pause the game"""
	show()
	if get_tree():
		get_tree().paused = true

func hide_pause_menu():
	"""Hide the pause menu and resume the game"""
	hide()
	if get_tree():
		get_tree().paused = false

# Input is handled by the parent scene (Workshop) via MainHUD signals
# No need for _input handler here to avoid conflicts

func _on_resume_pressed():
	"""Handle resume button press"""
	hide_pause_menu()
	resume_requested.emit()

func _on_skills_pressed():
	"""Handle skills button press"""
	skills_requested.emit()

func _on_inventory_pressed():
	"""Handle inventory button press"""
	inventory_requested.emit()

func _on_portfolio_pressed():
	"""Handle portfolio button press"""
	portfolio_requested.emit()

func _on_achievements_pressed():
	"""Handle achievements button press"""
	achievements_requested.emit()

func _on_settings_pressed():
	"""Handle settings button press"""
	show_settings_window()

func _on_save_pressed():
	"""Handle save button press"""
	var success = false
	if GameManager:
		success = GameManager.save_game()
	
	if success:
		show_message("Game Saved Successfully!", "success")
	else:
		show_message("Failed to Save Game", "error")

func _on_load_pressed():
	"""Handle load button press"""
	var success = false
	if GameManager:
		success = GameManager.load_game()
	
	if success:
		show_message("Game Loaded Successfully!", "success")
		hide_pause_menu()
	else:
		show_message("No Save File Found", "error")

func _on_main_menu_pressed():
	"""Handle main menu button press"""
	# Show confirmation dialog
	show_confirmation_dialog(
		"Return to Main Menu?",
		"Any unsaved progress will be lost.",
		_on_main_menu_confirmed
	)

func _on_quit_pressed():
	"""Handle quit button press"""
	# Show confirmation dialog
	show_confirmation_dialog(
		"Quit Game?",
		"Any unsaved progress will be lost.",
		_on_quit_confirmed
	)

func show_settings_window():
	"""Show the settings window"""
	if settings_window and is_instance_valid(settings_window):
		settings_window.queue_free()
	
	settings_window = Window.new()
	settings_window.title = "Settings"
	settings_window.size = Vector2i(500, 400)
	settings_window.position = Vector2i(200, 150)
	
	var settings_ui = create_settings_ui()
	settings_window.add_child(settings_ui)
	
	get_tree().root.add_child(settings_window)
	settings_window.close_requested.connect(_on_settings_window_closed)

func create_settings_ui() -> Control:
	"""Create the settings UI"""
	var main_container = VBoxContainer.new()
	main_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main_container.add_theme_constant_override("separation", 15)
	
	# Title
	var title = Label.new()
	title.text = "Game Settings"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	main_container.add_child(title)
	
	# Audio Settings
	var audio_section = create_audio_settings()
	main_container.add_child(audio_section)
	
	# Display Settings
	var display_section = create_display_settings()
	main_container.add_child(display_section)
	
	# Gameplay Settings
	var gameplay_section = create_gameplay_settings()
	main_container.add_child(gameplay_section)
	
	# Controls Settings
	var controls_section = create_controls_settings()
	main_container.add_child(controls_section)
	
	# Buttons
	var button_container = HBoxContainer.new()
	button_container.alignment = BoxContainer.ALIGNMENT_CENTER
	main_container.add_child(button_container)
	
	var apply_btn = Button.new()
	apply_btn.text = "Apply"
	apply_btn.pressed.connect(_on_settings_apply)
	button_container.add_child(apply_btn)
	
	var close_btn = Button.new()
	close_btn.text = "Close"
	close_btn.pressed.connect(_on_settings_window_closed)
	button_container.add_child(close_btn)
	
	return main_container

func create_audio_settings() -> Control:
	"""Create audio settings section"""
	var section = VBoxContainer.new()
	
	var title = Label.new()
	title.text = "Audio"
	title.add_theme_font_size_override("font_size", 14)
	section.add_child(title)
	
	# Master Volume
	var master_container = HBoxContainer.new()
	var master_label = Label.new()
	master_label.text = "Master Volume:"
	master_label.custom_minimum_size.x = 120
	master_container.add_child(master_label)
	
	var master_slider = HSlider.new()
	master_slider.name = "master_volume"
	master_slider.min_value = 0.0
	master_slider.max_value = 1.0
	master_slider.step = 0.1
	master_slider.value = 0.8
	master_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	master_container.add_child(master_slider)
	
	section.add_child(master_container)
	
	# SFX Volume
	var sfx_container = HBoxContainer.new()
	var sfx_label = Label.new()
	sfx_label.text = "SFX Volume:"
	sfx_label.custom_minimum_size.x = 120
	sfx_container.add_child(sfx_label)
	
	var sfx_slider = HSlider.new()
	sfx_slider.name = "sfx_volume"
	sfx_slider.min_value = 0.0
	sfx_slider.max_value = 1.0
	sfx_slider.step = 0.1
	sfx_slider.value = 0.8
	sfx_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sfx_container.add_child(sfx_slider)
	
	section.add_child(sfx_container)
	
	return section

func create_display_settings() -> Control:
	"""Create display settings section"""
	var section = VBoxContainer.new()
	
	var title = Label.new()
	title.text = "Display"
	title.add_theme_font_size_override("font_size", 14)
	section.add_child(title)
	
	# Fullscreen toggle
	var fullscreen_check = CheckBox.new()
	fullscreen_check.name = "fullscreen"
	fullscreen_check.text = "Fullscreen"
	fullscreen_check.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	section.add_child(fullscreen_check)
	
	# VSync toggle
	var vsync_check = CheckBox.new()
	vsync_check.name = "vsync"
	vsync_check.text = "VSync"
	vsync_check.button_pressed = DisplayServer.window_get_vsync_mode() != DisplayServer.VSYNC_DISABLED
	section.add_child(vsync_check)
	
	return section

func create_gameplay_settings() -> Control:
	"""Create gameplay settings section"""
	var section = VBoxContainer.new()
	
	var title = Label.new()
	title.text = "Gameplay"
	title.add_theme_font_size_override("font_size", 14)
	section.add_child(title)
	
	# Auto-save toggle
	var autosave_check = CheckBox.new()
	autosave_check.name = "autosave"
	autosave_check.text = "Auto-save enabled"
	autosave_check.button_pressed = true
	section.add_child(autosave_check)
	
	# Tutorial hints toggle
	var hints_check = CheckBox.new()
	hints_check.name = "tutorial_hints"
	hints_check.text = "Show tutorial hints"
	hints_check.button_pressed = true
	section.add_child(hints_check)
	
	return section

func create_controls_settings() -> Control:
	"""Create controls settings section"""
	var section = VBoxContainer.new()
	
	var title = Label.new()
	title.text = "Controls"
	title.add_theme_font_size_override("font_size", 14)
	section.add_child(title)
	
	var controls_info = Label.new()
	controls_info.text = "Movement: WASD or Arrow Keys\nInventory: I\nPortfolio: P\nSkills: K\nPause: ESC"
	controls_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	section.add_child(controls_info)
	
	return section

func _on_settings_apply():
	"""Apply settings changes"""
	if not settings_window:
		return
	
	# Find and apply audio settings
	var master_slider = settings_window.find_child("master_volume")
	var sfx_slider = settings_window.find_child("sfx_volume")
	
	if master_slider:
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(master_slider.value))
	if sfx_slider:
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(sfx_slider.value))
	
	# Find and apply display settings
	var fullscreen_check = settings_window.find_child("fullscreen")
	var vsync_check = settings_window.find_child("vsync")
	
	if fullscreen_check:
		if fullscreen_check.button_pressed:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	
	if vsync_check:
		if vsync_check.button_pressed:
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
		else:
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	
	show_message("Settings Applied!", "success")

func _on_settings_window_closed():
	"""Handle settings window close"""
	if settings_window:
		settings_window.queue_free()
		settings_window = null

func show_message(message: String, type: String = "info"):
	"""Show a temporary message"""
	# Create a temporary label for feedback
	var message_label = Label.new()
	message_label.text = message
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.add_theme_font_size_override("font_size", 14)
	
	# Color based on type
	match type:
		"success":
			message_label.modulate = Color.GREEN
		"error":
			message_label.modulate = Color.RED
		_:
			message_label.modulate = Color.WHITE
	
	# Add to menu panel temporarily
	$MenuPanel/VBoxContainer.add_child(message_label)
	
	# Remove after delay
	var tween = create_tween()
	tween.tween_delay(2.0)
	tween.tween_callback(_on_message_timeout.bind(message_label))

func _on_main_menu_confirmed():
	"""Handle main menu confirmation"""
	hide_pause_menu()
	main_menu_requested.emit()

func _on_quit_confirmed():
	"""Handle quit confirmation"""
	get_tree().quit()

func _on_dialog_close_requested(dialog: AcceptDialog):
	"""Handle dialog close request"""
	dialog.queue_free()

func _on_message_timeout(message_label: Label):
	"""Handle message timeout"""
	message_label.queue_free()

func show_confirmation_dialog(title: String, message: String, confirm_callback: Callable):
	"""Show a confirmation dialog"""
	var dialog = AcceptDialog.new()
	dialog.title = title
	dialog.dialog_text = message
	dialog.add_cancel_button("Cancel")
	
	get_tree().root.add_child(dialog)
	dialog.popup_centered()
	
	dialog.confirmed.connect(confirm_callback)
	dialog.close_requested.connect(_on_dialog_close_requested.bind(dialog))
