extends Node2D

# Minimal test to verify UI system works

func _ready():
	print("=== Minimal UI Test ===")
	print("Testing UI system initialization...")
	
	# Test that we can access the UI classes
	test_ui_classes()
	
	print("✅ Minimal UI test completed!")

func test_ui_classes():
	"""Test that UI classes are accessible"""
	print("Testing UI class accessibility...")
	
	# Test that we can reference the classes without errors
	var main_hud_class = MainHUD
	var skill_tree_class = SkillTreeUI
	var pause_menu_class = PauseMenu
	var crafting_ui_class = CraftingStationUI
	
	print("✅ MainHUD class accessible: %s" % str(main_hud_class))
	print("✅ SkillTreeUI class accessible: %s" % str(skill_tree_class))
	print("✅ PauseMenu class accessible: %s" % str(pause_menu_class))
	print("✅ CraftingStationUI class accessible: %s" % str(crafting_ui_class))
	
	print("✅ All UI classes are accessible")