extends Node

## Step 8 Test Harness — MasterArtistAgent end-to-end validation
##
## Keys:
##   SPACE  — Ask the Master for a new AI task
##   R      — Register + start the last generated task with TaskManager
##   C      — Simulate crafting a paint (triggers craft_item objectives)
##   V      — Simulate crafting a canvas (triggers craft_item objectives)
##   A      — Simulate creating an artwork (triggers create_artwork objectives)
##   S      — Simulate completing a sketch (triggers create_sketch objectives)
##   G      — Simulate gathering a resource (triggers gather_resource objectives)
##   P      — Print current task progress summary
##   ESC    — Quit

var _last_generated_task: TaskData = null

func _ready():
	_print_header("STEP 8: MASTER ARTIST AGENT — TEST HARNESS")
	print("Controls:")
	print("  SPACE  — Ask Master for new AI task")
	print("  R      — Register + start the last generated task")
	print("  C      — Simulate craft PAINT (e.g. paint_red)")
	print("  V      — Simulate craft CANVAS (e.g. canvas_small)")
	print("  A      — Simulate create ARTWORK")
	print("  S      — Simulate complete SKETCH")
	print("  G      — Simulate GATHER resource")
	print("  P      — Print active task progress")
	print("  ESC    — Quit")
	print("")

	# Listen for progress and completion signals from TaskManager
	TaskManager.task_progress_updated.connect(_on_task_progress_updated)
	TaskManager.task_completed.connect(_on_task_completed)
	TaskManager.task_assigned.connect(_on_task_assigned)

	print("✅ Signal listeners connected.")
	print("Press SPACE to begin.\n")

func _input(event):
	if not (event is InputEventKey and event.pressed):
		return

	match event.keycode:
		KEY_SPACE:
			_ask_for_task()
		KEY_R:
			_register_and_start_task()
		KEY_C:
			_simulate_craft_paint()
		KEY_V:
			_simulate_craft_canvas()
		KEY_A:
			_simulate_create_artwork()
		KEY_S:
			_simulate_create_sketch()
		KEY_G:
			_simulate_gather_resource()
		KEY_P:
			_print_active_progress()
		KEY_ESCAPE:
			get_tree().quit()

# ── STEP 1: Generate a task ────────────────────────────────────────────────

func _ask_for_task():
	_print_header("ASKING MASTER FOR NEW TASK...")
	var task = await MasterArtistAgent.generate_task()

	if task == null:
		print("❌ No task returned. Is LM Studio running?")
		print("   → Open LM Studio, load Gemma 3, start Local Server, then try again.")
		print("   → Or: set MasterArtistAgent.ai_enabled = false for a fallback task.\n")
		return

	_last_generated_task = task

	_print_header("✅ TASK GENERATED — Press R to register it")
	print("ID          : %s" % task.task_id)
	print("Title       : %s" % task.title)
	print("Description : %s" % task.description)
	print("Type        : %d   Difficulty: %d" % [task.task_type, task.difficulty])
	print("")
	print("Assignment dialogue:")
	print("  \"%s\"" % task.assignment_dialogue)
	print("Completion dialogue:")
	print("  \"%s\"" % task.completion_dialogue)
	print("")

	if task.objectives.size() > 0:
		print("Objectives (%d):" % task.objectives.size())
		for i in range(task.objectives.size()):
			var obj = task.objectives[i]
			var extra = ""
			if obj.has("item_type"):
				extra = "  [item_type: %s]" % obj["item_type"]
			print("  %d. [%s] %s  (target: %d)%s" % [
				i + 1,
				obj.get("type", "?"),
				obj.get("description", "?"),
				obj.get("target", 0),
				extra
			])
	print("")

	if task.required_items.size() > 0:
		print("Required items: %s" % str(task.required_items))
	if task.skill_rewards.size() > 0:
		print("Skill rewards : %s" % str(task.skill_rewards))
	if task.item_rewards.size() > 0:
		print("Item rewards  : %s" % str(task.item_rewards))
	print("Reputation    : +%d" % task.reputation_reward)
	print("")

# ── STEP 2: Register the task ────────────────────────────────────────────

func _register_and_start_task():
	if _last_generated_task == null:
		print("⚠️  No task to register. Press SPACE first to generate one.\n")
		return

	_print_header("REGISTERING TASK WITH TASKMANAGER...")
	var registered = TaskManager.register_ai_task(_last_generated_task)
	if not registered:
		print("❌ Failed to register task.\n")
		return

	# register_ai_task may have changed the id — use the stored reference
	var task_id = _last_generated_task.task_id
	var started = TaskManager.start_task(task_id)
	if started:
		print("✅ Task '%s' is now IN PROGRESS." % task_id)
		_print_key_cheatsheet(_last_generated_task)
	else:
		print("⚠️  Task registered but could not be started (status: %d)." % _last_generated_task.status)
		print("   It may already be started or require prerequisites.\n")

func _print_key_cheatsheet(task: TaskData):
	# Map each objective type to its simulation key so the player knows what to press
	var key_map = {
		"craft_item":      {"paint": "C  (craft paint)", "canvas": "V  (craft canvas)", "": "C or V (craft item)"},
		"create_artwork":  {"": "A  (create artwork)"},
		"create_sketch":   {"": "S  (complete sketch)"},
		"gather_resource": {"": "G  (gather resource)"},
	}
	print("\n🎮 Keys to press for this task:")
	for obj in task.objectives:
		var obj_type     = obj.get("type", "?")
		var item_type    = obj.get("item_type", "")
		var target       = obj.get("target", 1)
		var description  = obj.get("description", "?")
		var type_keys    = key_map.get(obj_type, {})
		var key_hint     = type_keys.get(item_type, type_keys.get("", "? (unknown type: %s)" % obj_type))
		print("  → Press %s  ×%d   \"%s\"" % [key_hint, target, description])
	print("")

# ── STEP 3: Simulate objective completions ───────────────────────────────

func _simulate_craft_paint():
	print("🔨 Simulating: craft PAINT (item_type='paint', item_id='paint_red')")
	TaskManager.on_item_crafted("paint", "paint_red")

func _simulate_craft_canvas():
	print("🔨 Simulating: craft CANVAS (item_type='canvas', item_id='canvas_small')")
	TaskManager.on_item_crafted("canvas", "canvas_small")

func _simulate_create_artwork():
	print("🎨 Simulating: create ARTWORK")
	var dummy_artwork = ArtworkData.new()
	dummy_artwork.title = "Test Artwork"
	TaskManager.on_artwork_created(dummy_artwork)

func _simulate_create_sketch():
	print("✏️  Simulating: complete SKETCH (sketch_type='building', subject='duomo')")
	TaskManager.on_sketch_created("building", "duomo")

func _simulate_gather_resource():
	print("⛏️  Simulating: GATHER resource (resource_type='pigment_red')")
	TaskManager.on_resource_gathered("pigment_red", false)

# ── STEP 4: Print live progress ────────────────────────────────────────────

func _print_active_progress():
	var active = TaskManager.get_active_tasks()
	if active.size() == 0:
		print("ℹ️  No active tasks right now.\n")
		return

	_print_header("ACTIVE TASK PROGRESS")
	for task in active:
		print("Task: %s  [%s]" % [task.title, task.task_id])
		for obj in task.objectives:
			var obj_id  = obj.get("id", "")
			# current_progress is on the TaskData object, keyed by objective id
			var current = task.current_progress.get(obj_id, 0)
			var target  = obj.get("target", 1)
			var bar     = _progress_bar(current, target)
			print("  • %s" % obj.get("description", "?"))
			print("    %s  %d / %d" % [bar, current, target])
		print("")

func _progress_bar(current: int, target: int) -> String:
	var filled = clampi(current * 10 / maxi(target, 1), 0, 10)
	var bar = "[" + "█".repeat(filled) + "░".repeat(10 - filled) + "]"
	return bar

# ── Signal handlers ────────────────────────────────────────────────────────

func _on_task_assigned(task: TaskData):
	print("📋 Signal: task_assigned  → '%s'" % task.title)

func _on_task_progress_updated(task: TaskData, objective_id: String):
	var obj = _find_objective(task, objective_id)
	if obj:
		# current_progress is on the TaskData object, not inside the objective dict
		var current = task.current_progress.get(objective_id, 0)
		var target  = obj.get("target", 1)
		print("📈 Progress: [%s] '%s' — %d / %d" % [
			objective_id,
			obj.get("description", "?"),
			current, target
		])
	else:
		print("📈 Progress updated: task='%s'  objective='%s'" % [task.task_id, objective_id])

func _on_task_completed(task: TaskData):
	_print_header("🏆 TASK COMPLETED!")
	print("Task   : %s" % task.title)
	print("Rewards:")
	if task.skill_rewards.size() > 0:
		for skill in task.skill_rewards:
			print("  +%d XP  %s" % [task.skill_rewards[skill], skill])
	print("  +%d reputation" % task.reputation_reward)
	print("")
	print("Completion dialogue:")
	print("  \"%s\"\n" % task.completion_dialogue)

# ── Utility ────────────────────────────────────────────────────────────────

func _find_objective(task: TaskData, objective_id: String) -> Dictionary:
	for obj in task.objectives:
		if obj.get("id", "") == objective_id:
			return obj
	return {}

func _print_header(text: String):
	var line = "─".repeat(54)
	print("\n" + line)
	print("  " + text)
	print(line)
