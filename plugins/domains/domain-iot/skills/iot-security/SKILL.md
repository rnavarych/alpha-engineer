---
name: iot-security
description: IoT security practices covering device identity with X.509 and secure elements, secure boot chains, encrypted communication (TLS/DTLS), firmware signing, network segmentation, device attestation, and vulnerability management for resource-constrained devices.
allowed-tools: Read, Grep, Glob, Bash
---

# IoT Security

## When to use
- Designing device identity infrastructure using X.509 certificates, secure elements, or TPMs
- Implementing a secure boot chain from hardware root of trust to application firmware
- Configuring TLS 1.3 or DTLS for MQTT, HTTPS, CoAP, or LwM2M device communication
- Signing firmware images for OTA distribution and verifying them on-device
- Segmenting IoT devices on dedicated VLANs and configuring egress firewall rules
- Building device attestation workflows to detect tampering at scale
- Managing CVEs and SBOM tracking across a constrained device fleet

## Core principles
1. **Private keys never leave hardware** — secure element or TPM for key operations; flash-stored keys are not keys, they are secrets waiting to be extracted
2. **Chain of trust starts in ROM** — every link in the boot chain verifies the next; one unsigned hop breaks the whole model
3. **mTLS everywhere on the wire** — device authenticates server, server authenticates device; one-way TLS is half a handshake
4. **Sign firmware with an offline HSM key** — the signing key never touches a networked machine; downgrade attacks need anti-rollback counters in OTP fuses
5. **Segment and minimize blast radius** — IoT VLAN, gateway as single egress, no device-to-device unless explicitly required

## Reference Files
- `references/device-identity-and-secure-boot.md` — X.509 per-device certs, hardware security components (SE, TPM, TrustZone), identity lifecycle, secure boot chain from ROM to application
- `references/communication-and-firmware-security.md` — TLS 1.3 config, embedded TLS libraries (mbedTLS, wolfSSL), DTLS for UDP, firmware signing with HSM, anti-rollback counters
- `references/network-and-vulnerability-management.md` — VLAN segmentation, device attestation workflow, SBOM tracking, CVE prioritization, compensating controls for unpatched devices
