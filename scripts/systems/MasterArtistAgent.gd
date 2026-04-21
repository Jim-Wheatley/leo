extends Node
## MasterArtistAgent - AI-powered task generation orchestrator
##
## This agent gathers game state context, calls the local LLM via LLMClient,
## validates the AI-generated JSON, and returns a TaskData object or null.

# Reference to the LLM client
var llm_client: LLMClient

# Set to false to skip the LLM entirely and use fallback dialogue.
# Useful when LM Studio is not running or you want to test without AI.
var ai_enabled: bool = true

# Set to true to see detailed step-by-step logs in the Godot Output panel.
var debug_mode: bool = true

func _ready():
	# Create and initialize the LLM client
	llm_client = LLMClient.new()
	add_child(llm_client)
	print("✅ MasterArtistAgent initialized")

## Main entry point: generate a new task for the player
func generate_task() -> TaskData:
	# --- AI toggle ---
	if not ai_enabled:
		print("[MasterArtistAgent] ⚠️  AI is DISABLED (ai_enabled = false). Returning null → fallback will show.")
		return null

	print("[MasterArtistAgent] ── Task generation START ─────────────────────────")

	# Step 1: Gather game state context
	var context = _build_game_context()

	# Step 2: Build the AI prompt
	var messages = _build_prompt_messages(context)

	# Step 3: Call the LLM
	var llm_response = await _call_llm(messages)

	# Step 4: Validate and parse the response
	if llm_response.ok:
		var task = _validate_and_parse_response(llm_response.content)
		if task:
			print("[MasterArtistAgent] ── Task generation COMPLETE ──────────────────────")
		else:
			print("[MasterArtistAgent] ── Task generation FAILED (validation) ──────────")
		return task
	else:
		print("[MasterArtistAgent] ── Task generation FAILED (LLM error) ─────────────")
		print("[MasterArtistAgent]    Error: %s" % llm_response.error)
		return null

# --- Private helper methods ---

func _build_game_context() -> Dictionary:
	"""Gather current game state to inform the LLM's task generation"""
	
	var context = {}
	
	# 1. Get skill levels
	context["skills"] = {
		"crafting": SkillManager.get_skill_level("crafting"),
		"painting": SkillManager.get_skill_level("painting"),
		"color_theory": SkillManager.get_skill_level("color_theory"),
		"sketching": SkillManager.get_skill_level("sketching"),
		"portfolio_management": SkillManager.get_skill_level("portfolio_management"),
		"gathering": SkillManager.get_skill_level("gathering")
	}
	
	# 2. Get inventory summary (only items with quantity > 0)
	context["inventory"] = {}
	var player_inventory = GameManager.player_data.inventory
	if player_inventory is Array:
		for item in player_inventory:
			if item is InventoryItem:
				var item_id = item.item_id
				var quantity = item.current_stack
				if quantity > 0:
					context["inventory"][item_id] = context["inventory"].get(item_id, 0) + quantity
	elif player_inventory is Dictionary:
		for item_id in player_inventory:
			var quantity = player_inventory[item_id]
			if quantity > 0:
				context["inventory"][item_id] = quantity
	
	# 3. Get recent task history
	var completed_tasks = GameManager.player_data.completed_tasks
	context["completed_task_count"] = completed_tasks.size()
	# Just send the IDs of the last 5 completed tasks
	var start_index = maxi(0, completed_tasks.size() - 5)
	context["recent_completed_tasks"] = completed_tasks.slice(start_index, completed_tasks.size())
	
	# 4. Get active tasks
	var active_tasks = TaskManager.get_active_tasks()
	context["active_task_ids"] = []
	for task in active_tasks:
		context["active_task_ids"].append(task.task_id)
	
	# 5. Get relationship score (optional but adds flavor)
	context["master_relationship"] = GameManager.player_data.master_relationship
	
	if debug_mode:
		print("📊 Game Context Built:")
		print("  Skills: ", context["skills"])
		print("  Inventory items: ", context["inventory"].size())
		print("  Completed tasks: ", context["completed_task_count"])
		print("  Active tasks: ", context["active_task_ids"].size())
		print("  Relationship: ", context["master_relationship"])
	
	return context

func _build_prompt_messages(context: Dictionary) -> Array:
	"""Construct the LLM prompt with system persona, developer constraints, and user context"""
	
	# Message 1: System - Define the AI's persona
	var system_message = {
		"role": "system",
		"content": """You are a Renaissance master artist and mentor. You are wise, encouraging, and have high standards. 
You assign tasks to your apprentice that challenge them appropriately based on their skills and materials.
Your tasks should feel authentic to Renaissance art apprenticeship - focused on fundamentals, materials, and gradual mastery."""
	}
	
	# Message 2: Developer - Define strict rules and JSON format
	var developer_message = {
		"role": "developer",
		"content": _get_json_contract_instructions()
	}
	
	# Message 3: User - Provide current game state
	var user_message = {
		"role": "user",
		"content": _format_context_for_prompt(context)
	}
	
	var messages = [system_message, developer_message, user_message]
	
	if debug_mode:
		print("📝 Prompt Messages Built:")
		print("  System: %d chars" % system_message["content"].length())
		print("  Developer: %d chars" % developer_message["content"].length())
		print("  User: %d chars" % user_message["content"].length())
	
	return messages

func _get_json_contract_instructions() -> String:
	"""Return the strict JSON format and constraints"""
	return """You must respond with ONLY a valid JSON object. No explanation, no markdown, no code blocks — just the raw JSON.

STRICT RULES:
1. task_type must be exactly one of: SKILL_PRACTICE, CRAFTING, GATHERING, EXPLORATION, ARTWORK_CREATION, LEARNING
2. difficulty must be exactly one of: BEGINNER, APPRENTICE, JOURNEYMAN, EXPERT, MASTER
3. Use ONLY these item IDs (do NOT invent new ones): %s
4. Use ONLY these skill names: crafting, painting, color_theory, sketching, portfolio_management, gathering
5. Objectives: minimum 1, maximum 3
6. required_items MUST be a JSON object (dictionary) — keys are item ID strings, values are integer quantities.
   CORRECT:   "required_items": {"pigment_red": 2, "binding_agent": 1}
   WRONG:     "required_items": [{"item_id": "pigment_red", "quantity": 2}]
7. item_rewards MUST be a JSON array of objects, each with exactly "item_id" (string) and "quantity" (integer).
   CORRECT:   "item_rewards": [{"item_id": "paint_red", "quantity": 1}]
   WRONG:     "item_rewards": [{"item_id": "paint_red", 1}]
8. Target values: 1-5 (keep goals achievable)
9. Skill rewards: 10-100 per skill, maximum 3 skills rewarded
10. item_rewards: maximum 3 entries
11. Reputation reward: 0-20
12. task_id must be unique and descriptive (e.g. "task_mix_red_pigment")

OBJECTIVE TYPES — use ONLY these four. Each has a required extra field:
  "craft_item"     — player crafts something. Add "item_type": "paint" OR "item_type": "canvas" to the objective.
  "create_artwork" — player creates an artwork at the artwork station. No extra fields needed.
  "create_sketch"  — player completes sketches. No extra fields needed.
  "gather_resource"— player gathers materials from gathering nodes. No extra fields needed.

COMPLETE EXAMPLE — copy this structure exactly:
{
  "task_id": "task_mix_red_pigment",
  "title": "Mix Your First Red Paint",
  "description": "Practice mixing pigment with binding agent to produce red paint.",
  "task_type": "CRAFTING",
  "difficulty": "BEGINNER",
  "required_items": {"pigment_red": 2, "binding_agent": 1},
  "objectives": [
    {"id": "obj_1", "description": "Create red paint at the paint station", "target": 2, "type": "craft_item", "item_type": "paint"}
  ],
  "skill_rewards": {"crafting": 25, "color_theory": 15},
  "item_rewards": [{"item_id": "paint_red", "quantity": 1}],
  "reputation_reward": 5,
  "assignment_dialogue": "Begin with the red pigment — mix it carefully with the binding agent.",
  "completion_dialogue": "Excellent. You have produced your first red paint. Consistency is the mark of a craftsman."
}""" % [_get_allowed_item_ids()]

func _get_allowed_item_ids() -> String:
	"""Return comma-separated list of valid item IDs"""
	var items = [
		"pigment_red", "pigment_blue", "pigment_yellow", "pigment_green",
		"paint_red", "paint_blue", "paint_yellow", "paint_green", "paint_white", "paint_black",
		"canvas_small", "canvas_medium",
		"binding_agent", "wood_frame", "canvas_fabric"
	]
	return ", ".join(items)

func _format_context_for_prompt(context: Dictionary) -> String:
	"""Format the game context into natural language for the LLM"""
	var prompt = "Generate a new task for my apprentice.\n\n"
	
	prompt += "APPRENTICE STATUS:\n"
	prompt += "Skills: "
	for skill in context["skills"]:
		prompt += "%s (level %d), " % [skill, context["skills"][skill]]
	prompt += "\n\n"
	
	prompt += "Inventory: "
	if context["inventory"].size() > 0:
		for item_id in context["inventory"]:
			prompt += "%s x%d, " % [item_id, context["inventory"][item_id]]
	else:
		prompt += "(empty)"
	prompt += "\n\n"
	
	prompt += "Completed %d tasks so far.\n" % context["completed_task_count"]
	
	if context["active_task_ids"].size() > 0:
		prompt += "Currently working on: %s\n" % ", ".join(context["active_task_ids"])
	
	prompt += "Master relationship: %d/100\n\n" % context["master_relationship"]
	
	prompt += "Based on this, create ONE appropriate task. Consider their skill levels and available materials."
	
	return prompt

func _call_llm(messages: Array) -> Dictionary:
	"""Call the LLM and return the response or error"""
	
	var start_time = Time.get_ticks_msec()
	print("[MasterArtistAgent] → REQUEST SENT  endpoint=%s  max_tokens=800" % (LLMClient.BASE_URL + LLMClient.ENDPOINT))

	# Request more tokens for task generation (we need complete JSON)
	var response = await llm_client.call_completions(messages, 800)

	var elapsed_ms = Time.get_ticks_msec() - start_time
	if response.ok:
		print("[MasterArtistAgent] ← RESPONSE OK   %.1fs  %d chars" % [elapsed_ms / 1000.0, response.content.length()])
		if debug_mode:
			var preview = response.content.substr(0, 300)
			if response.content.length() > 300:
				preview += "..."
			print("[MasterArtistAgent]   Preview: %s" % preview)
	else:
		print("[MasterArtistAgent] ← RESPONSE FAIL  %.1fs  error: %s" % [elapsed_ms / 1000.0, response.error])

	return response

func _sanitize_json_string(raw: String) -> String:
	"""Fix common LLM formatting mistakes before JSON.parse_string() is called.

	Known Gemma 3 failure mode:
	  The model writes  {"item_id": "pigment_red", 1}
	  instead of       {"item_id": "pigment_red", "quantity": 1}
	  The bare integer after the comma makes the JSON unparseable.
	  We detect that pattern and insert the missing "quantity": key.
	"""
	var regex = RegEx.new()
	# Match: "item_id": "some_id",   N  }
	#         ─ string key ─────────  ↑ bare number without a key
	var err = regex.compile('"item_id":\\s*"([^"]+)",\\s*(\\d+)\\s*\\}')
	if err != OK:
		if debug_mode:
			print("⚠️ Sanitiser regex failed to compile (skipping)")
		return raw

	var fixed = regex.sub(raw, '"item_id": "$1", "quantity": $2}', true)
	if fixed != raw and debug_mode:
		print("🔧 Sanitiser: repaired bare-number syntax in item objects")
	return fixed

func _validate_and_parse_response(content: String) -> TaskData:
	"""Parse JSON response and validate it matches our contract"""

	print("[MasterArtistAgent] ↳ VALIDATE  raw length=%d chars" % content.length())

	# --- Step 0a: Strip markdown fences (some models wrap output in ```json) ---
	if content.begins_with("```json"):
		content = content.trim_prefix("```json")
	if content.begins_with("```"):
		content = content.trim_prefix("```")
	if content.ends_with("```"):
		content = content.trim_suffix("```")
	content = content.strip_edges()

	# --- Step 0b: Repair common JSON syntax mistakes before parsing ---
	content = _sanitize_json_string(content)

	# --- Step 1: Parse JSON ---
	var json_result = JSON.parse_string(content)
	if json_result == null:
		if debug_mode:
			print("❌ Invalid JSON received (could not parse even after sanitising)")
			print("Raw content: %s" % content)
		return null

	# --- Step 1b: Convert required_items array → dict if the model used the wrong format ---
	# Correct:  "required_items": {"pigment_red": 2}
	# Wrong:    "required_items": [{"item_id": "pigment_red", "quantity": 2}]
	if json_result.has("required_items") and json_result["required_items"] is Array:
		var converted: Dictionary = {}
		for entry in json_result["required_items"]:
			if entry is Dictionary and entry.has("item_id"):
				var qty = int(entry.get("quantity", entry.get("count", 1)))
				converted[entry["item_id"]] = qty
		json_result["required_items"] = converted
		if debug_mode:
			print("🔧 Sanitiser: converted required_items array → dict: %s" % str(converted))
	
	# Step 2: Validate required fields exist
	var required_fields = [
		"task_id", "title", "description", "task_type", "difficulty",
		"objectives", "skill_rewards", "assignment_dialogue", "completion_dialogue"
	]
	
	for field in required_fields:
		if not json_result.has(field):
			if debug_mode:
				print("❌ Missing required field: %s" % field)
			return null
	
	# Step 3: Validate task_type
	var valid_types = ["SKILL_PRACTICE", "CRAFTING", "GATHERING", "EXPLORATION", "ARTWORK_CREATION", "LEARNING"]
	if not json_result["task_type"] in valid_types:
		if debug_mode:
			print("❌ Invalid task_type: %s" % json_result["task_type"])
		return null
	
	# Step 4: Validate difficulty
	var valid_difficulties = ["BEGINNER", "APPRENTICE", "JOURNEYMAN", "EXPERT", "MASTER"]
	if not json_result["difficulty"] in valid_difficulties:
		if debug_mode:
			print("❌ Invalid difficulty: %s" % json_result["difficulty"])
		return null
	
	# Step 5: Validate objectives
	if not json_result["objectives"] is Array or json_result["objectives"].size() == 0:
		if debug_mode:
			print("❌ Objectives must be a non-empty array")
		return null
	
	if json_result["objectives"].size() > 3:
		if debug_mode:
			print("⚠️ Too many objectives (%d), truncating to 3" % json_result["objectives"].size())
		json_result["objectives"] = json_result["objectives"].slice(0, 3)
	
	# Step 6: Sanitise item IDs — strip unrecognised ones rather than rejecting
	#          the whole task. The AI sometimes hallucinates item names (e.g. "azurite").
	var allowed_items = _get_allowed_items_array()

	# Sanitise required_items: remove any keys that aren't in our allowed list
	if json_result.has("required_items") and json_result["required_items"] is Dictionary:
		var clean_required: Dictionary = {}
		for item_id in json_result["required_items"].keys():
			if item_id in allowed_items:
				clean_required[item_id] = json_result["required_items"][item_id]
			elif debug_mode:
				print("⚠️ Stripped unknown required_item: '%s' (not in game)" % item_id)
		json_result["required_items"] = clean_required

	# Sanitise item_rewards: remove entries whose item_id isn't in our allowed list
	if json_result.has("item_rewards") and json_result["item_rewards"] is Array:
		var clean_rewards: Array = []
		for reward in json_result["item_rewards"]:
			if reward.has("item_id") and reward["item_id"] in allowed_items:
				clean_rewards.append(reward)
			elif reward.has("item_id") and debug_mode:
				print("⚠️ Stripped unknown item_reward: '%s' (not in game)" % reward["item_id"])
		json_result["item_rewards"] = clean_rewards
	
	# If we got here, it's valid!
	if debug_mode:
		print("✅ Validation passed!")
		print("  Task: %s" % json_result["title"])
		print("  Type: %s, Difficulty: %s" % [json_result["task_type"], json_result["difficulty"]])
		print("  Objectives: %d" % json_result["objectives"].size())

	# Step 5: Convert validated JSON into a fully populated TaskData object
	var task = _json_to_task_data(json_result)

	# Keep raw JSON attached for debugging purposes
	task.set_meta("raw_json", json_result)

	return task

func _get_allowed_items_array() -> Array:
	"""Return array of valid item IDs for validation"""
	return [
		"pigment_red", "pigment_blue", "pigment_yellow", "pigment_green",
		"paint_red", "paint_blue", "paint_yellow", "paint_green", "paint_white", "paint_black",
		"canvas_small", "canvas_medium",
		"binding_agent", "wood_frame", "canvas_fabric"
	]

func _json_to_task_data(json_result: Dictionary) -> TaskData:
	"""Convert a validated JSON dictionary into a fully populated TaskData object."""

	# Create the base task with id, title, and description
	var task = TaskData.new(json_result["task_id"], json_result["title"], json_result["description"])

	# --- Map task_type string → TaskData.TaskType enum ---
	# The AI sends us a plain text string like "CRAFTING".
	# Godot needs the matching integer value from the enum instead.
	var type_map = {
		"SKILL_PRACTICE":   TaskData.TaskType.SKILL_PRACTICE,
		"CRAFTING":         TaskData.TaskType.CRAFTING,
		"GATHERING":        TaskData.TaskType.GATHERING,
		"EXPLORATION":      TaskData.TaskType.EXPLORATION,
		"ARTWORK_CREATION": TaskData.TaskType.ARTWORK_CREATION,
		"LEARNING":         TaskData.TaskType.LEARNING
	}
	task.task_type = type_map.get(json_result["task_type"], TaskData.TaskType.SKILL_PRACTICE)

	# --- Map difficulty string → TaskData.TaskDifficulty enum ---
	var difficulty_map = {
		"BEGINNER":    TaskData.TaskDifficulty.BEGINNER,
		"APPRENTICE":  TaskData.TaskDifficulty.APPRENTICE,
		"JOURNEYMAN":  TaskData.TaskDifficulty.JOURNEYMAN,
		"EXPERT":      TaskData.TaskDifficulty.EXPERT,
		"MASTER":      TaskData.TaskDifficulty.MASTER
	}
	task.difficulty = difficulty_map.get(json_result["difficulty"], TaskData.TaskDifficulty.BEGINNER)

	# --- Fill objectives ---
	# Each objective is a Dictionary: {id, description, target, type}
	task.objectives = json_result.get("objectives", [])

	# --- Fill required items ---
	# Dictionary: {item_id: quantity}  e.g. {"pigment_red": 2}
	if json_result.get("required_items") is Dictionary:
		task.required_items = json_result["required_items"]

	# --- Fill skill rewards ---
	# Dictionary: {skill_name: xp_amount}  e.g. {"painting": 50}
	if json_result.get("skill_rewards") is Dictionary:
		task.skill_rewards = json_result["skill_rewards"]

	# --- Fill item rewards ---
	# Array of Dictionaries: [{item_id: String, quantity: int}]
	if json_result.get("item_rewards") is Array:
		task.item_rewards = json_result["item_rewards"]

	# --- Fill reputation reward ---
	task.reputation_reward = int(json_result.get("reputation_reward", 0))

	# --- Fill dialogue lines ---
	task.assignment_dialogue = json_result.get("assignment_dialogue", "")
	task.completion_dialogue = json_result.get("completion_dialogue", "")

	if debug_mode:
		print("📦 TaskData built:")
		print("  task_type  = %d (%s)" % [task.task_type, json_result["task_type"]])
		print("  difficulty = %d (%s)" % [task.difficulty, json_result["difficulty"]])
		print("  objectives = %d" % task.objectives.size())
		print("  required_items = %s" % str(task.required_items))
		print("  skill_rewards  = %s" % str(task.skill_rewards))
		print("  item_rewards   = %d" % task.item_rewards.size())
		print("  reputation_reward = %d" % task.reputation_reward)

	return task
