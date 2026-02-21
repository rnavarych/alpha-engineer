---
name: iot-security
description: |
  IoT security practices covering device identity with X.509 and secure elements,
  secure boot chains, encrypted communication (TLS/DTLS), firmware signing,
  network segmentation, device attestation, and vulnerability management
  for resource-constrained devices.
allowed-tools: Read, Grep, Glob, Bash
---

# IoT Security

## Device Identity

### X.509 Certificates
- Issue per-device certificates from a dedicated IoT CA (not your web PKI CA)
- Use short-lived certificates (1-2 years) with automated renewal before expiry
- Include the device ID in the certificate Common Name or Subject Alternative Name
- Validate the full certificate chain on both device and server sides
- Maintain a Certificate Revocation List (CRL) or use OCSP for compromised devices

### Hardware Security

| Component | Capability | Examples |
|-----------|-----------|----------|
| **Secure Element** | Key storage, crypto operations, tamper resistance | Microchip ATECC608, NXP SE050 |
| **TPM 2.0** | Platform integrity, measured boot, key sealing | Infineon OPTIGA TPM, STMicro STSAFE |
| **ARM TrustZone** | Hardware-isolated secure world for key operations | Available on Cortex-A and Cortex-M33+ |

- Store private keys exclusively in hardware secure elements; never in firmware flash
- Use the secure element for TLS handshake operations so the private key never leaves hardware
- If no secure element is available, use flash encryption and secure boot to protect key material

### Device Identity Lifecycle
1. **Manufacturing**: Inject unique identity and credentials during factory provisioning
2. **Provisioning**: Device registers with cloud platform using bootstrap credentials
3. **Operation**: Device authenticates with operational credentials on every connection
4. **Rotation**: Rotate credentials periodically or on suspected compromise
5. **Decommission**: Revoke credentials, wipe keys, remove from device registry

## Secure Boot Chain

Establish a chain of trust from hardware root to application code:

1. **Hardware root of trust**: Immutable bootloader in ROM verifies first-stage bootloader
2. **First-stage bootloader**: Verifies the second-stage bootloader or RTOS image signature
3. **Second-stage bootloader**: Verifies the application firmware signature
4. **Application**: Verifies integrity of configuration and data partitions

- Sign firmware images with Ed25519 or ECDSA-P256 (faster verification than RSA on MCUs)
- Store the public verification key in OTP (one-time programmable) fuses or secure element
- Lock debug interfaces (JTAG/SWD) in production to prevent firmware extraction
- Enable flash encryption to protect firmware intellectual property and secrets at rest

## Encrypted Communication

### TLS 1.3 for TCP-Based Protocols (MQTT, HTTPS)
- Use TLS 1.3 for reduced handshake latency (1-RTT vs 2-RTT in TLS 1.2)
- Prefer ECDHE key exchange with X25519 or P-256 curves
- Use AES-128-GCM or ChaCha20-Poly1305 cipher suites (both supported in embedded TLS stacks)
- Mutual TLS (mTLS): Both device and server present certificates for bidirectional authentication
- Embedded TLS libraries: mbedTLS (ARM), wolfSSL, BearSSL (minimal footprint)

### DTLS for UDP-Based Protocols (CoAP, LwM2M)
- DTLS adds TLS-equivalent security to unreliable UDP transport
- Handle packet reordering and loss with DTLS record sequence numbers
- Use connection ID extension to survive NAT rebinding without full re-handshake
- Session resumption with PSK or session tickets to reduce reconnection overhead

## Firmware Signing and Verification

- Sign every firmware image before distribution using an offline signing key
- Store the signing private key in an HSM (AWS CloudHSM, Azure Dedicated HSM, YubiHSM)
- Verify the signature on the device before writing the image to the update partition
- Include firmware version and hardware compatibility in the signed metadata to prevent downgrade attacks
- Implement anti-rollback counters in OTP fuses to block installation of older vulnerable firmware

## Network Segmentation

- Place IoT devices on a dedicated VLAN, isolated from corporate and guest networks
- Use a firewall or security group to allow only the required outbound connections (IoT Hub endpoints)
- Block device-to-device communication unless explicitly required (prevent lateral movement)
- Deploy an IoT gateway as the single egress point; devices communicate only with the gateway
- Monitor IoT network traffic for anomalous patterns (unexpected destinations, unusual data volumes)

## Device Attestation

- On boot, the device measures its firmware and configuration integrity
- The device sends a signed attestation report (PCR values or firmware hash) to the backend
- The backend verifies the report against known-good measurements
- Devices failing attestation are quarantined: limited access, flagged for remediation
- Use remote attestation to detect firmware tampering or unauthorized modifications

## Vulnerability Management for Constrained Devices

- Maintain a Software Bill of Materials (SBOM) for each firmware version
- Track CVEs against SBOM components using automated scanning (Dependabot, Snyk, OWASP Dependency-Check)
- Prioritize patches based on exploitability and device exposure (internet-facing vs isolated)
- Test patches on representative hardware before fleet-wide deployment
- For devices that cannot be patched (legacy, end-of-life): implement compensating controls at the network layer
- Define a responsible disclosure process for vulnerabilities found by researchers
