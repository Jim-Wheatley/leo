extends CharacterBody2D

# Master Artist NPC
# Provides dialogue, tasks, and guidance to the player

@onready var interaction_area: Area2D = $InteractionArea

var dialogue_system: DialogueSystem
var current_task_offer: TaskData = null
var last_interaction_time: float = 0.0

func _ready():
	# Create dialogue system
	dialogue_system = preload("res://scripts/systems/DialogueSystem.gd").new()
	add_child(dialogue_system)
	
	# Connect dialogue signals
	dialogue_system.option_selected.connect(_on_dialogue_option_selected)
	dialogue_system.dialogue_finished.connect(_on_dialogue_finished)
	
	# Connect to task system
	TaskManager.task_completed.connect(_on_task_completed)
	TaskManager.new_tasks_available.connect(_on_new_tasks_available)

func interact_with_player():
	"""Main interaction method called when player interacts"""
	# Prevent rapid interactions
	var current_time = Time.get_time_dict_from_system()
	var time_float = current_time.hour * 3600 + current_time.minute * 60 + current_time.second
	if time_float - last_interaction_time < 1.0:
		return
	last_interaction_time = time_float
	
	# Check for completed tasks first
	var completed_tasks = check_for_completed_tasks()
	if completed_tasks.size() > 0:
		handle_task_completion(completed_tasks[0])
		return
	
	# Check for available tasks
	var available_tasks = TaskManager.get_available_tasks()
	if available_tasks.size() > 0:
		offer_task(available_tasks[0])
		return
	
	# Check for tasks in progress
	var active_tasks = TaskManager.get_active_tasks()
	if active_tasks.size() > 0:
		provide_task_guidance(active_tasks[0])
		return
	
	# Default dialogue based on progress
	provide_general_guidance()

func check_for_completed_tasks() -> Array:
	"""Check if player has any tasks ready for completion"""
	var completed = []
	var active_tasks = TaskManager.get_active_tasks()
	
	for task in active_tasks:
		if task.can_complete():
			completed.append(task)
	
	return completed

func handle_task_completion(task: TaskData):
	"""Handle completion of a task"""
	dialogue_system.show_task_completion_dialogue(task)
	TaskManager.complete_task(task.task_id)

func offer_task(task: TaskData):
	"""Offer a new task to the player"""
	current_task_offer = task
	dialogue_system.show_task_assignment_dialogue(task)

func provide_task_guidance(task: TaskData):
	"""Provide guidance on current task progress"""
	var progress_text = task.progress_dialogue
	if progress_text == "":
		progress_text = "Continue working on your current task: " + task.title
		progress_text += "\n\n" + task.get_progress_summary()
	
	dialogue_system.show_simple_dialogue("Master Artist", progress_text)

func provide_general_guidance():
	"""Provide general guidance based on player's skill level"""
	var guidance = get_guidance_based_on_skills()
	var full_message = guidance + "\n\nI have no new tasks for you at the moment. Continue practicing your skills, and more opportunities will arise."
	dialogue_system.show_simple_dialogue("Master Artist", full_message)

func get_guidance_based_on_skills() -> String:
	"""Get guidance text based on player's current skill levels"""
	var painting_level = SkillManager.get_skill_level("painting")
	var sketching_level = SkillManager.get_skill_level("sketching")
	var crafting_level = SkillManager.get_skill_level("crafting")
	var gathering_level = SkillManager.get_skill_level("gathering")
	var observation_level = SkillManager.get_skill_level("observation")
	var color_theory_level = SkillManager.get_skill_level("color_theory")
	
	var total_skill = painting_level + sketching_level + crafting_level + gathering_level + observation_level + color_theory_level
	var relationship = GameManager.player_data.master_relationship
	
	# High skill and relationship
	if total_skill >= 30 and relationship >= 50:
		return "You have grown into a remarkable artist, my dear apprentice. Your dedication inspires even me."
	elif total_skill >= 20 and relationship >= 30:
		return "Your progress continues to impress me. You're developing the eye and hand of a true artist."
	elif total_skill >= 15 and relationship >= 20:
		return "I can see real improvement in your work. Keep pushing yourself to new heights."
	elif total_skill >= 10 and relationship >= 10:
		return "Good progress, apprentice. Your skills are developing nicely."
	else:
		# Give specific advice based on lowest skills
		var lowest_skill = "painting"
		var lowest_level = painting_level
		
		if sketching_level < lowest_level:
			lowest_skill = "sketching"
			lowest_level = sketching_level
		if crafting_level < lowest_level:
			lowest_skill = "crafting"
			lowest_level = crafting_level
		if gathering_level < lowest_level:
			lowest_skill = "gathering"
			lowest_level = gathering_level
		if observation_level < lowest_level:
			lowest_skill = "observation"
			lowest_level = observation_level
		if color_theory_level < lowest_level:
			lowest_skill = "color_theory"
			lowest_level = color_theory_level
		
		match lowest_skill:
			"painting":
				return "I notice your painting technique could use more practice. Spend time creating artworks to develop your brush control and artistic vision."
			"sketching":
				return "Your sketching skills need development. I recommend visiting Florence to practice observing and capturing what you see."
			"crafting":
				return "You should spend more time at the workshop stations. Mastering material preparation is fundamental to quality artwork."
			"gathering":
				return "Consider exploring the natural areas to improve your gathering skills. Understanding where materials come from deepens your artistry."
			"observation":
				return "Work on training your eye by sketching various subjects. Sharp observation is the bedrock of all artistic endeavors."
			"color_theory":
				return "I suggest experimenting with color mixing at the paint station. Understanding color relationships will greatly enhance your work."
			_:
				return "Welcome to my workshop, young apprentice! Take your time learning the basics at our workstations."

func _on_dialogue_option_selected(option_index: int):
	"""Handle dialogue option selection"""
	if current_task_offer:
		match option_index:
			0:  # Accept Task
				if TaskManager.start_task(current_task_offer.task_id):
					dialogue_system.show_simple_dialogue("Master Artist", "Excellent! I have faith in your abilities.")
				else:
					dialogue_system.show_simple_dialogue("Master Artist", "It seems you're not quite ready for this task yet.")
			1:  # Not Now
				dialogue_system.show_simple_dialogue("Master Artist", "Very well. Come back when you're ready to take on new challenges.")
		
		current_task_offer = null

func _on_dialogue_finished():
	"""Handle dialogue completion"""
	# Reset any temporary state
	current_task_offer = null

func _on_task_completed(task: TaskData):
	"""Handle task completion signal from TaskManager"""
	pass  # Could add special reactions to task completion here

func _on_new_tasks_available():
	"""Handle new tasks becoming available"""
	pass  # Could add notification system here

# Legacy methods for compatibility
func get_dialogue() -> String:
	"""Legacy method - now handled by interaction system"""
	return get_guidance_based_on_skills()

func give_task() -> Dictionary:
	"""Legacy method - now handled by TaskManager"""
	var available_tasks = TaskManager.get_available_tasks()
	if available_tasks.size() > 0:
		var task = available_tasks[0]
		return {
			"title": task.title,
			"description": task.description,
			"type": task.task_type,
			"requirements": task.skill_requirements,
			"rewards": task.skill_rewards
		}
	else:
		return {
			"title": "No Tasks Available",
			"description": "Continue practicing your skills.",
			"type": "none",
			"requirements": {},
			"rewards": {}
		}

func check_player_progress() -> String:
	"""Legacy method - now handled by guidance system"""
	return get_guidance_based_on_skills()

# Note: Interaction prompts are handled by the Workshop script
