# Design Document — Task 15: Master Artist Agentic AI (LM Studio Local LLM)

## Overview

Task 15 introduces an **agentic Master Artist** powered by a local LLM running through **LM Studio**.

The AI is not authoritative over game state. Instead:

- The LLM **proposes** a task + dialogue (strict JSON).
- The game **validates** and **converts** it into existing `TaskData`.
- The game **assigns** tasks via existing systems (e.g., `TaskManager.assign_task`).

This creates an agent-like loop: **plan → propose → validate → execute**.

## Why LM Studio (Phase 1)

- Beginner-friendly: no keys, no billing.
- Fast iteration: local requests, easy prompt tweaking.
- Teaches the core integration pattern that later ports to Azure/OpenAI/Anthropic.

## Architecture

### Components

1. **`LLMClient` (new helper/service)**
   - Sends HTTP requests to LM Studio’s OpenAI-compatible endpoint.
   - Returns parsed JSON response (or a structured error).

2. **`MasterArtistAgent` (new agent/orchestrator)**
   - Builds a compact context payload from game state (skills, inventory summary, task history).
   - Builds prompts with strict JSON output constraints.
   - Validates the response JSON against allow-lists.
   - Produces a `TaskData` instance + assignment dialogue.

3. **Existing systems (unchanged authority)**
   - `TaskData` remains the canonical representation.
   - `TaskManager` remains responsible for assigning and tracking tasks.
   - `DialogueSystem` (or existing MasterArtist dialogue flow) displays text.

### Data Flow

1. Player interacts with Master Artist and requests a new assignment.
2. Master Artist calls `MasterArtistAgent.generate_task(context)`.
3. `MasterArtistAgent` calls `LLMClient.chat_completions()` to LM Studio.
4. Agent validates JSON output (schema + allow-lists).
5. On success: create `TaskData` → assign via `TaskManager` → show dialogue.
6. On failure: show fallback dialogue and/or assign a deterministic non-AI task.

## LM Studio Setup (Developer Workflow)

### One-time setup

1. Install LM Studio (macOS app).
2. Download an instruction-tuned model (7B/8B is a reasonable starting point).
3. Open LM Studio → enable **Local Server**.

### Server expectations

- Default base URL: `http://localhost:1234`
- OpenAI-compatible endpoint: `POST /v1/chat/completions`

### Minimal sanity check (conceptual)

- If the server is running, a POST request returns JSON with `choices[0].message.content`.

## Prompting Strategy

### Roles

- **System**: establishes Renaissance master persona and hard constraints.
- **Developer**: forces strict JSON output and forbids inventing entities.
- **User**: provides the current request (“Give me a new task.”) and game state summary.

### Output Contract

Require a single JSON object with fields that map into `TaskData`:

- `task_id`, `title`, `description`
- `task_type` (string enum mapped to `TaskData.TaskType`)
- `difficulty` (string enum mapped to `TaskData.TaskDifficulty`)
- `skill_requirements`, `required_items`, `prerequisite_tasks`
- `objectives` (array of { id, description, target, type, target_id })
- `skill_rewards`, `item_rewards`, `reputation_reward`, `unlock_rewards`
- `assignment_dialogue`, `progress_dialogue`, `completion_dialogue`, `failure_dialogue`

### Allow-lists

To reduce hallucinations, the agent supplies explicit allow-lists:

- Allowed `task_type` values: `SKILL_PRACTICE`, `CRAFTING`, `GATHERING`, `EXPLORATION`, `ARTWORK_CREATION`, `LEARNING`
- Allowed `difficulty` values: `BEGINNER`, `APPRENTICE`, `JOURNEYMAN`, `EXPERT`, `MASTER`
- Allowed objective `type` values should match what `TaskManager.update_task_progress()` expects.

## Validation Rules (must-have)

1. JSON must parse.
2. `task_id`, `title`, `description` must be non-empty.
3. `task_type` and `difficulty` must be in allow-list.
4. Objectives must be present and each objective must have:
   - `id` (string)
   - `description` (string)
   - `target` (int >= 1)
   - `type` (string allow-listed)
5. Item ids referenced in `required_items` and `item_rewards` should be validated against known inventory item ids (phase 1 can use a small allow-list until you expose a canonical registry).

## Graceful Fallback

When LM Studio is unavailable or output fails validation:

- Show a deterministic Master response: “Return when you have mixed paint / sketched a landmark…”
- Optionally assign a simple existing task from the current pool.

## UX Notes

- Keep AI interactions short: one request per “new task” interaction.
- Keep dialogue to ~2–6 sentences; prefer actionable bullet-like objectives.
- Consider a dev toggle: AI on/off.

## Security Notes (local prototype)

- Never execute code from the model.
- Treat model output as untrusted input.
- Validate everything before applying to game state.
