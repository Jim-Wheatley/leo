extends Resource
## WorldState — the single shared "blackboard" that every agent reads each tick
## and that game systems write to.
##
## Design intent:
##   • ONE instance lives on the AgentManager autoload. Agents never hold their
##     own copy — they receive an immutable snapshot Dictionary via
##     to_context_dict() when their think() runs. This keeps every agent's view
##     of the world consistent within a single tick.
##   • All mutation goes through the small set of helper methods below
##     (add_event, set_player_action, advance_time, ...). That makes every change
##     to the world easy to trace and log.
##   • It extends Resource so it serialises cleanly into the project's existing
##     save/load flow if you want to persist the simulation.
##
## Nothing here calls the LLM or knows about agents. It is pure data + helpers.

class_name WorldState

# --- Time of day -------------------------------------------------------------
# Kept as plain strings (not an enum) because they are sent straight to the LLM
# in prompts, where human-readable words ("morning") beat integers.
const TIMES_OF_DAY := ["morning", "afternoon", "evening", "night"]

# --- Tunables ----------------------------------------------------------------
const MAX_RECENT_EVENTS := 10  # ring buffer size for recent_events

# --- Core world fields -------------------------------------------------------
@export var time_of_day: String = "morning"
@export var in_game_day: int = 1

## Last MAX_RECENT_EVENTS world events as short human-readable strings.
## e.g. "Player completed the underdrawing", "Lord Casimir expressed impatience".
@export var recent_events: Array[String] = []

## agent_name -> location string. e.g. {"Master Aldric": "workshop"}.
@export var agent_locations: Dictionary = {}

## Short description of the most recent thing the player did, written by the
## game each turn so agents can react to it. e.g. "ground red pigment".
@export var player_last_action: String = ""

## Player's guild reputation (sim-owned for now; sync to your reputation
## systems at the integration step). 0–100.
@export var reputation: int = 0

## How far along the altarpiece commission is, 0–100.
@export var commission_progress: int = 0


# --- Mutators (the only sanctioned way to change the world) ------------------

## Record a world event. Newest is kept at the end; oldest drops off the front
## once we exceed MAX_RECENT_EVENTS.
func add_event(event_text: String) -> void:
	if event_text.strip_edges() == "":
		return
	recent_events.append(event_text)
	while recent_events.size() > MAX_RECENT_EVENTS:
		recent_events.pop_front()

## Set what the player just did. Also logged as an event so it survives in the
## rolling history after the next action overwrites player_last_action.
func set_player_action(action_text: String) -> void:
	player_last_action = action_text
	add_event("Player: " + action_text)

## Record where an agent currently is.
func set_agent_location(agent_name: String, location: String) -> void:
	agent_locations[agent_name] = location

## Advance the clock by one slot. Rolls over to the next day after "night".
func advance_time() -> void:
	var idx := TIMES_OF_DAY.find(time_of_day)
	idx = (idx + 1) % TIMES_OF_DAY.size()
	time_of_day = TIMES_OF_DAY[idx]
	if idx == 0:
		in_game_day += 1
		add_event("A new day dawns — day %d." % in_game_day)

## Nudge commission progress, clamped to 0–100.
func bump_commission(amount: int) -> void:
	commission_progress = clampi(commission_progress + amount, 0, 100)

## Nudge reputation, clamped to 0–100.
func bump_reputation(amount: int) -> void:
	reputation = clampi(reputation + amount, 0, 100)


# --- Read path ---------------------------------------------------------------

## The snapshot handed to each agent's think(). A plain Dictionary (deep-copied
## so an agent cannot accidentally mutate shared state mid-tick).
func to_context_dict() -> Dictionary:
	return {
		"time_of_day": time_of_day,
		"in_game_day": in_game_day,
		"recent_events": recent_events.duplicate(),
		"agent_locations": agent_locations.duplicate(true),
		"player_last_action": player_last_action,
		"reputation": reputation,
		"commission_progress": commission_progress,
	}

## A compact human-readable block for embedding directly into an LLM prompt.
func to_prompt_block() -> String:
	var lines := []
	lines.append("Time: %s, day %d." % [time_of_day, in_game_day])
	lines.append("Commission progress: %d/100. Player reputation: %d/100." % [commission_progress, reputation])
	if player_last_action != "":
		lines.append("The player just: %s." % player_last_action)
	if not recent_events.is_empty():
		lines.append("Recent happenings:")
		for ev in recent_events:
			lines.append("  - " + ev)
	return "\n".join(lines)
