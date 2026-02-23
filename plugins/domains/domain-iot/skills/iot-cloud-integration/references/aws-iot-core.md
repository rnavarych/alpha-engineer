# AWS IoT Core

## When to load
Load when integrating devices with AWS IoT Core, configuring Rules Engine routing, or deploying AWS IoT Greengrass for edge processing.

## Core Components
- **Device Gateway**: Supports MQTT, MQTT over WebSocket, and HTTPS protocols
- **Message Broker**: Manages pub/sub message routing with per-device topic policies
- **Device Shadow**: JSON document representing desired and reported device state, persisted in the cloud
- **Registry**: Device identity store with metadata and group organization (thing types, thing groups)
- **Device Defender**: Audits device configurations and monitors device behavior for anomalies

## Rules Engine
Route, transform, and act on device messages without writing server code:

```sql
-- Rule SQL: Route high-temperature alerts to SNS and DynamoDB
SELECT device_id, temperature, timestamp()
FROM 'devices/+/telemetry'
WHERE temperature > 80
```

**Rule Actions**: Forward to Lambda, Kinesis, S3, DynamoDB, SNS, SQS, IoT Analytics, Timestream, Step Functions, Elasticsearch, CloudWatch

## AWS IoT Greengrass (Edge)
- Run Lambda functions, Docker containers, and ML models at the edge
- Local MQTT broker for device-to-device communication without cloud connectivity
- Stream manager for reliable data export to S3, Kinesis, IoT Analytics
- Secrets manager integration for local credential access
- Component-based deployment model with OTA updates from the cloud

## Data Pipeline Pattern
```
Devices --> IoT Core --> Rules Engine --> Kinesis Data Streams
                                            |
                    +------- Lambda (transform) -------+
                    |                                   |
              Timestream (hot)                    S3 (cold)
                    |                                   |
              Grafana (dashboards)              Athena (ad-hoc queries)
```
