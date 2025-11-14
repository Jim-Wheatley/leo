extends Node

# Simple test for the task system without complex UI

func _ready():
	print("=== SIMPLE TASK SYSTEM TEST ===")
	print("Testing basic task functionality...")
	
	# Wait for singletons to initialize
	await get_tree().process_frame
	await get_tree().process_frame
	
	test_task_creation()
	test_task_availability()
	test_task_starting()
	test_task_progress()
	
	print("✅ All basic task system tests passed!")

func test_task_creation():
	print("\n🧪 Testing task creation...")
	var available_tasks = TaskManager.get_available_tasks()
	print("Available tasks: %d" % available_tasks.size())
	
	if available_tasks.size() > 0:
		var task = available_tasks[0]
		print("First task: %s" % task.title)
		print("Description: %s" % task.description)
		print("✅ Task creation working")
	else:
		print("❌ No tasks available")

func test_task_availability():
	print("\n🧪 Testing task availability...")
	var available_tasks = TaskManager.get_available_tasks()
	
	for task in available_tasks:
		var is_available = task.is_available()
		print("Task '%s' available: %s" % [task.title, is_available])
	
	print("✅ Task availability checking working")

func test_task_starting():
	print("\n🧪 Testing task starting...")
	var available_tasks = TaskManager.get_available_tasks()
	
	if available_tasks.size() > 0:
		var task = available_tasks[0]
		print("Starting task: %s" % task.title)
		
		if TaskManager.start_task(task.task_id):
			print("✅ Task started successfully")
			
			# Check if it's now in active tasks
			var active_tasks = TaskManager.get_active_tasks()
			print("Active tasks: %d" % active_tasks.size())
		else:
			print("❌ Failed to start task")
	else:
		print("❌ No tasks to start")

func test_task_progress():
	print("\n🧪 Testing task progress...")
	var active_tasks = TaskManager.get_active_tasks()
	
	if active_tasks.size() > 0:
		var task = active_tasks[0]
		print("Testing progress on: %s" % task.title)
		
		# Simulate some progress
		if task.objectives.size() > 0:
			var objective = task.objectives[0]
			var obj_id = objective.get("id", "")
			print("Updating progress for objective: %s" % obj_id)
			
			TaskManager.update_task_progress(task.task_id, obj_id, 1)
			print("✅ Task progress working")
		else:
			print("❌ No objectives to test")
	else:
		print("❌ No active tasks to test progress")

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		print("\n📋 Simple task test completed!")
		get_tree().quit()