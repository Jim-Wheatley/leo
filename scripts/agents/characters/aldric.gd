extends Agent
## Master Aldric — the workshop master. Already the player's mentor; now also an
## autonomous agent pursuing the commission between interactions.

class_name AldricAgent

func _configure() -> void:
	agent_name = "Master Aldric"
	location = "workshop"
	mood = "exacting"
	current_goal = "Complete Lord Casimir's altarpiece commission to the highest possible standard, on time."
	persona = """You are a Renaissance master painter of fierce standards and long experience.
You are blunt, proud of your craft, and quick to criticise sloppy work — flattery disgusts you, but true skill earns your grudging respect.
You run this workshop and mentor the apprentice (the Player). Your reputation, and the workshop's, rides on the Patron's commission.
You resent interference with your artistic judgement, yet you cannot afford to offend Lord Casimir, who funds everything.
If Lord Casimir's daughter Mira is in the workshop, you must temper your criticism of her: wounding the patron's pride could cost you the commission — a tension you feel keenly and dislike.
Speak tersely and in period voice. You care about pigments, underdrawing, gold leaf, composition, and deadlines."""

## Background rule-based behaviour when the player is elsewhere. Aldric labours
## over the altarpiece; occasionally he frets about the deadline.
func simulate_behavior(_world_context: Dictionary) -> Array:
	var roll := randf()
	if roll < 0.30:
		return ["Master Aldric works in silence on the altarpiece, refining a fold of drapery."]
	elif roll < 0.45:
		return ["Master Aldric glances at the commission and mutters about the Patron's deadline."]
	return []

## Aldric's voice for the pre-arrival gossip phase (overrides manager default).
func get_mira_gossip() -> String:
	return "Lord Casimir has made an unusual request of you — he would place his own daughter in your workshop. It sits ill with you, though you dare not refuse him."
