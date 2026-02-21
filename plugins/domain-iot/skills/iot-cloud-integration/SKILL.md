---
name: iot-cloud-integration
description: |
  Cloud IoT platform integration covering AWS IoT Core, Azure IoT Hub, and
  Google Cloud IoT. Includes device shadow/twin patterns, rules engines,
  edge runtimes, data pipelines from ingestion to analytics, and multi-cloud
  considerations.
allowed-tools: Read, Grep, Glob, Bash
---

# IoT Cloud Integration

## AWS IoT Core

### Core Components
- **Device Gateway**: Supports MQTT, MQTT over WebSocket, and HTTPS protocols
- **Message Broker**: Manages pub/sub message routing with per-device topic policies
- **Device Shadow**: JSON document representing desired and reported device state, persisted in the cloud
- **Registry**: Device identity store with metadata and group organization (thing types, thing groups)
- **Device Defender**: Audits device configurations and monitors device behavior for anomalies

### Rules Engine
Route, transform, and act on device messages without writing server code:

```sql
-- Rule SQL: Route high-temperature alerts to SNS and DynamoDB
SELECT device_id, temperature, timestamp()
FROM 'devices/+/telemetry'
WHERE temperature > 80
```

**Rule Actions**: Forward to Lambda, Kinesis, S3, DynamoDB, SNS, SQS, IoT Analytics, Timestream, Step Functions, Elasticsearch, CloudWatch

### AWS IoT Greengrass (Edge)
- Run Lambda functions, Docker containers, and ML models at the edge
- Local MQTT broker for device-to-device communication without cloud connectivity
- Stream manager for reliable data export to S3, Kinesis, IoT Analytics
- Secrets manager integration for local credential access
- Component-based deployment model with OTA updates from the cloud

### Data Pipeline Pattern
```
Devices --> IoT Core --> Rules Engine --> Kinesis Data Streams
                                            |
                    +------- Lambda (transform) -------+
                    |                                   |
              Timestream (hot)                    S3 (cold)
                    |                                   |
              Grafana (dashboards)              Athena (ad-hoc queries)
```

## Azure IoT Hub

### Core Components
- **Device-to-Cloud (D2C)**: Telemetry messages, file upload notifications
- **Cloud-to-Device (C2D)**: Messages, direct methods (synchronous RPC), device twin desired properties
- **Device Twins**: JSON documents with desired/reported properties and tags for fleet queries
- **IoT Hub Routing**: Route messages to built-in endpoint (Event Hub) or custom endpoints based on message properties

### Device Provisioning Service (DPS)
- Zero-touch provisioning at scale with enrollment groups
- Allocation policies: hashed (load balance), geo-latency (closest hub), static, custom (Azure Function)
- Supports X.509, TPM, and symmetric key attestation
- Automatic re-provisioning on policy change or device reset

### Azure IoT Edge
- Container-based modules running on edge devices
- Built-in modules: Edge Hub (local MQTT/AMQP broker), Edge Agent (module lifecycle manager)
- Route messages between modules locally before forwarding to the cloud
- Supports nested edge topologies for network-isolated environments
- Deploy and manage modules from IoT Hub with automatic rollout

### Message Routing
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

### Data Pipeline Pattern
```
Devices --> IoT Hub --> Event Hub --> Stream Analytics (or Azure Functions)
                                        |
                    +------ Azure Data Explorer ------+
                    |          (hot queries)           |
                    |                                  |
              Power BI (dashboards)         Blob Storage (archive)
```

## Google Cloud IoT

### Core Components (Post-Deprecation Alternatives)
- Google deprecated Cloud IoT Core in August 2023
- **Recommended migration**: Use MQTT broker (EMQX, HiveMQ) with Pub/Sub integration
- **Alternative path**: ClearBlade IoT Core (Google-endorsed replacement)
- **Data pipeline**: Pub/Sub --> Dataflow --> BigQuery / Bigtable

### GCP IoT Data Stack
- **Pub/Sub**: Message ingestion (replaces IoT Core message broker)
- **Dataflow**: Apache Beam-based stream and batch processing
- **BigQuery**: Serverless analytics warehouse for historical IoT data
- **Bigtable**: Low-latency, high-throughput NoSQL for time-series at scale
- **Looker**: Dashboards and embedded analytics

## End-to-End Data Pipeline Architecture

### Generic Pattern (Platform-Agnostic)
```
[Devices] --> [MQTT Broker / IoT Hub]
                    |
              [Message Router / Rules Engine]
                    |
         +----+----+----+
         |         |         |
   [Stream        [Alert     [Raw Archive]
    Processor]    Service]        |
         |              |     [Object Storage]
   [Time-Series DB]   [Notification]
         |
   [Dashboard / BI]
```

### Pipeline Design Principles
1. **Decouple ingestion from processing**: Use a message broker or queue between device gateway and processors
2. **Schema validation early**: Validate and normalize message format at the ingestion layer
3. **Enrich in-flight**: Add device metadata (location, type, owner) during stream processing
4. **Branch for latency tiers**: Hot path (real-time alerts), warm path (minute-level dashboards), cold path (historical archive)
5. **Idempotent processing**: Design consumers to handle duplicate messages safely

## Multi-Cloud and Vendor Lock-In Considerations

- Abstract the IoT platform behind an internal API layer to enable future migration
- Use standard protocols (MQTT, HTTP) rather than proprietary device SDKs where feasible
- Store data in open formats (Parquet, Avro) in platform-neutral storage
- Evaluate total cost per device per month: ingestion, storage, compute, egress
- Consider hybrid architectures: one cloud for IoT ingestion, another for analytics or ML
