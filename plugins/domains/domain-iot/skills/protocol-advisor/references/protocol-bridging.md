# Protocol Bridging and Gateway Patterns

## When to load
Load when designing a multi-protocol IoT gateway, implementing protocol translation between device-side and cloud-side communication layers, or selecting an edge platform for heterogeneous device environments.

## Bridge Architecture
```
[BLE Sensors] --> [Gateway: BLE-to-MQTT] --> [MQTT Broker] --> [Cloud]
[Modbus RTU]  --> [Gateway: Modbus-to-MQTT] --> [MQTT Broker] --> [Cloud]
[Zigbee Mesh] --> [Gateway: Zigbee-to-HTTP] --> [REST API] --> [Cloud]
```

## Gateway Design Considerations
- Translate device-side protocols to a single cloud-side protocol (usually MQTT or HTTPS)
- Map device-specific data formats to a canonical data model at the gateway
- Handle device authentication locally; use a single cloud identity for the gateway
- Buffer messages during cloud outages and replay on reconnection
- Support bidirectional translation for cloud-to-device commands

## Multi-Protocol Edge Platforms
- **Eclipse Kura**: Java-based IoT gateway framework with protocol bundles (Modbus, BLE, OPC-UA)
- **EdgeX Foundry**: Microservice-based edge platform with device service adapters
- **Node-RED**: Visual flow programming for protocol translation and data routing
- **AWS IoT Greengrass**: Edge runtime with Lambda functions and protocol adapters
