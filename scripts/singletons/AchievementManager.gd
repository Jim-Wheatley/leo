extends Node

# Achievement Manager - Tracks and awards achievements for milestone recognition

signal achievement_unlocked(achievement_id: String)
signal achievement_progress_updated(achievement_id: String, progress: float)

# Achievement data
var unlocked_achievements: Array[String] = []
var achievement_progress: Dictionary = {}

# Achievement definitions
var achievements: Dictionary = {
	# Skill-based achievements
	"first_steps": {
		"title": "First Steps",
		"description": "Complete your first day as an apprentice",
		"icon": null,
		"type": "story",
		"hidden": false
	},
	"novice_painter": {
		"title": "Novice Painter",
		"description": "Reach level 5 in Painting skill",
		"icon": null,
		"type": "skill",
		"requirement": {"skill": "painting", "level": 5},
		"hidden": false
	},
	"skilled_painter": {
		"title": "Skilled Painter",
		"description": "Reach level 10 in Painting skill",
		"icon": null,
		"type": "skill",
		"requirement": {"skill": "painting", "level": 10},
		"hidden": false
	},
	"master_painter": {
		"title": "Master Painter",
		"description": "Reach level 20 in Painting skill",
		"icon": null,
		"type": "skill",
		"requirement": {"skill": "painting", "level": 20},
		"hidden": false
	},
	"keen_observer": {
		"title": "Keen Observer",
		"description": "Reach level 10 in Observation skill",
		"icon": null,
		"type": "skill",
		"requirement": {"skill": "observation", "level": 10},
		"hidden": false
	},
	
	# Crafting achievements
	"first_paint": {
		"title": "First Paint",
		"description": "Create your first paint color",
		"icon": null,
		"type": "crafting",
		"hidden": false
	},
	"color_collector": {
		"title": "Color Collector",
		"description": "Create 10 different paint colors",
		"icon": null,
		"type": "crafting",
		"requirement": {"paints_created": 10},
		"hidden": false
	},
	"rainbow_palette": {
		"title": "Rainbow Palette",
		"description": "Create 25 different paint colors",
		"icon": null,
		"type": "crafting",
		"requirement": {"paints_created": 25},
		"hidden": false
	},
	
	# Artwork achievements
	"first_artwork": {
		"title": "First Artwork",
		"description": "Complete your first artwork",
		"icon": null,
		"type": "artwork",
		"hidden": false
	},
	"prolific_artist": {
		"title": "Prolific Artist",
		"description": "Complete 10 artworks",
		"icon": null,
		"type": "artwork",
		"requirement": {"artworks_completed": 10},
		"hidden": false
	},
	"quality_work": {
		"title": "Quality Work",
		"description": "Create an artwork with quality rating above 80",
		"icon": null,
		"type": "artwork",
		"requirement": {"artwork_quality": 80},
		"hidden": false
	},
	"masterpiece": {
		"title": "Masterpiece",
		"description": "Create an artwork with quality rating above 95",
		"icon": null,
		"type": "artwork",
		"requirement": {"artwork_quality": 95},
		"hidden": true
	},
	
	# Exploration achievements
	"city_explorer": {
		"title": "City Explorer",
		"description": "Visit all major landmarks in Florence",
		"icon": null,
		"type": "exploration",
		"requirement": {"landmarks_visited": 5},
		"hidden": false
	},
	"sketch_enthusiast": {
		"title": "Sketch Enthusiast",
		"description": "Complete 20 sketches",
		"icon": null,
		"type": "exploration",
		"requirement": {"sketches_completed": 20},
		"hidden": false
	},
	"nature_gatherer": {
		"title": "Nature Gatherer",
		"description": "Gather materials from 10 different locations",
		"icon": null,
		"type": "exploration",
		"requirement": {"gathering_locations": 10},
		"hidden": false
	},
	"rare_find": {
		"title": "Rare Find",
		"description": "Discover a rare pigment source",
		"icon": null,
		"type": "exploration",
		"hidden": false
	},
	
	# Task achievements
	"dedicated_apprentice": {
		"title": "Dedicated Apprentice",
		"description": "Complete 5 tasks from your master",
		"icon": null,
		"type": "task",
		"requirement": {"tasks_completed": 5},
		"hidden": false
	},
	"trusted_student": {
		"title": "Trusted Student",
		"description": "Complete 15 tasks from your master",
		"icon": null,
		"type": "task",
		"requirement": {"tasks_completed": 15},
		"hidden": false
	},
	
	# Special achievements
	"perfectionist": {
		"title": "Perfectionist",
		"description": "Complete 5 artworks with quality above 90",
		"icon": null,
		"type": "special",
		"requirement": {"high_quality_artworks": 5},
		"hidden": true
	},
	"renaissance_artist": {
		"title": "Renaissance Artist",
		"description": "Master all artistic skills",
		"icon": null,
		"type": "special",
		"requirement": {"all_skills_mastered": true},
		"hidden": true
	}
}

func _ready():
	_load_achievement_data()
	_connect_to_game_events()

func _connect_to_game_events():
	# Connect to various game systems to track progress
	if SkillManager:
		SkillManager.skill_increased.connect(_on_skill_increased)
	
	if GameManager:
		GameManager.artwork_completed.connect(_on_artwork_completed)
		GameManager.task_completed.connect(_on_task_completed)

func unlock_achievement(achievement_id: String):
	if achievement_id in unlocked_achievements:
		return
	
	if not achievements.has(achievement_id):
		push_warning("Achievement not found: " + achievement_id)
		return
	
	unlocked_achievements.append(achievement_id)
	achievement_unlocked.emit(achievement_id)
	
	# Show notification
	_show_achievement_notification(achievement_id)
	
	# Play effects
	if AudioManager:
		AudioManager.play_sfx("achievement_unlocked")
	
	_save_achievement_data()

func update_progress(achievement_id: String, progress_value: float):
	if achievement_id in unlocked_achievements:
		return
	
	achievement_progress[achievement_id] = progress_value
	achievement_progress_updated.emit(achievement_id, progress_value)
	
	# Check if achievement should be unlocked
	if achievements.has(achievement_id):
		var req = achievements[achievement_id].get("requirement", {})
		if _check_requirement_met(req, progress_value):
			unlock_achievement(achievement_id)

func is_unlocked(achievement_id: String) -> bool:
	return achievement_id in unlocked_achievements

func get_progress(achievement_id: String) -> float:
	return achievement_progress.get(achievement_id, 0.0)

func get_unlocked_count() -> int:
	return unlocked_achievements.size()

func get_total_count() -> int:
	return achievements.size()

func get_unlocked_achievements() -> Array[String]:
	return unlocked_achievements.duplicate()

func get_visible_achievements() -> Array:
	var visible = []
	for id in achievements:
		if not achievements[id].get("hidden", false) or is_unlocked(id):
			visible.append({
				"id": id,
				"data": achievements[id],
				"unlocked": is_unlocked(id),
				"progress": get_progress(id)
			})
	return visible

func _check_requirement_met(requirement: Dictionary, current_value: float) -> bool:
	if requirement.is_empty():
		return true
	
	# Check different requirement types
	for key in requirement:
		var required_value = requirement[key]
		if typeof(required_value) == TYPE_FLOAT or typeof(required_value) == TYPE_INT:
			if current_value < required_value:
				return false
	
	return true

func _show_achievement_notification(achievement_id: String):
	if not achievements.has(achievement_id):
		return
	
	var achievement_data = achievements[achievement_id]
	
	# Try UIManager first (for scenes that use it)
	var ui_manager = get_tree().root.get_node_or_null("UIManager")
	if ui_manager and ui_manager.has_method("show_achievement_notification"):
		ui_manager.show_achievement_notification(
			achievement_data["title"],
			achievement_data["description"]
		)
		return
	
	# Fallback: Find AchievementNotification directly in the scene tree
	var notification_ui = _find_achievement_notification_ui()
	if notification_ui and notification_ui.has_method("queue_notification"):
		print("🏆 Calling notification UI directly")
		notification_ui.queue_notification(
			achievement_data["title"],
			achievement_data["description"]
		)
	else:
		print("❌ Could not find AchievementNotification UI")

func _find_achievement_notification_ui() -> Node:
	"""Find the AchievementNotification UI in the scene tree"""
	# Search in all CanvasLayers
	for node in get_tree().root.get_children():
		var result = _search_for_notification_ui(node)
		if result:
			return result
	return null

func _search_for_notification_ui(node: Node) -> Node:
	"""Recursively search for AchievementNotification UI"""
	if node.get_script():
		var script_path = node.get_script().resource_path
		if "AchievementNotification" in script_path:
			return node
	
	for child in node.get_children():
		var result = _search_for_notification_ui(child)
		if result:
			return result
	
	return null

# Event handlers
func _on_skill_increased(skill_name: String, new_level: int):
	# Check skill-based achievements
	for achievement_id in achievements:
		var achievement = achievements[achievement_id]
		if achievement.get("type") == "skill":
			var req = achievement.get("requirement", {})
			if req.get("skill") == skill_name and req.get("level", 0) <= new_level:
				unlock_achievement(achievement_id)

func _on_artwork_completed(artwork_data: Dictionary):
	print("🏆 AchievementManager received artwork_completed signal!")
	
	# First artwork
	if not is_unlocked("first_artwork"):
		print("🏆 Unlocking first_artwork achievement")
		unlock_achievement("first_artwork")
	else:
		print("🏆 first_artwork already unlocked")
	
	# Count artworks
	var artwork_count = GameManager.get_artwork_count() if GameManager else 0
	update_progress("prolific_artist", artwork_count)
	
	# Quality-based achievements
	var quality = artwork_data.get("quality_score", 0)
	if quality >= 80 and not is_unlocked("quality_work"):
		unlock_achievement("quality_work")
	if quality >= 95 and not is_unlocked("masterpiece"):
		unlock_achievement("masterpiece")

func _on_task_completed(task_id: String):
	var task_count = GameManager.get_completed_task_count() if GameManager else 0
	update_progress("dedicated_apprentice", task_count)
	update_progress("trusted_student", task_count)

func _save_achievement_data():
	var save_data = {
		"unlocked": unlocked_achievements,
		"progress": achievement_progress
	}
	if GameManager:
		GameManager.save_achievement_data(save_data)

func _load_achievement_data():
	if GameManager and GameManager.has_method("load_achievement_data"):
		var data = GameManager.load_achievement_data()
		if data:
			var loaded_unlocked = data.get("unlocked", [])
			unlocked_achievements.clear()
			for item in loaded_unlocked:
				if item is String:
					unlocked_achievements.append(item)
			achievement_progress = data.get("progress", {})
