---
name: domain-iot:device-management
description: IoT device lifecycle management including zero-touch provisioning, firmware OTA updates with rollback, device registry, device twin/shadow state patterns, command-and-control mechanisms, and fleet-wide operations.
allowed-tools: Read, Grep, Glob, Bash
---

# IoT Device Management

## When to use
- Designing zero-touch provisioning flows for manufacturing at scale
- Implementing OTA firmware updates with A/B partitions and rollback
- Building device twin / shadow state synchronization between device and backend
- Setting up command-and-control (request-response, fire-and-forget, direct methods)
- Managing fleet operations: group updates, health dashboards, decommissioning

## Core principles
1. **Provision from hardware roots** — private keys belong in secure elements or TPMs; never in firmware flash or environment variables
2. **A/B partitions over in-place updates** — the inactive slot absorbs the risk; rollback is a reboot, not a crisis
3. **Twin delta is the source of truth** — desired vs reported gap tells you exactly what the fleet hasn't converged on yet
4. **Commands must be idempotent and TTL-bound** — offline devices wake up; stale reboot commands should not execute
5. **Fleet operations are canary-first** — 1% → 10% → 50% → 100% with automated pause on error rate threshold

## Reference Files
- `references/provisioning.md` — zero-touch provisioning flow, certificate-based onboarding, DPS allocation policies, device registry structure
- `references/ota-updates.md` — A/B partition strategy, delta updates with bsdiff, rollback mechanisms, staged campaign management
- `references/device-twin-and-fleet.md` — twin/shadow state pattern, synchronization, conflict resolution, command patterns, fleet operations
