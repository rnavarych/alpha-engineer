# Edge-Cloud Synchronization and Offline Operation

## When to load
Load when designing data sync strategies between edge and cloud, implementing conflict resolution, or building offline-resilient edge systems that must survive intermittent connectivity.

## Data Synchronization Strategies
- **Streaming**: Continuous telemetry forwarding via MQTT or Kafka for near-real-time cloud views
- **Batch upload**: Periodic uploads (every 5-15 minutes) of aggregated data to reduce API calls
- **Event-driven**: Forward only when thresholds are crossed or significant events occur

## Conflict Resolution
- For configuration: cloud-desired state wins; edge reports actual state
- For data: append-only telemetry avoids conflicts; use timestamps for ordering
- For edge-generated alerts: deliver at-least-once and deduplicate in the cloud

## Offline Operation
Design for intermittent connectivity as the default, not the exception:
- **Local storage**: SQLite, LevelDB, or circular buffer in flash for telemetry queuing
- **Autonomous decisions**: Edge must operate with locally cached rules and models
- **Sync on reconnect**: Replay queued messages in order; use sequence numbers for gap detection
- **Graceful degradation**: Clearly define which features work offline vs require connectivity
- **Time handling**: Use NTP when online, RTC with drift compensation when offline; timestamp all data at the source
