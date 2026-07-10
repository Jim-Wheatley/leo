extends Node
## AgentManager — the heartbeat of the living world.
##
## Responsibilities (per spec):
##   • Holds references to all agents and owns the shared WorldState.
##   • Runs one simulation tick per in-game turn (run_tick()).
##   • ACTIVE agents (co-located with the player) call think() — sequentially,
##     so a single local LLM is never hit concurrently.
##   • BACKGROUND agents run the cheap rule-based simulate_behavior() — no LLM.
##   • Promotes/demotes agents between tiers based on proximity (location match).
##   • Routes [ACTION: ...] tags from agent replies to game systems.
##   • Handles Mira's late-join: monitors the milestone, then activate_mira()
##     seeds a pre-arrival gossip phase before she spawns as an active agent.
##
## Can be used as an autoload OR a child of the main scene. It does NOT create
## the cast itself — integration code registers agents (see Component 6).

class_name AgentManager

# --- Tiers -------------------------------------------------------------------
enum Tier { DORMANT, BACKGROUND, ACTIVE }

# --- Tunables ----------------------------------------------------------------
## Max agents allowed to call the LLM in a single tick (protects the local LLM).
@export var max_active_agents: int = 3
## If true, run_tick() advances the world clock by one slot each tick.
@export var advance_time_each_tick: bool = true

# --- Mira milestone config (OR semantics — any one trips the trigger) --------
@export var mira_trigger_reputation: int = 40
@export var mira_trigger_commission: int = 50
@export var mira_trigger_day: int = 5
## Ticks the pre-arrival gossip phase lasts before Mira actually arrives.
@export var mira_gossip_ticks: int = 3

# --- Signals (integration hooks for the game / UI) ---------------------------
signal agent_spoke(agent_name: String, dialogue_text: String)   # clean prose
signal agent_acted(agent_name: String, action: Dictionary)      # parsed action
signal tick_completed(in_game_day: int, time_of_day: String)
signal mira_gossip_started()
signal mira_arrived()

# --- State -------------------------------------------------------------------
var world_state: WorldState
var agents: Array = []                  # all registered Agent instances
var player_location: String = "workshop"

var _by_name: Dictionary = {}           # agent_name -> Agent
var _tier: Dictionary = {}              # agent_name -> Tier
var _is_ticking: bool = false
var debug_mode: bool = true

# Mira bookkeeping
var _mira_agent: Agent = null
var _mira_gossip_active: bool = false
var _mira_arrival_countdown: int = -1
var mira_has_arrived: bool = false
## Game sets this true when the player finishes their first major task — one of
## the milestone conditions for Mira.
var first_major_task_done: bool = false


func _ready() -> void:
	if world_state == null:
		world_state = WorldState.new()


# --- Registration ------------------------------------------------------------

## Register an agent that exists in the world from the start. Added as a child
## so its LLMClient/HTTPRequest works. Starts BACKGROUND; tiers are recomputed
## each tick by proximity.
func register_agent(agent: Agent) -> void:
	_add(agent, Tier.BACKGROUND)
	world_state.set_agent_location(agent.agent_name, agent.location)

## Register Mira (or any late-join character) as DORMANT — present in memory but
## not in the world, not ticked, not counted for proximity, until activated.
func register_dormant_agent(agent: Agent) -> void:
	_add(agent, Tier.DORMANT)

func _add(agent: Agent, tier: int) -> void:
	# Add to the tree FIRST so the agent's _ready() -> _configure() runs and sets
	# agent_name/location before we key anything off the name. (Character
	# subclasses set their identity in _configure(), not at construction.)
	if agent.get_parent() == null:
		add_child(agent)

	if _by_name.has(agent.agent_name):
		push_warning("AgentManager: duplicate agent '%s' ignored" % agent.agent_name)
		return
	agents.append(agent)
	_by_name[agent.agent_name] = agent
	_set_tier(agent, tier)
	agent.thought_ready.connect(_on_agent_thought)
	if agent.has_signal("thought_failed"):
		agent.thought_failed.connect(_on_agent_thought_failed)

func get_agent(agent_name: String) -> Agent:
	return _by_name.get(agent_name, null)


# --- The simulation tick -----------------------------------------------------

## Run one in-game turn. Async: `await manager.run_tick()`. Re-entrancy guarded
## so a slow LLM tick can't overlap the next.
func run_tick() -> void:
	if _is_ticking:
		if debug_mode:
			print("[AgentManager] tick skipped — previous tick still running")
		return
	_is_ticking = true

	if advance_time_each_tick:
		world_state.advance_time()

	update_tiers()

	var ctx := world_state.to_context_dict()

	# 1. BACKGROUND agents: cheap rule-based behaviour, no LLM.
	for agent in _present_agents():
		if _tier[agent.agent_name] == Tier.BACKGROUND:
			var events: Array = agent.simulate_behavior(ctx)
			for ev in events:
				world_state.add_event(str(ev))

	# 2. ACTIVE agents: LLM think(), one at a time. Routing happens in the
	#    thought_ready handler, which fires before think() returns.
	for agent in _present_agents():
		if _tier[agent.agent_name] == Tier.ACTIVE:
			await agent.think(world_state.to_context_dict())

	# 3. Late-join monitoring.
	_update_mira()

	_is_ticking = false
	tick_completed.emit(world_state.in_game_day, world_state.time_of_day)


# --- Tier management ---------------------------------------------------------

## Recompute ACTIVE/BACKGROUND tiers by proximity to the player. An agent is a
## candidate for ACTIVE when it shares the player's location; the nearest
## max_active_agents become ACTIVE, the rest BACKGROUND. DORMANT agents are
## untouched.
##
## NOTE: proximity here is location-string equality. To use true 2D distance,
## replace the `agent.location == player_location` test below with a distance
## check against the player node — nothing else needs to change.
func update_tiers() -> void:
	var candidates: Array = []
	for agent in _present_agents():
		if agent.location == player_location:
			candidates.append(agent)

	var active_count := 0
	for agent in _present_agents():
		var should_be_active: bool = (agent in candidates) and (active_count < max_active_agents)
		if should_be_active:
			_set_tier(agent, Tier.ACTIVE)
			active_count += 1
		else:
			_set_tier(agent, Tier.BACKGROUND)

func _set_tier(agent: Agent, tier: int) -> void:
	_tier[agent.agent_name] = tier
	agent.is_active = (tier == Tier.ACTIVE)

func get_tier(agent_name: String) -> int:
	return _tier.get(agent_name, Tier.DORMANT)

## Agents that currently exist in the world (everything except DORMANT).
func _present_agents() -> Array:
	var out: Array = []
	for agent in agents:
		if _tier.get(agent.agent_name, Tier.DORMANT) != Tier.DORMANT:
			out.append(agent)
	return out


# --- Player hooks ------------------------------------------------------------

## Game calls this when the player does something observable, so nearby agents
## react next tick.
func note_player_action(action_text: String, location: String = "") -> void:
	world_state.set_player_action(action_text)
	if location != "":
		player_location = location
		world_state.set_agent_location("Player", location)

func set_player_location(location: String) -> void:
	player_location = location
	world_state.set_agent_location("Player", location)


# --- Action routing ----------------------------------------------------------

func _on_agent_thought(agent_name: String, response_text: String) -> void:
	# Clean prose for the dialogue UI.
	var prose := ActionParser.strip_actions(response_text)
	if prose != "":
		agent_spoke.emit(agent_name, prose)

	# Structured actions for the world.
	var actions := ActionParser.parse(response_text)
	for action in actions:
		_route_action(agent_name, action)

func _on_agent_thought_failed(agent_name: String, error: String) -> void:
	if debug_mode:
		print("[AgentManager] %s failed to think: %s" % [agent_name, error])

## Apply one parsed action. Minimal world-state effects here; richer game-system
## effects (inventory, reputation, etc.) are wired by listeners on agent_acted.
func _route_action(agent_name: String, action: Dictionary) -> void:
	if not action.get("recognized", false):
		if debug_mode:
			print("[AgentManager] %s: ignoring unknown action — %s" % [
				agent_name, ActionParser.describe(action)])
		return

	var verb: String = action["verb"]
	var target: String = action.get("target", "")
	var agent: Agent = _by_name.get(agent_name, null)

	match verb:
		"move":
			if target != "" and agent != null:
				agent.location = target
				world_state.set_agent_location(agent_name, target)
				world_state.add_event("%s moved to the %s." % [agent_name, target])
		"speak":
			world_state.add_event("%s spoke to %s." % [agent_name, target if target != "" else "the room"])
		"give":
			var item := " ".join(action.get("args", []))
			world_state.add_event("%s gave %s %s." % [agent_name, target, item if item != "" else "something"])
		"take":
			world_state.add_event("%s took %s." % [agent_name, target])
		"inspect":
			world_state.add_event("%s inspected the %s." % [agent_name, target])
		"work":
			world_state.add_event("%s worked on the %s." % [agent_name, target])
		"emote":
			if agent != null and target != "":
				agent.mood = target
			world_state.add_event("%s seems %s." % [agent_name, target])
		"wait":
			pass
		_:
			# recognized verb with no specific handler — still surface it
			world_state.add_event("%s: %s" % [agent_name, ActionParser.describe(action)])

	# Let game systems apply real effects.
	agent_acted.emit(agent_name, action)


# --- Mira late-join ----------------------------------------------------------

func _update_mira() -> void:
	if mira_has_arrived or _mira_agent == null:
		return

	if not _mira_gossip_active:
		if _mira_milestone_met():
			activate_mira()
	else:
		_mira_arrival_countdown -= 1
		if _mira_arrival_countdown <= 0:
			_complete_mira_arrival()

func _mira_milestone_met() -> bool:
	return first_major_task_done \
		or world_state.reputation >= mira_trigger_reputation \
		or world_state.commission_progress >= mira_trigger_commission \
		or world_state.in_game_day >= mira_trigger_day

## Begin Mira's arrival: inject the pre-arrival gossip phase into the other
## agents' memories, then start the countdown to her actual appearance. Safe to
## call manually (e.g. from a story script) as well as via the milestone monitor.
func activate_mira() -> void:
	if _mira_agent == null or _mira_gossip_active or mira_has_arrived:
		return
	_mira_gossip_active = true
	_mira_arrival_countdown = max(1, mira_gossip_ticks)

	if debug_mode:
		print("[AgentManager] Mira milestone reached — seeding gossip phase (%d ticks)" % _mira_arrival_countdown)

	for agent in _present_agents():
		var line := _gossip_line_for(agent)
		if line != "":
			agent.remember_event(line)

	world_state.add_event("Whispers spread of an unusual request from Lord Casimir...")
	mira_gossip_started.emit()

## Gossip line for a given agent. Prefers a character-supplied get_mira_gossip()
## (Component 5); falls back to spec-accurate defaults so this works standalone.
func _gossip_line_for(agent: Agent) -> String:
	if agent.has_method("get_mira_gossip"):
		var line: String = agent.get_mira_gossip()
		if line != "":
			return line
	match agent.agent_name:
		"Master Aldric":
			return "You overhear that Lord Casimir has made an unusual request of the workshop."
		"Brother Fenwick":
			return "Word reaches you that a young noblewoman has been receiving private drawing lessons."
		"Serafine":
			return "You remind yourself the guild will expect no special treatment, whatever the parentage."
		"Lord Casimir":
			return "You consider how best to raise the matter of your daughter's apprenticeship."
		_:
			return "Talk spreads of a new apprentice soon to join the workshop."

func _complete_mira_arrival() -> void:
	_mira_gossip_active = false
	mira_has_arrived = true
	# Promote Mira from DORMANT into the world.
	_set_tier(_mira_agent, Tier.BACKGROUND)
	world_state.set_agent_location(_mira_agent.agent_name, _mira_agent.location)
	world_state.add_event("%s has arrived at the workshop." % _mira_agent.agent_name)
	# Tiers will be recomputed on the next tick; if she's with the player she
	# becomes ACTIVE then.
	if debug_mode:
		print("[AgentManager] %s has arrived." % _mira_agent.agent_name)
	mira_arrived.emit()

## Tell the manager which registered dormant agent is Mira (drives the trigger).
func set_mira(agent: Agent) -> void:
	_mira_agent = agent
