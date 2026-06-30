extends Node
## Agent — base class for every simulated NPC in the living world.
##
## One Agent = one character (Aldric, Casimir, Fenwick, ...). Character-specific
## files in scripts/agents/characters/ subclass this and override _configure()
## to set their persona and goal. The base class handles everything else:
##   • building a fresh, self-contained system prompt each tick
##   • a rolling conversation history capped at MAX_HISTORY turns
##   • condensing overflow into a lean running summary
##   • the async LLM call (reusing the project's existing LLMClient)
##
## Agent deliberately knows NOTHING about game systems. think() emits the raw
## LLM response via the thought_ready signal; AgentManager + action_parser turn
## that text into actual game actions. That keeps each agent self-contained.

class_name Agent

# --- Tunables ----------------------------------------------------------------
const MAX_HISTORY := 15      # rolling window of {role, content} turns
const SUMMARISE_KEEP := 7    # turns retained verbatim after a summarise pass
const THINK_MAX_TOKENS := 350

# --- Signals -----------------------------------------------------------------
## Emitted after a successful think(). AgentManager listens and routes the text
## through action_parser. response_text is the full natural-language reply.
signal thought_ready(agent_name: String, response_text: String)
## Emitted when the LLM call fails (LM Studio offline, bad response, ...).
signal thought_failed(agent_name: String, error: String)

# --- Identity / state --------------------------------------------------------
var agent_name: String = "Unnamed"
var persona: String = ""          # who they are — set by _configure()
var current_goal: String = ""     # what they're pursuing right now
var mood: String = "neutral"
var location: String = "workshop"

## When false, AgentManager runs this agent on cheap rule-based behaviour
## instead of calling the LLM (see simulate_behavior in the manager).
var is_active: bool = false

# --- Memory ------------------------------------------------------------------
## Rolling list of {role: "user"/"assistant", content: String}. Capped at
## MAX_HISTORY; older turns are folded into history_summary.
var conversation_history: Array[Dictionary] = []
## Condensed text of everything that scrolled out of the window.
var history_summary: String = ""
## The last thing this agent said — handy for debugging and for the manager.
var last_response: String = ""
## The system prompt built on the most recent think() (exposed for inspection).
var system_prompt: String = ""

# --- Internals ---------------------------------------------------------------
var _llm_client: LLMClient = null
var _request_in_flight: bool = false
var debug_mode: bool = true


func _ready() -> void:
	_configure()
	if agent_name == "Unnamed" and debug_mode:
		push_warning("Agent _configure() did not set agent_name")

## Override in character subclasses to set agent_name / persona / current_goal /
## mood / location. Base implementation does nothing.
func _configure() -> void:
	pass

## Cheap, rule-based behaviour for when this agent is in the BACKGROUND tier
## (too far from the player to justify an LLM call). Override in character
## subclasses. MUST NOT call the LLM. Return a list of short world-event strings
## to record this tick (or [] for nothing happening).
func simulate_behavior(_world_context: Dictionary) -> Array:
	return []


# --- Thinking ----------------------------------------------------------------

## Ask the LLM what this agent does/says this tick, given the world snapshot.
## Async: callers may `await agent.think(ctx)`. Result is delivered via the
## thought_ready / thought_failed signals (and stored in last_response).
func think(world_context: Dictionary) -> void:
	if _request_in_flight:
		if debug_mode:
			print("[%s] think() skipped — a request is already in flight" % agent_name)
		return
	_request_in_flight = true

	_ensure_client()

	# Build a fresh system prompt every tick so world context is never stale.
	system_prompt = _build_system_prompt(world_context)

	# Perception: what the agent notices this tick becomes a user turn.
	var perception := _build_perception(world_context)
	_append_history("user", perception)

	var messages := _assemble_messages()

	if debug_mode:
		print("[%s] → thinking (%d history turns, mood=%s)" % [agent_name, conversation_history.size(), mood])

	var response: Dictionary = await _llm_client.call_completions(messages, THINK_MAX_TOKENS)
	_request_in_flight = false

	if not response.ok:
		if debug_mode:
			print("[%s] ← LLM failed: %s" % [agent_name, response.error])
		thought_failed.emit(agent_name, response.error)
		return

	var reply: String = response.content.strip_edges()
	last_response = reply
	_append_history("assistant", reply)
	_maybe_summarise()

	if debug_mode:
		var preview := reply.substr(0, 160)
		print("[%s] ← %s%s" % [agent_name, preview, "..." if reply.length() > 160 else ""])

	thought_ready.emit(agent_name, reply)


# --- Prompt construction -----------------------------------------------------

func _build_system_prompt(world_context: Dictionary) -> String:
	var parts: Array[String] = []

	parts.append("You are %s." % agent_name)
	if persona != "":
		parts.append(persona)
	if current_goal != "":
		parts.append("Your current goal: %s" % current_goal)
	parts.append("Your current mood is %s. You are at the %s." % [mood, location])

	# Live world context.
	parts.append("\nCURRENT WORLD STATE:")
	parts.append(_world_context_to_text(world_context))

	# Carry the condensed memory of older events, if any.
	if history_summary != "":
		parts.append("\nWHAT HAS HAPPENED BEFORE (summary):\n" + history_summary)

	# Behavioural contract: stay in character, keep it short, use actions.
	parts.append("""
Stay fully in character. Speak and act as %s would, in a fantasy medieval setting.
Keep your reply to a few sentences — this is one moment in an ongoing day, not a speech.
You MAY take in-world actions by embedding them on their own, using this exact syntax:
[ACTION: verb target]
Examples: [ACTION: move market]  [ACTION: speak Player]  [ACTION: give Player pigment]  [ACTION: inspect commission]
Only use actions that make sense for what you are doing. Narrate naturally; the actions drive the world.""" % agent_name)

	return "\n".join(parts)

## Default world-context formatting. Mirrors WorldState.to_prompt_block() but
## works straight off the snapshot Dictionary so Agent stays decoupled from the
## WorldState class.
func _world_context_to_text(ctx: Dictionary) -> String:
	var lines: Array[String] = []
	lines.append("Time: %s, day %s." % [ctx.get("time_of_day", "?"), str(ctx.get("in_game_day", "?"))])
	lines.append("Commission progress: %s/100. Player reputation: %s/100." % [
		str(ctx.get("commission_progress", 0)), str(ctx.get("reputation", 0))])
	var locs: Dictionary = ctx.get("agent_locations", {})
	if not locs.is_empty():
		var who: Array[String] = []
		for n in locs:
			who.append("%s at %s" % [n, locs[n]])
		lines.append("Who is around: " + ", ".join(who) + ".")
	var last_action: String = ctx.get("player_last_action", "")
	if last_action != "":
		lines.append("The player just: %s." % last_action)
	var events: Array = ctx.get("recent_events", [])
	if not events.is_empty():
		lines.append("Recent happenings:")
		for ev in events:
			lines.append("  - " + str(ev))
	return "\n".join(lines)

## The user-turn "perception" for this tick. Kept short; the heavy context lives
## in the system prompt. Subclasses can override for character-specific framing.
func _build_perception(ctx: Dictionary) -> String:
	var last_action: String = ctx.get("player_last_action", "")
	if last_action != "":
		return "It is %s. The player just %s. What do you do or say now?" % [
			ctx.get("time_of_day", "now"), last_action]
	return "It is %s. What do you do or say now?" % ctx.get("time_of_day", "now")

## Final message array sent to the LLM: system prompt + rolling history.
func _assemble_messages() -> Array:
	var messages: Array = [{"role": "system", "content": system_prompt}]
	for turn in conversation_history:
		messages.append(turn)
	return messages


# --- Memory management -------------------------------------------------------

func _append_history(role: String, content: String) -> void:
	if content.strip_edges() == "":
		return
	conversation_history.append({"role": role, "content": content})

## Fold the oldest turns into history_summary once we exceed the window, keeping
## only the most recent SUMMARISE_KEEP turns verbatim. Synchronous + local so it
## never adds latency to the tick that triggers it.
func _maybe_summarise() -> void:
	if conversation_history.size() <= MAX_HISTORY:
		return
	summarise_history()

## Public so AgentManager / tests can force a condense. Heuristic for now;
## swap in an LLM-based history_summariser util later without changing callers.
func summarise_history() -> void:
	var overflow := conversation_history.size() - SUMMARISE_KEEP
	if overflow <= 0:
		return

	var to_fold := conversation_history.slice(0, overflow)
	conversation_history = conversation_history.slice(overflow, conversation_history.size())

	var bullets: Array[String] = []
	for turn in to_fold:
		var speaker: String = agent_name if turn["role"] == "assistant" else "Events"
		var text: String = turn["content"].strip_edges()
		if text.length() > 140:
			text = text.substr(0, 140) + "..."
		bullets.append("- %s: %s" % [speaker, text])

	var folded := "\n".join(bullets)
	history_summary = folded if history_summary == "" else history_summary + "\n" + folded

	# Keep the summary itself bounded so it can't grow without limit either.
	var summary_lines := history_summary.split("\n")
	if summary_lines.size() > MAX_HISTORY:
		summary_lines = summary_lines.slice(summary_lines.size() - MAX_HISTORY, summary_lines.size())
		history_summary = "\n".join(summary_lines)

	if debug_mode:
		print("[%s] summarised %d turns; history now %d turns" % [
			agent_name, to_fold.size(), conversation_history.size()])


# --- Misc --------------------------------------------------------------------

func _ensure_client() -> void:
	if _llm_client == null:
		_llm_client = LLMClient.new()
		add_child(_llm_client)

## Convenience for the manager: drop this agent's perception of an external
## event straight into its memory without an LLM call (e.g. gossip seeding).
func remember_event(text: String) -> void:
	_append_history("user", text)
	_maybe_summarise()
