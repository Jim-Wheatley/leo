# Task 06 — Track Unique Paint Colors for Tasks

Status: not-started

## Summary

Certain tasks (e.g. `create_different_colors`) should count unique paint colors created by the player rather than incrementing the objective each time a paint is created. Implement per-task unique-color tracking to prevent duplicate colors from inflating progress.

## Motivation

- Match task semantics with player expectations ("Create 3 different colors").
- Prevent accidental completion by crafting the same color repeatedly.

## Scope

- `scripts/systems/TaskData.gd` (objective definitions)
- `scripts/singletons/TaskManager.gd` (event handling)

## Acceptance Criteria

- Tasks that require different colors track an internal set/list of unique color IDs.
- Creating a paint of an already-tracked color does not increase progress.
- Progress persists across saves (see Task 5) and restores correctly.

## Implementation Steps

1. Add a convention to `TaskData.objectives` where `type == "craft_different_colors"` uses `current_progress["colors"]` as an Array of strings.
2. Update `TaskManager.on_item_crafted()` so when handling `craft_different_colors` it adds the `item_id` (or color id) to the set if not present and updates progress to the set size.
3. Ensure `TaskData.to_dict()`/`from_dict()` serialize the colors array.
4. Add UI text to show which colors have been created for the task (optional).

## Test Cases

- Start the `color_theory` task, craft `paint_red`, `paint_blue`, `paint_red` — progress should be 2/3.
- Save while at 2/3, reload — progress remains 2/3.
