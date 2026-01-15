# Task 04 — Sync SkillManager On Load

Status: not-started

## Summary

When loading saved games, `SkillManager` may not reflect `GameManager.player_data` until new experience is gained. Connect `SkillManager` to `GameManager.player_data_loaded` to ensure skill levels and experience are updated immediately after load.

## Motivation

- Keep skill levels and experience consistent after load
- Avoid confusing UX where skills appear lower until next activity

## Scope

- `scripts/singletons/SkillManager.gd`
- `scripts/singletons/GameManager.gd` (signal is already present)

## Acceptance Criteria

- `SkillManager` listens for `GameManager.player_data_loaded` and calls `sync_with_player_data()`.
- After loading a save, `SkillManager.skills` and `skill_experience` match `GameManager.player_data.skills` and any saved XP.

## Implementation Steps

1. Connect a handler in `_ready()` of `SkillManager` to the `GameManager.player_data_loaded` signal (avoid duplicate connects).
2. Implement the handler to call `sync_with_player_data()`.
3. Add small tests: load a save with modified skill levels and confirm UI/SkillManager reflects values.

## Test Cases

- Save a game after setting skill levels > 1 and XP > 0, reload: SkillManager shows those levels and XP immediately.
