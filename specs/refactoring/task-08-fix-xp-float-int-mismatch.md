# Task 08 — Fix XP Float/Int Mismatch

Status: not-started

## Summary

Some systems (e.g., `SketchingSystem`) compute experience as floats and pass them to `SkillManager.add_experience()` which expects ints. This causes implicit truncation. Decide a consistent experience type and fix mismatches.

## Motivation

- Avoid lost progress and inconsistent leveling due to truncation.
- Make experience calculations reproducible and transparent.

## Scope

- `scripts/systems/SketchingSystem.gd`
- `scripts/singletons/SkillManager.gd`

## Acceptance Criteria

- The system uses either integer XP everywhere or accepts floats consistently.
- No silent truncation (use explicit rounding or update method signatures).
- Logged messages show whole-number experience where appropriate.

## Implementation Steps

1. Choose representation: prefer integer XP for clarity. Document this choice in `SkillManager.gd`.
2. Update `SketchingSystem.award_sketching_experience()` to compute integer XP (round or floor explicitly) before calling `add_experience()`.
3. Add type checks or casts inside `SkillManager.add_experience()` and log a warning if a non-int is passed.
4. Update any other callers that pass float XP.

## Test Cases

- Complete sketches that previously awarded fractional XP and confirm `SkillManager` shows expected integer gains.
- No warnings about implicit truncation after changes.
