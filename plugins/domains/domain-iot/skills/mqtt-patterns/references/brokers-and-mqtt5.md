# Broker Selection, MQTT 5.0 Features, and Client Libraries

## When to load
Load when selecting an MQTT broker for a deployment, adopting MQTT 5.0 features, choosing client libraries for embedded or server-side code, or reviewing anti-patterns to avoid.

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
