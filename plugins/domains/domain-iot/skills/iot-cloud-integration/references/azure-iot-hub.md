# Azure IoT Hub

## When to load
Load when integrating devices with Azure IoT Hub, configuring Device Provisioning Service (DPS), setting up IoT Edge modules, or routing messages to downstream services.

## Core Components
- **Device-to-Cloud (D2C)**: Telemetry messages, file upload notifications
- **Cloud-to-Device (C2D)**: Messages, direct methods (synchronous RPC), device twin desired properties
- **Device Twins**: JSON documents with desired/reported properties and tags for fleet queries
- **IoT Hub Routing**: Route messages to built-in endpoint (Event Hub) or custom endpoints based on message properties

## Device Provisioning Service (DPS)
- Zero-touch provisioning at scale with enrollment groups
- Allocation policies: hashed (load balance), geo-latency (closest hub), static, custom (Azure Function)
- Supports X.509, TPM, and symmetric key attestation
- Automatic re-provisioning on policy change or device reset

## Azure IoT Edge
- Container-based modules running on edge devices
- Built-in modules: Edge Hub (local MQTT/AMQP broker), Edge Agent (module lifecycle manager)
- Route messages between modules locally before forwarding to the cloud
- Supports nested edge topologies for network-isolated environments
- Deploy and manage modules from IoT Hub with automatic rollout

## Message Routing
```json
{
  "routes": {
    "telemetryToHotPath": {
      "source": "DeviceMessages",
      "condition": "IS_DEFINED($body.temperature)",
      "endpointNames": ["eventhub-hot"],
      "isEnabled": true
    },
    "alertsToColdStorage": {
      "source": "DeviceMessages",
      "condition": "$body.severity = 'critical'",
      "endpointNames": ["blob-storage"],
      "isEnabled": true
    }
  }
}
```

## Data Pipeline Pattern
```
Devices --> IoT Hub --> Event Hub --> Stream Analytics (or Azure Functions)
                                        |
                    +------ Azure Data Explorer ------+
                    |          (hot queries)           |
                    |                                  |
              Power BI (dashboards)         Blob Storage (archive)
```
