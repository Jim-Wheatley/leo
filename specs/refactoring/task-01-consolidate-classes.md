# Task 01 — Consolidate Duplicate Classes

Status: in-progress

## Summary

Two core data classes, `ArtworkData` and `InventoryItem`, are defined twice:
- `scripts/data/*` contains one versionAchievementManager.debug_reset_and_trigger_samples()
- `scripts/player/*` contains a second version with different fields and behaviour

Having two `class_name` definitions with the same name causes unpredictable runtime behaviour and conflicts when Godot autoloads classes. This task consolidates the canonical definitions under `scripts/data/` and removes duplicates under `scripts/player/`.

## Motivation

- Prevent runtime ambiguity when `class_name` is registered twice.
- Ensure save/load, portfolio and inventory logic are consistent across systems.
- Make future maintenance straightforward by having a single source of truth for item and artwork data.

## Files To Keep (Canonical)

- `scripts/data/ArtworkData.gd` — canonical ArtworkData
- `scripts/data/InventoryItem.gd` — canonical InventoryItem

## Files To Remove

- `scripts/player/ArtworkData.gd` — remove duplicate
- `scripts/player/InventoryItem.gd` — remove duplicate

## Acceptance Criteria (SpecKit style)

- The repository contains only one `class_name ArtworkData` and one `class_name InventoryItem`.
- Running the demo save/load sequence preserves inventory and portfolio without errors.
- No runtime warnings about duplicate class names appear in the console.
- Tests that interact with inventory and portfolio (manual or automated) produce identical results before and after the change.

## Implementation Steps

1. Inspect both versions of `ArtworkData.gd` and `InventoryItem.gd` and choose the richer/most complete implementation as canonical (prefer `scripts/data/`).
2. Update canonical files' APIs so they satisfy uses across the project (fields/methods found in player copies).
3. Replace or adapt code that relied on the player-local variant where necessary.
4. Remove duplicate files from `scripts/player/`.
5. Run a manual test scenario: create sketch, craft paint, create artwork, save, reload, ensure data restored.

## Rolling Back

- Keep a Git branch before starting this change and commit small incremental changes so it's easy to revert.

## Test Cases

- Create a canvas and paint, craft an artwork, save the game, quit, reload — verify `GameManager.player_data.portfolio` contains the artwork.
- Serialize and deserialize `InventoryItem.to_dict()` and `from_dict()` round-trip without data loss.
- Ensure `class_name` logs do not warn about duplicates.

## Notes

- If fields differ, the canonical class should include compatibility logic in `from_dict()` to accept legacy keys.
- Keep the `Resource` vs `RefCounted` decisions consistent; prefer `Resource` for saved data objects unless lifetime semantics require `RefCounted`.
