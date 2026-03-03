---
name: domain-iot:digital-twin
description: Digital twin design patterns including state-based and simulation-based modeling, real-time state synchronization, predictive maintenance via simulation, what-if scenario analysis, 3D visualization, and platform guidance for Azure Digital Twins and AWS IoT TwinMaker.
allowed-tools: Read, Grep, Glob, Bash
---

# Digital Twin Patterns

## When to use
- Designing a digital twin architecture from scratch (shadow vs twin vs simulation)
- Modeling twin ontologies with DTDL, RealEstateCore, or custom schemas
- Implementing device-to-twin and twin-to-device synchronization pipelines
- Building predictive maintenance with RUL models and anomaly detection
- Running what-if scenario analysis in a sandboxed twin environment
- Selecting Azure Digital Twins, AWS IoT TwinMaker, or open-source alternatives

## Core principles
1. **Maturity determines complexity** — start with a digital shadow (read-only), graduate to bidirectional twin only when control use cases are proven
2. **Graph topology mirrors physical topology** — site → building → floor → room → device; queries follow the physical hierarchy
3. **Eventual consistency is fine for monitoring; not for control** — sub-second twin updates matter only in closed-loop control scenarios
4. **Staleness thresholds are a first-class feature** — a twin that hasn't updated in 5x its expected interval is broken, not just quiet
5. **Sandbox before touching the physical asset** — all what-if scenarios run on a cloned twin state, never against the live twin

## Reference Files
- `references/twin-modeling.md` — maturity levels, state-based vs simulation-based twins, DTDL ontology design, example twin state document
- `references/sync-and-scenarios.md` — device-to-twin and twin-to-device sync flows, consistency model, staleness handling, what-if sandbox implementation
- `references/predictive-maintenance.md` — RUL prediction approach, baseline modeling, degradation tracking, ML model selection (Isolation Forest, LSTM, Weibull)
- `references/visualization-and-platforms.md` — 3D visualization options (Three.js, BIM, Unreal), Azure Digital Twins, AWS IoT TwinMaker, Eclipse Ditto, FIWARE
