# Task 09 — Explicit Dictionary Access in Crafting

Status: not-started

## Summary

Crafting station scripts use dot-style access (`material.item_id`) on dictionaries, which is unsafe and unclear. Switch to explicit `Dictionary.get()` calls and add schema documentation for recipe dictionaries.

## Motivation

- Reduce runtime errors from missing keys.
- Make the recipe schema explicit and easier to maintain.

## Scope

- `scripts/crafting/PaintCreationStation.gd`
- `scripts/crafting/CanvasMakingStation.gd`
- `scripts/crafting/ArtworkCreationStation.gd`
- `scripts/crafting/WorkstationBase.gd`

## Acceptance Criteria

- All recipe access uses `material.get("item_id", "")` and `material.get("amount", 1)`.
- Recipe schema documented at top of each station file.
- No runtime errors caused by missing keys when recipes are malformed.

## Implementation Steps

1. Add a short schema comment to each station file describing expected keys: `item_id`, `amount`, `result_id`, `result_name`, `size`.
2. Replace references like `material.item_id` with `material.get("item_id", "")`.
3. Add assertions or `push_warning()` when required keys are missing.

## Test Cases

- Provide a malformed recipe (missing `amount`) and verify the station warns instead of erroring.
- Normal recipes still craft correctly.
