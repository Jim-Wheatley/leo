extends Node

## Simple test script for MasterArtistAgent
## Attach this to a test scene and press Space to generate a task

func _ready():
	print("🧪 MasterArtistAgent Test Ready")
	print("Press SPACE to generate a task")
	print("Press ESC to quit")

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE:
			print("\n" + "=".repeat(50))
			print("🎨 Testing MasterArtistAgent...")
			print("=".repeat(50) + "\n")
			
			test_task_generation()
		
		elif event.keycode == KEY_ESCAPE:
			print("Exiting test...")
			get_tree().quit()

func test_task_generation():
	"""Test generating a task"""
	
	# Show current game state
	print("📊 Current Game State:")
	print("  Skills: crafting=%d, painting=%d, color_theory=%d, sketching=%d, gathering=%d, portfolio=%d" % [
		SkillManager.get_skill_level("crafting"),
		SkillManager.get_skill_level("painting"),
		SkillManager.get_skill_level("color_theory"),
		SkillManager.get_skill_level("sketching"),
		SkillManager.get_skill_level("gathering"),
		SkillManager.get_skill_level("portfolio_management")
	])
	
	var inventory_items = []
	var inventory_summary: Dictionary = {}
	var inventory_data = GameManager.player_data.inventory
	
	if inventory_data is Array:
		for item in inventory_data:
			if item is InventoryItem and item.current_stack > 0:
				inventory_summary[item.item_id] = inventory_summary.get(item.item_id, 0) + item.current_stack
	elif inventory_data is Dictionary:
		for item_id in inventory_data:
			if inventory_data[item_id] > 0:
				inventory_summary[item_id] = inventory_data[item_id]
	
	for item_id in inventory_summary:
		inventory_items.append("%s: %d" % [item_id, inventory_summary[item_id]])
	
	if inventory_items.size() > 0:
		print("  Inventory: %s" % ", ".join(inventory_items))
	else:
		print("  Inventory: (empty)")
	
	print("  Completed tasks: %d" % GameManager.player_data.completed_tasks.size())
	print("  Master relationship: %d/100\n" % GameManager.player_data.master_relationship)
	
	# Generate task
	var task = await MasterArtistAgent.generate_task()
	
	if task:
		print("\n" + "=".repeat(50))
		print("✅ SUCCESS! Generated task:")
		print("=".repeat(50))
		print("📋 ID: %s" % task.task_id)
		print("📝 Title: %s" % task.title)
		print("📄 Description: %s" % task.description)
		print("\n💬 Assignment Dialogue:")
		print("   \"%s\"\n" % task.assignment_dialogue)
		print("💬 Completion Dialogue:")
		print("   \"%s\"\n" % task.completion_dialogue)
		
		# Show raw JSON if available
		if task.has_meta("raw_json"):
			var raw = task.get_meta("raw_json")
			print("🔍 Raw JSON Details:")
			print("   Task Type: %s" % raw.get("task_type", "N/A"))
			print("   Difficulty: %s" % raw.get("difficulty", "N/A"))
			
			if raw.has("objectives"):
				print("   Objectives (%d):" % raw["objectives"].size())
				for i in range(raw["objectives"].size()):
					var obj = raw["objectives"][i]
					print("     %d. %s (target: %d, type: %s)" % [
						i + 1,
						obj.get("description", "N/A"),
						obj.get("target", 0),
						obj.get("type", "N/A")
					])
			
			if raw.has("required_items"):
				var required_items_data = raw["required_items"]
				if required_items_data is Dictionary and required_items_data.size() > 0:
					print("   Required Items:")
					for item_id in required_items_data:
						print("     - %s x%d" % [item_id, int(required_items_data[item_id])])
				elif required_items_data is Array and required_items_data.size() > 0:
					print("   Required Items:")
					for entry in required_items_data:
						if entry is Dictionary:
							print("     - %s x%d" % [entry.get("item_id", "?"), int(entry.get("quantity", 0))])
			
			if raw.has("skill_rewards") and raw["skill_rewards"].size() > 0:
				print("   Skill Rewards:")
				for skill in raw["skill_rewards"]:
					print("     - %s: +%d XP" % [skill, raw["skill_rewards"][skill]])
			
			if raw.has("item_rewards"):
				var item_rewards_data = raw["item_rewards"]
				if item_rewards_data is Array and item_rewards_data.size() > 0:
					print("   Item Rewards:")
					for reward in item_rewards_data:
						if reward is Dictionary:
							print("     - %s x%d" % [reward.get("item_id", "?"), int(reward.get("quantity", 0))])
				elif item_rewards_data is Dictionary and item_rewards_data.size() > 0:
					print("   Item Rewards:")
					for reward_item_id in item_rewards_data:
						print("     - %s x%d" % [reward_item_id, int(item_rewards_data[reward_item_id])])
			
			if raw.has("reputation_reward"):
				print("   Reputation: +%d" % raw["reputation_reward"])
		
		print("=".repeat(50))
		print("Press SPACE to generate another task")
		
	else:
		print("\n" + "=".repeat(50))
		print("❌ FAILED: No task generated")
		print("=".repeat(50))
		print("Troubleshooting:")
		print("  1. Is LM Studio running?")
		print("     → Open LM Studio and check the server is ON (green checkmark)")
		print("  2. Did you load a model?")
		print("     → In LM Studio, make sure a model is loaded in the Local Server tab")
		print("  3. Check the URL")
		print("     → Should be http://localhost:1234 or http://127.0.0.1:1234")
		print("  4. Check above error messages for details")
		print("=".repeat(50))
		print("Press SPACE to try again, ESC to quit")
