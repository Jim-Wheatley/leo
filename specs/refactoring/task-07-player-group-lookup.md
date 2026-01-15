# Task 07 — Use Player Group Lookup

Status: not-started

## Summary

Replace fragile hierarchical player lookup (`find_child("Player")`) with a group-based lookup (`get_tree().get_first_node_in_group("player")`) so systems can find the player reliably regardless of scene structure.

## Motivation

- Scene refactors shouldn't break code that locates the player node.
- Group lookups are faster and more robust across nested scenes.

## Scope

- `scripts/singletons/GameManager.gd` and other files using `find_child("Player")`.
- Scenes where the Player node lives (add to group in editor or via script).

## Acceptance Criteria

- All lookups use `get_first_node_in_group("player")`.
- Player nodes are added to the `player` group in scenes (either in scene files or `_ready()` of `PlayerController`).
- No runtime errors when trying to get player reference.

## Implementation Steps

1. Add `add_to_group("player")` in the player's scene `_ready()` (e.g., `PlayerController.gd`).
2. Replace `current_scene.find_child("Player")` usages with a helper `get_player()` that returns `get_tree().get_first_node_in_group("player")`.
3. Centralize `get_player()` in `GameManager` for a single canonical lookup.
4. Add null-checks where player-dependent code runs and fail gracefully.

## Test Cases

- Move the Player node deeper in scene hierarchy; verify `GameManager` still finds it.
- Run save/load that uses player position restore and confirm it sets the correct node.
