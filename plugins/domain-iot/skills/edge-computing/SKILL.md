---
name: edge-computing
description: |
  Edge computing patterns for IoT including gateway architecture, local vs cloud
  processing decisions, edge ML inference, containerized edge workloads,
  edge-cloud data synchronization, and offline-resilient operation.
allowed-tools: Read, Grep, Glob, Bash
---

# Edge Computing for IoT

## Edge Gateway Design

### Gateway Responsibilities
- **Protocol translation**: Convert device-side protocols (BLE, Zigbee, Modbus, CAN bus) to cloud-side protocols (MQTT, HTTPS, AMQP)
- **Data aggregation**: Collect telemetry from many local devices and batch-publish to reduce cloud ingestion costs
- **Local processing**: Run filtering, anomaly detection, and alerting without round-tripping to the cloud
- **Store-and-forward**: Buffer messages during network outages and flush when connectivity returns
- **Security boundary**: Terminate TLS from the cloud side, manage device credentials locally

### Hardware Selection
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

## Edge ML Inference

### Frameworks
- **TensorFlow Lite**: Quantized models for ARM Cortex-M and Cortex-A, GPU delegate for mobile GPUs
- **ONNX Runtime**: Cross-framework model deployment, supports models from PyTorch, TF, scikit-learn
- **NVIDIA TensorRT**: Optimized inference on Jetson devices (Nano, Xavier, Orin)
- **OpenVINO**: Intel hardware optimization for NUC and x86 edge devices

### Deployment Pipeline
1. Train the model in the cloud with full datasets
2. Optimize: quantize (INT8/FP16), prune, distill to reduce size and latency
3. Validate the optimized model against accuracy thresholds
4. Package the model as part of an edge module or firmware update
5. Deploy via OTA to edge devices with staged rollout
6. Monitor inference accuracy and drift; retrain when performance degrades

### Use Cases at the Edge
- Predictive maintenance: vibration and temperature anomaly detection on industrial equipment
- Visual inspection: defect detection on manufacturing lines using camera feeds
- Occupancy detection: people counting for HVAC optimization in smart buildings
- Voice/keyword detection: wake-word recognition on smart devices

## Containers on the Edge

### K3s (Lightweight Kubernetes)
- Single binary, runs on ARM and x86 with 512MB RAM minimum
- Supports standard Kubernetes APIs: Deployments, Services, ConfigMaps
- Use for multi-container edge workloads that need orchestration
- Integrate with Rancher for centralized multi-edge cluster management

### Azure IoT Edge
- Docker-based module system managed from Azure IoT Hub
- Built-in modules: Edge Hub (local MQTT broker), Edge Agent (module lifecycle)
- Custom modules as Docker containers with automatic deployment from cloud
- Supports offline operation with local message routing

### Best Practices
- Pin container image versions; do not use `latest` on edge devices
- Limit container resource usage (CPU, memory) to prevent one module from starving others
- Use read-only root filesystems where possible for security
- Pre-pull images during maintenance windows to avoid download delays

## Edge-Cloud Synchronization

### Data Synchronization Strategies
- **Streaming**: Continuous telemetry forwarding via MQTT or Kafka for near-real-time cloud views
- **Batch upload**: Periodic uploads (every 5-15 minutes) of aggregated data to reduce API calls
- **Event-driven**: Forward only when thresholds are crossed or significant events occur

### Conflict Resolution
- For configuration: cloud-desired state wins; edge reports actual state
- For data: append-only telemetry avoids conflicts; use timestamps for ordering
- For edge-generated alerts: deliver at-least-once and deduplicate in the cloud

## Offline Operation

Design for intermittent connectivity as the default, not the exception:
- **Local storage**: SQLite, LevelDB, or circular buffer in flash for telemetry queuing
- **Autonomous decisions**: Edge must operate with locally cached rules and models
- **Sync on reconnect**: Replay queued messages in order; use sequence numbers for gap detection
- **Graceful degradation**: Clearly define which features work offline vs require connectivity
- **Time handling**: Use NTP when online, RTC with drift compensation when offline; timestamp all data at the source
