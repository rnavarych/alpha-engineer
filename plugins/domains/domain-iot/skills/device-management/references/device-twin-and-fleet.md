# Device Twin, Shadow State and Fleet Management

## When to load
Load when implementing device shadow/twin synchronization, command-and-control patterns, or fleet-wide operations such as group updates, health monitoring, and decommissioning.

## Device Twin / Shadow State Pattern
```
Desired State (set by backend)     Reported State (set by device)
{                                  {
  "telemetryInterval": 30,           "telemetryInterval": 60,
  "firmwareVersion": "2.1.0"         "firmwareVersion": "2.0.5"
}                                  }
```

- Backend writes desired state; device reads it and applies changes
- Device writes reported state; backend reads it to verify convergence
- Delta between desired and reported indicates pending or failed updates
- Use versioning or ETags to prevent write conflicts

## Synchronization
- Device fetches desired state on connect and subscribes to change notifications
- On receiving a desired state change, the device applies it and reports the new state
- If the device is offline, the desired state queues and delivers on reconnection
- Implement conflict resolution: last-writer-wins, version vectors, or application-specific merge

## Command and Control Patterns

| Pattern | Mechanism | Use Case |
|---------|-----------|----------|
| **Request-Response** | Cloud sends command, device acknowledges with result | Reboot, config change, diagnostic query |
| **Fire-and-Forget** | Cloud sends command via QoS 0/1, no response expected | Non-critical hints, display updates |
| **Method Invocation** | Direct method call with timeout (Azure), Job (AWS) | Time-sensitive operations requiring confirmation |

- Set command TTL to prevent stale commands from executing on devices that were offline
- Log all commands for auditing: who issued, when, to which device, result
- Implement idempotent command handlers to safely handle duplicate delivery

## Fleet Management
- **Group operations**: Apply firmware updates, configuration changes, or commands to device groups defined by tags
- **Monitoring dashboards**: Aggregate fleet health (online %, firmware distribution, error rates)
- **Alerting**: Trigger alerts when a device group's error rate or disconnection rate exceeds thresholds
- **Decommissioning**: Revoke device credentials, remove from registry, wipe sensitive data remotely
- **Compliance**: Track firmware versions across the fleet, flag devices running vulnerable versions
