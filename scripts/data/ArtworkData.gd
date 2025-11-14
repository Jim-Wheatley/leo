class_name ArtworkData extends RefCounted

# Artwork data class for portfolio management

enum ArtworkType {
	SKETCH,
	PAINTING,
	STUDY,
	MASTERWORK
}

var artwork_id: String
var title: String
var artwork_type: ArtworkType
var quality_score: float
var creation_date: String
var materials_used: Array = []
var skill_level_at_creation: Dictionary = {}
var thumbnail_texture: Texture2D
var inspiration_source: String = ""

func _init():
	artwork_id = ""
	title = ""
	artwork_type = ArtworkType.SKETCH
	quality_score = 1.0
	creation_date = Time.get_datetime_string_from_system()
	materials_used = []
	skill_level_at_creation = {}
	thumbnail_texture = null
	inspiration_source = ""

func get_quality_description() -> String:
	"""Get a text description of the artwork quality"""
	if quality_score >= 9.0:
		return "Masterpiece"
	elif quality_score >= 7.5:
		return "Excellent"
	elif quality_score >= 6.0:
		return "Good"
	elif quality_score >= 4.5:
		return "Fair"
	elif quality_score >= 3.0:
		return "Poor"
	else:
		return "Terrible"

func calculate_quality_from_skills(skills: Dictionary, materials: Array):
	"""Calculate artwork quality based on player skills and materials"""
	var base_quality = 2.0
	
	# Skill-based quality calculation
	match artwork_type:
		ArtworkType.PAINTING:
			var painting_skill = skills.get("painting", 1)
			var color_theory_skill = skills.get("color_theory", 1)
			var crafting_skill = skills.get("crafting", 1)
			quality_score = base_quality + (painting_skill * 0.4) + (color_theory_skill * 0.3) + (crafting_skill * 0.2)
		
		ArtworkType.SKETCH:
			var sketching_skill = skills.get("sketching", 1)
			var observation_skill = skills.get("observation", 1)
			quality_score = base_quality + (sketching_skill * 0.5) + (observation_skill * 0.4)
		
		ArtworkType.STUDY:
			var avg_skill = 0
			var skill_count = 0
			for skill_name in skills:
				avg_skill += skills[skill_name]
				skill_count += 1
			if skill_count > 0:
				avg_skill /= skill_count
			quality_score = base_quality + (avg_skill * 0.3)
		
		ArtworkType.MASTERWORK:
			var total_skill = 0
			for skill_name in skills:
				total_skill += skills[skill_name]
			quality_score = base_quality + (total_skill * 0.1)
	
	# Add some randomness
	quality_score += randf_range(-0.5, 0.5)
	
	# Ensure quality is within bounds
	quality_score = clamp(quality_score, 0.1, 10.0)

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
		"inspiration_source": inspiration_source
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

# Static factory methods for common artwork types
static func create_sketch(subject: String, skills: Dictionary) -> ArtworkData:
	"""Create a sketch artwork"""
	var sketch = ArtworkData.new()
	sketch.artwork_id = "sketch_" + subject.to_lower().replace(" ", "_")
	sketch.title = "Sketch of " + subject
	sketch.artwork_type = ArtworkType.SKETCH
	sketch.skill_level_at_creation = skills
	sketch.materials_used = ["Charcoal", "Paper"]
	sketch.inspiration_source = subject
	
	# Calculate quality based on skills
	sketch.calculate_quality_from_skills(skills, sketch.materials_used)
	
	return sketch

static func create_painting(title: String, skills: Dictionary, materials: Array) -> ArtworkData:
	"""Create a painting artwork"""
	var painting = ArtworkData.new()
	painting.artwork_id = "painting_" + title.to_lower().replace(" ", "_")
	painting.title = title
	painting.artwork_type = ArtworkType.PAINTING
	painting.skill_level_at_creation = skills
	painting.materials_used = materials
	
	# Calculate quality based on skills
	painting.calculate_quality_from_skills(skills, materials)
	
	return painting