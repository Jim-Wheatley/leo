# Task 02 — UI Null Guards (UIManager)

Status: not-started

## Summary

`UIManager.gd` currently toggles and directly accesses UI nodes that may not exist in certain scenes (optional UI). This causes runtime errors when developers run the game without all UI scenes present. Add robust null checks and graceful fallbacks.

## Motivation

- Prevent crashes when optional UI scenes are missing.
- Provide graceful degradation for test scenes and CI.

## Scope

- `scripts/ui/UIManager.gd`

## Acceptance Criteria

- All UI toggle/open/close methods safely handle null `inventory_ui`, `portfolio_ui`, `skill_tree_ui`, `pause_menu`, `crafting_station_ui`, `achievement_list_ui`.
- Where a UI is missing, the function logs a warning and returns false or no-op instead of throwing.
- The manager continues to function for available UI components.

## Implementation Steps

1. Audit all `toggle_*`, `open_*`, `close_*` methods in `UIManager.gd`.
2. Add defensive `if not inventory_ui: push_warning(...)` style checks and early returns.
3. Add lightweight tests (manual): call toggle functions in a scene with missing UI.

## Test Cases

- Start scene without `InventoryUI.tscn` — invoking `toggle_inventory()` should not crash and should log a warning.
- Start scene with all UIs present — normal behaviour unchanged.
