# Task 03 — UIManager CanvasLayer Lifecycle

Status: not-started

## Summary

`UIManager.gd` creates a `CanvasLayer` and `Control` container at runtime. On scene reload the CanvasLayer can be duplicated, causing multiple UI layers and input handling issues. Implement lifecycle ownership and cleanup.

## Motivation

- Prevent duplicate UI layers after scene reloads
- Ensure a single source of UI input and layering

## Scope

- `scripts/ui/UIManager.gd`

## Acceptance Criteria

- `UIManager` stores a reference to the created `CanvasLayer`.
- On `_exit_tree()` or cleanup, `UIManager` frees the `CanvasLayer` it created.
- Re-initializing `UIManager` in the same session produces exactly one `UIContainer` layer.

## Implementation Steps

1. Modify `setup_ui_container()` to store `canvas_layer` as `self.canvas_layer`.
2. Implement `_exit_tree()` or `_notification()` to call `canvas_layer.queue_free()` if it exists and is still in tree.
3. Add guard to avoid freeing a user-provided layer.

## Test Cases

- Enter and exit the scene multiple times: ensure only one `UIManagerLayer` exists in the root.
- Confirm UI input functions still operate.
