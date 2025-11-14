extends Node

# Tutorial Manager - Handles new player onboarding and tutorial sequences

signal tutorial_started(tutorial_id: String)
signal tutorial_completed(tutorial_id: String)
signal tutorial_step_changed(step_index: int)

# Tutorial state
var active_tutorial: String = ""
var current_step: int = 0
var completed_tutorials: Array[String] = []
var tutorial_enabled: bool = true

# Tutorial definitions
var tutorials: Dictionary = {
	"welcome": {
		"title": "Welcome to the Workshop",
		"steps": [
			{
				"text": "Welcome, apprentice! I am your master, and you will learn the art of Renaissance painting under my guidance.",
				"highlight": null,
				"wait_for": "continue"
			},
			{
				"text": "Use WASD or Arrow Keys to move around the workshop. Try moving to the paint station.",
				"highlight": "paint_station",
				"wait_for": "reach_paint_station"
			},
			{
				"text": "Press E to interact with objects. This is how you'll use crafting stations and talk to people.",
				"highlight": "interaction_prompt",
				"wait_for": "interaction"
			}
		]
	},
	"crafting_basics": {
		"title": "Creating Paint",
		"steps": [
			{
				"text": "To create paint, you need pigments and a binding agent. Let's make your first color!",
				"highlight": "paint_station",
				"wait_for": "continue"
			},
			{
				"text": "Select a pigment from your inventory, then choose a binder. The quality of materials affects the final paint.",
				"highlight": "crafting_ui",
				"wait_for": "craft_paint"
			},
			{
				"text": "Excellent! You've created your first paint. You'll need various colors for your artworks.",
				"highlight": null,
				"wait_for": "continue"
			}
		]
	},
	"sketching": {
		"title": "Sketching in Florence",
		"steps": [
			{
				"text": "Sketching is essential for improving your observation skills. Head outside to explore Florence!",
				"highlight": "exit_door",
				"wait_for": "enter_florence"
			},
			{
				"text": "Look for interesting subjects - buildings, people, or scenes. They'll be highlighted when you're near.",
				"highlight": null,
				"wait_for": "find_sketch_subject"
			},
			{
				"text": "Press E to start sketching. Take your time to observe the details carefully.",
				"highlight": "sketch_subject",
				"wait_for": "complete_sketch"
			},
			{
				"text": "Great work! Sketches provide inspiration for your paintings and improve your skills.",
				"highlight": null,
				"wait_for": "continue"
			}
		]
	},
	"gathering": {
		"title": "Gathering Natural Materials",
		"steps": [
			{
				"text": "Natural pigments can be found in the areas around Florence. Let's gather some materials!",
				"highlight": null,
				"wait_for": "continue"
			},
			{
				"text": "Look for clay deposits and mineral veins. These provide authentic pigments for your art.",
				"highlight": "gathering_node",
				"wait_for": "gather_material"
			},
			{
				"text": "Resources regenerate over time, so remember good locations. Rare materials are valuable!",
				"highlight": null,
				"wait_for": "continue"
			}
		]
	},
	"artwork_creation": {
		"title": "Creating Your First Artwork",
		"steps": [
			{
				"text": "Now you're ready to create a finished artwork! You'll need paint, canvas, and inspiration.",
				"highlight": "artwork_station",
				"wait_for": "continue"
			},
			{
				"text": "Your sketches provide inspiration. The quality of your work depends on your skill level.",
				"highlight": "artwork_ui",
				"wait_for": "create_artwork"
			},
			{
				"text": "Congratulations! Your artwork is complete. Check your portfolio to see all your creations.",
				"highlight": "portfolio_button",
				"wait_for": "continue"
			}
		]
	},
	"skills": {
		"title": "Skill Progression",
		"steps": [
			{
				"text": "Every activity improves your skills. Open the skill menu to see your progress.",
				"highlight": "skill_button",
				"wait_for": "open_skills"
			},
			{
				"text": "Higher skills unlock new techniques and improve the quality of your work. Practice makes perfect!",
				"highlight": "skill_tree",
				"wait_for": "continue"
			}
		]
	}
}

func _ready():
	_load_tutorial_progress()

func start_tutorial(tutorial_id: String):
	if not tutorial_enabled:
		return
	
	if tutorial_id in completed_tutorials:
		return
	
	if not tutorials.has(tutorial_id):
		push_warning("Tutorial not found: " + tutorial_id)
		return
	
	active_tutorial = tutorial_id
	current_step = 0
	tutorial_started.emit(tutorial_id)
	_show_current_step()

func advance_tutorial():
	if active_tutorial == "":
		return
	
	current_step += 1
	
	if current_step >= tutorials[active_tutorial]["steps"].size():
		complete_tutorial()
	else:
		tutorial_step_changed.emit(current_step)
		_show_current_step()

func complete_tutorial():
	if active_tutorial == "":
		return
	
	completed_tutorials.append(active_tutorial)
	tutorial_completed.emit(active_tutorial)
	_save_tutorial_progress()
	
	active_tutorial = ""
	current_step = 0
	
	# Hide tutorial UI
	var ui_manager = get_tree().root.get_node_or_null("UIManager")
	if ui_manager and ui_manager.has_method("hide_tutorial"):
		ui_manager.hide_tutorial()

func skip_tutorial():
	if active_tutorial != "":
		completed_tutorials.append(active_tutorial)
		_save_tutorial_progress()
		active_tutorial = ""
		current_step = 0
		
		var ui_manager = get_tree().root.get_node_or_null("UIManager")
		if ui_manager and ui_manager.has_method("hide_tutorial"):
			ui_manager.hide_tutorial()

func is_tutorial_active() -> bool:
	return active_tutorial != ""

func get_current_step_data() -> Dictionary:
	if active_tutorial == "" or current_step >= tutorials[active_tutorial]["steps"].size():
		return {}
	
	return tutorials[active_tutorial]["steps"][current_step]

func check_tutorial_trigger(trigger_name: String):
	if not is_tutorial_active():
		return
	
	var step_data = get_current_step_data()
	if step_data.get("wait_for", "") == trigger_name:
		advance_tutorial()

func _show_current_step():
	if not is_tutorial_active():
		return
	
	var step_data = get_current_step_data()
	var ui_manager = get_tree().root.get_node_or_null("UIManager")
	if ui_manager and ui_manager.has_method("show_tutorial"):
		var highlight = step_data.get("highlight", "")
		if highlight == null:
			highlight = ""
		ui_manager.show_tutorial(
			tutorials[active_tutorial]["title"],
			step_data.get("text", ""),
			highlight
		)

func set_tutorial_enabled(enabled: bool):
	tutorial_enabled = enabled
	if not enabled and is_tutorial_active():
		skip_tutorial()

func reset_tutorials():
	completed_tutorials.clear()
	active_tutorial = ""
	current_step = 0
	_save_tutorial_progress()

func _save_tutorial_progress():
	var save_data = {
		"completed_tutorials": completed_tutorials,
		"tutorial_enabled": tutorial_enabled
	}
	# Save to GameManager or file
	if GameManager:
		GameManager.save_tutorial_data(save_data)

func _load_tutorial_progress():
	# Load from GameManager or file
	if GameManager and GameManager.has_method("load_tutorial_data"):
		var data = GameManager.load_tutorial_data()
		if data:
			var loaded_tutorials = data.get("completed_tutorials", [])
			completed_tutorials.clear()
			for item in loaded_tutorials:
				if item is String:
					completed_tutorials.append(item)
			tutorial_enabled = data.get("tutorial_enabled", true)
