# Edge Gateway Design and Processing Decisions

## When to load
Load when designing edge gateway architecture, selecting edge hardware, or deciding what to process locally versus offloading to the cloud.

## Gateway Responsibilities
- **Protocol translation**: Convert device-side protocols (BLE, Zigbee, Modbus, CAN bus) to cloud-side protocols (MQTT, HTTPS, AMQP)
- **Data aggregation**: Collect telemetry from many local devices and batch-publish to reduce cloud ingestion costs
- **Local processing**: Run filtering, anomaly detection, and alerting without round-tripping to the cloud
- **Store-and-forward**: Buffer messages during network outages and flush when connectivity returns
- **Security boundary**: Terminate TLS from the cloud side, manage device credentials locally

## Hardware Selection
- **Low-end**: Raspberry Pi, BeagleBone for prototyping and small deployments (10-50 devices)
- **Mid-range**: Intel NUC, NVIDIA Jetson Nano for ML inference at the edge
- **Industrial**: Advantech, Moxa, Dell Edge Gateway for ruggedized deployments (temperature, vibration, DIN rail)
- **Considerations**: CPU/GPU for ML workloads, storage for buffering, connectivity ports, power supply options

## Local Processing vs Cloud Offload

### Process at the Edge When:
- Latency requirements are below 100ms (real-time control loops, safety systems)
- Bandwidth is constrained or expensive (cellular, satellite links)
- Data volume is high but only summaries or exceptions need to reach the cloud
- Privacy or regulatory requirements prohibit sending raw data off-premises
- The system must operate during internet outages

### Offload to the Cloud When:
- Complex model training or retraining is required (edge runs inference only)
- Cross-device or cross-site correlation is needed
- Long-term storage and historical analysis are required
- Compute requirements exceed edge hardware capabilities
- Centralized dashboards and reporting aggregate data from many edges

### Hybrid Pattern
Run a lightweight model or rule engine at the edge for immediate decisions. Stream raw or enriched data to the cloud for deeper analytics, model retraining, and fleet-wide insights. Push updated models back to the edge periodically.
