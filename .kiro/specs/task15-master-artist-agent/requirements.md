# Requirements Document — Task 15: Master Artist Agentic AI (LM Studio Local LLM)

## Introduction

This task adds an **agentic AI mode** to the Master Artist NPC so the Master can:

- Generate new, context-aware quests (tasks) for the player.
- Offer artistic advice and “Renaissance master” wisdom grounded in the player’s current progress.

For early development and learning, the AI runs locally through **LM Studio** using its **OpenAI-compatible local server** (no API keys).

## Requirements

### Requirement 15.1: Local LLM Connectivity (LM Studio)

**User Story:** As a developer, I want the game to connect to a local LLM via LM Studio, so that I can prototype AI-driven gameplay without cloud accounts or API keys.

#### Acceptance Criteria

1. WHEN LM Studio’s local server is running THEN the game SHALL be able to send a chat completion request to `http://localhost:1234/v1/chat/completions`.
2. WHEN the local server is not running THEN the game SHALL fail gracefully and provide a non-AI fallback response.
3. WHEN the player requests a new assignment THEN the game SHALL make at most one LLM request for that interaction.

### Requirement 15.2: AI-Generated Tasks Must Map to Existing Task System

**User Story:** As a developer, I want AI output to map into the existing `TaskData` structure, so that AI-generated quests integrate with current progress tracking and rewards.

#### Acceptance Criteria

1. WHEN the Master requests an AI-generated task THEN the system SHALL require the model to return **strict JSON** describing a `TaskData`-compatible task.
2. WHEN the response JSON is invalid or incomplete THEN the system SHALL reject it and use a safe fallback task or dialogue.
3. WHEN the response JSON references task types, difficulties, or objective verbs THEN the system SHALL validate them against an allow-list.

### Requirement 15.3: Hallucination Resistance via Allow-Lists

**User Story:** As a developer, I want the AI to only use items/locations/objectives that exist in the game, so the AI cannot invent non-existent gameplay elements.

#### Acceptance Criteria

1. WHEN generating tasks THEN the system SHALL provide the model a list of allowed task types, difficulty levels, and objective templates.
2. WHEN the model references an unknown item/location/objective id THEN the system SHALL reject or sanitize it.

### Requirement 15.4: Renaissance Master Voice with Actionable Guidance

**User Story:** As a player, I want the Master’s advice to feel like a Renaissance artist and also be actionable, so I learn artistic practice while progressing.

#### Acceptance Criteria

1. WHEN the Master speaks THEN dialogue SHALL be in a Renaissance-inspired tone (strict but caring) while remaining clear.
2. WHEN the Master offers advice THEN the system SHALL include 1–3 concrete next actions the player can do within existing mechanics.

### Requirement 15.5: Privacy and Safety Defaults

**User Story:** As a developer, I want safe defaults around what is sent to the LLM, so that I do not accidentally send personal data.

#### Acceptance Criteria

1. The system SHALL only send game state relevant to the request (skills, inventory counts, task history summaries), not raw logs or personal identifiers.
2. The system SHALL not require cloud connectivity for the Task 15 prototype.

### Traceability to Core Game Spec

This feature supports and extends existing game requirements:

- 1.2 (Interact with master artist → dialogue options and task assignments)
- 1.4 (Unlock new tasks/responsibilities based on skill)
- 5.3 (Study with the master → learning sessions and skill boosts)
