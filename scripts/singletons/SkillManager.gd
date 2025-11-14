extends Node

# Skill Manager Singleton
# Handles skill progression, experience tracking, and ability unlocks

signal skill_increased(skill_name: String, new_level: int)
signal skill_milestone_reached(skill_name: String, milestone_level: int)
signal new_technique_unlocked(technique_name: String, skill_name: String)

# Skill categories and their current levels
var skills: Dictionary = {
	"painting": 1,
	"sketching": 1,
	"color_theory": 1,
	"crafting": 1,
	"gathering": 1,
	"observation": 1
}

# Experience points for each skill (separate from levels)
var skill_experience: Dictionary = {
	"painting": 0,
	"sketching": 0,
	"color_theory": 0,
	"crafting": 0,
	"gathering": 0,
	"observation": 0
}

# Experience required for each level (exponential growth)
var experience_thresholds: Array = [
	0,    # Level 1 (starting level)
	100,  # Level 2
	250,  # Level 3
	450,  # Level 4
	700,  # Level 5
	1000, # Level 6
	1350, # Level 7
	1750, # Level 8
	2200, # Level 9
	2700, # Level 10
	3250, # Level 11
	3850, # Level 12
	4500, # Level 13
	5200, # Level 14
	5950, # Level 15
	6750, # Level 16
	7600, # Level 17
	8500, # Level 18
	9450, # Level 19
	10450 # Level 20 (master level)
]

# Unlocked techniques and abilities
var unlocked_techniques: Dictionary = {}

# Milestone levels that unlock new content
var milestone_levels: Dictionary = {
	"painting": [3, 5, 8, 10, 15],
	"sketching": [2, 4, 7, 10, 12],
	"color_theory": [3, 6, 9, 12, 15],
	"crafting": [2, 5, 8, 11, 14],
	"gathering": [3, 6, 9, 12, 15],
	"observation": [2, 5, 8, 11, 14]
}

func _ready():
	# Connect to GameManager to sync with PlayerData
	if GameManager.player_data:
		sync_with_player_data()

func sync_with_player_data():
	"""Sync skill data with PlayerData"""
	if GameManager.player_data:
		skills = GameManager.player_data.skills.duplicate()
		# Initialize experience if not present
		for skill_name in skills:
			if not skill_experience.has(skill_name):
				skill_experience[skill_name] = get_experience_for_level(skills[skill_name])

func get_skill_level(skill_name: String) -> int:
	"""Get the current level of a specific skill"""
	return skills.get(skill_name, 1)

func get_skill_experience(skill_name: String) -> int:
	"""Get the current experience points for a skill"""
	return skill_experience.get(skill_name, 0)

func get_experience_for_level(level: int) -> int:
	"""Get the minimum experience required for a given level"""
	if level <= 1:
		return 0
	if level > experience_thresholds.size():
		return experience_thresholds[-1]
	return experience_thresholds[level - 1]

func get_experience_to_next_level(skill_name: String) -> int:
	"""Get experience points needed to reach the next level"""
	var current_level = get_skill_level(skill_name)
	var current_exp = get_skill_experience(skill_name)
	var next_level_exp = get_experience_for_level(current_level + 1)
	
	if current_level >= experience_thresholds.size():
		return 0  # Max level reached
	
	return next_level_exp - current_exp

func add_experience(skill_name: String, amount: int, activity_description: String = ""):
	"""Add experience to a skill and handle level ups"""
	if not skills.has(skill_name):
		print("Warning: Unknown skill '%s'" % skill_name)
		return
	
	var old_level = skills[skill_name]
	var old_experience = skill_experience[skill_name]
	
	# Add experience
	skill_experience[skill_name] += amount
	
	# Check for level ups
	var new_level = calculate_level_from_experience(skill_name)
	
	if new_level > old_level:
		skills[skill_name] = new_level
		
		# Update PlayerData
		if GameManager.player_data:
			GameManager.player_data.skills[skill_name] = new_level
		
		# Play audio and visual effects
		if AudioManager:
			AudioManager.play_skill_up()
		
		# Emit signals
		skill_increased.emit(skill_name, new_level)
		
		# Check for milestones
		if milestone_levels.has(skill_name) and milestone_levels[skill_name].has(new_level):
			skill_milestone_reached.emit(skill_name, new_level)
			check_technique_unlocks(skill_name, new_level)
		
		# Print level up message
		var exp_gained_text = ""
		if activity_description != "":
			exp_gained_text = " (%s: +%d exp)" % [activity_description, amount]
		
		print("🎉 %s increased to level %d!%s" % [skill_name.capitalize(), new_level, exp_gained_text])
	else:
		# Just experience gained, no level up
		if activity_description != "":
			var exp_to_next = get_experience_to_next_level(skill_name)
			print("📈 %s: +%d exp (%d to next level)" % [skill_name.capitalize(), amount, exp_to_next])

func calculate_level_from_experience(skill_name: String) -> int:
	"""Calculate what level a skill should be based on experience"""
	var exp = skill_experience[skill_name]
	
	for i in range(experience_thresholds.size() - 1, -1, -1):
		if exp >= experience_thresholds[i]:
			return i + 1
	
	return 1  # Minimum level

func check_technique_unlocks(skill_name: String, level: int):
	"""Check if reaching this skill level unlocks new techniques"""
	var techniques = get_techniques_for_skill_level(skill_name, level)
	
	for technique in techniques:
		if not unlocked_techniques.has(technique):
			unlocked_techniques[technique] = true
			new_technique_unlocked.emit(technique, skill_name)
			print("🔓 New technique unlocked: %s!" % technique)

func get_techniques_for_skill_level(skill_name: String, level: int) -> Array:
	"""Get techniques that should be unlocked at this skill level"""
	var techniques = []
	
	match skill_name:
		"painting":
			if level >= 3:
				techniques.append("Advanced Brush Techniques")
			if level >= 5:
				techniques.append("Color Blending Mastery")
			if level >= 8:
				techniques.append("Portrait Painting")
			if level >= 10:
				techniques.append("Landscape Painting")
			if level >= 15:
				techniques.append("Masterwork Creation")
		
		"sketching":
			if level >= 2:
				techniques.append("Perspective Drawing")
			if level >= 4:
				techniques.append("Figure Studies")
			if level >= 7:
				techniques.append("Architectural Sketching")
			if level >= 10:
				techniques.append("Speed Sketching")
			if level >= 12:
				techniques.append("Master Studies")
		
		"color_theory":
			if level >= 3:
				techniques.append("Color Harmony")
			if level >= 6:
				techniques.append("Advanced Mixing")
			if level >= 9:
				techniques.append("Light and Shadow")
			if level >= 12:
				techniques.append("Atmospheric Perspective")
			if level >= 15:
				techniques.append("Color Psychology")
		
		"crafting":
			if level >= 2:
				techniques.append("Canvas Stretching")
			if level >= 5:
				techniques.append("Pigment Grinding")
			if level >= 8:
				techniques.append("Brush Making")
			if level >= 11:
				techniques.append("Panel Preparation")
			if level >= 14:
				techniques.append("Varnish Application")
		
		"gathering":
			if level >= 3:
				techniques.append("Rare Pigment Detection")
			if level >= 6:
				techniques.append("Quality Assessment")
			if level >= 9:
				techniques.append("Seasonal Gathering")
			if level >= 12:
				techniques.append("Trade Route Knowledge")
			if level >= 15:
				techniques.append("Master Gatherer")
		
		"observation":
			if level >= 2:
				techniques.append("Detail Recognition")
			if level >= 5:
				techniques.append("Composition Analysis")
			if level >= 8:
				techniques.append("Light Study")
			if level >= 11:
				techniques.append("Master's Eye")
			if level >= 14:
				techniques.append("Artistic Vision")
	
	return techniques

func is_technique_unlocked(technique_name: String) -> bool:
	"""Check if a specific technique is unlocked"""
	return unlocked_techniques.get(technique_name, false)

func get_skill_progress_percentage(skill_name: String) -> float:
	"""Get progress to next level as a percentage (0.0 to 1.0)"""
	var current_level = get_skill_level(skill_name)
	var current_exp = get_skill_experience(skill_name)
	
	if current_level >= experience_thresholds.size():
		return 1.0  # Max level
	
	var current_level_exp = get_experience_for_level(current_level)
	var next_level_exp = get_experience_for_level(current_level + 1)
	
	if next_level_exp == current_level_exp:
		return 1.0
	
	return float(current_exp - current_level_exp) / float(next_level_exp - current_level_exp)

func get_all_unlocked_techniques() -> Array:
	"""Get a list of all unlocked techniques"""
	var techniques = []
	for technique in unlocked_techniques:
		if unlocked_techniques[technique]:
			techniques.append(technique)
	return techniques

func set_skill_level(skill_name: String, level: int):
	"""Set a skill to a specific level (for testing)"""
	if not skills.has(skill_name):
		print("Warning: Unknown skill '%s'" % skill_name)
		return
	
	level = clamp(level, 1, experience_thresholds.size())
	skills[skill_name] = level
	skill_experience[skill_name] = get_experience_for_level(level)
	
	if GameManager.player_data:
		GameManager.player_data.skills[skill_name] = level
	
	print("Set %s to level %d" % [skill_name.capitalize(), level])

func reset_skills():
	"""Reset all skills to level 1 (for testing)"""
	for skill_name in skills:
		skills[skill_name] = 1
		skill_experience[skill_name] = 0
	
	unlocked_techniques.clear()
	
	if GameManager.player_data:
		GameManager.player_data.skills = skills.duplicate()
	
	print("All skills reset to level 1")
