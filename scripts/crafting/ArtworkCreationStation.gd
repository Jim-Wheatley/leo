extends WorkstationBase
class_name ArtworkCreationStation

# Artwork Creation Station
# Allows players to create artworks using paint, canvas, and inspiration (sketches)

func _ready():
	super._ready()
	station_name = "Artwork Creation Station"
	required_skill = "painting"
	min_skill_level = 1

func get_station_type() -> String:
	return "artwork_station"

func show_crafting_ui():
	"""Show artwork creation interface"""
	print("\n🎨 === ARTWORK CREATION STATION ===")
	print("Create paintings using your materials and inspiration!")
	
	# Check what the player has available
	var available_canvases = get_available_canvases()
	var available_paints = get_available_paints()
	var available_sketches = get_available_sketches()
	
	if available_canvases.is_empty():
		print("❌ No canvases available.")
		print("💡 Tip: Visit the Canvas Making Station or gather materials to craft one.")
		return
	
	if available_paints.is_empty():
		print("❌ No paints available.")
		print("💡 Tip: Visit the Paint Creation Station or gather pigments to make paint.")
		return
	
	print("✅ Ready to create artwork!")
	print("📋 Available materials:")
	print("  🖼️ Canvases: %s" % ", ".join(available_canvases))
	print("  🎨 Paints: %s" % ", ".join(available_paints))
	
	if available_sketches.is_empty():
		print("  💭 Inspiration: None")
		print("     💡 Tip: Sketch subjects in Florence for inspiration and higher quality!")
	else:
		print("  💭 Inspiration: %s" % ", ".join(available_sketches))
	
	print("\n🎯 Creating your artwork...")
	
	# Attempt to create artwork automatically
	attempt_auto_create_artwork()

func attempt_auto_create_artwork():
	"""Attempt to create artwork with available materials"""
	var canvases = get_available_canvases()
	var paints = get_available_paints()
	
	if canvases.is_empty() or paints.is_empty():
		print("❌ Cannot create artwork without canvas and paint")
		return
	
	# Use random available materials for variety
	var canvas_size = canvases[randi() % canvases.size()]
	var paint_color = paints[randi() % paints.size()]
	var inspiration = get_best_available_sketch()
	
	create_artwork(canvas_size, paint_color, inspiration)

func create_artwork(canvas_size: String, paint_color: String, inspiration_source: String = ""):
	"""Create an artwork with specified materials"""
	print("\n🎨 === STARTING ARTWORK CREATION ===")
	print("Canvas: %s, Paint: %s" % [canvas_size, paint_color])
	if inspiration_source != "":
		print("Inspiration: %s" % inspiration_source)
	
	start_crafting()
	
	if not is_crafting:
		return
	
	# Define required materials
	var canvas_id = "canvas_" + canvas_size.to_lower()
	var paint_id = "paint_" + paint_color.to_lower()
	
	var required_materials = [
		{"item_id": canvas_id, "amount": 1},
		{"item_id": paint_id, "amount": 1}
	]
	
	# Check materials
	var check_result = check_material_requirements(required_materials)
	if not check_result.has_materials:
		var missing_text = get_missing_materials_text(check_result.missing_items)
		crafting_failed.emit(get_station_type(), "Missing materials: " + missing_text)
		is_crafting = false
		return
	
	print("✅ Materials available, consuming...")
	
	# Consume materials
	if not consume_materials(required_materials):
		crafting_failed.emit(get_station_type(), "Failed to consume materials")
		is_crafting = false
		return
	
	print("✅ Materials consumed successfully")
	
	# Show current skill levels
	print("Current skills:")
	print("  Painting: %d" % SkillManager.get_skill_level("painting"))
	print("  Color Theory: %d" % SkillManager.get_skill_level("color_theory"))
	print("  Crafting: %d" % SkillManager.get_skill_level("crafting"))
	
	# Create the artwork
	var artwork = create_artwork_data(canvas_size, paint_color, inspiration_source)
	
	# Add to portfolio instead of inventory
	if GameManager.player_data:
		GameManager.player_data.add_artwork(artwork)
	
	# Notify task system about artwork creation
	TaskManager.on_artwork_created(artwork)
	
	# Award experience
	var exp_gained = award_painting_experience(artwork.quality_score)
	
	is_crafting = false
	
	# Detailed completion message
	print("\n🎨 === ARTWORK COMPLETED ===")
	print("Title: '%s'" % artwork.title)
	print("Quality: %.1f (%s)" % [artwork.quality_score, artwork.get_quality_description()])
	print("Materials used: %s" % ", ".join(artwork.materials_used))
	print("Experience gained: %d painting, %d color theory" % [exp_gained.painting, exp_gained.color_theory])
	
	# Emit success signal
	crafting_completed.emit(get_station_type(), artwork.title)

func create_artwork_data(canvas_size: String, paint_color: String, inspiration: String) -> ArtworkData:
	"""Create artwork data based on materials and player skills"""
	var artwork = ArtworkData.new()
	
	# Generate varied title based on materials and inspiration
	if inspiration != "":
		artwork.title = "Painting of " + inspiration
		artwork.inspiration_source = inspiration
	else:
		# Create more varied titles without inspiration
		var subjects = ["Abstract Composition", "Color Study", "Light and Shadow", "Morning Scene", "Evening Mood", "Artistic Expression", "Creative Vision", "Workshop Study"]
		var subject = subjects[randi() % subjects.size()]
		artwork.title = paint_color.capitalize() + " " + subject
	
	artwork.artwork_type = ArtworkData.ArtworkType.PAINTING
	
	# Materials used
	artwork.materials_used = [canvas_size + " Canvas", paint_color.capitalize() + " Paint"]
	
	# Current skill levels
	artwork.skill_level_at_creation = {
		"painting": SkillManager.get_skill_level("painting"),
		"color_theory": SkillManager.get_skill_level("color_theory"),
		"crafting": SkillManager.get_skill_level("crafting")
	}
	
	# Calculate base quality from skills
	artwork.calculate_quality_from_skills(artwork.skill_level_at_creation, artwork.materials_used)
	
	# Apply material and inspiration bonuses
	apply_artwork_bonuses(artwork, canvas_size, paint_color, inspiration)
	
	# Ensure quality is within valid range
	artwork.quality_score = clamp(artwork.quality_score, 0.1, 10.0)
	
	return artwork

func apply_artwork_bonuses(artwork: ArtworkData, canvas_size: String, paint_color: String, inspiration: String):
	"""Apply bonuses to artwork quality based on materials and inspiration"""
	
	# Canvas size bonus
	match canvas_size.to_lower():
		"large":
			artwork.quality_score += 0.5
		"medium":
			artwork.quality_score += 0.2
		"small":
			artwork.quality_score += 0.0
	
	# Paint quality bonus (some colors are harder to work with)
	match paint_color.to_lower():
		"purple", "orange":
			artwork.quality_score += 0.3  # Complex mixed colors
		"red", "blue", "yellow":
			artwork.quality_score += 0.1  # Primary colors
		"green":
			artwork.quality_score += 0.2  # Mixed color
	
	# Inspiration bonus
	if inspiration != "":
		var inspiration_bonus = get_inspiration_quality_bonus(inspiration)
		artwork.quality_score += inspiration_bonus
		print("  Inspiration bonus from '%s': +%.1f" % [inspiration, inspiration_bonus])
	
	# Skill synergy bonus (when multiple skills are high)
	var skill_synergy = calculate_skill_synergy_bonus(artwork.skill_level_at_creation)
	artwork.quality_score += skill_synergy
	if skill_synergy > 0:
		print("  Skill synergy bonus: +%.1f" % skill_synergy)

func get_inspiration_quality_bonus(inspiration: String) -> float:
	"""Calculate quality bonus from inspiration source"""
	if not GameManager.player_data:
		return 0.0
	
	# Find the sketch that matches this inspiration
	for artwork_item in GameManager.player_data.portfolio:
		if artwork_item.artwork_type == ArtworkData.ArtworkType.SKETCH:
			var sketch_subject = artwork_item.title.replace("Sketch of ", "")
			if sketch_subject == inspiration:
				# Bonus based on sketch quality
				return artwork_item.quality_score * 0.1
	
	return 0.3  # Default bonus if sketch not found

func calculate_skill_synergy_bonus(skills: Dictionary) -> float:
	"""Calculate bonus for having multiple high skills"""
	var high_skills = 0
	var total_skill_level = 0
	
	for skill_name in ["painting", "color_theory", "crafting"]:
		if skills.has(skill_name):
			var level = skills[skill_name]
			total_skill_level += level
			if level >= 5:
				high_skills += 1
	
	# Bonus for having multiple high skills
	var synergy_bonus = 0.0
	if high_skills >= 2:
		synergy_bonus += 0.3
	if high_skills >= 3:
		synergy_bonus += 0.2
	
	# Additional bonus for very high average skill level
	var average_skill = total_skill_level / 3.0
	if average_skill >= 7:
		synergy_bonus += 0.4
	elif average_skill >= 5:
		synergy_bonus += 0.2
	
	return synergy_bonus

func award_painting_experience(quality: float) -> Dictionary:
	"""Award painting experience based on artwork quality"""
	var base_exp = 15
	var quality_bonus = int(quality * 3)
	var painting_exp = base_exp + quality_bonus
	var color_theory_exp = (base_exp + quality_bonus) / 2
	
	# Award experience with detailed feedback
	SkillManager.add_experience("painting", painting_exp, "Creating artwork")
	SkillManager.add_experience("color_theory", color_theory_exp, "Color application")
	
	# Small bonus to crafting for using materials skillfully
	var crafting_exp = max(5, quality_bonus / 2)
	SkillManager.add_experience("crafting", crafting_exp, "Material application")
	
	return {
		"painting": painting_exp,
		"color_theory": color_theory_exp,
		"crafting": crafting_exp
	}

func get_available_canvases() -> Array:
	"""Get list of available canvas sizes in inventory"""
	var canvases = []
	if GameManager.player_data:
		for item in GameManager.player_data.inventory:
			if item.item_type == InventoryItem.ItemType.CANVAS:
				var size = item.display_name.replace(" Canvas", "")
				if not canvases.has(size):
					canvases.append(size)
	return canvases

func get_available_paints() -> Array:
	"""Get list of available paint colors in inventory"""
	var paints = []
	if GameManager.player_data:
		for item in GameManager.player_data.inventory:
			if item.item_type == InventoryItem.ItemType.PAINT:
				var color = item.display_name.replace(" Paint", "")
				if not paints.has(color):
					paints.append(color)
	return paints

func get_available_sketches() -> Array:
	"""Get list of available sketches for inspiration"""
	var sketches = []
	if GameManager.player_data:
		for artwork in GameManager.player_data.portfolio:
			if artwork.artwork_type == ArtworkData.ArtworkType.SKETCH:
				var subject = artwork.title.replace("Sketch of ", "")
				if not sketches.has(subject):
					sketches.append(subject)
	return sketches

func get_best_available_sketch() -> String:
	"""Get the highest quality sketch for inspiration"""
	var best_sketch = ""
	var best_quality = 0.0
	
	if GameManager.player_data:
		for artwork in GameManager.player_data.portfolio:
			if artwork.artwork_type == ArtworkData.ArtworkType.SKETCH and artwork.quality_score > best_quality:
				best_quality = artwork.quality_score
				best_sketch = artwork.title.replace("Sketch of ", "")
	
	return best_sketch

func get_materials_text(materials: Array) -> String:
	"""Get formatted text for materials list"""
	var text_parts = []
	for material in materials:
		var name = get_material_display_name(material.item_id)
		text_parts.append("%s x%d" % [name, material.amount])
	return ", ".join(text_parts)

func get_missing_materials_text(missing_materials: Array) -> String:
	"""Get formatted text for missing materials"""
	return get_materials_text(missing_materials)

func get_material_display_name(item_id: String) -> String:
	"""Get display name for material item ID"""
	return item_id.capitalize().replace("_", " ")

# Test function to add some starting materials
func add_test_materials():
	"""Add some test materials to player"""
	if GameManager.player_data:
		# Add some canvases and paints
		var small_canvas = InventoryItem.create_canvas("Small")
		var red_paint = InventoryItem.create_paint("Red")
		var blue_paint = InventoryItem.create_paint("Blue")
		
		GameManager.player_data.add_inventory_item(small_canvas)
		GameManager.player_data.add_inventory_item(red_paint)
		GameManager.player_data.add_inventory_item(blue_paint)
		
		print("✅ Added test materials to inventory")
