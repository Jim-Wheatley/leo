extends Control

# Test script for Task 3: Skill Progression System

@onready var painting_btn: Button = $HBoxContainer/LeftPanel/ActivityButtons/PaintingBtn
@onready var sketching_btn: Button = $HBoxContainer/LeftPanel/ActivityButtons/SketchingBtn
@onready var color_theory_btn: Button = $HBoxContainer/LeftPanel/ActivityButtons/ColorTheoryBtn
@onready var crafting_btn: Button = $HBoxContainer/LeftPanel/ActivityButtons/CraftingBtn
@onready var gathering_btn: Button = $HBoxContainer/LeftPanel/ActivityButtons/GatheringBtn
@onready var observation_btn: Button = $HBoxContainer/LeftPanel/ActivityButtons/ObservationBtn

@onready var big_boost_btn: Button = $HBoxContainer/LeftPanel/UtilityButtons/BigBoostBtn
@onready var reset_btn: Button = $HBoxContainer/LeftPanel/UtilityButtons/ResetBtn

@onready var skill_container: VBoxContainer = $HBoxContainer/RightPanel/ScrollContainer/VBoxContainer
@onready var techniques_label: Label = $HBoxContainer/RightPanel/TechniquesPanel/TechniquesLabel

var skill_ui: Control

func _ready():
	# Connect button signals
	painting_btn.pressed.connect(_on_painting_pressed)
	sketching_btn.pressed.connect(_on_sketching_pressed)
	color_theory_btn.pressed.connect(_on_color_theory_pressed)
	crafting_btn.pressed.connect(_on_crafting_pressed)
	gathering_btn.pressed.connect(_on_gathering_pressed)
	observation_btn.pressed.connect(_on_observation_pressed)
	
	big_boost_btn.pressed.connect(_on_big_boost_pressed)
	reset_btn.pressed.connect(_on_reset_pressed)
	
	# Create skill UI
	create_skill_ui()
	
	# Connect to SkillManager signals
	SkillManager.skill_increased.connect(_on_skill_increased)
	SkillManager.new_technique_unlocked.connect(_on_technique_unlocked)
	
	# Initial update of all skill displays
	for skill_name in SkillManager.skills:
		update_skill_display(skill_name)

func create_skill_ui():
	"""Create the skill progression UI"""
	skill_ui = preload("res://scripts/ui/SkillProgressionUI.gd").new()
	
	# Manually create the UI elements since we can't load the scene
	for skill_name in SkillManager.skills:
		var skill_panel = create_skill_panel(skill_name)
		skill_container.add_child(skill_panel)
	
	update_techniques_display()

func create_skill_panel(skill_name: String) -> Control:
	"""Create a panel showing skill level and progress"""
	var panel = VBoxContainer.new()
	panel.name = skill_name + "_panel"
	
	# Skill name and level
	var header = HBoxContainer.new()
	var name_label = Label.new()
	name_label.text = skill_name.capitalize()
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var level_label = Label.new()
	level_label.name = "level_label"
	level_label.text = "Level %d" % SkillManager.get_skill_level(skill_name)
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	
	header.add_child(name_label)
	header.add_child(level_label)
	
	# Progress bar
	var progress_bar = ProgressBar.new()
	progress_bar.name = "progress_bar"
	progress_bar.min_value = 0.0
	progress_bar.max_value = 1.0
	progress_bar.value = SkillManager.get_skill_progress_percentage(skill_name)
	progress_bar.show_percentage = false
	
	# Experience info
	var exp_label = Label.new()
	exp_label.name = "exp_label"
	exp_label.text = get_experience_text(skill_name)
	exp_label.add_theme_font_size_override("font_size", 12)
	
	# Add all children to panel
	panel.add_child(header)
	panel.add_child(progress_bar)
	panel.add_child(exp_label)
	
	# Separator
	var separator = HSeparator.new()
	panel.add_child(separator)
	
	# Store direct references to the nodes we need to update
	panel.set_meta("level_label", level_label)
	panel.set_meta("progress_bar", progress_bar)
	panel.set_meta("exp_label", exp_label)
	
	return panel

func get_experience_text(skill_name: String) -> String:
	"""Get formatted experience text"""
	var current_exp = SkillManager.get_skill_experience(skill_name)
	var exp_to_next = SkillManager.get_experience_to_next_level(skill_name)
	
	if exp_to_next > 0:
		return "%d exp (%d to next level)" % [current_exp, exp_to_next]
	else:
		return "%d exp (MAX LEVEL)" % current_exp

func update_skill_display(skill_name: String):
	"""Update the display for a specific skill"""
	var panel = skill_container.get_node_or_null(skill_name + "_panel")
	if not panel:
		return
	
	# Use metadata references instead of searching for child nodes
	var level_label = panel.get_meta("level_label", null)
	var progress_bar = panel.get_meta("progress_bar", null)
	var exp_label = panel.get_meta("exp_label", null)
	
	if level_label:
		level_label.text = "Level %d" % SkillManager.get_skill_level(skill_name)
	
	if progress_bar:
		progress_bar.value = SkillManager.get_skill_progress_percentage(skill_name)
	
	if exp_label:
		exp_label.text = get_experience_text(skill_name)

func update_techniques_display():
	"""Update the techniques display"""
	var techniques = SkillManager.get_all_unlocked_techniques()
	
	if techniques.is_empty():
		techniques_label.text = "No techniques unlocked yet.\nGain skill levels to unlock new abilities!"
	else:
		var text = "Unlocked Techniques:\n"
		for technique in techniques:
			text += "• " + technique + "\n"
		techniques_label.text = text

func _update_all_displays():
	"""Deferred function to update all skill displays"""
	for skill_name in SkillManager.skills:
		update_skill_display(skill_name)
	
	# Update techniques display in case new ones were unlocked
	update_techniques_display()

# Activity button handlers
func _on_painting_pressed():
	SkillManager.add_experience("painting", 15, "Practice painting")
	update_skill_display("painting")

func _on_sketching_pressed():
	SkillManager.add_experience("sketching", 12, "Sketching practice")
	update_skill_display("sketching")

func _on_color_theory_pressed():
	SkillManager.add_experience("color_theory", 10, "Color theory study")
	update_skill_display("color_theory")

func _on_crafting_pressed():
	SkillManager.add_experience("crafting", 8, "Material crafting")
	update_skill_display("crafting")

func _on_gathering_pressed():
	SkillManager.add_experience("gathering", 6, "Pigment gathering")
	update_skill_display("gathering")

func _on_observation_pressed():
	SkillManager.add_experience("observation", 5, "Nature observation")
	update_skill_display("observation")

func _on_big_boost_pressed():
	"""Give a big boost to all skills for testing"""
	for skill_name in SkillManager.skills:
		SkillManager.add_experience(skill_name, 85, "Big boost")
	
	# Use call_deferred to ensure UI updates happen after all experience is added
	call_deferred("_update_all_displays")

func _on_reset_pressed():
	"""Reset all skills for testing"""
	SkillManager.reset_skills()
	# Update all displays
	for skill_name in SkillManager.skills:
		update_skill_display(skill_name)
	update_techniques_display()

# Signal handlers
func _on_skill_increased(skill_name: String, new_level: int):
	"""Called when a skill increases"""
	update_skill_display(skill_name)

func _on_technique_unlocked(technique_name: String, skill_name: String):
	"""Called when a technique is unlocked"""
	update_techniques_display()
