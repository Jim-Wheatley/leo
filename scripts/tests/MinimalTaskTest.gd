extends Node

# Minimal test for task system - no UI, no complex dependencies

func _ready():
	print("=== MINIMAL TASK SYSTEM TEST ===")
	
	# Wait for singletons to initialize
	await get_tree().process_frame
	await get_tree().process_frame
	
	print("Testing basic task creation...")
	test_basic_task_creation()
	
	print("\n✅ Minimal task test completed successfully!")
	print("Press any key to exit...")

func test_basic_task_creation():
	"""Test creating a basic task without complex dependencies"""
	print("Creating a simple task...")
	
	var task = TaskData.new("test_task", "Test Task", "A simple test task")
	
	# Set up basic properties
	task.task_type = TaskData.TaskType.SKILL_PRACTICE
	task.difficulty = TaskData.TaskDifficulty.BEGINNER
	task.status = TaskData.TaskStatus.NOT_STARTED
	
	# Add a simple objective
	task.objectives.append({
		"id": "test_objective",
		"description": "Complete test objective",
		"target": 1,
		"type": "test"
	})
	
	# Add simple rewards
	task.skill_rewards["painting"] = 10
	task.reputation_reward = 5
	
	print("Task created: %s" % task.title)
	print("Objectives: %d" % task.objectives.size())
	print("Skill rewards: %s" % str(task.skill_rewards))
	
	# Test availability
	var is_available = task.is_available()
	print("Task available: %s" % is_available)
	
	# Test starting
	if task.start_task():
		print("Task started successfully")
		print("Status: %s" % TaskData.TaskStatus.keys()[task.status])
	else:
		print("Failed to start task")

func _input(event):
	if event.is_pressed():
		print("Exiting test...")
		get_tree().quit()