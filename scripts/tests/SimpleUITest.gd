extends Node2D

# Simple test to verify UI system works without errors

func _ready():
	print("=== Simple UI System Test ===")
	
	# Test basic functionality
	test_basic_ui_creation()
	
	print("✅ Simple UI test completed successfully!")

func test_basic_ui_creation():
	"""Test basic UI component creation"""
	print("Testing basic UI component creation...")
	
	# Test creating UI scenes instead of scripts directly
	var main_hud_scene = preload("res://scenes/ui/MainHUD.tscn")
	var main_hud = main_hud_scene.instantiate()
	print("✅ MainHUD scene created")
	
	var skill_tree_scene = preload("res://scenes/ui/SkillTreeUI.tscn")
	var skill_tree_ui = skill_tree_scene.instantiate()
	print("✅ SkillTreeUI scene created")
	
	var pause_menu_scene = preload("res://scenes/ui/PauseMenu.tscn")
	var pause_menu = pause_menu_scene.instantiate()
	print("✅ PauseMenu scene created")
	
	var crafting_scene = preload("res://scenes/ui/CraftingStationUI.tscn")
	var crafting_ui = crafting_scene.instantiate()
	print("✅ CraftingStationUI scene created")
	
	# Clean up
	main_hud.queue_free()
	skill_tree_ui.queue_free()
	pause_menu.queue_free()
	crafting_ui.queue_free()
	
	print("✅ All UI components created successfully")