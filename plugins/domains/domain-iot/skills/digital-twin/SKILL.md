---
name: digital-twin
description: |
  Digital twin design patterns including state-based and simulation-based
  modeling, real-time state synchronization, predictive maintenance via
  simulation, what-if scenario analysis, 3D visualization, and platform
  guidance for Azure Digital Twins and AWS IoT TwinMaker.
allowed-tools: Read, Grep, Glob, Bash
---

# Digital Twin Patterns

## What is a Digital Twin?

A digital twin is a virtual representation of a physical entity (device, machine, building, process) that stays synchronized with the real-world counterpart through live data feeds. It enables monitoring, simulation, prediction, and optimization without interacting directly with the physical asset.

### Maturity Levels
1. **Digital Shadow**: One-way sync. Physical asset pushes data to the digital model. Read-only representation.
2. **Digital Twin**: Bidirectional sync. The digital model can send commands or configuration back to the physical asset.
3. **Digital Twin with Simulation**: The digital model runs predictive simulations and what-if scenarios, feeding insights back into operations.

## Twin Modeling Approaches

### State-Based Twins
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

### Simulation-Based Twins
- Attach physics models, ML models, or rule engines to the twin
- Feed live telemetry into the simulation to predict future states
- Compare predicted vs actual behavior to detect anomalies
- Use cases: remaining useful life prediction, energy optimization, process simulation

### Ontology and Schema Design
- Use DTDL (Digital Twins Definition Language) for Azure Digital Twins
- Define models with properties (static attributes), telemetry (time-varying values), relationships (connections between twins), and commands (actions)
- Build a twin graph that mirrors the physical topology: site > building > floor > room > device
- Reuse industry-standard ontologies (RealEstateCore for buildings, WoT for generic IoT)

## State Synchronization Patterns

### Device-to-Twin Sync
1. Device publishes telemetry to MQTT topic or IoT Hub
2. Stream processor or rules engine routes data to the twin service
3. Twin service updates the relevant twin properties
4. Change events propagate to subscribed consumers (dashboards, alerting, other twins)

### Twin-to-Device Sync
1. Operator or automation updates the twin's desired state
2. Twin service publishes the desired state change to the device (via device shadow, direct method, or MQTT command)
3. Device applies the change and reports back its new actual state
4. Twin reconciles desired vs reported state

### Consistency Model
- Eventual consistency is acceptable for monitoring and analytics use cases
- For control loops, minimize sync latency: target sub-second twin updates
- Use timestamps and sequence numbers to handle out-of-order updates
- Define staleness thresholds: flag twins as "stale" if no update received within expected interval

## Predictive Maintenance via Simulation

### Approach
1. **Baseline model**: Establish normal operating parameters from historical data (vibration range, temperature envelope, performance curves)
2. **Live comparison**: Continuously compare incoming telemetry against the baseline model
3. **Degradation tracking**: Track how far current readings deviate from the baseline over time
4. **Remaining useful life (RUL)**: Predict when the asset will cross failure thresholds using regression or survival analysis
5. **Maintenance scheduling**: Trigger work orders when RUL drops below a configurable lead time

### ML Models for Predictive Maintenance
- Anomaly detection: Isolation Forest, Autoencoders on multivariate sensor data
- Failure classification: Random Forest, XGBoost trained on labeled failure events
- RUL prediction: LSTM networks on sequential sensor history, Weibull survival models
- Deploy lightweight inference models at the edge for real-time detection; retrain in the cloud

## What-If Scenario Analysis

Enable operators and engineers to test hypothetical scenarios without affecting the physical system:

- **Capacity planning**: "What if we increase production throughput by 20%? Will cooling capacity be sufficient?"
- **Failure impact**: "What if pump-003 fails? How does flow redistribute across the system?"
- **Configuration optimization**: "What telemetry interval minimizes battery drain while maintaining acceptable data resolution?"
- **Upgrade evaluation**: "What if we replace motor-A with a more efficient model? What is the projected energy savings?"

### Implementation
- Clone the current twin state into a sandbox environment
- Apply the hypothetical changes to the sandbox twin
- Run the simulation model forward in time
- Compare results (energy, throughput, cost) against the baseline
- Present results in a dashboard for decision-making

## 3D Visualization

### Approaches
- **Web-based 3D**: Three.js, Babylon.js for browser-rendered 3D twin views
- **BIM integration**: Import IFC/Revit building models and overlay IoT data
- **Game engine**: Unreal Engine or Unity for high-fidelity industrial visualization
- **AR/VR**: HoloLens or Quest for on-site overlay of twin data onto physical equipment

### Dashboard Design
- Color-code assets by status: green (healthy), yellow (warning), red (critical)
- Click-to-drill: click a 3D asset to see its time-series charts and properties
- Spatial heatmaps: temperature, occupancy, or vibration intensity across a floor plan
- Animated flows: visualize fluid flow, energy distribution, or data flow through the system

## Platform Guidance

### Azure Digital Twins
- DTDL-based model definitions with inheritance and relationships
- Twin graph for modeling complex topologies with queryable relationships
- Event routes to Event Grid, Event Hub, or Service Bus for downstream processing
- Integration with Azure Maps (spatial), Time Series Insights (historical), and 3D Scenes Studio (visualization)
- Pricing: per million operations (reads, writes, queries)

### AWS IoT TwinMaker
- Entity-component model for defining twin structures
- Scenes for 3D visualization using AWS IoT TwinMaker scene viewer (built on Babylon.js)
- Knowledge graph for relationship queries across entities
- Data connectors: pull from IoT SiteWise, S3, Timestream, or custom Lambda data sources
- Integration with Grafana IoT TwinMaker plugin for unified dashboards
- Pricing: per entity, per data connector, per scene

### Open-Source Alternatives
- **Eclipse Ditto**: Digital twin framework with HTTP/WebSocket APIs, policy-based access control
- **FIWARE NGSI-LD**: Context broker with linked data model for smart city and industry twins
- **Custom**: Build on a graph database (Neo4j) or document store (MongoDB) with a custom sync layer
