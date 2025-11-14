extends Control

# UI for displaying skill progression and unlocked techniques

@onready var skill_container: VBoxContainer = $ScrollContainer/VBoxContainer
@onready var techniques_label: Label = $TechniquesPanel/TechniquesLabel

var skill_bars: Dictionary = {}

func _ready():
	# Connect to SkillManager signals
	SkillManager.skill_increased.connect(_on_skill_increased)
	SkillManager.skill_milestone_reached.connect(_on_milestone_reached)
	SkillManager.new_technique_unlocked.connect(_on_technique_unlocked)
	
	# Create skill bars
	create_skill_bars()
	update_all_skills()
	update_techniques_display()

func create_skill_bars():
	"""Create progress bars for each skill"""
	for skill_name in SkillManager.skills:
		var skill_panel = create_skill_panel(skill_name)
		skill_container.add_child(skill_panel)

func create_skill_panel(skill_name: String) -> Control:
	"""Create a panel showing skill level and progress"""
	var panel = VBoxContainer.new()
	panel.name = skill_name + "_panel"
	
	# Skill name and level label
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
	
	# Experience label
	var exp_label = Label.new()
	exp_label.name = "exp_label"
	exp_label.text = get_experience_text(skill_name)
	exp_label.add_theme_font_size_override("font_size", 12)
	
	panel.add_child(header)
	panel.add_child(progress_bar)
	panel.add_child(exp_label)
	
	# Add separator
	var separator = HSeparator.new()
	panel.add_child(separator)
	
	# Store reference for updates
	skill_bars[skill_name] = {
		"panel": panel,
		"level_label": level_label,
		"progress_bar": progress_bar,
		"exp_label": exp_label
	}
	
	return panel

func get_experience_text(skill_name: String) -> String:
	"""Get formatted experience text for a skill"""
	var current_exp = SkillManager.get_skill_experience(skill_name)
	var exp_to_next = SkillManager.get_experience_to_next_level(skill_name)
	
	if exp_to_next > 0:
		return "%d exp (%d to next level)" % [current_exp, exp_to_next]
	else:
		return "%d exp (MAX LEVEL)" % current_exp

func update_skill_display(skill_name: String):
	"""Update the display for a specific skill"""
	if not skill_bars.has(skill_name):
		return
	
	var bars = skill_bars[skill_name]
	var level = SkillManager.get_skill_level(skill_name)
	var progress = SkillManager.get_skill_progress_percentage(skill_name)
	
	bars.level_label.text = "Level %d" % level
	bars.progress_bar.value = progress
	bars.exp_label.text = get_experience_text(skill_name)

func update_all_skills():
	"""Update all skill displays"""
	for skill_name in SkillManager.skills:
		update_skill_display(skill_name)

func update_techniques_display():
	"""Update the unlocked techniques display"""
	var techniques = SkillManager.get_all_unlocked_techniques()
	
	if techniques.is_empty():
		techniques_label.text = "No techniques unlocked yet.\nGain skill levels to unlock new abilities!"
	else:
		var text = "Unlocked Techniques:\n"
		for technique in techniques:
			text += "• " + technique + "\n"
		techniques_label.text = text

func _on_skill_increased(skill_name: String, new_level: int):
	"""Called when a skill level increases"""
	update_skill_display(skill_name)
	
	# Add visual feedback
	if skill_bars.has(skill_name):
		var panel = skill_bars[skill_name].panel
		# Simple flash effect
		var tween = create_tween()
		tween.tween_method(_flash_panel, Color.WHITE, Color.YELLOW, 0.2)
		tween.tween_method(_flash_panel, Color.YELLOW, Color.WHITE, 0.2)

func _flash_panel(color: Color):
	"""Flash effect for skill level up"""
	# This would need to be implemented with a ColorRect overlay
	pass

func _on_milestone_reached(skill_name: String, milestone_level: int):
	"""Called when a skill reaches a milestone level"""
	pass

func _on_technique_unlocked(technique_name: String, skill_name: String):
	"""Called when a new technique is unlocked"""
	update_techniques_display()