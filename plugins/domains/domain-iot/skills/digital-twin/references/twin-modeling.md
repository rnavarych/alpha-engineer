# Digital Twin Modeling Approaches

## When to load
Load when designing digital twin architecture, defining twin models and ontologies, or choosing between state-based and simulation-based approaches.

## What is a Digital Twin?
A digital twin is a virtual representation of a physical entity (device, machine, building, process) that stays synchronized with the real-world counterpart through live data feeds. It enables monitoring, simulation, prediction, and optimization without interacting directly with the physical asset.

### Maturity Levels
1. **Digital Shadow**: One-way sync. Physical asset pushes data to the digital model. Read-only representation.
2. **Digital Twin**: Bidirectional sync. The digital model can send commands or configuration back to the physical asset.
3. **Digital Twin with Simulation**: The digital model runs predictive simulations and what-if scenarios, feeding insights back into operations.

## State-Based Twins
- Model the twin as a live state document reflecting current sensor readings and configuration
- Structure as a JSON/graph model with properties, telemetry, relationships, and commands
- Update properties in real-time as device telemetry arrives
- Query twin state for current conditions without hitting the physical device

```json
{
  "twinId": "pump-001",
  "model": "dtmi:factory:pump;1",
  "properties": {
    "flowRate": 12.5,
    "pressure": 3.2,
    "temperature": 45.8,
    "vibration": 0.03,
    "status": "running",
    "maintenanceDue": "2024-03-15"
  },
  "relationships": {
    "locatedIn": "building-a/floor-2/room-201",
    "suppliedBy": "valve-042",
    "feedsInto": "tank-007"
  }
}
```

## Simulation-Based Twins
- Attach physics models, ML models, or rule engines to the twin
- Feed live telemetry into the simulation to predict future states
- Compare predicted vs actual behavior to detect anomalies
- Use cases: remaining useful life prediction, energy optimization, process simulation

## Ontology and Schema Design
- Use DTDL (Digital Twins Definition Language) for Azure Digital Twins
- Define models with properties (static attributes), telemetry (time-varying values), relationships (connections between twins), and commands (actions)
- Build a twin graph that mirrors the physical topology: site > building > floor > room > device
- Reuse industry-standard ontologies (RealEstateCore for buildings, WoT for generic IoT)
