---
name: iot-cloud-integration
description: Cloud IoT platform integration covering AWS IoT Core, Azure IoT Hub, and Google Cloud IoT. Includes device shadow/twin patterns, rules engines, edge runtimes, data pipelines from ingestion to analytics, and multi-cloud considerations.
allowed-tools: Read, Grep, Glob, Bash
---

# IoT Cloud Integration

## When to use
- Integrating devices with AWS IoT Core, Azure IoT Hub, or GCP after the Cloud IoT Core deprecation
- Configuring rules engines to route device messages to downstream services
- Designing hot/warm/cold data pipeline architectures for telemetry ingestion
- Setting up Device Provisioning Service (DPS) for zero-touch at scale
- Evaluating multi-cloud trade-offs or avoiding vendor lock-in
- Choosing between Timestream, Azure Data Explorer, BigQuery, and Bigtable for IoT storage

## Core principles
1. **Decouple ingestion from processing** — message broker or queue between device gateway and any processor; never direct device-to-database writes
2. **Schema validation at the ingestion boundary** — malformed payloads caught at the door, not discovered three hops later in a dashboard
3. **Branch early for latency tiers** — hot path (real-time alerts), warm path (dashboards), cold path (archive) forked at the rules engine, not bolted on later
4. **Idempotent consumers everywhere** — IoT protocols guarantee at-least-once; your processors must handle duplicates gracefully
5. **Open formats in storage** — Parquet/Avro in object storage makes the next cloud migration a query problem, not a rewrite

## Reference Files
- `references/aws-iot-core.md` — Device Gateway, Message Broker, Device Shadow, Rules Engine SQL, IoT Greengrass edge runtime, AWS data pipeline pattern
- `references/azure-iot-hub.md` — D2C/C2D messaging, Device Twins, DPS allocation policies, IoT Edge modules, message routing config, Azure data pipeline pattern
- `references/gcp-and-pipeline-design.md` — GCP post-deprecation stack (Pub/Sub, Dataflow, BigQuery, Bigtable), generic platform-agnostic pipeline pattern, multi-cloud considerations
