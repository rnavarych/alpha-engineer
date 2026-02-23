---
name: protocol-advisor
description: IoT communication protocol selection and advisory covering MQTT, CoAP, AMQP, HTTP comparison, wireless technologies (Zigbee, Z-Wave, BLE, LoRaWAN, NB-IoT, LTE-M), and protocol bridging patterns for heterogeneous IoT deployments.
allowed-tools: Read, Grep, Glob, Bash
---

# IoT Protocol Advisor

## When to use
- Choosing between MQTT, CoAP, AMQP, and HTTP for device communication
- Selecting a wireless technology based on range, power, and data rate requirements
- Designing a multi-protocol gateway that bridges device-side and cloud-side protocols
- Evaluating BLE, Zigbee, Z-Wave, Wi-Fi, LoRaWAN, NB-IoT, or LTE-M for a specific deployment
- Building a canonical data model at the gateway boundary for heterogeneous device types

## Core principles
1. **Match protocol to the constraint profile** — CoAP for 10KB RAM devices, MQTT for everything above that, HTTP only for infrequent config calls
2. **Wireless range and power are the first filter** — pick the frequency band before picking the stack; LoRaWAN for kilometers at microwatts, BLE for meters at microwatts
3. **Translate once at the gateway boundary** — device speaks Modbus or Zigbee, cloud speaks MQTT; the gateway is the only place that knows both
4. **One cloud identity per gateway, not per device** — device authentication stays local; a single gateway credential reduces cloud certificate management overhead dramatically
5. **Buffer at the gateway during outages** — the bridge must absorb disconnections; cloud-side consumers should never know the link went down

## Reference Files
- `references/application-layer-protocols.md` — MQTT, CoAP, AMQP, HTTP detailed comparison with selection decision matrix across RAM, power, delivery, throughput, and ecosystem maturity
- `references/wireless-technologies.md` — BLE, Zigbee, Z-Wave, Wi-Fi, LoRaWAN, NB-IoT, LTE-M with range/power/data-rate specs and best-fit scenarios
- `references/protocol-bridging.md` — bridge architecture diagrams, gateway design considerations, multi-protocol edge platforms (Eclipse Kura, EdgeX Foundry, Node-RED, Greengrass)
