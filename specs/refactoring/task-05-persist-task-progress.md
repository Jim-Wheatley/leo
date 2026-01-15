# Task 05 — Persist Task Progress

Status: not-started

## Summary

`TaskManager` currently uses `PlayerData.completed_tasks` but does not persist in-progress task `current_progress` or active tasks. This causes loss of progress across saves. Add serialization and restore for active tasks and objective progress.

## Motivation

- Preserve player progress across sessions
- Improve player trust and continuity

## Scope

- `scripts/systems/TaskData.gd`
- `scripts/singletons/TaskManager.gd`
- `scripts/player/PlayerData.gd`

## Acceptance Criteria

- `TaskData.to_dict()` includes `current_progress` and `status`.
- `PlayerData.to_dict()`/`from_dict()` serializes and deserializes `active_tasks` (task IDs) and `task_progress` (map task_id -> current_progress).
- `TaskManager.sync_with_player_data()` restores `active_tasks` and `current_progress` for each task.
- Saving and loading mid-task does not reset progress.

## Implementation Steps

1. Ensure `TaskData.to_dict()` returns `current_progress` and `status` (already present).
2. Add `player_data.active_tasks` and `player_data.task_progress` to `PlayerData` and include in `to_dict`/`from_dict`.
3. Update `TaskManager.sync_with_player_data()` to restore `TaskData.current_progress` and `TaskData.status`, and to add in-progress tasks to `active_tasks`.
4. Add tests: start a task, progress objectives, save, reload, ensure progress restored and task marked in progress.

## Test Cases

- Start `color_theory` task, craft one color, save, reload — task progress should be 1/3.
- Ensure completed tasks remain completed.
