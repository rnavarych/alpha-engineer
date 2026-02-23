# Story Points and Estimation

## When to load
Load when estimating stories with Planning Poker, calibrating the Fibonacci scale, calculating sprint capacity, or validating that a sprint is correctly loaded against team velocity.

---

## Fibonacci Scale and Calibration

Story points measure relative complexity, not time. They encode effort, uncertainty, and risk together.

| Points | Meaning | Real-world calibration example |
|--------|---------|-------------------------------|
| 1 | Trivial — copy change, config update | Change button label text in one place |
| 2 | Small — well-understood, low risk | Add a new field to an existing form with validation |
| 3 | Medium — some complexity or unknowns | Add a new API endpoint with auth, validation, and tests |
| 5 | Large — significant complexity | Integrate a new third-party API with error handling and retry logic |
| 8 | Very large — multiple moving parts | Build a complete checkout flow (use this as a signal to split) |
| 13 | Epic — too big for one sprint | Entire feature area; must be decomposed |
| 21 | Estimation exercise is impossible | Scope unclear; run a spike first |

---

## Planning Poker Rules

1. Everyone estimates independently before revealing — no anchoring
2. If variance is large (e.g., 2 vs. 13), the extremes explain their reasoning — the divergence reveals hidden assumptions
3. Re-vote after discussion if needed; aim for consensus, not average
4. If you can't converge in 3 rounds, the story needs more clarification before estimation

---

## Velocity and Capacity Formula

```
Sprint capacity = team_size × sprint_days × focus_factor × average_hours_per_point

Focus factor: 0.7 is a safe default (accounts for meetings, reviews, incidents, context-switching)

Example:
  4 developers × 10 days × 0.7 focus × 1 day/point = 28 story points capacity

  MoSCoW split:
  Must Have: 28 × 0.60 = 17 points
  Should Have: 28 × 0.20 = 6 points
  Could Have: 28 × 0.20 = 6 points

  Load Must Have: 17 points first. If Should Have can fit: add them.
  If Could Have can fit: add them. Never exceed total capacity.
```

---

## Anti-Patterns

### Estimating in Hours
Hours feel precise but carry false confidence. Story points encode uncertainty — a 5-point story might take 3 hours or 3 days depending on what you find. The relative scale is honest in a way hours aren't.

### Using Velocity to Pressure the Team
"Your velocity was 32 last sprint, why only 28 this sprint?" Velocity is a planning tool, not a performance metric. Pressuring teams on velocity leads to point inflation, not faster delivery.

---

## Quick Reference

```
Story points: Fibonacci scale; relative complexity + uncertainty + risk
8+ points: split signal — story is too large for confident estimation
21 points: run a spike first — scope is unclear
Planning Poker: estimate independently, surface divergence, converge on consensus not average
Velocity formula: team_size × sprint_days × 0.7 focus × avg_hours_per_point
Never exceed total sprint capacity — MoSCoW split determines load order
```
