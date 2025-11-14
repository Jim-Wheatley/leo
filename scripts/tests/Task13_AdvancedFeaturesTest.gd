extends Node2D

# Task 13 Test - Advanced Features and Polish
# Tests audio, VFX, tutorials, and achievements

@onready var test_label = $CanvasLayer/TestLabel
@onready var instructions_label = $CanvasLayer/InstructionsLabel

var test_position: Vector2
var ui_manager: UIManager

func _ready():
	test_position = Vector2(576, 324)  # Center of 1152x648 screen
	
	# Set up UIManager for this test scene
	setup_ui_manager()
	
	instructions_label.text = """Task 13 - Advanced Features Test

Controls:
1 - Play UI Click Sound
2 - Play Crafting Success Sound
3 - Play Skill Up Sound
4 - Show Skill Up VFX
5 - Show Crafting Success VFX
6 - Show Gathering Effect
7 - Toggle Tutorial (Start/Skip)
8 - Unlock Test Achievement
9 - Show Achievement List
0 - Screen Flash Effect

A - Toggle Audio (Music/Ambient)
R - Reset Achievements
T - Test Tutorial Trigger
ESC - Close UI"""
	
	test_label.text = "Advanced Features Test Ready"
	
	# Start background music
	if AudioManager:
		AudioManager.play_music("workshop_theme", 1.0)
	
func setup_ui_manager():
	"""Set up UIManager for the test scene"""
	# Check if UIManager already exists in root
	var existing_ui = get_tree().root.get_node_or_null("UIManager")
	if existing_ui:
		ui_manager = existing_ui
		print("✅ Using existing UIManager")
		return
	
	# Create new UIManager and add to root so it can be found by other systems
	ui_manager = UIManager.new()
	ui_manager.name = "UIManager"
	get_tree().root.add_child.call_deferred(ui_manager)
	
	# Wait for UIManager to initialize
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Manually load the Task 13 UI scenes since UIManager's auto-load isn't working
	_manually_load_task13_ui()
	
	print("✅ UIManager initialized for test scene")
	
	# Debug: Check what UI components were loaded
	if ui_manager.tutorial_ui:
		print("  ✅ Tutorial UI is available")
	else:
		print("  ❌ Tutorial UI is NOT available")
	
	if ui_manager.achievement_notification:
		print("  ✅ Achievement Notification is available")
	else:
		print("  ❌ Achievement Notification is NOT available")
	
	if ui_manager.achievement_list_ui:
		print("  ✅ Achievement List UI is available")
	else:
		print("  ❌ Achievement List UI is NOT available")

func _manually_load_task13_ui():
	"""Manually load Task 13 UI components"""
	print("🔧 Manually loading Task 13 UI components...")
	
	# Load Tutorial UI (only if not already loaded)
	if not ui_manager.tutorial_ui:
		var tutorial_scene = load("res://scenes/ui/TutorialUI.tscn")
		if tutorial_scene:
			ui_manager.tutorial_ui = tutorial_scene.instantiate()
			get_tree().root.add_child(ui_manager.tutorial_ui)
			print("  ✅ Tutorial UI loaded manually")
		else:
			print("  ❌ Failed to load Tutorial UI scene")
	else:
		print("  ℹ️ Tutorial UI already loaded by UIManager")
	
	# Load Achievement Notification (only if not already loaded)
	if not ui_manager.achievement_notification:
		var achievement_notif_scene = load("res://scenes/ui/AchievementNotification.tscn")
		if achievement_notif_scene:
			ui_manager.achievement_notification = achievement_notif_scene.instantiate()
			get_tree().root.add_child(ui_manager.achievement_notification)
			print("  ✅ Achievement Notification loaded manually")
		else:
			print("  ❌ Failed to load Achievement Notification scene")
	else:
		print("  ℹ️ Achievement Notification already loaded by UIManager")
	
	# Load Achievement List UI (only if not already loaded)
	if not ui_manager.achievement_list_ui:
		var achievement_list_scene = load("res://scenes/ui/AchievementListUI.tscn")
		if achievement_list_scene:
			ui_manager.achievement_list_ui = achievement_list_scene.instantiate()
			get_tree().root.add_child(ui_manager.achievement_list_ui)
			print("  ✅ Achievement List UI loaded manually")
		else:
			print("  ❌ Failed to load Achievement List UI scene")
	else:
		print("  ℹ️ Achievement List UI already loaded by UIManager")

func _exit_tree():
	"""Clean up when exiting"""
	# UIManager will be cleaned up automatically since it's in the tree

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		# Close any open UI first
		if ui_manager:
			ui_manager.close_current_ui()
		else:
			get_tree().quit()
	
	# Audio tests
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1:
				test_label.text = "Playing UI Click Sound"
				if AudioManager:
					AudioManager.play_ui_click()
			
			KEY_2:
				test_label.text = "Playing Crafting Success Sound"
				if AudioManager:
					AudioManager.play_crafting_success()
			
			KEY_3:
				test_label.text = "Playing Skill Up Sound"
				if AudioManager:
					AudioManager.play_skill_up()
			
			KEY_4:
				test_label.text = "Showing Skill Up VFX"
				if VFXManager:
					VFXManager.create_skill_up_effect(test_position, "Painting")
			
			KEY_5:
				test_label.text = "Showing Crafting Success VFX"
				if VFXManager:
					VFXManager.create_crafting_success_effect(test_position)
			
			KEY_6:
				test_label.text = "Showing Gathering Effect"
				if VFXManager:
					VFXManager.create_gathering_effect(test_position, randf() > 0.5)
			
			KEY_7:
				# Toggle tutorial on/off
				if TutorialManager and TutorialManager.is_tutorial_active():
					test_label.text = "Skipping Tutorial"
					TutorialManager.skip_tutorial()
					print("Tutorial skipped")
				elif TutorialManager:
					test_label.text = "Starting Tutorial"
					# Try different tutorials to avoid "already completed"
					var test_tutorials = ["welcome", "crafting_basics", "sketching", "gathering", "artwork_creation", "skills"]
					var started = false
					for tut_id in test_tutorials:
						if not tut_id in TutorialManager.completed_tutorials:
							TutorialManager.start_tutorial(tut_id)
							print("Tutorial started: " + tut_id + " - look for UI at bottom of screen")
							started = true
							break
					
					if not started:
						print("All tutorials completed! Resetting tutorial progress...")
						TutorialManager.reset_tutorials()
						TutorialManager.start_tutorial("welcome")
						print("Tutorial started - look for UI at bottom of screen")
				else:
					test_label.text = "TutorialManager not available"
			
			KEY_8:
				test_label.text = "Unlocking Test Achievement"
				if AchievementManager:
					# Try different achievements to avoid "already unlocked"
					var test_achievements = ["first_steps", "first_paint", "novice_painter", "first_artwork", 
											 "skilled_painter", "keen_observer", "color_collector", 
											 "prolific_artist", "quality_work", "city_explorer"]
					var unlocked_any = false
					for ach_id in test_achievements:
						if not AchievementManager.is_unlocked(ach_id):
							AchievementManager.unlock_achievement(ach_id)
							print("Achievement unlocked: " + ach_id + " - look for notification in top-right")
							unlocked_any = true
							break
					
					if not unlocked_any:
						print("All test achievements unlocked! Press R to reset achievements")
						test_label.text = "All achievements unlocked (press R to reset)"
				else:
					test_label.text = "AchievementManager not available"
			
			KEY_R:
				# Reset achievements for testing
				if AchievementManager:
					print("🔄 Resetting all achievements...")
					AchievementManager.unlocked_achievements.clear()
					AchievementManager.achievement_progress.clear()
					AchievementManager._save_achievement_data()
					test_label.text = "Achievements reset!"
					print("✅ All achievements reset")
			
			KEY_9:
				test_label.text = "Opening Achievement List"
				if ui_manager and ui_manager.has_method("toggle_achievement_list"):
					ui_manager.toggle_achievement_list()
				else:
					test_label.text = "Achievement List UI not available"
			
			KEY_0:
				test_label.text = "Screen Flash Effect"
				if VFXManager:
					VFXManager.screen_flash(Color.WHITE, 0.3)
			
			KEY_A:
				test_label.text = "Toggling Audio"
				_toggle_audio()
			
			KEY_T:
				test_label.text = "Testing Tutorial Trigger"
				if TutorialManager:
					if TutorialManager.is_tutorial_active():
						# If tutorial is active, advance it
						TutorialManager.check_tutorial_trigger("continue")
						print("Tutorial trigger 'continue' sent - tutorial should advance")
					else:
						print("No active tutorial - start one with key 7 first")
						test_label.text = "No active tutorial (press 7 first)"

func _toggle_audio():
	if not AudioManager:
		return
	
	if AudioManager.music_player.playing:
		AudioManager.stop_music(0.5)
	else:
		AudioManager.play_music("workshop_theme", 1.0)

func _on_test_skill_increase():
	"""Simulate a skill increase"""
	if SkillManager:
		SkillManager.add_experience("painting", 150, "Test Activity")
		
		# Show VFX at player position
		if VFXManager:
			VFXManager.create_skill_up_effect(test_position, "Painting")

func _on_test_crafting():
	"""Simulate crafting completion"""
	if AudioManager:
		AudioManager.play_crafting_success()
	
	if VFXManager:
		VFXManager.create_crafting_success_effect(test_position)

func _on_test_achievement():
	"""Test achievement unlock"""
	if AchievementManager:
		# Unlock a few test achievements
		AchievementManager.unlock_achievement("first_paint")
		await get_tree().create_timer(2.0).timeout
		AchievementManager.unlock_achievement("novice_painter")
