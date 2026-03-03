---
name: domain-iot:mqtt-patterns
description: MQTT messaging patterns for IoT systems including topic hierarchy design, QoS level selection, retained messages, last will and testament, broker deployment, and MQTT 5.0 feature adoption.
allowed-tools: Read, Grep, Glob, Bash
---

# MQTT Patterns for IoT

## When to use
- Designing MQTT topic hierarchies for a new IoT system
- Choosing the right QoS level for telemetry, commands, or alerts
- Implementing device presence detection with retained messages and LWT
- Selecting or scaling an MQTT broker (Mosquitto, EMQX, HiveMQ, VerneMQ)
- Adopting MQTT 5.0 features like shared subscriptions, message expiry, or user properties
- Reviewing client library options for embedded C, Python, Node.js, Java, or Go

## Core principles
1. **Topic hierarchy is your ACL and filter contract** — put the device ID early; flat topics destroy per-device access control and wildcard efficiency
2. **QoS 1 is the sane default** — deduplicate on the backend; QoS 2's four-way handshake costs more than it saves in most telemetry scenarios
3. **LWT plus retained messages equals a free presence system** — no polling, no heartbeat endpoint, broker handles it
4. **MQTT 5.0 shared subscriptions replace every hand-rolled consumer group** — load-balance backend processors without custom coordination
5. **Never subscribe to `#` in production** — you will receive everything on the broker; your consumer will not survive it

## Reference Files
- `references/topics-and-qos.md` — topic naming conventions, hierarchy patterns, QoS comparison table, retained messages, LWT configuration for device presence
- `references/brokers-and-mqtt5.md` — broker selection (Mosquitto / EMQX / HiveMQ / VerneMQ), MQTT 5.0 feature guide, client libraries per language, anti-patterns to avoid
