# Task 12 — Preload UI Scenes

Status: not-started

## Summary

To avoid blocking I/O and inconsistent load times, preload or export PackedScenes for critical UI components instead of calling `ResourceLoader.exists()` and `load()` at runtime.

## Motivation

- Faster UI instantiation
- Fewer I/O stalls during scene startup

## Scope

- `scripts/ui/UIManager.gd`

## Acceptance Criteria

- UIManager exposes `@export var ui_scenes: Dictionary` or preloads PackedScenes at top-level.
- During `_ready()` the manager instantiates from preloaded PackedScenes if available; otherwise uses `ResourceLoader` as a fallback with a logged warning.
- No blocking load calls on the main critical path.

## Implementation Steps

1. Add exported `PackedScene` fields or a dictionary mapping keys to `PackedScene`.
2. Update `setup_ui_scenes()` to prefer these preloaded scenes and only fall back to `ResourceLoader.exists()` when a PackedScene isn't provided.
3. Document required scene names in the spec file so designers can set exported fields in the editor.

## Test Cases

- Run a cold start scene and verify UI instantiation is immediate and does not block.
- Leave exports empty and verify fallback still loads UIs but logs warning suggesting export usage.
