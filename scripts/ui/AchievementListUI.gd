extends Control

# Achievement List UI - Displays all achievements and progress

signal close_requested

@onready var achievement_list = $Panel/VBoxContainer/ScrollContainer/VBoxContainer
@onready var progress_label = $Panel/VBoxContainer/HeaderContainer/ProgressLabel

var achievement_item_scene: PackedScene

func _ready():
	# Allow processing even when game is paused (like PauseMenu)
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	
	# Create achievement item scene programmatically if not loaded
	if not achievement_item_scene:
		_create_achievement_item_scene()

func open_achievements():
	_refresh_achievement_list()
	show()

func _refresh_achievement_list():
	# Clear existing items
	for child in achievement_list.get_children():
		child.queue_free()
	
	if not AchievementManager:
		return
	
	# Update progress label
	var unlocked = AchievementManager.get_unlocked_count()
	var total = AchievementManager.get_total_count()
	progress_label.text = "Achievements: %d / %d" % [unlocked, total]
	
	# Add achievement items
	var visible_achievements = AchievementManager.get_visible_achievements()
	for achievement in visible_achievements:
		_add_achievement_item(achievement)

func _add_achievement_item(achievement: Dictionary):
	var item = HBoxContainer.new()
	item.custom_minimum_size = Vector2(0, 60)
	
	# Icon placeholder
	var icon = ColorRect.new()
	icon.custom_minimum_size = Vector2(50, 50)
	icon.color = Color(0.3, 0.3, 0.3) if not achievement["unlocked"] else Color(0.8, 0.6, 0.2)
	item.add_child(icon)
	
	# Text container
	var text_container = VBoxContainer.new()
	text_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Title
	var title = Label.new()
	title.text = achievement["data"]["title"]
	title.add_theme_font_size_override("font_size", 16)
	if achievement["unlocked"]:
		title.modulate = Color.WHITE
	else:
		title.modulate = Color(0.6, 0.6, 0.6)
	text_container.add_child(title)
	
	# Description
	var desc = Label.new()
	desc.text = achievement["data"]["description"]
	desc.add_theme_font_size_override("font_size", 12)
	desc.modulate = Color(0.8, 0.8, 0.8)
	text_container.add_child(desc)
	
	# Progress bar (if applicable)
	if not achievement["unlocked"] and achievement["progress"] > 0:
		var progress_bar = ProgressBar.new()
		progress_bar.max_value = 100
		progress_bar.value = achievement["progress"]
		progress_bar.custom_minimum_size = Vector2(0, 10)
		text_container.add_child(progress_bar)
	
	item.add_child(text_container)
	
	# Status indicator
	if achievement["unlocked"]:
		var checkmark = Label.new()
		checkmark.text = "✓"
		checkmark.add_theme_font_size_override("font_size", 24)
		checkmark.modulate = Color(0.3, 1.0, 0.3)
		item.add_child(checkmark)
	
	# Add separator
	var separator = HSeparator.new()
	
	achievement_list.add_child(item)
	achievement_list.add_child(separator)

func _create_achievement_item_scene():
	# Fallback if scene file doesn't exist
	pass

func _input(event):
	"""Handle input events - ESC to close"""
	if visible and event.is_action_pressed("ui_cancel"):
		close_requested.emit()
		hide()
		get_viewport().set_input_as_handled()  # Prevent event from propagating
