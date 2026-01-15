# Task 10 — Index Task Objectives By Type

Status: not-started

## Summary

`TaskManager` currently loops all tasks and their objectives on each activity event (craft/gather/sketch). Build an index `objectives_by_type` to map activity types to the tasks/objectives that care about them, reducing event handling cost.

## Motivation

- Improve performance as task count grows
- Make event dispatch O(k) where k = number of interested objectives

## Scope

- `scripts/singletons/TaskManager.gd`

## Acceptance Criteria

- `objectives_by_type` exists and is updated whenever tasks are created/loaded/updated.
- Activity events consult the index and update only matching tasks/objectives.
- No change in task semantics.

## Implementation Steps

1. Add `objectives_by_type: Dictionary` to `TaskManager`.
2. During `create_initial_tasks()` and any `from_dict()` restore, index each objective by `type` and store reference to task_id/objective_id.
3. Update event handlers (`on_item_crafted`, `on_artwork_created`, `on_resource_gathered`, etc.) to consult `objectives_by_type` rather than iterating all tasks.
4. Maintain index consistency when tasks change state.

## Test Cases

- With many tasks, measure event handling time before/after (manual profile).
- Ensure task updates still fire for matching events.
