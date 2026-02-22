---
name: protocol-advisor
description: |
  IoT communication protocol selection and advisory covering MQTT, CoAP, AMQP,
  HTTP comparison, wireless technologies (Zigbee, Z-Wave, BLE, LoRaWAN, NB-IoT,
  LTE-M), and protocol bridging patterns for heterogeneous IoT deployments.
allowed-tools: Read, Grep, Glob, Bash
---

# IoT Protocol Advisor

## Application-Layer Protocol Comparison

### MQTT (Message Queuing Telemetry Transport)
- **Transport**: TCP (port 1883, TLS on 8883), WebSocket for browser clients
- **Pattern**: Publish-subscribe with broker
- **Strengths**: Low overhead (2-byte minimum header), bidirectional, retained messages, LWT, mature ecosystem
- **Best for**: Telemetry ingestion, device-to-cloud and cloud-to-device messaging, event-driven architectures
- **Limitations**: Requires persistent TCP connection, broker is a central dependency

### CoAP (Constrained Application Protocol)
- **Transport**: UDP (port 5683, DTLS on 5684)
- **Pattern**: Request-response (REST-like: GET, PUT, POST, DELETE)
- **Strengths**: Very low overhead, designed for constrained devices (8-bit MCUs, 10KB RAM), multicast support, observable resources
- **Best for**: Constrained devices with limited memory, battery-powered sensors, LAN discovery
- **Limitations**: UDP means no guaranteed delivery (application must handle), less mature tooling than MQTT

### AMQP (Advanced Message Queuing Protocol)
- **Transport**: TCP (port 5672, TLS on 5671)
- **Pattern**: Queue-based with exchanges and routing
- **Strengths**: Rich routing (direct, topic, fanout, headers), message acknowledgment, transactions, high reliability
- **Best for**: Enterprise integration, backend service communication, scenarios requiring message ordering guarantees
- **Limitations**: Higher overhead, complex for constrained devices, overkill for simple telemetry

### HTTP/REST
- **Transport**: TCP (port 80/443)
- **Pattern**: Request-response
- **Strengths**: Universal, well-understood, extensive tooling, firewall-friendly
- **Best for**: Device configuration APIs, firmware download, infrequent data reporting
- **Limitations**: High overhead per request (headers), no server-initiated push (requires polling or WebSocket), not suitable for high-frequency telemetry

### Selection Decision Matrix

| Criterion | MQTT | CoAP | AMQP | HTTP |
|-----------|------|------|------|------|
| Device RAM < 32KB | Fair | Best | Poor | Poor |
| Battery life critical | Good | Best | Poor | Poor |
| Bidirectional messaging | Best | Fair | Good | Poor |
| Reliable delivery | Good (QoS) | Fair | Best | Good |
| Firewall traversal | Good | Fair | Fair | Best |
| Message throughput | Best | Good | Good | Fair |
| Ecosystem maturity | Best | Fair | Good | Best |

## Wireless Technology Selection

### Short Range (< 100m)

**Bluetooth Low Energy (BLE)**
- Range: 10-100m, Data rate: 1-2 Mbps (BLE 5.0), Power: Very low
- Use cases: Wearables, proximity beacons, medical devices, asset tracking
- Mesh support via Bluetooth Mesh for building automation
- Best when: Devices pair with smartphones or local gateways, low data volume

**Zigbee (IEEE 802.15.4)**
- Range: 10-100m, Data rate: 250 kbps, Power: Low
- Use cases: Home automation (lights, switches, sensors), industrial sensor networks
- Self-forming and self-healing mesh network with up to 65,000 nodes
- Best when: Dense mesh networks, home/building automation, Matter-compatible ecosystem

**Z-Wave**
- Range: 30-100m, Data rate: 100 kbps, Power: Low
- Use cases: Home automation (locks, thermostats, security)
- Sub-GHz frequency (less interference than 2.4GHz), mesh with up to 232 nodes
- Best when: Home automation requiring reliable sub-GHz mesh, interoperability matters (Z-Wave Alliance certification)

### Medium Range (100m - 10km)

**Wi-Fi (802.11 b/g/n/ac/ax)**
- Range: 50-100m indoor, Data rate: Up to 9.6 Gbps (Wi-Fi 6), Power: High
- Use cases: Cameras, smart speakers, appliances, any device near mains power
- Wi-Fi HaLow (802.11ah): Sub-GHz, lower power, longer range for IoT
- Best when: High bandwidth needed, mains-powered devices, existing Wi-Fi infrastructure

### Long Range (> 1km)

**LoRaWAN**
- Range: 2-15km (urban/rural), Data rate: 0.3-50 kbps, Power: Very low
- Use cases: Smart agriculture, water metering, environmental monitoring, asset tracking
- Unlicensed spectrum (ISM bands), low infrastructure cost
- Best when: Long range, very low power, small data payloads (< 250 bytes), low cost per device

**NB-IoT (Narrowband IoT)**
- Range: Cellular coverage, Data rate: ~250 kbps, Power: Low
- Use cases: Smart metering, connected health, urban infrastructure
- Licensed spectrum (deployed by carriers), better building penetration than LTE
- Best when: Carrier coverage available, moderate data needs, reliable delivery required

**LTE-M (Cat-M1)**
- Range: Cellular coverage, Data rate: ~1 Mbps, Power: Moderate
- Use cases: Asset tracking with mobility, connected vehicles, wearables with voice
- Supports handover between cells (mobility), VoLTE support
- Best when: Mobile devices needing cellular handover, higher bandwidth than NB-IoT, voice capability needed

## Protocol Bridging and Gateway Patterns

### Bridge Architecture
```
[BLE Sensors] --> [Gateway: BLE-to-MQTT] --> [MQTT Broker] --> [Cloud]
[Modbus RTU]  --> [Gateway: Modbus-to-MQTT] --> [MQTT Broker] --> [Cloud]
[Zigbee Mesh] --> [Gateway: Zigbee-to-HTTP] --> [REST API] --> [Cloud]
```

### Gateway Design Considerations
- Translate device-side protocols to a single cloud-side protocol (usually MQTT or HTTPS)
- Map device-specific data formats to a canonical data model at the gateway
- Handle device authentication locally; use a single cloud identity for the gateway
- Buffer messages during cloud outages and replay on reconnection
- Support bidirectional translation for cloud-to-device commands

### Multi-Protocol Edge Platforms
- **Eclipse Kura**: Java-based IoT gateway framework with protocol bundles (Modbus, BLE, OPC-UA)
- **EdgeX Foundry**: Microservice-based edge platform with device service adapters
- **Node-RED**: Visual flow programming for protocol translation and data routing
- **AWS IoT Greengrass**: Edge runtime with Lambda functions and protocol adapters
