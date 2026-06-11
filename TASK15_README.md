# Task 15: Master Artist Agentic AI (LM Studio Local LLM)

## Overview

Task 15 adds an **agentic AI mode** to the Master Artist NPC so the Master can:

- Generate new, context-aware tasks using the existing `TaskData` / `TaskManager` system.
- Offer artistic advice and wisdom in a Renaissance master style.

This task is designed for beginners to LLM development and uses a **local LLM** via **LM Studio** (no API keys required).

## Where the spec lives

- `.kiro/specs/task15-master-artist-agent/requirements.md`
- `.kiro/specs/task15-master-artist-agent/design.md`
- `.kiro/specs/task15-master-artist-agent/tasks.md`

## LM Studio quick start (macOS)

1. Install **LM Studio**.
2. Download an instruction-tuned model (start with something small like a 7B/8B instruct model).
3. Open LM Studio → enable **Local Server**.
4. Confirm it shows a server URL like `http://localhost:1234`.

Your game will call the OpenAI-compatible endpoint:

- `POST http://localhost:1234/v1/chat/completions`

## How the integration works (high level)

- The LLM is asked to return **strict JSON** for a task.
- The game validates that JSON against allow-lists.
- If valid, the game converts it into `TaskData` and assigns it.
- If invalid or LM Studio isn’t running, the Master falls back to a safe deterministic response.

## Notes

- Treat all model output as untrusted input.
- Keep requests small (one call per “new task” interaction).
- Start with a minimal allow-list of item ids/objective types, then expand.
