# Task 11 — Pool VFX Objects

Status: not-started

## Summary

`VFXManager.gd` creates particle and label nodes on the fly for each effect. Under heavy use this causes allocation spikes. Implement a small object pool to reuse CPUParticles2D, Labels, and any ephemeral nodes.

## Motivation

- Reduce GC and allocation churn during effect-heavy scenes
- Maintain visual quality while improving runtime stability

## Scope

- `scripts/singletons/VFXManager.gd`

## Acceptance Criteria

- A simple pool of reusable nodes is maintained for common VFX types.
- `create_*` methods check out nodes from the pool and return them after use.
- Pool sizes are bounded and can grow/shrink with demand.

## Implementation Steps

1. Add `pool: Dictionary` keyed by type string ("particles", "label", etc.) with arrays of nodes.
2. Implement `checkout(type)` and `checkin(node, type)` helpers.
3. Replace ad-hoc `CPUParticles2D.new()` / `Label.new()` with pooled checkouts.
4. Ensure nodes are reset (stop emitting, reset modulate) before reuse.

## Test Cases

- Trigger 100 gather events in quick succession and validate heap/GC behaviour remains stable.
- Visual effects identical to before; no leaked nodes remain after effects complete.
