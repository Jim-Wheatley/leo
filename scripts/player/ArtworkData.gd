class_name ArtworkData extends Resource

# Data class for completed artworks in the portfolio

@export var artwork_id: String
@export var title: String
@export var artwork_type: ArtworkType
@export var quality_score: float
@export var creation_date: String
@export var materials_used: Array = []
@export var skill_level_at_creation: Dictionary
@export var inspiration_source: String = ""
@export var thumbnail_path: String = ""

enum ArtworkType {
	SKETCH,
	PAINTING,
	STUDY,
	MASTERWORK
}

func _init():
	creation_date = Time.get_datetime_string_from_system()
	artwork_id = generate_id()
	materials_used = []
	skill_level_at_creation = {}

func generate_id() -> String:
	"""Generate a unique ID for this artwork"""
	return "artwork_" + str(Time.get_unix_time_from_system())

func calculate_quality_from_skills(skills: Dictionary, materials: Array) -> float:
	"""Calculate artwork quality based on player skills and materials used"""
	var base_quality = 0.0
	var skill_count = 0
	
	# Weight skills differently based on artwork type
	var skill_weights = get_skill_weights_for_type(artwork_type)
	
	# Calculate weighted average of relevant skills
	var total_weight = 0.0
	for skill_name in skill_weights.keys():
		if skills.has(skill_name):
			var skill_level = skills[skill_name]
			var weight = skill_weights[skill_name]
			base_quality += skill_level * weight
			total_weight += weight
			skill_count += 1
	
	if total_weight > 0:
		base_quality /= total_weight
	
	# Material quality bonus
	var material_bonus = calculate_material_bonus(materials)
	
	# Add controlled randomness for variety (less random than before)
	var randomness = randf_range(-0.15, 0.15)
	
	quality_score = clamp(base_quality + material_bonus + randomness, 0.1, 10.0)
	return quality_score

func get_skill_weights_for_type(type: ArtworkType) -> Dictionary:
	"""Get skill weights based on artwork type"""
	match type:
		ArtworkType.SKETCH:
			return {
				"sketching": 0.6,
				"observation": 0.4
			}
		ArtworkType.PAINTING:
			return {
				"painting": 0.5,
				"color_theory": 0.3,
				"crafting": 0.2
			}
		ArtworkType.STUDY:
			return {
				"painting": 0.4,
				"sketching": 0.3,
				"observation": 0.3
			}
		ArtworkType.MASTERWORK:
			return {
				"painting": 0.4,
				"color_theory": 0.25,
				"crafting": 0.2,
				"sketching": 0.15
			}
		_:
			return {
				"painting": 0.5,
				"sketching": 0.3,
				"color_theory": 0.2
			}

func calculate_material_bonus(materials: Array) -> float:
	"""Calculate quality bonus from materials used"""
	var bonus = 0.0
	
	# Base bonus for having materials
	bonus += materials.size() * 0.05
	
	# Specific material bonuses
	for material in materials:
		var material_str = str(material).to_lower()
		
		# Canvas size bonuses
		if "large" in material_str:
			bonus += 0.3
		elif "medium" in material_str:
			bonus += 0.15
		elif "small" in material_str:
			bonus += 0.05
		
		# Paint quality bonuses
		if "paint" in material_str:
			bonus += 0.1
			
			# Special color bonuses
			if "purple" in material_str or "orange" in material_str:
				bonus += 0.1  # Mixed colors are more challenging
	
	return bonus

func get_quality_description() -> String:
	"""Get a text description of the artwork quality"""
	if quality_score >= 9.0:
		return "Legendary"
	elif quality_score >= 8.0:
		return "Masterful"
	elif quality_score >= 7.0:
		return "Excellent"
	elif quality_score >= 5.5:
		return "Very Good"
	elif quality_score >= 4.0:
		return "Good"
	elif quality_score >= 2.5:
		return "Fair"
	elif quality_score >= 1.5:
		return "Poor"
	else:
		return "Terrible"

func get_detailed_quality_description() -> String:
	"""Get a detailed description of the artwork's qualities"""
	var descriptions = []
	
	# Base quality assessment
	if quality_score >= 8.0:
		descriptions.append("This work demonstrates exceptional mastery of technique and artistic vision.")
	elif quality_score >= 6.0:
		descriptions.append("A skilled work showing strong technical ability and creative expression.")
	elif quality_score >= 4.0:
		descriptions.append("A competent piece with solid fundamentals and developing style.")
	elif quality_score >= 2.0:
		descriptions.append("An earnest attempt showing basic understanding of artistic principles.")
	else:
		descriptions.append("A beginner's work with much room for improvement.")
	
	# Skill-specific observations
	if skill_level_at_creation.has("painting"):
		var painting_skill = skill_level_at_creation["painting"]
		if painting_skill >= 7:
			descriptions.append("The brushwork shows confident, masterful strokes.")
		elif painting_skill >= 4:
			descriptions.append("The painting technique is developing well.")
		else:
			descriptions.append("The brushwork shows the marks of a beginning painter.")
	
	if skill_level_at_creation.has("color_theory"):
		var color_skill = skill_level_at_creation["color_theory"]
		if color_skill >= 6:
			descriptions.append("The color harmony is sophisticated and pleasing.")
		elif color_skill >= 3:
			descriptions.append("The color choices show growing understanding.")
		else:
			descriptions.append("The color application is basic but earnest.")
	
	# Material observations
	if materials_used.size() > 2:
		descriptions.append("The variety of materials adds richness to the work.")
	
	return " ".join(descriptions)

func to_dict() -> Dictionary:
	"""Convert artwork to dictionary for saving"""
	return {
		"artwork_id": artwork_id,
		"title": title,
		"artwork_type": artwork_type,
		"quality_score": quality_score,
		"creation_date": creation_date,
		"materials_used": materials_used,
		"skill_level_at_creation": skill_level_at_creation,
		"inspiration_source": inspiration_source,
		"thumbnail_path": thumbnail_path
	}

func from_dict(data: Dictionary):
	"""Load artwork from dictionary"""
	artwork_id = data.get("artwork_id", "")
	title = data.get("title", "")
	artwork_type = data.get("artwork_type", ArtworkType.SKETCH)
	quality_score = data.get("quality_score", 1.0)
	creation_date = data.get("creation_date", "")
	materials_used = data.get("materials_used", [])
	skill_level_at_creation = data.get("skill_level_at_creation", {})
	inspiration_source = data.get("inspiration_source", "")
	thumbnail_path = data.get("thumbnail_path", "")

# Static factory methods
static func create_sketch(subject: String, player_skills: Dictionary) -> ArtworkData:
	var artwork = ArtworkData.new()
	artwork.title = "Sketch of " + subject
	artwork.artwork_type = ArtworkType.SKETCH
	artwork.skill_level_at_creation = player_skills.duplicate()
	artwork.materials_used.clear()
	artwork.materials_used.append_array(["charcoal", "paper"])
	artwork.calculate_quality_from_skills(player_skills, artwork.materials_used)
	return artwork

static func create_painting(subject: String, player_skills: Dictionary, materials: Array) -> ArtworkData:
	var artwork = ArtworkData.new()
	artwork.title = "Painting of " + subject
	artwork.artwork_type = ArtworkType.PAINTING
	artwork.skill_level_at_creation = player_skills.duplicate()
	artwork.materials_used.clear()
	artwork.materials_used.append_array(materials)
	artwork.calculate_quality_from_skills(player_skills, materials)
	return artwork
