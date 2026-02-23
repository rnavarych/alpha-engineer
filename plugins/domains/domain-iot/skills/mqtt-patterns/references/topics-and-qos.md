# MQTT Topic Hierarchy and QoS Selection

## When to load
Load when designing MQTT topic structures, choosing QoS levels for different message types, or configuring retained messages and Last Will and Testament (LWT) for device presence.

## Topic Hierarchy Design
Structure topics as a logical hierarchy reflecting your domain model:

```
{organization}/{site}/{device-type}/{device-id}/{data-type}
```

**Common patterns:**
- Telemetry: `home/living-room/temperature` or `fleet/{device-id}/telemetry`
- Commands: `devices/{device-id}/commands/reboot`
- Status: `devices/{device-id}/status` (online/offline via LWT)
- Wildcards: `home/+/temperature` (single level), `fleet/device-123/#` (multi level)

**Topic naming rules:**
- Use lowercase with hyphens, not camelCase or underscores
- Keep topics short to save bandwidth on constrained devices
- Avoid leading slashes (they create an empty first level)
- Place the most selective segment (device ID) early for efficient ACL matching
- Use `$SYS/` prefix awareness; it is reserved for broker statistics

## QoS Level Selection

| QoS | Delivery | Use Case | Overhead |
|-----|----------|----------|----------|
| 0 - At most once | Fire and forget | High-frequency sensor data where occasional loss is acceptable | Lowest |
| 1 - At least once | Acknowledged, possible duplicates | Alerts, commands, important telemetry | Moderate |
| 2 - Exactly once | Four-step handshake, no duplicates | Financial transactions, billing events, critical state changes | Highest |

**Guidelines:**
- Default to QoS 1 for most IoT telemetry; deduplicate on the backend if needed
- Use QoS 0 only when data arrives frequently enough that a missed message is irrelevant
- Reserve QoS 2 for scenarios where duplicate processing causes real harm
- Match QoS on publish and subscribe sides; the effective QoS is the minimum of both

## Retained Messages
- Use retained messages for device status so new subscribers get the current state immediately
- Publish a retained empty payload to clear a previously retained message
- Combine retained messages with LWT for reliable online/offline status tracking
- Avoid retaining high-frequency telemetry; retain only "latest known state" topics

## Last Will and Testament (LWT)
Configure LWT at connection time to auto-publish on ungraceful disconnect:

```
Will Topic:  devices/{device-id}/status
Will Payload: {"status": "offline", "timestamp": "..."}
Will QoS:    1
Will Retain: true
```

On connect, publish a retained `{"status": "online"}` to the same topic. This creates a reliable presence system without polling.
