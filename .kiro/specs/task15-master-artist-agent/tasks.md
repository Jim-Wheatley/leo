# Implementation Plan — Task 15: Master Artist Agentic AI (LM Studio Local LLM)

## Goal

Integrate a local-LLM-driven Master Artist NPC that can generate and assign new tasks through the existing `TaskData`/`TaskManager` system, using LM Studio’s OpenAI-compatible local server.

## Steps

- [x] 1. Install and configure LM Studio
  - Install LM Studio on macOS
  - Download an instruction-tuned model (Gemma 3 4B: `google/gemma-3-4b`)
  - Enable **Local Server** (OpenAI-compatible)
  - Confirm server base URL is `http://localhost:1234`

- [x] 2. Add a minimal LLM HTTP client in Godot
  - Create an `LLMClient` helper that calls `POST /v1/chat/completions` ✓ (`scripts/systems/LLMClient.gd`)
  - Add timeouts and basic error handling ✓
  - Parse response JSON and extract `choices[0].message.content` ✓

- [x] 3. Define the strict JSON contract for AI-generated tasks
  - Created a JSON schema-like spec (documented in STEP3_JSON_CONTRACT.md) ✓
  - Defined allow-lists for `task_type`, `difficulty`, and objective `type` ✓
  - Identified all 15 item IDs from the game (using 10 for Phase 1) ✓
  - Added `required_items` field to the contract ✓
  - Documented constraints and validation rules ✓

- [x] 4. Implement `MasterArtistAgent` orchestrator
  - Build a compact game-state context: ✓
    - Skill levels summary ✓
    - Inventory summary (ids + counts) ✓
    - Recent task ids (active/completed) ✓
    - Relationship score (optional) ✓
  - Construct prompts: ✓
    - Renaissance master persona (system) ✓
    - Hard constraints + "strict JSON only" requirement (developer) ✓
  - Call `LLMClient` and validate the returned JSON ✓
  - Created `MasterArtistAgent.gd` in `scripts/systems/` ✓
  - Created test script `test_master_artist_agent.gd` ✓
  - Documented in STEP4_BEGINNER_GUIDE.md ✓

- [x] 5. Convert valid JSON → `TaskData`
  - Map strings to `TaskData.TaskType` and `TaskData.TaskDifficulty` ✓
  - Fill `objectives`, rewards, required items, and dialogue fields ✓
  - Added `_json_to_task_data()` method to `MasterArtistAgent.gd` ✓
  - Tested end-to-end via test scene — full `TaskData` object confirmed ✓

- [x] 6. Wire it into Master Artist interaction
  - On “request new assignment”, call the agent ✓
  - If valid, `TaskManager.register_ai_task(task)` and show assignment dialogue ✓
  - If invalid/unavailable, show fallback dialogue and/or assign a deterministic task ✓
  - Added `_is_requesting_task` guard to prevent duplicate LLM calls while awaiting ✓
  - Added `_offer_fallback_guidance()` for graceful degradation when LLM is offline ✓
  - **Fix (JSON contract):** Improved prompt with concrete examples; added `_sanitize_json_string()`
    pre-parser (regex repairs bare-number syntax e.g. `{“item_id”:”x”, 1}`) and post-parse
    `required_items` array→dict converter for Gemma 3 format deviations ✓
  - **Fix (hallucinated items):** Validator now strips unknown item IDs from `required_items`
    and `item_rewards` instead of rejecting the whole task ✓
  - **Fix (task completion):** Prompt updated to use only the four trackable objective types
    (`craft_item`, `create_artwork`, `create_sketch`, `gather_resource`); added `item_type`
    field guidance for `craft_item`; `TaskManager.on_item_crafted()` updated to match
    objectives where `item_type` is omitted (counts any crafted item) ✓

- [x] 7. Add developer ergonomics
  - Added `ai_enabled: bool = true` flag to `MasterArtistAgent.gd` ✓
    - Set to `false` to bypass the LLM entirely — fallback dialogue shows instantly, no timeout wait
    - Sits alongside existing `debug_mode` flag; the two flags are independent
  - Added structured console logs throughout `MasterArtistAgent.gd` ✓
    - `generate_task()`: prints START / COMPLETE / FAILED (validation) / FAILED (LLM error) banners
    - `_call_llm()`: prints `→ REQUEST SENT endpoint=... max_tokens=800` before the call, then
      `← RESPONSE OK  Xs  N chars` or `← RESPONSE FAIL  Xs  error: ...` with elapsed time after
    - `_validate_and_parse_response()`: prints `↳ VALIDATE  raw length=N chars` at entry
  - Verified behaviour with LM Studio offline ✓
    - Connection refused (result code 2) is detected instantly (0.0s) — no 60-second timeout
    - Fallback guidance fires correctly and shows skill-based dialogue to the player

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
