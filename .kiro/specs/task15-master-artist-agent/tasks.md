# Implementation Plan — Task 15: Master Artist Agentic AI (LM Studio Local LLM)

## Goal

Integrate a local-LLM-driven Master Artist NPC that can generate and assign new tasks through the existing `TaskData`/`TaskManager` system, using LM Studio’s OpenAI-compatible local server.

## Steps

- [ ] 1. Install and configure LM Studio
  - Install LM Studio on macOS
  - Download an instruction-tuned model (7B/8B recommended for first prototype)
  - Enable **Local Server** (OpenAI-compatible)
  - Confirm server base URL is `http://localhost:1234`

- [ ] 2. Add a minimal LLM HTTP client in Godot
  - Create an `LLMClient` helper that calls `POST /v1/chat/completions`
  - Add timeouts and basic error handling
  - Parse response JSON and extract `choices[0].message.content`

- [ ] 3. Define the strict JSON contract for AI-generated tasks
  - Create a JSON schema-like spec (documented in code and/or a markdown snippet)
  - Define allow-lists for `task_type`, `difficulty`, and objective `type`
  - Decide a minimal allow-list of item ids/locations for phase 1

- [ ] 4. Implement `MasterArtistAgent` orchestrator
  - Build a compact game-state context:
    - Skill levels summary
    - Inventory summary (ids + counts)
    - Recent task ids (active/completed)
    - Relationship score (optional)
  - Construct prompts:
    - Renaissance master persona (system)
    - Hard constraints + “strict JSON only” requirement (developer)
  - Call `LLMClient` and validate the returned JSON

- [ ] 5. Convert valid JSON → `TaskData`
  - Map strings to `TaskData.TaskType` and `TaskData.TaskDifficulty`
  - Fill `objectives`, rewards, required items, and dialogue fields

- [ ] 6. Wire it into Master Artist interaction
  - On “request new assignment”, call the agent
  - If valid, `TaskManager.assign_task(task)` and show assignment dialogue
  - If invalid/unavailable, show fallback dialogue and/or assign a deterministic task

- [ ] 7. Add developer ergonomics
  - Add an “AI enabled” toggle (debug flag)
  - Print helpful console logs: request sent, response received, validation failures

- [ ] 8. Add a lightweight test harness
  - Extend an existing test scene or add a new one:
    - Press a key to “Ask Master for new task”
    - Print task + objectives + dialogue
  - Validate that completing objectives triggers normal progress updates

## Definition of Done

- The Master can assign at least one AI-generated task end-to-end.
- Output is validated; invalid output does not corrupt game state.
- When LM Studio is stopped, the Master provides a clear fallback response.
- Documentation exists for setup and the interaction loop.

_Requirements: 1.2, 1.4, 5.3; Task 15.1–15.5_
