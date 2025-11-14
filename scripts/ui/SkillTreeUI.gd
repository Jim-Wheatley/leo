extends Control
class_name SkillTreeUI

# Comprehensive skill tree and progression display

signal close_requested

@onready var tab_container: TabContainer = $MainPanel/VBoxContainer/TabContainer if has_node("MainPanel/VBoxContainer/TabContainer") else null
@onready var skills_container: VBoxContainer = $MainPanel/VBoxContainer/TabContainer/Skills/SkillsContainer if has_node("MainPanel/VBoxContainer/TabContainer/Skills/SkillsContainer") else null
@onready var techniques_container: VBoxContainer = $MainPanel/VBoxContainer/TabContainer/Techniques/TechniquesContainer if has_node("MainPanel/VBoxContainer/TabContainer/Techniques/TechniquesContainer") else null
@onready var progress_container: VBoxContainer = $MainPanel/VBoxContainer/TabContainer/Progress/ProgressContainer if has_node("MainPanel/VBoxContainer/TabContainer/Progress/ProgressContainer") else null

var skill_panels: Dictionary = {}

func _ready():
	
	# Connect to SkillManager signals
	if SkillManager:
		SkillManager.skill_increased.connect(_on_skill_increased)
		SkillManager.new_technique_unlocked.connect(_on_technique_unlocked)
	
	# Build the UI
	build_skills_tab()
	build_techniques_tab()
	build_progress_tab()
	
	# Hide initially
	hide()

func show_skill_tree():
	"""Show the skill tree UI"""
	refresh_all_displays()
	show()

func hide_skill_tree():
	"""Hide the skill tree UI"""
	hide()

func build_skills_tab():
	"""Build the skills overview tab"""
	if not SkillManager or not skills_container:
		return
	
	for skill_name in SkillManager.skills.keys():
		var skill_panel = create_detailed_skill_panel(skill_name)
		skills_container.add_child(skill_panel)
		skill_panels[skill_name] = skill_panel

func create_detailed_skill_panel(skill_name: String) -> Control:
	"""Create a detailed skill panel with level, progress, and benefits"""
	var main_panel = Panel.new()
	main_panel.custom_minimum_size = Vector2(0, 120)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 15
	vbox.offset_top = 10
	vbox.offset_right = -15
	vbox.offset_bottom = -10
	main_panel.add_child(vbox)
	
	# Header with skill name and level
	var header = HBoxContainer.new()
	vbox.add_child(header)
	
	var skill_title = Label.new()
	skill_title.text = skill_name.capitalize()
	skill_title.add_theme_font_size_override("font_size", 18)
	skill_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(skill_title)
	
	var level_label = Label.new()
	level_label.name = "level_label"
	level_label.text = "Level %d" % SkillManager.get_skill_level(skill_name)
	level_label.add_theme_font_size_override("font_size", 16)
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	header.add_child(level_label)
	
	# Progress bar with detailed info
	var progress_container = HBoxContainer.new()
	vbox.add_child(progress_container)
	
	var progress_bar = ProgressBar.new()
	progress_bar.name = "progress_bar"
	progress_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	progress_bar.min_value = 0.0
	progress_bar.max_value = 1.0
	progress_bar.value = SkillManager.get_skill_progress_percentage(skill_name)
	progress_bar.show_percentage = false
	progress_container.add_child(progress_bar)
	
	var exp_label = Label.new()
	exp_label.name = "exp_label"
	exp_label.text = get_detailed_experience_text(skill_name)
	exp_label.add_theme_font_size_override("font_size", 12)
	progress_container.add_child(exp_label)
	
	# Skill benefits/description
	var description_label = Label.new()
	description_label.name = "description_label"
	description_label.text = get_skill_description(skill_name)
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description_label.add_theme_font_size_override("font_size", 12)
	description_label.modulate = Color(0.8, 0.8, 0.8)
	vbox.add_child(description_label)
	
	# Next level benefits
	var next_level_label = Label.new()
	next_level_label.name = "next_level_label"
	next_level_label.text = get_next_level_benefits(skill_name)
	next_level_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	next_level_label.add_theme_font_size_override("font_size", 11)
	next_level_label.modulate = Color(0.7, 0.9, 0.7)
	vbox.add_child(next_level_label)
	
	return main_panel

func get_detailed_experience_text(skill_name: String) -> String:
	"""Get detailed experience information"""
	var current_exp = SkillManager.get_skill_experience(skill_name)
	var exp_to_next = SkillManager.get_experience_to_next_level(skill_name)
	var current_level = SkillManager.get_skill_level(skill_name)
	
	if exp_to_next > 0:
		return "%d XP (%d to level %d)" % [current_exp, exp_to_next, current_level + 1]
	else:
		return "%d XP (MAX LEVEL)" % current_exp

func get_skill_description(skill_name: String) -> String:
	"""Get description of what the skill does"""
	var descriptions = {
		"painting": "Improves artwork quality and unlocks advanced painting techniques. Higher levels allow for more complex compositions and better color mixing.",
		"sketching": "Enhances observation accuracy and sketch quality. Unlocks ability to sketch more complex subjects and improves inspiration generation.",
		"crafting": "Increases efficiency in workshop activities and unlocks advanced crafting recipes. Reduces material waste and improves tool durability.",
		"gathering": "Improves resource collection efficiency and unlocks rare material discovery. Higher levels reveal better gathering locations.",
		"color_theory": "Enhances understanding of color relationships and paint mixing. Unlocks advanced color techniques and improves artwork appeal.",
		"observation": "Sharpens ability to notice details and improves sketching accuracy. Higher levels unlock hidden details in the environment."
	}
	
	return descriptions.get(skill_name, "This skill enhances your artistic abilities.")

func get_next_level_benefits(skill_name: String) -> String:
	"""Get information about next level benefits"""
	var current_level = SkillManager.get_skill_level(skill_name)
	var exp_to_next = SkillManager.get_experience_to_next_level(skill_name)
	
	if exp_to_next <= 0:
		return "Maximum level reached!"
	
	var next_level = current_level + 1
	var benefits = get_level_benefits(skill_name, next_level)
	
	return "Next level (%d): %s" % [next_level, benefits]

func get_level_benefits(skill_name: String, level: int) -> String:
	"""Get benefits for a specific skill level"""
	# This would ideally come from a data file or SkillManager
	var level_benefits = {
		"painting": {
			2: "Unlock color blending techniques",
			3: "Improved brush control",
			5: "Advanced composition techniques",
			7: "Master-level painting skills",
			10: "Legendary artist status"
		},
		"sketching": {
			2: "Sketch people and animals",
			3: "Improved line quality",
			5: "Complex architectural sketching",
			7: "Master observation skills",
			10: "Perfect artistic vision"
		},
		"crafting": {
			2: "Advanced paint mixing",
			3: "Efficient material usage",
			5: "Master craftsman techniques",
			7: "Innovative tool creation",
			10: "Legendary workshop mastery"
		}
	}
	
	var skill_benefits = level_benefits.get(skill_name, {})
	return skill_benefits.get(level, "Continued improvement in %s abilities" % skill_name)

func build_techniques_tab():
	"""Build the techniques tab showing unlocked abilities"""
	if not techniques_container:
		return
		
	var title_label = Label.new()
	title_label.text = "Unlocked Techniques"
	title_label.add_theme_font_size_override("font_size", 16)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	techniques_container.add_child(title_label)
	
	var separator = HSeparator.new()
	techniques_container.add_child(separator)
	
	refresh_techniques_display()

func refresh_techniques_display():
	"""Refresh the techniques display"""
	if not techniques_container:
		return
		
	# Clear existing technique displays (except title and separator)
	var children = techniques_container.get_children()
	for i in range(2, children.size()):
		children[i].queue_free()
	
	if not SkillManager:
		return
	
	var techniques = SkillManager.get_all_unlocked_techniques()
	
	if techniques.is_empty():
		var no_techniques_label = Label.new()
		no_techniques_label.text = "No techniques unlocked yet.\nGain skill levels to unlock new abilities!"
		no_techniques_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		no_techniques_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		techniques_container.add_child(no_techniques_label)
	else:
		for technique in techniques:
			var technique_panel = create_technique_panel(technique)
			techniques_container.add_child(technique_panel)

func create_technique_panel(technique_name: String) -> Control:
	"""Create a panel for a technique"""
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(0, 60)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 10
	vbox.offset_top = 5
	vbox.offset_right = -10
	vbox.offset_bottom = -5
	panel.add_child(vbox)
	
	var technique_title = Label.new()
	technique_title.text = technique_name
	technique_title.add_theme_font_size_override("font_size", 14)
	vbox.add_child(technique_title)
	
	var technique_desc = Label.new()
	technique_desc.text = get_technique_description(technique_name)
	technique_desc.add_theme_font_size_override("font_size", 12)
	technique_desc.modulate = Color(0.8, 0.8, 0.8)
	technique_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(technique_desc)
	
	return panel

func get_technique_description(technique_name: String) -> String:
	"""Get description for a technique"""
	var descriptions = {
		"Basic Paint Mixing": "Mix primary colors to create secondary colors",
		"Canvas Preparation": "Properly prepare canvases for painting",
		"Color Blending": "Blend colors smoothly on the canvas",
		"Advanced Sketching": "Create detailed and accurate sketches",
		"Efficient Gathering": "Gather resources more effectively",
		"Master Observation": "Notice fine details in subjects"
	}
	
	return descriptions.get(technique_name, "A useful artistic technique")

func build_progress_tab():
	"""Build the progress tracking tab"""
	if not progress_container:
		return
		
	var title_label = Label.new()
	title_label.text = "Learning Progress"
	title_label.add_theme_font_size_override("font_size", 16)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	progress_container.add_child(title_label)
	
	var separator = HSeparator.new()
	progress_container.add_child(separator)
	
	# Add overall progress summary
	create_progress_summary()

func create_progress_summary():
	"""Create overall progress summary"""
	if not SkillManager or not progress_container:
		return
	
	var summary_panel = Panel.new()
	summary_panel.custom_minimum_size = Vector2(0, 100)
	progress_container.add_child(summary_panel)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 15
	vbox.offset_top = 10
	vbox.offset_right = -15
	vbox.offset_bottom = -10
	summary_panel.add_child(vbox)
	
	var total_levels = 0
	var total_exp = 0
	
	for skill_name in SkillManager.skills.keys():
		total_levels += SkillManager.get_skill_level(skill_name)
		total_exp += SkillManager.get_skill_experience(skill_name)
	
	var total_label = Label.new()
	total_label.text = "Total Skill Levels: %d" % total_levels
	total_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(total_label)
	
	var exp_label = Label.new()
	exp_label.text = "Total Experience: %d" % total_exp
	exp_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(exp_label)
	
	var techniques_count = 0
	if SkillManager.has_method("get_all_unlocked_techniques"):
		techniques_count = SkillManager.get_all_unlocked_techniques().size()
	
	var techniques_label = Label.new()
	techniques_label.text = "Techniques Unlocked: %d" % techniques_count
	techniques_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(techniques_label)

func refresh_all_displays():
	"""Refresh all UI displays"""
	refresh_skills_display()
	refresh_techniques_display()

func refresh_skills_display():
	"""Refresh the skills display"""
	for skill_name in skill_panels.keys():
		var panel = skill_panels[skill_name]
		if not is_instance_valid(panel):
			continue
		
		var level_label = panel.find_child("level_label")
		var progress_bar = panel.find_child("progress_bar")
		var exp_label = panel.find_child("exp_label")
		var next_level_label = panel.find_child("next_level_label")
		
		if level_label:
			level_label.text = "Level %d" % SkillManager.get_skill_level(skill_name)
		if progress_bar:
			progress_bar.value = SkillManager.get_skill_progress_percentage(skill_name)
		if exp_label:
			exp_label.text = get_detailed_experience_text(skill_name)
		if next_level_label:
			next_level_label.text = get_next_level_benefits(skill_name)

func _input(event):
	"""Handle input events - ESC to close"""
	if visible and event.is_action_pressed("ui_cancel"):
		close_requested.emit()
		hide_skill_tree()
		get_viewport().set_input_as_handled()

func _on_skill_increased(skill_name: String, new_level: int):
	"""Handle skill level increase"""
	refresh_skills_display()

func _on_technique_unlocked(technique_name: String, skill_name: String):
	"""Handle new technique unlock"""
	refresh_techniques_display()
