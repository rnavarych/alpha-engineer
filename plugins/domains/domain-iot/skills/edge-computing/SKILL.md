---
name: edge-computing
description: Edge computing patterns for IoT including gateway architecture, local vs cloud processing decisions, edge ML inference, containerized edge workloads with K3s and Azure IoT Edge, edge-cloud data synchronization, and offline-resilient operation.
allowed-tools: Read, Grep, Glob, Bash
---

# Edge Computing for IoT

## When to use
- Designing edge gateway architecture and selecting hardware (Raspberry Pi to industrial)
- Deciding what to process at the edge vs offload to the cloud
- Deploying ML inference models on constrained edge hardware
- Containerizing edge workloads with K3s or Azure IoT Edge modules
- Implementing edge-cloud data sync and conflict resolution strategies
- Building systems that must function during internet outages

## Core principles
1. **Intermittent connectivity is the default** — design store-and-forward from day one; connectivity is the exception, not the guarantee
2. **Edge runs inference, cloud runs training** — push optimized models down, pull raw data and drift metrics up
3. **Protocol translation lives at the gateway boundary** — one cloud-side identity, many device-side protocols; canonical data model applied at the seam
4. **Pin container versions on edge devices** — `latest` in a factory is a production incident waiting to happen
5. **100ms is the latency ceiling for control loops** — anything safety-critical or real-time stays local regardless of network quality

## Reference Files
- `references/gateway-and-processing.md` — gateway responsibilities, hardware selection guide, edge vs cloud processing decision criteria, hybrid pattern
- `references/edge-ml-and-containers.md` — TensorFlow Lite / ONNX / TensorRT frameworks, ML deployment pipeline, K3s, Azure IoT Edge, container best practices
- `references/sync-and-offline.md` — data synchronization strategies, conflict resolution, offline operation with local storage and RTC drift handling
