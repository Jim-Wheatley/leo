class_name TaskData extends RefCounted

# Task data class for quest/assignment system

enum TaskType {
	SKILL_PRACTICE,      # Practice a specific skill
	CRAFTING,           # Create specific items
	GATHERING,          # Collect materials
	EXPLORATION,        # Visit locations or sketch subjects
	ARTWORK_CREATION,   # Create artworks with specific requirements
	LEARNING            # Study with master or learn techniques
}

enum TaskStatus {
	NOT_STARTED,
	AVAILABLE,
	IN_PROGRESS,
	COMPLETED,
	FAILED
}

enum TaskDifficulty {
	BEGINNER,
	APPRENTICE,
	JOURNEYMAN,
	EXPERT,
	MASTER
}

@export var task_id: String
@export var title: String
@export var description: String
@export var task_type: TaskType
@export var difficulty: TaskDifficulty
@export var status: TaskStatus = TaskStatus.NOT_STARTED

# Requirements to unlock this task
var skill_requirements: Dictionary = {}  # skill_name: minimum_level
var prerequisite_tasks: Array = []  # task_ids that must be completed first
var required_items: Dictionary = {}  # item_id: quantity needed

# Task objectives and progress
var objectives: Array = []  # List of objectives with progress tracking
var current_progress: Dictionary = {}  # objective_id: current_value

# Rewards for completion
var skill_rewards: Dictionary = {}  # skill_name: experience_amount
var item_rewards: Array = []  # [{item_id: String, quantity: int}]
var reputation_reward: int = 0
var unlock_rewards: Array = []  # New areas, techniques, or tasks unlocked

# Dialogue and flavor
var assignment_dialogue: String = ""
var progress_dialogue: String = ""
var completion_dialogue: String = ""
var failure_dialogue: String = ""

func _init(id: String = "", task_title: String = "", task_description: String = ""):
	task_id = id
	title = task_title
	description = task_description
	status = TaskStatus.NOT_STARTED
	
	# Initialize arrays and dictionaries
	skill_requirements = {}
	prerequisite_tasks = []
	required_items = {}
	objectives = []
	current_progress = {}
	skill_rewards = {}
	item_rewards = []
	unlock_rewards = []
	reputation_reward = 0
	
	# Initialize dialogue strings
	assignment_dialogue = ""
	progress_dialogue = ""
	completion_dialogue = ""
	failure_dialogue = ""

func is_available() -> bool:
	"""Check if this task can be started by the player"""
	if status != TaskStatus.NOT_STARTED:
		return false
	
	# Check skill requirements
	for skill_name in skill_requirements:
		var required_level = skill_requirements[skill_name]
		var current_level = SkillManager.get_skill_level(skill_name)
		if current_level < required_level:
			return false
	
	# Check prerequisite tasks
	for prereq_task_id in prerequisite_tasks:
		if not TaskManager.is_task_completed(prereq_task_id):
			return false
	
	# Check required items
	for item_id in required_items:
		var required_quantity = required_items[item_id]
		if not GameManager.player_data.has_item(item_id, required_quantity):
			return false
	
	return true

func can_complete() -> bool:
	"""Check if all objectives are completed"""
	if status != TaskStatus.IN_PROGRESS:
		return false
	
	for objective in objectives:
		var obj_id = objective.get("id", "")
		var target_value = objective.get("target", 1)
		var current_value = current_progress.get(obj_id, 0)
		
		if current_value < target_value:
			return false
	
	return true

func start_task():
	"""Start this task"""
	if not is_available():
		print("Cannot start task: requirements not met")
		return false
	
	status = TaskStatus.IN_PROGRESS
	
	# Initialize progress tracking
	for objective in objectives:
		var obj_id = objective.get("id", "")
		current_progress[obj_id] = 0
	
	return true

func update_progress(objective_id: String, amount: int = 1):
	"""Update progress on a specific objective"""
	if status != TaskStatus.IN_PROGRESS:
		return
	
	if not current_progress.has(objective_id):
		current_progress[objective_id] = 0
	
	current_progress[objective_id] += amount
	
	# Find the objective to check completion
	for objective in objectives:
		if objective.get("id", "") == objective_id:
			var target_value = objective.get("target", 1)
			var current_value = current_progress[objective_id]
			var obj_description = objective.get("description", "Unknown objective")
			
			if current_value >= target_value:
				print("✅ Objective completed: %s" % obj_description)
			break

func complete_task():
	"""Complete this task and give rewards"""
	if not can_complete():
		print("Cannot complete task: objectives not finished")
		return false
	
	status = TaskStatus.COMPLETED
	
	# Give skill rewards
	for skill_name in skill_rewards:
		var exp_amount = skill_rewards[skill_name]
		SkillManager.add_experience(skill_name, exp_amount, "Task: " + title)
	
	# Give item rewards
	for item_reward in item_rewards:
		var item_id = item_reward.get("item_id", "")
		var quantity = item_reward.get("quantity", 1)
		if item_id != "":
			GameManager.add_item_to_inventory(item_id, quantity)
	
	# Give reputation reward
	if reputation_reward > 0:
		GameManager.player_data.master_relationship += reputation_reward
		print("👨‍🎨 Master relationship increased by %d" % reputation_reward)
	
	# Handle unlock rewards
	for unlock in unlock_rewards:
		print("🔓 Unlocked: %s" % unlock)
	
	# Mark as completed in player data
	GameManager.player_data.complete_task(task_id)
	
	print("🎉 Task completed: %s" % title)
	return true

func get_progress_summary() -> String:
	"""Get a summary of current progress"""
	if status != TaskStatus.IN_PROGRESS:
		return ""
	
	var summary = ""
	for objective in objectives:
		var obj_id = objective.get("id", "")
		var obj_description = objective.get("description", "Unknown")
		var target_value = objective.get("target", 1)
		var current_value = current_progress.get(obj_id, 0)
		
		summary += "• %s: %d/%d\n" % [obj_description, current_value, target_value]
	
	return summary

func to_dict() -> Dictionary:
	"""Convert task data to dictionary for saving"""
	return {
		"task_id": task_id,
		"title": title,
		"description": description,
		"task_type": task_type,
		"difficulty": difficulty,
		"status": status,
		"skill_requirements": skill_requirements,
		"prerequisite_tasks": prerequisite_tasks,
		"required_items": required_items,
		"objectives": objectives,
		"current_progress": current_progress,
		"skill_rewards": skill_rewards,
		"item_rewards": item_rewards,
		"reputation_reward": reputation_reward,
		"unlock_rewards": unlock_rewards,
		"assignment_dialogue": assignment_dialogue,
		"progress_dialogue": progress_dialogue,
		"completion_dialogue": completion_dialogue,
		"failure_dialogue": failure_dialogue
	}

func from_dict(data: Dictionary):
	"""Load task data from dictionary"""
	task_id = data.get("task_id", "")
	title = data.get("title", "")
	description = data.get("description", "")
	task_type = data.get("task_type", TaskType.SKILL_PRACTICE)
	difficulty = data.get("difficulty", TaskDifficulty.BEGINNER)
	status = data.get("status", TaskStatus.NOT_STARTED)
	skill_requirements = data.get("skill_requirements", {})
	prerequisite_tasks = data.get("prerequisite_tasks", [])
	required_items = data.get("required_items", {})
	objectives = data.get("objectives", [])
	current_progress = data.get("current_progress", {})
	skill_rewards = data.get("skill_rewards", {})
	item_rewards = data.get("item_rewards", [])
	reputation_reward = data.get("reputation_reward", 0)
	unlock_rewards = data.get("unlock_rewards", [])
	assignment_dialogue = data.get("assignment_dialogue", "")
	progress_dialogue = data.get("progress_dialogue", "")
	completion_dialogue = data.get("completion_dialogue", "")
	failure_dialogue = data.get("failure_dialogue", "")