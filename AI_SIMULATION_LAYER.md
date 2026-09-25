# AI Simulation Layer — Integration Guide

This document explains how the autonomous-agent simulation is wired into the
existing game, and exactly what to add to hook it up. It follows the **coexist**
strategy: the existing Master Aldric task-generation (`MasterArtistAgent.generate_task()`)
is **left untouched**; the simulation layers *alongside* it for autonomous
between-interaction behaviour and conversational reactions.

## Files

```
scripts/agents/
  world_state.gd          # shared blackboard (Resource)
  agent.gd                # base Agent class (think/history/system prompt)
  agent_manager.gd        # tick loop, tiers, action routing, Mira trigger
  simulation.gd           # game-specific bootstrap -> autoload "Sim"
  characters/
    aldric.gd  lord_casimir.gd  fenwick.gd  serafine.gd  mira.gd
  utils/
    action_parser.gd      # [ACTION: verb target] parsing
```

## What is already done

- `simulation.gd` is registered as the **autoload `Sim`** (see `project.godot`).
  On boot it creates the shared `WorldState` and registers the whole cast
  (Aldric, Casimir, Fenwick, Serafine present; Mira dormant).
- `Sim` is globally accessible from any script, exactly like `GameManager`.
- **The Workshop hooks are APPLIED** (`Workshop.gd`): player location is set,
  `run_tick()` runs on master interaction + a 45s ambient timer, player task
  completion feeds the world, and `agent_spoke` / `agent_acted` / visitor / Mira
  signals are surfaced through the dialogue box and HUD notifications.
- **The Aldric coexist hook is APPLIED** (`MasterArtist.gd`): fallback guidance
  is coloured with Aldric's latest simulated remark. Task generation is untouched.
- **Periodic visits (Phase A)** are implemented in `simulation.gd`: Casimir and
  Serafine drop into the workshop, become active (so they actually speak), linger
  a couple of ticks, then return home. They only visit while the player is in the
  workshop, so a visit is never wasted off-screen.

The code sections below document HOW these hooks work (and are the reference if
you move/rebuild them). They are already in place — you do not need to re-add them.

## Presence phases

The simulation runs all five characters logically regardless of physical
presence. How the player *experiences* each character is a separate, per-character
choice:

- **Phase A (done):** Aldric is the physical master; Casimir & Serafine appear via
  periodic visits; Mira arrives on her milestone. Fenwick is off-screen at the
  market for now. No new environments required.
- **Phase B (planned):** give Fenwick a body at Florence's existing Market Square
  and Serafine one at the Cathedral, and set the player's location string when
  they enter those Florence sub-areas so those agents wake up on proximity.
- **Phase C (optional):** dedicated estate / guild-hall scenes, only if the story
  ever needs them.

---

## 1. Scene tree

No scene changes are needed for the manager itself — `Sim` is an autoload, so
the agents live under `/root/Sim`. You only add *hooks* in the scripts that
already exist (`Workshop.gd`, `MasterArtist.gd`).

```
/root
  Sim (autoload)                 <- the simulation; agents are children
    Master Aldric (Agent)
    Lord Casimir (Agent)
    Brother Fenwick (Agent)
    Serafine (Agent)
    Mira (Agent, dormant)
  Workshop (current main scene)
    Player
    MasterArtist                 <- keeps its own task-gen agent (unchanged)
    MainHUD
    ...
```

---

## 2. Tell the sim where the player is (Workshop.gd)

Add to `Workshop._ready()` (after the existing setup calls):

```gdscript
func _ready():
    # ... existing setup ...

    # --- AI simulation hookup ---
    Sim.set_player_location("workshop")
    Sim.agent_spoke.connect(_on_agent_spoke)
    Sim.agent_acted.connect(_on_agent_acted)
    # Optional ambient ticks while the player is in the workshop:
    _start_ambient_sim_timer()
```

When the player leaves for Florence / natural areas, update the location so
proximity tiers are correct:

```gdscript
func exit_to_florence():
    Sim.set_player_location("florence")   # add this line
    get_tree().change_scene_to_file("res://scenes/environments/Florence.tscn")
```

---

## 3. Drive the tick (Workshop.gd)

A tick with 2 active agents costs ~10–15s on a local model, so **do not tie
`run_tick()` to a fast timer**. Two good triggers:

**a) React when the player interacts with the master** — add to `interact_with_master()`:

```gdscript
func interact_with_master():
    if master_artist.has_method("interact_with_player"):
        master_artist.interact_with_player()   # existing task flow (unchanged)
    # ... existing fallback ...

    # Let the living world react to this moment (fire-and-forget).
    _run_sim_tick()
```

**b) Optional slow ambient ticks** so the world breathes even when idle:

```gdscript
var _sim_timer: Timer

func _start_ambient_sim_timer():
    _sim_timer = Timer.new()
    _sim_timer.wait_time = 45.0          # tune to taste
    _sim_timer.autostart = true
    add_child(_sim_timer)
    _sim_timer.timeout.connect(_run_sim_tick)

func _run_sim_tick():
    if Sim._is_ticking:                  # manager also guards internally
        return
    await Sim.run_tick()
```

---

## 4. Feed player actions into the world

The richer the `player_last_action`, the better agents react. Hook the events
you already emit. Minimal high-value set:

```gdscript
# In Workshop._ready(), or wherever you already listen to these:
TaskManager.task_completed.connect(func(task):
    Sim.note_player_action("completed the task '%s'" % task.title, "workshop")
    Sim.world_state.bump_commission(10)          # advance the altarpiece
    Sim.first_major_task_done = true             # trips Mira's arrival milestone
)
```

You can add more granular feeds anywhere the player does something observable,
e.g. after crafting paint or finishing a sketch:

```gdscript
Sim.note_player_action("ground and mixed a batch of red paint")
```

`reputation` and `commission_progress` on `Sim.world_state` are the other two
knobs agents read — set them from your reputation / progress systems as they
change (e.g. after a Serafine assessment).

---

## 5. Present what agents say and do

`agent_spoke` gives clean dialogue (action tags stripped); `agent_acted` gives
structured actions for real game effects. Add these handlers to `Workshop.gd`:

```gdscript
func _on_agent_spoke(agent_name: String, dialogue: String):
    # Master Aldric is physically present -> use his dialogue box when nearby.
    if agent_name == "Master Aldric" and current_interactable == master_artist:
        master_artist.dialogue_system.show_simple_dialogue("Master Artist", dialogue)
    else:
        # Everyone else is "ambient" for now -> a HUD notification.
        if main_hud:
            main_hud.show_notification("%s: %s" % [agent_name, dialogue], 5.0, "info")

func _on_agent_acted(agent_name: String, action: Dictionary):
    match action.verb:
        "give":
            # e.g. Fenwick hands the player a material — grant it via your inventory.
            # var item := " ".join(action.args)
            # GameManager.player_data.add_inventory_item(...)
            pass
        "work":
            if action.target == "commission":
                Sim.world_state.bump_commission(2)
        # inspect / move / speak / emote are already reflected in world events.
        _:
            pass
```

Real game-system effects (inventory grants, reputation changes) are deliberately
left to these handlers — the manager only does minimal world-state bookkeeping,
so gameplay-affecting changes stay in your code where you can balance them.

---

## 6. The Aldric "LM Studio call" — coexist before/after

**Decision: coexist.** `MasterArtistAgent.generate_task()` is NOT removed —
it still produces the validated `TaskData` your progression depends on. The
simulation adds Aldric's autonomous life on top. The only change to
`MasterArtist.gd` is *additive*: surface his simulated mood/latest reaction so
he feels like the same character the rest of the world is reacting to.

### Before (MasterArtist.gd — unchanged core)

```gdscript
func _offer_fallback_guidance():
    var guidance = get_guidance_based_on_skills()
    var full_message = guidance
    full_message += "\n\n(My thoughts are scattered today, apprentice...)"
    dialogue_system.show_simple_dialogue("Master Artist", full_message)
```

### After (additive — pull in his simulated state)

```gdscript
func _offer_fallback_guidance():
    var guidance = get_guidance_based_on_skills()

    # Coexist: colour the guidance with Aldric's current simulated mood, and
    # reuse his most recent autonomous remark if he has one.
    var aldric = Sim.get_agent("Master Aldric")
    if aldric and aldric.last_response != "":
        guidance += "\n\n" + ActionParser.strip_actions(aldric.last_response)

    dialogue_system.show_simple_dialogue("Master Artist", guidance)
```

Nothing about task generation changes. `generate_task()`, the JSON contract,
validation, and `TaskData` conversion all stay exactly as they are. Aldric now
*also* lives in the simulation: he reacts to the player and pursues the
commission between interactions, and his voice there is consistent with the box
the player sees when they walk up to him.

---

## 7. Mira's arrival

Mira is registered dormant. She arrives automatically when any milestone trips
(`Sim.first_major_task_done`, or `Sim.world_state.reputation >= 40`, or
`commission_progress >= 50`, or `in_game_day >= 5` — all tunable on `Sim`).
When it trips, the other agents get pre-arrival gossip seeded into their memory,
then after `Sim.mira_gossip_ticks` ticks she becomes an active agent.

To react in-game (e.g. a cutscene or notification):

```gdscript
Sim.mira_gossip_started.connect(func():
    main_hud.show_notification("Word spreads of an unusual request from Lord Casimir...", 6.0, "info"))
Sim.mira_arrived.connect(func():
    main_hud.show_notification("A new apprentice, Mira, has arrived at the workshop.", 6.0, "info"))
```

You can also force her arrival for testing: `Sim.activate_mira()`.

---

## Tuning reference (all on `Sim`)

| Property | Default | Meaning |
|---|---|---|
| `max_active_agents` | 3 | how many agents may call the LLM per tick |
| `advance_time_each_tick` | true | advance the world clock each tick |
| `mira_trigger_reputation` | 40 | reputation that trips Mira's arrival |
| `mira_trigger_commission` | 50 | commission % that trips Mira's arrival |
| `mira_trigger_day` | 5 | in-game day that trips Mira's arrival |
| `mira_gossip_ticks` | 3 | length of the pre-arrival gossip phase |
```
