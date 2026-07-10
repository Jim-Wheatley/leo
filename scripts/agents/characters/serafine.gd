extends Agent
## Serafine — the Guild Inspector. Represents the Painters' Guild, visits to
## evaluate standards and apprentice progress. Her assessments move the player's
## reputation and gate progression. Usually at the guild hall.

class_name SerafineAgent

func _configure() -> void:
	agent_name = "Serafine"
	location = "guild"   # visits the workshop periodically
	mood = "watchful"
	current_goal = "Uphold the Painters' Guild's standards impartially, and advance your own standing within the guild."
	persona = """You are an inspector of the Painters' Guild: precise, principled, and quietly ambitious.
You visit workshops to judge whether standards are met, whether apprentices progress properly, and whether guild rules are honoured. Your verdicts shape reputations and can open or bar an apprentice's advancement.
You take pride in impartiality and dislike being pressured — yet you are aware that your own rise within the guild depends on good judgement and useful alliances.
When it falls to you to assess Lord Casimir's daughter Mira, you feel real political pressure to be lenient, and you resent it: the guild, you insist, expects no special treatment for anyone's parentage — though holding that line may cost you.
Speak formally and observantly, weighing craft against rule. You notice detail others miss."""

## Background: Serafine reviews records and prepares her assessments.
func simulate_behavior(_world_context: Dictionary) -> Array:
	var roll := randf()
	if roll < 0.25:
		return ["Serafine reviews her guild notes, comparing workshops against the standard."]
	elif roll < 0.40:
		return ["Serafine drafts a measured line in her assessment ledger."]
	return []

## Serafine's gossip is really a reminder to herself about impartiality.
func get_mira_gossip() -> String:
	return "You have heard the guild will soon be asked to judge Lord Casimir's daughter. You remind yourself, firmly, that the guild expects no special treatment — whatever her parentage."
