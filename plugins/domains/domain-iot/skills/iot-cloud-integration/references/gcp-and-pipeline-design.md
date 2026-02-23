# GCP IoT Stack and End-to-End Pipeline Design

## When to load
Load when building on Google Cloud after the IoT Core deprecation, designing a platform-agnostic data pipeline, or evaluating multi-cloud and vendor lock-in considerations.

## Google Cloud IoT (Post-Deprecation)
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

## Generic End-to-End Pipeline Pattern (Platform-Agnostic)
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
