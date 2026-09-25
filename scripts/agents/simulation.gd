extends AgentManager
## Simulation bootstrap — the game-specific glue that builds the fantasy-medieval
## cast and exposes the running simulation as the `Sim` autoload.
##
## This is intentionally SEPARATE from AgentManager: the manager is reusable and
## knows nothing about specific characters; this file wires up THIS game's cast
## AND this game's "who visits the workshop when" scheduling.
## Register it as an autoload named "Sim" (see project.godot [autoload]).
##
## Usage from anywhere in the game:
##   Sim.note_player_action("completed the underdrawing", "workshop")
##   await Sim.run_tick()
##   Sim.agent_spoke.connect(_on_agent_spoke)
##   Sim.first_major_task_done = true   # trips Mira's arrival milestone

const AldricScript   = preload("res://scripts/agents/characters/aldric.gd")
const CasimirScript  = preload("res://scripts/agents/characters/lord_casimir.gd")
const FenwickScript  = preload("res://scripts/agents/characters/fenwick.gd")
const SerafineScript = preload("res://scripts/agents/characters/serafine.gd")
const MiraScript     = preload("res://scripts/agents/characters/mira.gd")

# --- Periodic visits (Phase A ambient presence) ------------------------------
## Characters who don't live in the workshop but drop in to check on things.
## When they visit they move to the workshop, become ACTIVE (so they actually
## speak via the LLM), linger a couple of ticks, then return home.
const VISITORS := ["Lord Casimir", "Serafine"]
## Ticks a visit lasts.
@export var visit_duration_ticks: int = 2
## Ticks a visitor must wait after leaving before they may visit again.
@export var visit_cooldown_ticks: int = 6
## Per-tick chance an eligible visitor drops in (only while the player is in
## the workshop, so visits are never wasted off-screen).
@export var visit_chance: float = 0.35

signal visitor_arrived(agent_name: String)
signal visitor_left(agent_name: String)

var _home_location: Dictionary = {}   # agent_name -> their home location
var _visiting: Dictionary = {}        # agent_name -> ticks left in the workshop
var _visit_cooldown: Dictionary = {}  # agent_name -> ticks until eligible again


func _ready() -> void:
	super()          # AgentManager._ready() creates the shared WorldState
	_build_cast()

func _build_cast() -> void:
	# Starting cast — present in the world from the beginning.
	register_agent(AldricScript.new())
	register_agent(CasimirScript.new())
	register_agent(FenwickScript.new())
	register_agent(SerafineScript.new())

	# Late-join — registered DORMANT; arrives when the milestone trips.
	var mira := MiraScript.new()
	register_dormant_agent(mira)
	set_mira(mira)

	# Remember where everyone lives so visitors can return home.
	for a in agents:
		_home_location[a.agent_name] = a.location

	if debug_mode:
		print("[Sim] Cast ready — %d agents registered (Mira dormant)." % agents.size())


## Override the tick to run visit scheduling first, then the normal simulation.
func run_tick() -> void:
	if _is_ticking:
		return
	_update_visits()
	await super()

## Decide who arrives/leaves this tick. Visits only happen while the player is
## in the workshop, so the player always witnesses them.
func _update_visits() -> void:
	for name in VISITORS:
		if _visiting.has(name):
			_visiting[name] -= 1
			if _visiting[name] <= 0:
				_end_visit(name)
		else:
			var cd: int = _visit_cooldown.get(name, 0)
			if cd > 0:
				_visit_cooldown[name] = cd - 1
			elif player_location == "workshop" and _no_one_visiting() and randf() < visit_chance:
				_begin_visit(name)

func _no_one_visiting() -> bool:
	return _visiting.is_empty()

func _begin_visit(name: String) -> void:
	var agent := get_agent(name)
	if agent == null:
		return
	agent.location = "workshop"
	world_state.set_agent_location(name, "workshop")
	world_state.add_event("%s has come to the workshop." % name)
	_visiting[name] = max(1, visit_duration_ticks)
	if debug_mode:
		print("[Sim] %s begins a visit." % name)
	visitor_arrived.emit(name)

func _end_visit(name: String) -> void:
	var agent := get_agent(name)
	var home: String = _home_location.get(name, "estate")
	if agent != null:
		agent.location = home
		world_state.set_agent_location(name, home)
	world_state.add_event("%s has left the workshop." % name)
	_visiting.erase(name)
	_visit_cooldown[name] = visit_cooldown_ticks
	if debug_mode:
		print("[Sim] %s ends their visit (returns to %s)." % [name, home])
	visitor_left.emit(name)

## True while the named character is currently visiting the workshop.
func is_visiting(name: String) -> bool:
	return _visiting.has(name)
