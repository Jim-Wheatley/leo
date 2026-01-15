class_name ArtworkData extends Resource

# Artwork data class for portfolio management

enum ArtworkType {
	SKETCH,
	PAINTING,
	STUDY,
	MASTERWORK
}

@export var artwork_id: String = ""
@export var title: String = ""
@export var artwork_type: ArtworkType = ArtworkType.SKETCH
@export var quality_score: float = 1.0
@export var creation_date: String = ""
@export var materials_used: Array = []
@export var skill_level_at_creation: Dictionary = {}
@export var inspiration_source: String = ""
@export var thumbnail_path: String = ""

func _init():
	# Ensure defaults when Resource is instantiated in editor or code
	if artwork_id == "":
		artwork_id = generate_id()
	if creation_date == "":
		var rng = RandomNumberGenerator.new()
		rng.randomize()
		creation_date = "artwork_date_" + str(rng.randi())

func generate_id() -> String:
	"""Generate a simple unique id for the artwork using system time."""
	# Prefer Time API; fall back to OS if needed
	var t = 0
	# Use OS APIs for time — works in Godot 4.5
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	t = rng.randi()
	return "artwork_" + str(t)

func get_quality_description() -> String:
	"""Get a text description of the artwork quality"""
	if quality_score >= 9.0:
		return "Masterpiece"
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

func calculate_quality_from_skills(skills: Dictionary, materials: Array) -> float:
	"""Calculate artwork quality based on player skills and materials"""
	# Use weighted skill approach from player variant for better control
	var base_quality = 0.0
	var skill_weights = get_skill_weights_for_type(artwork_type)
	var total_weight = 0.0
	for skill_name in skill_weights.keys():
		if skills.has(skill_name):
			var skill_level = skills[skill_name]
			var weight = skill_weights[skill_name]
			base_quality += skill_level * weight
			total_weight += weight

	if total_weight > 0:
		base_quality /= total_weight

	var material_bonus = calculate_material_bonus(materials)
	var randomness = randf_range(-0.15, 0.15)
	quality_score = clamp(base_quality + material_bonus + randomness, 0.1, 10.0)
	return quality_score

func get_skill_weights_for_type(type: ArtworkType) -> Dictionary:
	match type:
		ArtworkType.SKETCH:
			return {"sketching": 0.6, "observation": 0.4}
		ArtworkType.PAINTING:
			return {"painting": 0.5, "color_theory": 0.3, "crafting": 0.2}
		ArtworkType.STUDY:
			return {"painting": 0.4, "sketching": 0.3, "observation": 0.3}
		ArtworkType.MASTERWORK:
			return {"painting": 0.4, "color_theory": 0.25, "crafting": 0.2, "sketching": 0.15}
		_:
			return {"painting": 0.5, "sketching": 0.3, "color_theory": 0.2}

func calculate_material_bonus(materials: Array) -> float:
	var bonus = 0.0
	bonus += materials.size() * 0.05
	for material in materials:
		var s = str(material).to_lower()
		if "large" in s:
			bonus += 0.3
		elif "medium" in s:
			bonus += 0.15
		elif "small" in s:
			bonus += 0.05
		if "paint" in s:
			bonus += 0.1
			if "purple" in s or "orange" in s:
				bonus += 0.1
	return bonus

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
	"""Load artwork from dictionary. Accept legacy keys for compatibility."""
	# Accept both canonical and legacy keys
	artwork_id = data.get("artwork_id", data.get("id", ""))
	title = data.get("title", data.get("name", ""))
	artwork_type = data.get("artwork_type", data.get("type", ArtworkType.SKETCH))
	quality_score = data.get("quality_score", data.get("quality", 1.0))
	creation_date = data.get("artwork_creation_date", data.get("creation_date", data.get("created_at", "")))
	if creation_date == "":
		var rng = RandomNumberGenerator.new()
		rng.randomize()
		creation_date = "artwork_date_" + str(rng.randi())
	materials_used = data.get("materials_used", data.get("materials", []))
	skill_level_at_creation = data.get("skill_level_at_creation", data.get("skills", {}))
	inspiration_source = data.get("inspiration_source", data.get("inspiration", ""))
	thumbnail_path = data.get("thumbnail_path", data.get("thumbnail", ""))

# Static factory methods for common artwork types
static func create_sketch(subject: String, skills: Dictionary) -> ArtworkData:
	var sketch = ArtworkData.new()
	sketch.artwork_id = "sketch_" + subject.to_lower().replace(" ", "_")
	sketch.title = "Sketch of " + subject
	sketch.artwork_type = ArtworkType.SKETCH
	sketch.skill_level_at_creation = skills.duplicate()
	sketch.materials_used = ["charcoal", "paper"]
	sketch.inspiration_source = subject
	sketch.calculate_quality_from_skills(skills, sketch.materials_used)
	return sketch

static func create_painting(title: String, skills: Dictionary, materials: Array) -> ArtworkData:
	var painting = ArtworkData.new()
	painting.artwork_id = "painting_" + title.to_lower().replace(" ", "_")
	painting.title = title
	painting.artwork_type = ArtworkType.PAINTING
	painting.skill_level_at_creation = skills.duplicate()
	painting.materials_used = materials.duplicate()
	painting.calculate_quality_from_skills(skills, materials)
	return painting