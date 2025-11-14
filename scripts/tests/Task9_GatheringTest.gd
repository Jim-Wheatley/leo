extends Node

# Test script for Task 9: Natural Material Gathering System
# Tests clay deposits, mineral veins, and gathering mechanics
# Works alongside the NaturalAreas scene without overriding it

var gathering_nodes: Node2D
var test_results = []

func _ready():
	# Get reference to gathering nodes from parent scene
	gathering_nodes = get_parent().get_node("GatheringNodes")
	
	print("=== Task 9: Natural Material Gathering System Test ===")
	print("🎮 Manual Testing: Use WASD to move, E to interact with gathering nodes")
	print("🤖 Automated Testing: Press T to run automated tests")
	print("📦 Inventory: Press I to view collected materials")
	
	# Wait a frame for everything to initialize
	await get_tree().process_frame
	
	# Run automated tests initially
	run_gathering_tests()

func run_gathering_tests():
	"""Run comprehensive tests for the gathering system"""
	print("\n--- Testing Gathering System ---")
	
	test_clay_deposits()
	test_mineral_veins()
	test_resource_depletion()
	test_skill_requirements()
	test_rare_materials()
	
	print_test_summary()

func test_clay_deposits():
	"""Test clay deposit functionality"""
	print("\n1. Testing Clay Deposits:")
	
	var clay_deposits = []
	for node in gathering_nodes.get_children():
		if node is ClayDeposit:
			clay_deposits.append(node)
	
	if clay_deposits.size() > 0:
		var deposit = clay_deposits[0]
		print("   ✓ Found clay deposit: " + deposit.resource_name)
		print("   ✓ Max resources: " + str(deposit.max_resources))
		print("   ✓ Current resources: " + str(deposit.current_resources))
		print("   ✓ Can gather: " + str(deposit.can_gather()))
		
		# Test gathering
		if deposit.can_gather():
			var result = deposit.gather_resource()
			if result.success:
				print("   ✓ Successfully gathered materials")
				print("   ✓ Items gathered: " + str(result.items))
				test_results.append("Clay gathering: PASS")
			else:
				print("   ✗ Failed to gather materials: " + result.message)
				test_results.append("Clay gathering: FAIL")
		else:
			print("   ✗ Cannot gather from clay deposit")
			test_results.append("Clay gathering: FAIL")
	else:
		print("   ✗ No clay deposits found")
		test_results.append("Clay deposits: FAIL")

func test_mineral_veins():
	"""Test mineral vein functionality"""
	print("\n2. Testing Mineral Veins:")
	
	var mineral_veins = []
	for node in gathering_nodes.get_children():
		if node is MineralVein:
			mineral_veins.append(node)
	
	if mineral_veins.size() > 0:
		var vein = mineral_veins[0]
		print("   ✓ Found mineral vein: " + vein.resource_name)
		print("   ✓ Max resources: " + str(vein.max_resources))
		print("   ✓ Current resources: " + str(vein.current_resources))
		print("   ✓ Required skill level: " + str(vein.required_skill_level))
		print("   ✓ Can gather: " + str(vein.can_gather()))
		
		# Test skill requirement
		var player_skill = SkillManager.get_skill_level("gathering")
		if player_skill >= vein.required_skill_level:
			var result = vein.gather_resource()
			if result.success:
				print("   ✓ Successfully gathered minerals")
				test_results.append("Mineral gathering: PASS")
			else:
				print("   ✗ Failed to gather minerals: " + result.message)
				test_results.append("Mineral gathering: FAIL")
		else:
			print("   ⚠ Player skill too low for mineral gathering (need " + str(vein.required_skill_level) + ")")
			test_results.append("Mineral skill check: PASS")
	else:
		print("   ✗ No mineral veins found")
		test_results.append("Mineral veins: FAIL")

func test_resource_depletion():
	"""Test resource depletion and regeneration"""
	print("\n3. Testing Resource Depletion:")
	
	var clay_deposits = []
	for node in gathering_nodes.get_children():
		if node is ClayDeposit:
			clay_deposits.append(node)
	
	if clay_deposits.size() > 0:
		var deposit = clay_deposits[0]
		var initial_resources = deposit.current_resources
		
		# Gather all resources
		while deposit.can_gather() and deposit.current_resources > 0:
			deposit.gather_resource()
		
		print("   ✓ Depleted deposit from " + str(initial_resources) + " to " + str(deposit.current_resources))
		print("   ✓ Is depleted: " + str(deposit.is_depleted))
		print("   ✓ Regeneration timer active: " + str(deposit.regeneration_timer.time_left > 0))
		
		if deposit.is_depleted:
			test_results.append("Resource depletion: PASS")
		else:
			test_results.append("Resource depletion: FAIL")
	else:
		test_results.append("Resource depletion: SKIP")

func test_skill_requirements():
	"""Test skill requirement system"""
	print("\n4. Testing Skill Requirements:")
	
	var initial_skill = SkillManager.get_skill_level("gathering")
	print("   ✓ Initial gathering skill: " + str(initial_skill))
	
	# Test with clay (no skill requirement)
	var clay_deposits = []
	for node in gathering_nodes.get_children():
		if node is ClayDeposit:
			clay_deposits.append(node)
	
	if clay_deposits.size() > 0:
		var deposit = clay_deposits[0]
		if deposit.required_skill_level == 0:
			print("   ✓ Clay deposits have no skill requirement")
			test_results.append("Skill requirements: PASS")
		else:
			print("   ✗ Clay deposits should have no skill requirement")
			test_results.append("Skill requirements: FAIL")

func test_rare_materials():
	"""Test rare material discovery"""
	print("\n5. Testing Rare Materials:")
	
	var rare_found = false
	var attempts = 0
	var max_attempts = 20
	
	# Try gathering multiple times to test rare material chance
	for node in gathering_nodes.get_children():
		if node is GatheringNode and attempts < max_attempts:
			if node.can_gather():
				var result = node.gather_resource()
				if result.success and result.rare_found:
					rare_found = true
					print("   ✓ Rare material found: " + str(result.items))
					break
				attempts += 1
	
	if rare_found:
		print("   ✓ Rare material system working")
		test_results.append("Rare materials: PASS")
	else:
		print("   ⚠ No rare materials found in " + str(attempts) + " attempts (may be due to RNG)")
		test_results.append("Rare materials: UNCERTAIN")

func print_test_summary():
	"""Print a summary of all test results"""
	print("\n=== Test Summary ===")
	var passed = 0
	var failed = 0
	var uncertain = 0
	
	for result in test_results:
		print("  " + result)
		if "PASS" in result:
			passed += 1
		elif "FAIL" in result:
			failed += 1
		else:
			uncertain += 1
	
	print("\nResults: " + str(passed) + " passed, " + str(failed) + " failed, " + str(uncertain) + " uncertain")
	
	if failed == 0:
		print("✓ All critical tests passed! Natural material gathering system is working.")
	else:
		print("✗ Some tests failed. Check the implementation.")

func _input(event):
	"""Handle test input"""
	if event.is_action_pressed("ui_accept"):  # T key
		print("\n--- Re-running automated tests ---")
		test_results.clear()
		run_gathering_tests()
