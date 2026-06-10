# Step 4: MasterArtistAgent Orchestrator - Complete Beginner's Guide

## What You'll Build

You're going to create a "brain" for your Master Artist NPC that can use AI to generate custom tasks. Think of it like adding a smart assistant that:
1. **Looks at** what the player has (inventory, skills, etc.)
2. **Thinks** about what task would be good for them (using AI)
3. **Creates** a valid task that fits your game's rules

This is called an **orchestrator** because it coordinates multiple parts of your game system.

---

## Core Concepts Explained

### What is an Orchestrator?

An **orchestrator** is like a conductor of an orchestra - it doesn't play all the instruments itself, but it brings them together at the right time. Your `MasterArtistAgent` will:
- Gather information from different game systems (SkillManager, Inventory, TaskManager)
- Package that information for the AI
- Send it to the AI (via LLMClient)
- Check if the AI's response is valid
- Return the result

### What is Context?

**Context** is everything the AI needs to know to make a good decision. It's like giving someone background information before asking them a question. 

For example, if you tell the AI:
- "Player has 5 red pigments and 3 blue pigments"
- "Player's painting skill is level 3"
- "Player just completed the 'Basic Colors' task"

Then the AI can suggest a logical next task, like "Mix these pigments to create purple paint."

Without context, the AI might suggest tasks that are impossible (like "use the orange pigment" when the player doesn't have any).

### What is Validation?

**Validation** means checking if something is correct and safe to use. When the AI generates a task, you need to verify:
- Does it use only valid item IDs from your game?
- Does it use only valid task types?
- Are the numbers reasonable (not asking for 1000 items)?

This prevents the AI from "hallucinating" - making up things that don't exist in your game.

---

## Step-by-Step Implementation

### STEP 4.1: Create the MasterArtistAgent Script File

**What you're doing:** Creating a new GDScript file that will contain all the logic.

**How to do it:**

1. In Godot, navigate to `scripts/systems/` in the FileSystem panel
2. Right-click on the `systems` folder
3. Select "Create New" → "Script"
4. Name it: `MasterArtistAgent.gd`
5. Delete any template code Godot adds

**Or** use the command line:
```bash
touch scripts/systems/MasterArtistAgent.gd
```

---

### STEP 4.2: Set Up the Basic Script Structure

**What you're doing:** Creating the skeleton of your script with the essential parts.

**Copy this code** into `MasterArtistAgent.gd`:

```gdscript
extends Node
## MasterArtistAgent - AI-powered task generation orchestrator
##
## This agent gathers game state context, calls the local LLM via LLMClient,
## validates the AI-generated JSON, and returns a TaskData object or null.

class_name MasterArtistAgent

# Reference to the LLM client
var llm_client: LLMClient

# Debug flag (set to true to see detailed logs)
var debug_mode: bool = true

func _ready():
	# Create and initialize the LLM client
	llm_client = LLMClient.new()
	add_child(llm_client)
	print("✅ MasterArtistAgent initialized")

## Main entry point: generate a new task for the player
func generate_task() -> TaskData:
	if debug_mode:
		print("🎨 MasterArtistAgent: Starting task generation...")
	
	# Step 1: Gather game state context
	var context = _build_game_context()
	
	# Step 2: Build the AI prompt
	var messages = _build_prompt_messages(context)
	
	# Step 3: Call the LLM
	var llm_response = await _call_llm(messages)
	
	# Step 4: Validate and parse the response
	if llm_response.ok:
		var task = _validate_and_parse_response(llm_response.content)
		return task
	else:
		if debug_mode:
			print("❌ LLM call failed: %s" % llm_response.error)
		return null

# --- Private helper methods (we'll implement these next) ---

func _build_game_context() -> Dictionary:
	# TODO: Implement this in Step 4.3
	return {}

func _build_prompt_messages(context: Dictionary) -> Array:
	# TODO: Implement this in Step 4.4
	return []

func _call_llm(messages: Array) -> Dictionary:
	# TODO: Implement this in Step 4.5
	return {}

func _validate_and_parse_response(content: String) -> TaskData:
	# TODO: Implement this in Step 4.6
	return null
```

**What this does:**
- `class_name MasterArtistAgent` - Lets other scripts reference this by name
- `llm_client` - Stores a reference to your LLM client from Step 2
- `debug_mode` - When true, prints helpful information to the console
- `generate_task()` - The main function that other parts of your game will call
- Helper methods with `TODO` - We'll fill these in next

**Save the file** (Ctrl+S or Cmd+S)

---

### STEP 4.3: Implement `_build_game_context()`

**What you're doing:** Collecting information about the player's current state to give to the AI.

**Why this matters:** The AI needs to know what the player has and can do, so it doesn't suggest impossible tasks.

**Replace the empty `_build_game_context()` function** with this:

```gdscript
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
	for item_id in player_inventory:
		var quantity = player_inventory[item_id]
		if quantity > 0:
			context["inventory"][item_id] = quantity
	
	# 3. Get recent task history
	var completed_tasks = GameManager.player_data.completed_tasks
	context["completed_task_count"] = completed_tasks.size()
	# Just send the IDs of the last 5 completed tasks
	context["recent_completed_tasks"] = completed_tasks.slice(-5, completed_tasks.size())
	
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
```

**What this does:**
- **Skills**: Gets all 6 skill levels from SkillManager
- **Inventory**: Creates a dictionary of items the player has (only non-zero quantities)
- **Task History**: Shows what tasks were recently completed (to avoid repeats)
- **Active Tasks**: Shows what the player is currently working on
- **Relationship**: The player's relationship score with the Master (0-100)

**Key Learning:** Notice how we're calling existing systems (`SkillManager`, `GameManager`, `TaskManager`). The orchestrator doesn't store data itself - it just gathers it from the right places.

---

### STEP 4.4: Implement `_build_prompt_messages()`

**What you're doing:** Creating the instructions for the AI in a specific format.

**Why this matters:** The AI needs clear instructions on who it is, what it should do, and what rules to follow.

**Replace the empty `_build_prompt_messages()` function** with this:

```gdscript
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
```

**What this does:**
- Creates 3 messages in the format the OpenAI API expects
- **System**: Tells the AI it's a Renaissance master (gives it personality)
- **Developer**: Tells the AI the technical rules it must follow
- **User**: Gives the AI the current game state

**Now add these two helper functions** (add them below `_build_prompt_messages`):

```gdscript
func _get_json_contract_instructions() -> String:
	"""Return the strict JSON format and constraints"""
	return """You must respond with ONLY valid JSON. No explanation, no markdown, no code blocks.

STRICT RULES:
1. task_type must be one of: SKILL_PRACTICE, CRAFTING, GATHERING, EXPLORATION, ARTWORK_CREATION, LEARNING
2. difficulty must be one of: BEGINNER, APPRENTICE, JOURNEYMAN, EXPERT, MASTER
3. Use ONLY these item IDs: %s
4. Use ONLY these skill names: crafting, painting, color_theory, sketching, portfolio_management, gathering
5. Objective types: craft_item, create_artwork, gather_item, explore_location, skill_practice, learn_technique
6. Objectives: minimum 1, maximum 3
7. Required items: maximum 5 items, quantities 1-5 each
8. Target values: 1-5 (keep goals achievable)
9. Skill rewards: 10-100 per skill
10. Item rewards: maximum 3 items
11. Reputation reward: 0-20
12. task_id must be unique (use descriptive names like "task_red_paint_basics")

JSON Format:
{
  "task_id": "unique_id_here",
  "title": "Task Title (5-10 words)",
  "description": "Brief description (1-2 sentences)",
  "task_type": "TASK_TYPE",
  "difficulty": "DIFFICULTY",
  "required_items": {"item_id": 1},
  "objectives": [{"id": "obj_1", "description": "Do something", "target": 1, "type": "objective_type"}],
  "skill_rewards": {"skill_name": 25},
  "item_rewards": [{"item_id": "item_id", "quantity": 1}],
  "reputation_reward": 5,
  "assignment_dialogue": "What I say when giving this task",
  "completion_dialogue": "What I say when you complete it"
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
```

**What this does:**
- `_get_json_contract_instructions()`: Returns a big string with ALL the rules from Step 3
- `_get_allowed_item_ids()`: Lists the 15 items the AI can use
- `_format_context_for_prompt()`: Converts the context dictionary into readable text

**Key Learning:** We're being very explicit with the AI. We tell it exactly what it can and cannot do. This is crucial for getting reliable results.

---

### STEP 4.5: Implement `_call_llm()`

**What you're doing:** Sending the messages to your LLM and waiting for a response.

**Why this matters:** This is where your game talks to the AI server you set up in Step 1.

**Replace the empty `_call_llm()` function** with this:

```gdscript
func _call_llm(messages: Array) -> Dictionary:
	"""Call the LLM and return the response or error"""
	
	if debug_mode:
		print("🤖 Calling LLM...")
		print("  Endpoint: %s" % (LLMClient.BASE_URL + LLMClient.ENDPOINT))
	
	# Request more tokens for task generation (we need complete JSON)
	var response = await llm_client.call_completions(messages, 800)
	
	if response.ok:
		if debug_mode:
			print("✅ LLM Response Received:")
			print("  Length: %d characters" % response.content.length())
			# Print first 200 chars as preview
			var preview = response.content.substr(0, 200)
			if response.content.length() > 200:
				preview += "..."
			print("  Preview: %s" % preview)
	else:
		if debug_mode:
			print("❌ LLM Call Failed:")
			print("  Error: %s" % response.error)
	
	return response
```

**What this does:**
- Calls `llm_client.call_completions()` (from Step 2)
- Uses `await` because the call takes time (it's **asynchronous**)
- Requests 800 tokens (enough for a complete task JSON)
- Prints helpful debug info so you can see what's happening

**Key Learning:** The `await` keyword means "wait for this to finish before continuing." Without it, your code would try to use the response before it arrived.

---

### STEP 4.6: Implement `_validate_and_parse_response()`

**What you're doing:** Checking if the AI's response is valid and converting it to a TaskData object.

**Why this matters:** The AI can make mistakes or hallucinate. You need to catch these before they break your game.

**Replace the empty `_validate_and_parse_response()` function** with this:

```gdscript
func _validate_and_parse_response(content: String) -> TaskData:
	"""Parse JSON response and validate it matches our contract"""
	
	if debug_mode:
		print("🔍 Validating AI response...")
	
	# Step 1: Parse JSON
	var json_result = JSON.parse_string(content)
	if json_result == null:
		if debug_mode:
			print("❌ Invalid JSON received")
		return null
	
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
	
	# Step 6: Validate item IDs
	var allowed_items = _get_allowed_items_array()
	
	# Check required_items
	if json_result.has("required_items") and json_result["required_items"] is Dictionary:
		for item_id in json_result["required_items"].keys():
			if not item_id in allowed_items:
				if debug_mode:
					print("❌ Invalid item in required_items: %s" % item_id)
				return null
	
	# Check item_rewards
	if json_result.has("item_rewards") and json_result["item_rewards"] is Array:
		for reward in json_result["item_rewards"]:
			if reward.has("item_id") and not reward["item_id"] in allowed_items:
				if debug_mode:
					print("❌ Invalid item in rewards: %s" % reward["item_id"])
				return null
	
	# If we got here, it's valid!
	if debug_mode:
		print("✅ Validation passed!")
		print("  Task: %s" % json_result["title"])
		print("  Type: %s, Difficulty: %s" % [json_result["task_type"], json_result["difficulty"]])
		print("  Objectives: %d" % json_result["objectives"].size())
	
	# Note: We'll convert this to a TaskData object in Step 5
	# For now, just store the raw JSON in a temporary format
	var temp_task = TaskData.new(json_result["task_id"], json_result["title"], json_result["description"])
	temp_task.assignment_dialogue = json_result["assignment_dialogue"]
	temp_task.completion_dialogue = json_result["completion_dialogue"]
	
	return temp_task

func _get_allowed_items_array() -> Array:
	"""Return array of valid item IDs for validation"""
	return [
		"pigment_red", "pigment_blue", "pigment_yellow", "pigment_green",
		"paint_red", "paint_blue", "paint_yellow", "paint_green", "paint_white", "paint_black",
		"canvas_small", "canvas_medium",
		"binding_agent", "wood_frame", "canvas_fabric"
	]
```

**What this does:**
- **Step 1**: Tries to parse the AI's response as JSON
- **Step 2**: Checks that all required fields are present
- **Step 3**: Validates the task_type is one of the allowed types
- **Step 4**: Validates the difficulty is one of the allowed levels
- **Step 5**: Checks objectives array is valid (1-3 items)
- **Step 6**: Checks all item IDs are in the allowed list
- **Final**: If everything is valid, creates a temporary TaskData object

**Key Learning:** Validation is like a security guard checking IDs. If anything looks wrong, we reject it and return `null` rather than letting bad data into our game.

---

### STEP 4.7: Register the Agent as an Autoload Singleton

**What you're doing:** Making MasterArtistAgent available everywhere in your game.

**Why this matters:** This lets any part of your game call `MasterArtistAgent.generate_task()` without needing to create a new instance.

**How to do it:**

1. In Godot, go to **Project → Project Settings**
2. Click on the **Autoload** tab
3. Click the folder icon and navigate to `res://scripts/systems/MasterArtistAgent.gd`
4. In the "Node Name" field, type: `MasterArtistAgent`
5. Click **Add**
6. Click **Close**

**What happened:** Now `MasterArtistAgent` is available globally, just like `GameManager`, `TaskManager`, and `SkillManager`.

---

### STEP 4.8: Test Your Agent

**What you're doing:** Creating a simple test to verify the agent works.

**Create a test script** at `scripts/tests/test_master_artist_agent.gd`:

```gdscript
extends Node

## Simple test script for MasterArtistAgent
## Attach this to a test scene and press Space to generate a task

func _ready():
	print("🧪 MasterArtistAgent Test Ready")
	print("Press SPACE to generate a task")

func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		print("\n" + "=".repeat(50))
		print("🎨 Testing MasterArtistAgent...")
		print("=".repeat(50) + "\n")
		
		test_task_generation()

func test_task_generation():
	"""Test generating a task"""
	var task = await MasterArtistAgent.generate_task()
	
	if task:
		print("\n✅ SUCCESS! Generated task:")
		print("  ID: %s" % task.task_id)
		print("  Title: %s" % task.title)
		print("  Description: %s" % task.description)
		print("  Assignment: %s" % task.assignment_dialogue)
		print("  Completion: %s" % task.completion_dialogue)
	else:
		print("\n❌ FAILED: No task generated")
		print("  Check console for error messages")
		print("  Is LM Studio running?")
		print("  Did you load a model?")
```

**How to use this test:**

1. Create a new test scene: **Scene → New Scene**
2. Add a Node as the root and name it "MasterArtistAgentTest"
3. Attach the test script to it
4. Save the scene as `scenes/tests/MasterArtistAgentTest.tscn`
5. Run the scene (F6)
6. **Make sure LM Studio is running with a model loaded**
7. Press **Space** to generate a task
8. Watch the console for debug output

**What to look for:**
- ✅ "MasterArtistAgent initialized"
- ✅ "Game Context Built" with your player's stats
- ✅ "Prompt Messages Built"
- ✅ "Calling LLM..."
- ✅ "LLM Response Received"
- ✅ "Validation passed!"
- ✅ Task details printed

**If it fails:**
- Check that LM Studio is running (look for "http://localhost:1234")
- Check that you've loaded a model in LM Studio
- Check the console for error messages
- Try the debug_mode to see detailed logs

---

## Testing Checklist

Before moving on to Step 5, verify:

- [ ] `MasterArtistAgent.gd` exists in `scripts/systems/`
- [ ] The script has no syntax errors (check Godot's bottom panel)
- [ ] MasterArtistAgent is registered as an Autoload
- [ ] The test scene runs without crashes
- [ ] LM Studio local server is running
- [ ] Pressing Space in the test scene calls the LLM
- [ ] You can see debug output in the console
- [ ] The AI returns valid JSON (even if not perfect yet)

---

## Common Issues and Solutions

### Issue 1: "Failed to send request"
**Problem:** The LLM client can't connect to LM Studio.

**Solutions:**
- Start LM Studio
- Make sure the local server is enabled (green ✅ in LM Studio)
- Check that the URL is `http://localhost:1234` or `http://127.0.0.1:1234`
- Try accessing `http://localhost:1234/v1/models` in your web browser

### Issue 2: "Invalid JSON received"
**Problem:** The AI returned text that isn't proper JSON.

**Solutions:**
- The model might be adding markdown code blocks (```json)
- Try adding logic to strip markdown formatting:
  ```gdscript
  # In _validate_and_parse_response, before parsing:
  if content.begins_with("```json"):
      content = content.trim_prefix("```json")
  if content.ends_with("```"):
      content = content.trim_suffix("```")
  content = content.strip_edges()
  ```
- Try adjusting the temperature in `LLMClient.gd` (lower = more consistent, try 0.5)
- Try a different model (some are better at following JSON format)

### Issue 3: "Missing required field"
**Problem:** The AI didn't include all necessary fields.

**Solutions:**
- The prompt might be too complex
- Try making the `_get_json_contract_instructions()` more concise
- Add an example JSON output to the prompt
- Try increasing max_tokens (from 800 to 1200)

### Issue 4: "Invalid task_type" or similar
**Problem:** The AI used values not in your allow-list.

**Solutions:**
- This is normal! Validation is catching it correctly
- The AI might need clearer instructions
- Regenerate and try again
- Consider fine-tuning your prompt to be more explicit

### Issue 5: Agent returns null every time
**Problem:** Every validation check fails.

**Solutions:**
- Add print statements in `_validate_and_parse_response` to see which check fails
- Print the raw `content` before parsing to see what the AI actually sent
- Temporarily disable validation to see the raw TaskData
- Check if the model is too small (try a larger model)

---

## Next Steps

Once Step 4 is working, you'll move to **Step 5**: Converting the validated JSON into a full `TaskData` object with all the fields properly set.

Right now, your agent can:
- ✅ Gather game context
- ✅ Build proper prompts
- ✅ Call the LLM
- ✅ Validate responses
- ❌ Convert to full TaskData (that's Step 5!)
- ❌ Wire into the game (that's Step 6!)

**Congratulations!** You've built the core orchestrator. This is the hardest part of the AI integration.

---

## Summary: What You Built

You created `MasterArtistAgent.gd`, which:

1. **Gathers context** from your game systems (skills, inventory, tasks)
2. **Formats prompts** with personality, rules, and context
3. **Calls the LLM** via your HTTP client
4. **Validates responses** to ensure they're safe and correct
5. **Returns a TaskData** (basic version for now)

This is a complete AI orchestration pipeline! 🎉

The agent is now ready to be integrated into your MasterArtist NPC in Step 6.
