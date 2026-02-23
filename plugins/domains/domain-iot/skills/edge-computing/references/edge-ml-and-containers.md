# Edge ML Inference and Containerized Workloads

## When to load
Load when deploying ML inference at the edge, containerizing edge workloads with K3s or Azure IoT Edge, or optimizing models for resource-constrained hardware.

## Edge ML Frameworks
- **TensorFlow Lite**: Quantized models for ARM Cortex-M and Cortex-A, GPU delegate for mobile GPUs
- **ONNX Runtime**: Cross-framework model deployment, supports models from PyTorch, TF, scikit-learn
- **NVIDIA TensorRT**: Optimized inference on Jetson devices (Nano, Xavier, Orin)
- **OpenVINO**: Intel hardware optimization for NUC and x86 edge devices

## ML Deployment Pipeline
1. Train the model in the cloud with full datasets
2. Optimize: quantize (INT8/FP16), prune, distill to reduce size and latency
3. Validate the optimized model against accuracy thresholds
4. Package the model as part of an edge module or firmware update
5. Deploy via OTA to edge devices with staged rollout
6. Monitor inference accuracy and drift; retrain when performance degrades

## Edge ML Use Cases
- Predictive maintenance: vibration and temperature anomaly detection on industrial equipment
- Visual inspection: defect detection on manufacturing lines using camera feeds
- Occupancy detection: people counting for HVAC optimization in smart buildings
- Voice/keyword detection: wake-word recognition on smart devices

## K3s (Lightweight Kubernetes)
- Single binary, runs on ARM and x86 with 512MB RAM minimum
- Supports standard Kubernetes APIs: Deployments, Services, ConfigMaps
- Use for multi-container edge workloads that need orchestration
- Integrate with Rancher for centralized multi-edge cluster management

## Azure IoT Edge
- Docker-based module system managed from Azure IoT Hub
- Built-in modules: Edge Hub (local MQTT broker), Edge Agent (module lifecycle)
- Custom modules as Docker containers with automatic deployment from cloud
- Supports offline operation with local message routing

## Container Best Practices
- Pin container image versions; do not use `latest` on edge devices
- Limit container resource usage (CPU, memory) to prevent one module from starving others
- Use read-only root filesystems where possible for security
- Pre-pull images during maintenance windows to avoid download delays
