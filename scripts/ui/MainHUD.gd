extends CanvasLayer
class_name MainHUD

# Main HUD system for the Artist Apprentice RPG

signal inventory_requested
signal portfolio_requested
signal skills_requested
signal menu_requested

# Skill progress bars
@onready var painting_progress: ProgressBar = $HUDContainer/TopBar/SkillsPanel/SkillsContainer/PaintingSkill/ProgressBar
@onready var sketching_progress: ProgressBar = $HUDContainer/TopBar/SkillsPanel/SkillsContainer/SketchingSkill/ProgressBar
@onready var crafting_progress: ProgressBar = $HUDContainer/TopBar/SkillsPanel/SkillsContainer/CraftingSkill/ProgressBar
@onready var gathering_progress: ProgressBar = $HUDContainer/TopBar/SkillsPanel/SkillsContainer/GatheringSkill/ProgressBar

# Quick access buttons
@onready var inventory_btn: Button = $HUDContainer/BottomBar/QuickAccessPanel/QuickAccessContainer/InventoryBtn
@onready var portfolio_btn: Button = $HUDContainer/BottomBar/QuickAccessPanel/QuickAccessContainer/PortfolioBtn
@onready var skills_btn: Button = $HUDContainer/BottomBar/QuickAccessPanel/QuickAccessContainer/SkillsBtn
@onready var menu_btn: Button = $HUDContainer/BottomBar/QuickAccessPanel/QuickAccessContainer/MenuBtn

# Task display
@onready var task_title: Label = $HUDContainer/RightSidePanel/CurrentTaskPanel/TaskContainer/TaskTitle
@onready var task_description: Label = $HUDContainer/RightSidePanel/CurrentTaskPanel/TaskContainer/TaskDescription

# Notification area
@onready var notification_area: VBoxContainer = $HUDContainer/NotificationArea

var skill_progress_bars: Dictionary = {}
var active_notifications: Array[Control] = []

func _ready():
	# Allow input processing even when game is paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Set up skill progress bar references
	skill_progress_bars = {
		"painting": painting_progress,
		"sketching": sketching_progress,
		"crafting": crafting_progress,
		"gathering": gathering_progress
	}
	
	# Connect button signals
	inventory_btn.pressed.connect(_on_inventory_pressed)
	portfolio_btn.pressed.connect(_on_portfolio_pressed)
	skills_btn.pressed.connect(_on_skills_pressed)
	menu_btn.pressed.connect(_on_menu_pressed)
	
	# Connect to skill manager signals
	if SkillManager:
		SkillManager.skill_increased.connect(_on_skill_increased)
		SkillManager.skill_milestone_reached.connect(_on_skill_milestone_reached)
		SkillManager.new_technique_unlocked.connect(_on_technique_unlocked)
	
	# Connect to task manager signals
	if TaskManager:
		TaskManager.task_assigned.connect(_on_task_assigned)
		TaskManager.task_completed.connect(_on_task_completed)
		TaskManager.task_progress_updated.connect(_on_task_progress_updated)
	
	# Initial update
	update_all_skill_displays()
	update_current_task_display()

func _unhandled_input(event):
	"""Handle HUD input shortcuts (only if not handled by other nodes)"""
	if event.is_action_pressed("open_inventory"):
		_on_inventory_pressed()
	elif event.is_action_pressed("open_portfolio"):
		_on_portfolio_pressed()
	elif event.is_action_pressed("open_skills"):
		_on_skills_pressed()
	elif event.is_action_pressed("open_menu"):
		_on_menu_pressed()

func update_all_skill_displays():
	"""Update all skill progress bars"""
	if not SkillManager:
		return
		
	for skill_name in skill_progress_bars.keys():
		update_skill_display(skill_name)

func update_skill_display(skill_name: String):
	"""Update a specific skill progress bar"""
	if not skill_progress_bars.has(skill_name) or not SkillManager:
		return
	
	var progress_bar = skill_progress_bars[skill_name]
	var progress_percentage = SkillManager.get_skill_progress_percentage(skill_name)
	var skill_level = SkillManager.get_skill_level(skill_name)
	
	progress_bar.value = progress_percentage
	progress_bar.tooltip_text = "%s Level %d (%.1f%%)" % [skill_name.capitalize(), skill_level, progress_percentage * 100]

func update_current_task_display():
	"""Update the current task display"""
	if not TaskManager:
		task_title.text = "Current Task"
		task_description.text = "No active task"
		return
	
	# Get the first active task if any
	var current_task = null
	if TaskManager.active_tasks and TaskManager.active_tasks.size() > 0:
		current_task = TaskManager.active_tasks[0]
	
	if current_task:
		task_title.text = current_task.title
		task_description.text = current_task.description
	else:
		task_title.text = "Current Task"
		# Check if there are available tasks
		var available_tasks = TaskManager.get_available_tasks()
		if available_tasks.size() > 0:
			task_description.text = "Visit the Master Artist for a new task"
		else:
			task_description.text = "No active task. Continue practicing to unlock more tasks."

func show_notification(message: String, duration: float = 3.0, type: String = "info"):
	"""Show a notification message"""
	if not notification_area:
		return
	
	var notification = create_notification(message, type)
	notification_area.add_child(notification)
	active_notifications.append(notification)
	
	# Auto-remove after duration
	var tween = create_tween()
	tween.tween_interval(duration)
	tween.tween_callback(func(): remove_notification(notification))

func create_notification(message: String, type: String) -> Control:
	"""Create a notification panel"""
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(280, 50)
	
	# Set color based on type
	var style_box = StyleBoxFlat.new()
	match type:
		"success":
			style_box.bg_color = Color.GREEN * 0.8
		"warning":
			style_box.bg_color = Color.YELLOW * 0.8
		"error":
			style_box.bg_color = Color.RED * 0.8
		_:
			style_box.bg_color = Color.BLUE * 0.8
	
	style_box.corner_radius_top_left = 5
	style_box.corner_radius_top_right = 5
	style_box.corner_radius_bottom_left = 5
	style_box.corner_radius_bottom_right = 5
	panel.add_theme_stylebox_override("panel", style_box)
	
	var label = Label.new()
	label.text = message
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.offset_left = 10
	label.offset_right = -10
	label.offset_top = 5
	label.offset_bottom = -5
	
	panel.add_child(label)
	
	# Add fade-in animation
	panel.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(panel, "modulate:a", 1.0, 0.3)
	
	return panel

func remove_notification(notification: Control):
	"""Remove a notification with fade-out animation"""
	if not is_instance_valid(notification):
		return
	
	active_notifications.erase(notification)
	
	var tween = create_tween()
	tween.tween_property(notification, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func(): notification.queue_free())

func _on_inventory_pressed():
	"""Handle inventory button press"""
	inventory_requested.emit()

func _on_portfolio_pressed():
	"""Handle portfolio button press"""
	portfolio_requested.emit()

func _on_skills_pressed():
	"""Handle skills button press"""
	skills_requested.emit()

func _on_menu_pressed():
	"""Handle menu button press"""
	menu_requested.emit()

func _on_skill_increased(skill_name: String, new_level: int):
	"""Handle skill level increase"""
	update_skill_display(skill_name)
	show_notification("%s increased to level %d!" % [skill_name.capitalize(), new_level], 4.0, "success")

func _on_skill_milestone_reached(skill_name: String, milestone_level: int):
	"""Handle skill milestone reached"""
	show_notification("🌟 %s reached milestone level %d!" % [skill_name.capitalize(), milestone_level], 5.0, "success")

func _on_technique_unlocked(technique_name: String, skill_name: String):
	"""Handle new technique unlocked"""
	show_notification("New technique unlocked: %s!" % technique_name, 5.0, "success")

func _on_task_assigned(task_data):
	"""Handle new task assignment"""
	update_current_task_display()
	show_notification("New task assigned: %s" % task_data.title, 4.0, "info")

func _on_task_completed(task_data):
	"""Handle task completion"""
	update_current_task_display()
	show_notification("Task completed: %s" % task_data.title, 4.0, "success")

func _on_task_progress_updated(task_data, objective_id = ""):
	"""Handle task progress update"""
	update_current_task_display()

func set_hud_visible(visible: bool):
	"""Show or hide the entire HUD"""
	self.visible = visible

func is_hud_visible() -> bool:
	"""Check if HUD is currently visible"""
	return self.visible
