---
name: mqtt-patterns
description: |
  MQTT messaging patterns for IoT systems including topic hierarchy design,
  QoS level selection, retained messages, last will and testament, broker
  deployment, and MQTT 5.0 feature adoption.
allowed-tools: Read, Grep, Glob, Bash
---

# MQTT Patterns for IoT

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

## Broker Selection

| Broker | Strengths | Best For |
|--------|-----------|----------|
| **Mosquitto** | Lightweight, easy to deploy, wide adoption | Small to medium deployments, development/testing |
| **EMQX** | Clustering, high throughput, rule engine | Large-scale production, millions of connections |
| **HiveMQ** | Enterprise features, Kafka integration, support | Enterprise environments requiring SLA and support |
| **VerneMQ** | Erlang-based clustering, plugin system | Distributed deployments needing horizontal scale |

## MQTT 5.0 Features

Adopt MQTT 5.0 when your broker and clients support it for these key improvements:

- **Shared subscriptions** (`$share/group/topic`): Load-balance messages across consumer instances for horizontal scaling of backend processors
- **Message expiry interval**: Automatically discard stale messages; critical for command topics where old commands should not execute
- **User properties**: Attach key-value metadata (content-type, correlation IDs, trace context) without modifying the payload
- **Topic aliases**: Reduce per-message overhead by replacing long topic strings with short numeric aliases
- **Response topic + correlation data**: Native request-response pattern without building custom correlation logic
- **Reason codes**: Detailed error feedback on CONNACK, PUBACK, SUBACK for better client-side error handling

## Client Libraries

- **C/C++ (embedded)**: Eclipse Paho Embedded C, ESP-MQTT (ESP-IDF native)
- **Python**: paho-mqtt (synchronous), aiomqtt / gmqtt (asyncio)
- **JavaScript/Node.js**: mqtt.js (browser and Node, MQTT over WebSocket)
- **Java**: Eclipse Paho Java, HiveMQ MQTT Client (reactive, MQTT 5.0)
- **Go**: Eclipse Paho Go, mochi-mqtt (broker and client)

## Anti-Patterns to Avoid

- Publishing device IDs in the payload when they are already in the topic
- Using a single flat topic for all devices (destroys filtering and ACL capabilities)
- Setting QoS 2 on all messages "just to be safe" (wastes bandwidth and increases latency)
- Subscribing to `#` in production (receives all messages on the broker)
- Not implementing reconnection with exponential backoff in client code
