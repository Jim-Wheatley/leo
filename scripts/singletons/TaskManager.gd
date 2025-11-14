extends Node

# Task Manager Singleton
# Handles task assignment, progression, and completion

signal task_assigned(task: TaskData)
signal task_started(task: TaskData)
signal task_progress_updated(task: TaskData, objective_id: String)
signal task_completed(task: TaskData)
signal new_tasks_available()

# All available tasks in the game
var all_tasks: Dictionary = {}  # task_id: TaskData

# Player's current tasks
var active_tasks: Array = []
var completed_tasks: Array = []

func _ready():
	# Initialize the task system
	create_initial_tasks()
	
	# Connect to other systems
	if GameManager.player_data_loaded.is_connected(_on_player_data_loaded):
		GameManager.player_data_loaded.disconnect(_on_player_data_loaded)
	GameManager.player_data_loaded.connect(_on_player_data_loaded)

func _on_player_data_loaded():
	"""Called when player data is loaded"""
	sync_with_player_data()

func sync_with_player_data():
	"""Sync task data with PlayerData"""
	if GameManager.player_data:
		completed_tasks = GameManager.player_data.completed_tasks.duplicate()
		
		# Update task statuses based on completed tasks
		for task_id in completed_tasks:
			if all_tasks.has(task_id):
				all_tasks[task_id].status = TaskData.TaskStatus.COMPLETED

func create_initial_tasks():
	"""Create the initial set of tasks for the game"""
	
	# Beginner tasks
	create_first_paint_task()
	create_first_canvas_task()
	create_first_artwork_task()
	create_sketching_basics_task()
	create_gathering_introduction_task()
	
	# Intermediate tasks
	create_color_theory_task()
	create_florence_exploration_task()
	create_advanced_crafting_task()
	create_portfolio_building_task()
	
	# Advanced tasks
	create_masterwork_preparation_task()
	create_technique_mastery_task()

func create_first_paint_task():
	"""Create the first paint creation task"""
	var task = TaskData.new("first_paint", "Create Your First Paint", 
		"Learn the basics of paint creation by mixing pigments with binding agents.")
	
	task.task_type = TaskData.TaskType.CRAFTING
	task.difficulty = TaskData.TaskDifficulty.BEGINNER
	task.skill_requirements = {}  # No requirements - starting task
	
	task.objectives = [
		{
			"id": "create_paint",
			"description": "Create any color of paint",
			"target": 1,
			"type": "craft_item",
			"item_type": "paint"
		}
	]
	
	task.skill_rewards = {
		"crafting": 25,
		"color_theory": 15
	}
	
	task.reputation_reward = 5
	
	task.assignment_dialogue = "Welcome, young apprentice! Your first lesson is to create paint. Mix pigments with binding agents at the paint station."
	task.completion_dialogue = "Excellent! You've created your first paint. This is the foundation of all artistic work."
	
	all_tasks[task.task_id] = task

func create_first_canvas_task():
	"""Create the first canvas making task"""
	var task = TaskData.new("first_canvas", "Prepare Your First Canvas", 
		"Learn to prepare canvases by combining wood frames with canvas fabric.")
	
	task.task_type = TaskData.TaskType.CRAFTING
	task.difficulty = TaskData.TaskDifficulty.BEGINNER
	task.prerequisite_tasks = ["first_paint"]
	
	task.objectives = [
		{
			"id": "create_canvas",
			"description": "Create a canvas of any size",
			"target": 1,
			"type": "craft_item",
			"item_type": "canvas"
		}
	]
	
	task.skill_rewards = {
		"crafting": 30
	}
	
	task.reputation_reward = 5
	
	task.assignment_dialogue = "Now that you can create paint, you need something to paint on. Learn to prepare canvases at the canvas station."
	task.completion_dialogue = "Well done! A properly prepared canvas is essential for any artwork."
	
	all_tasks[task.task_id] = task

func create_first_artwork_task():
	"""Create the first artwork creation task"""
	var task = TaskData.new("first_artwork", "Create Your First Artwork", 
		"Combine your paint and canvas to create your very first artwork.")
	
	task.task_type = TaskData.TaskType.ARTWORK_CREATION
	task.difficulty = TaskData.TaskDifficulty.BEGINNER
	task.prerequisite_tasks = ["first_canvas"]
	
	task.objectives = [
		{
			"id": "create_artwork",
			"description": "Create an artwork using paint and canvas",
			"target": 1,
			"type": "create_artwork"
		}
	]
	
	task.skill_rewards = {
		"painting": 40,
		"color_theory": 20
	}
	
	task.reputation_reward = 10
	
	task.assignment_dialogue = "Now comes the moment of truth - create your first artwork! Use the artwork station to combine your materials."
	task.completion_dialogue = "Magnificent! You've created your first artwork. This marks the beginning of your artistic journey."
	
	all_tasks[task.task_id] = task

func create_sketching_basics_task():
	"""Create the sketching basics task"""
	var task = TaskData.new("sketching_basics", "Learn to Sketch", 
		"Practice your observation skills by sketching subjects around Florence.")
	
	task.task_type = TaskData.TaskType.EXPLORATION
	task.difficulty = TaskData.TaskDifficulty.BEGINNER
	task.skill_requirements = {"observation": 1}
	
	task.objectives = [
		{
			"id": "sketch_subjects",
			"description": "Complete sketches of different subjects",
			"target": 3,
			"type": "create_sketch"
		}
	]
	
	task.skill_rewards = {
		"sketching": 35,
		"observation": 25
	}
	
	task.reputation_reward = 8
	
	task.assignment_dialogue = "To become a great artist, you must learn to see. Go to Florence and sketch what you observe."
	task.completion_dialogue = "Your sketches show promise! Observation is the foundation of all artistic skill."
	
	all_tasks[task.task_id] = task

func create_gathering_introduction_task():
	"""Create the material gathering introduction task"""
	var task = TaskData.new("gathering_intro", "Gather Natural Materials", 
		"Learn to find and collect natural pigments from the areas around Florence.")
	
	task.task_type = TaskData.TaskType.GATHERING
	task.difficulty = TaskData.TaskDifficulty.BEGINNER
	task.skill_requirements = {"gathering": 1}
	
	task.objectives = [
		{
			"id": "gather_materials",
			"description": "Collect natural materials from gathering nodes",
			"target": 5,
			"type": "gather_resource"
		}
	]
	
	task.skill_rewards = {
		"gathering": 30,
		"observation": 15
	}
	
	task.reputation_reward = 6
	
	task.assignment_dialogue = "The finest pigments come from nature itself. Venture to the natural areas and learn to gather materials."
	task.completion_dialogue = "Excellent work! Understanding your materials is crucial for any artist."
	
	all_tasks[task.task_id] = task

func create_color_theory_task():
	"""Create the color theory task"""
	var task = TaskData.new("color_theory", "Master Color Mixing", 
		"Create paints of different colors to understand color relationships.")
	
	task.task_type = TaskData.TaskType.CRAFTING
	task.difficulty = TaskData.TaskDifficulty.APPRENTICE
	task.skill_requirements = {"crafting": 2, "color_theory": 2}
	task.prerequisite_tasks = ["first_artwork"]
	
	task.objectives = [
		{
			"id": "create_different_colors",
			"description": "Create paints of at least 3 different colors",
			"target": 3,
			"type": "craft_different_colors"
		}
	]
	
	task.skill_rewards = {
		"color_theory": 50,
		"crafting": 25
	}
	
	task.reputation_reward = 12
	
	task.assignment_dialogue = "Color is the language of painting. Learn to create different colors and understand their relationships."
	task.completion_dialogue = "Wonderful! You're beginning to understand the subtle art of color."
	
	all_tasks[task.task_id] = task

func create_florence_exploration_task():
	"""Create the Florence exploration task"""
	var task = TaskData.new("florence_exploration", "Explore Florence", 
		"Discover the beauty of Florence by sketching its famous landmarks and architecture.")
	
	task.task_type = TaskData.TaskType.EXPLORATION
	task.difficulty = TaskData.TaskDifficulty.APPRENTICE
	task.skill_requirements = {"sketching": 2, "observation": 2}
	task.prerequisite_tasks = ["sketching_basics"]
	
	task.objectives = [
		{
			"id": "sketch_landmarks",
			"description": "Sketch famous Florence landmarks",
			"target": 5,
			"type": "sketch_landmark"
		}
	]
	
	task.skill_rewards = {
		"sketching": 45,
		"observation": 35
	}
	
	task.reputation_reward = 15
	
	task.assignment_dialogue = "Florence is a living gallery. Study its architecture and capture its beauty in your sketches."
	task.completion_dialogue = "Your sketches capture the essence of our beautiful city. You have a keen eye!"
	
	all_tasks[task.task_id] = task

func create_advanced_crafting_task():
	"""Create the advanced crafting task"""
	var task = TaskData.new("advanced_crafting", "Advanced Workshop Techniques", 
		"Master the workshop by creating high-quality materials and tools.")
	
	task.task_type = TaskData.TaskType.CRAFTING
	task.difficulty = TaskData.TaskDifficulty.JOURNEYMAN
	task.skill_requirements = {"crafting": 4}
	task.prerequisite_tasks = ["color_theory"]
	
	task.objectives = [
		{
			"id": "create_quality_materials",
			"description": "Create high-quality paints and canvases",
			"target": 5,
			"type": "craft_quality_items"
		}
	]
	
	task.skill_rewards = {
		"crafting": 60,
		"color_theory": 30
	}
	
	task.reputation_reward = 20
	
	task.assignment_dialogue = "You've learned the basics. Now master the advanced techniques of the workshop."
	task.completion_dialogue = "Impressive! Your craftsmanship is becoming truly skilled."
	
	all_tasks[task.task_id] = task

func create_portfolio_building_task():
	"""Create the portfolio building task"""
	var task = TaskData.new("portfolio_building", "Build Your Portfolio", 
		"Create a collection of artworks to demonstrate your growing skills.")
	
	task.task_type = TaskData.TaskType.ARTWORK_CREATION
	task.difficulty = TaskData.TaskDifficulty.JOURNEYMAN
	task.skill_requirements = {"painting": 3}
	task.prerequisite_tasks = ["florence_exploration"]
	
	task.objectives = [
		{
			"id": "create_portfolio",
			"description": "Create multiple artworks for your portfolio",
			"target": 5,
			"type": "create_artwork"
		}
	]
	
	task.skill_rewards = {
		"painting": 75,
		"color_theory": 40
	}
	
	task.reputation_reward = 25
	
	task.assignment_dialogue = "An artist is known by their body of work. Create a portfolio that showcases your abilities."
	task.completion_dialogue = "Your portfolio shows remarkable progress. You're becoming a true artist!"
	
	all_tasks[task.task_id] = task

func create_masterwork_preparation_task():
	"""Create the masterwork preparation task"""
	var task = TaskData.new("masterwork_prep", "Prepare for Your Masterwork", 
		"Gather the finest materials and perfect your techniques for a masterwork creation.")
	
	task.task_type = TaskData.TaskType.LEARNING
	task.difficulty = TaskData.TaskDifficulty.EXPERT
	task.skill_requirements = {"painting": 5, "crafting": 4, "color_theory": 4}
	task.prerequisite_tasks = ["portfolio_building", "advanced_crafting"]
	
	task.objectives = [
		{
			"id": "gather_rare_materials",
			"description": "Collect rare pigments and materials",
			"target": 3,
			"type": "gather_rare_materials"
		},
		{
			"id": "perfect_techniques",
			"description": "Demonstrate mastery in multiple skills",
			"target": 1,
			"type": "skill_mastery_check"
		}
	]
	
	task.skill_rewards = {
		"painting": 100,
		"crafting": 75,
		"color_theory": 75
	}
	
	task.reputation_reward = 40
	task.unlock_rewards = ["Masterwork Creation Technique"]
	
	task.assignment_dialogue = "You've shown great progress. Now prepare for the ultimate test - creating a masterwork."
	task.completion_dialogue = "You are ready. Create your masterwork and take your place among the great artists."
	
	all_tasks[task.task_id] = task

func create_technique_mastery_task():
	"""Create the technique mastery task"""
	var task = TaskData.new("technique_mastery", "Master All Techniques", 
		"Demonstrate mastery across all artistic disciplines.")
	
	task.task_type = TaskData.TaskType.LEARNING
	task.difficulty = TaskData.TaskDifficulty.MASTER
	task.skill_requirements = {"painting": 6, "sketching": 6, "color_theory": 6, "crafting": 6, "gathering": 6, "observation": 6}
	task.prerequisite_tasks = ["masterwork_prep"]
	
	task.objectives = [
		{
			"id": "master_all_skills",
			"description": "Reach high levels in all artistic skills",
			"target": 6,
			"type": "skill_level_check"
		}
	]
	
	task.skill_rewards = {
		"painting": 150,
		"sketching": 150,
		"color_theory": 150,
		"crafting": 150,
		"gathering": 150,
		"observation": 150
	}
	
	task.reputation_reward = 100
	task.unlock_rewards = ["Master Artist Status", "All Advanced Techniques"]
	
	task.assignment_dialogue = "Few reach this level. Prove your mastery across all disciplines of art."
	task.completion_dialogue = "Incredible! You have achieved true mastery. You are no longer my apprentice, but my equal."
	
	all_tasks[task.task_id] = task

func get_available_tasks() -> Array:
	"""Get all tasks that are available to start"""
	var available = []
	
	for task_id in all_tasks:
		var task = all_tasks[task_id]
		if task.is_available():
			available.append(task)
	
	return available

func get_active_tasks() -> Array:
	"""Get all tasks currently in progress"""
	var active = []
	
	for task_id in all_tasks:
		var task = all_tasks[task_id]
		if task.status == TaskData.TaskStatus.IN_PROGRESS:
			active.append(task)
	
	return active

func get_completed_tasks() -> Array:
	"""Get all completed tasks"""
	var completed = []
	
	for task_id in all_tasks:
		var task = all_tasks[task_id]
		if task.status == TaskData.TaskStatus.COMPLETED:
			completed.append(task)
	
	return completed

func start_task(task_id: String) -> bool:
	"""Start a specific task"""
	if not all_tasks.has(task_id):
		return false
	
	var task = all_tasks[task_id]
	if task.start_task():
		active_tasks.append(task)
		task_assigned.emit(task)
		task_started.emit(task)
		return true
	
	return false

func update_task_progress(task_id: String, objective_id: String, amount: int = 1):
	"""Update progress on a task objective"""
	if not all_tasks.has(task_id):
		return
	
	var task = all_tasks[task_id]
	if task.status != TaskData.TaskStatus.IN_PROGRESS:
		return
	
	task.update_progress(objective_id, amount)
	task_progress_updated.emit(task, objective_id)
	
	# Check if task can be completed
	if task.can_complete():
		complete_task(task_id)

func complete_task(task_id: String) -> bool:
	"""Complete a specific task"""
	if not all_tasks.has(task_id):
		return false
	
	var task = all_tasks[task_id]
	if task.complete_task():
		# Remove from active tasks
		active_tasks.erase(task)
		completed_tasks.append(task_id)
		
		# Update player data
		if GameManager.player_data and not GameManager.player_data.completed_tasks.has(task_id):
			GameManager.player_data.completed_tasks.append(task_id)
		
		task_completed.emit(task)
		
		# Check for newly available tasks
		check_for_new_available_tasks()
		return true
	
	return false

func check_for_new_available_tasks():
	"""Check if any new tasks became available and emit signal if so"""
	var newly_available = false
	
	for task_id in all_tasks:
		var task = all_tasks[task_id]
		if task.status == TaskData.TaskStatus.NOT_STARTED and task.is_available():
			newly_available = true
			break
	
	if newly_available:
		new_tasks_available.emit()

func is_task_completed(task_id: String) -> bool:
	"""Check if a specific task is completed"""
	if not all_tasks.has(task_id):
		return false
	
	return all_tasks[task_id].status == TaskData.TaskStatus.COMPLETED

func get_task(task_id: String) -> TaskData:
	"""Get a specific task by ID"""
	return all_tasks.get(task_id, null)

func get_task_for_activity(activity_type: String, activity_data: Dictionary = {}) -> TaskData:
	"""Find a task that matches the given activity"""
	for task_id in all_tasks:
		var task = all_tasks[task_id]
		if task.status != TaskData.TaskStatus.IN_PROGRESS:
			continue
		
		# Check if this task has objectives that match the activity
		for objective in task.objectives:
			var obj_type = objective.get("type", "")
			if obj_type == activity_type:
				# Additional matching logic can be added here
				return task
	
	return null

# Activity tracking methods - called by other systems
func on_item_crafted(item_type: String, item_id: String):
	"""Called when player crafts an item"""
	for task_id in all_tasks:
		var task = all_tasks[task_id]
		if task.status != TaskData.TaskStatus.IN_PROGRESS:
			continue
		
		for objective in task.objectives:
			var obj_type = objective.get("type", "")
			var obj_id = objective.get("id", "")
			
			if obj_type == "craft_item" and objective.get("item_type", "") == item_type:
				update_task_progress(task_id, obj_id, 1)
			elif obj_type == "craft_different_colors" and item_type == "paint":
				# Special handling for color variety task
				update_task_progress(task_id, obj_id, 1)

func on_artwork_created(artwork: ArtworkData):
	"""Called when player creates an artwork"""
	for task_id in all_tasks:
		var task = all_tasks[task_id]
		if task.status != TaskData.TaskStatus.IN_PROGRESS:
			continue
		
		for objective in task.objectives:
			var obj_type = objective.get("type", "")
			var obj_id = objective.get("id", "")
			
			if obj_type == "create_artwork":
				update_task_progress(task_id, obj_id, 1)

func on_sketch_created(sketch_type: String, subject: String):
	"""Called when player creates a sketch"""
	for task_id in all_tasks:
		var task = all_tasks[task_id]
		if task.status != TaskData.TaskStatus.IN_PROGRESS:
			continue
		
		for objective in task.objectives:
			var obj_type = objective.get("type", "")
			var obj_id = objective.get("id", "")
			
			if obj_type == "create_sketch":
				update_task_progress(task_id, obj_id, 1)
			elif obj_type == "sketch_landmark" and sketch_type == "landmark":
				update_task_progress(task_id, obj_id, 1)

func on_resource_gathered(resource_type: String, is_rare: bool = false):
	"""Called when player gathers a resource"""
	for task_id in all_tasks:
		var task = all_tasks[task_id]
		if task.status != TaskData.TaskStatus.IN_PROGRESS:
			continue
		
		for objective in task.objectives:
			var obj_type = objective.get("type", "")
			var obj_id = objective.get("id", "")
			
			if obj_type == "gather_resource":
				update_task_progress(task_id, obj_id, 1)
			elif obj_type == "gather_rare_materials" and is_rare:
				update_task_progress(task_id, obj_id, 1)
