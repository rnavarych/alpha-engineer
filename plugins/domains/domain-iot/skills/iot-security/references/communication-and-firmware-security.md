# Encrypted Communication and Firmware Signing

## When to load
Load when configuring TLS/DTLS for IoT device communication, signing firmware for secure OTA distribution, or selecting embedded TLS libraries for constrained devices.

## TLS 1.3 for TCP-Based Protocols (MQTT, HTTPS)
- Use TLS 1.3 for reduced handshake latency (1-RTT vs 2-RTT in TLS 1.2)
- Prefer ECDHE key exchange with X25519 or P-256 curves
- Use AES-128-GCM or ChaCha20-Poly1305 cipher suites (both supported in embedded TLS stacks)
- Mutual TLS (mTLS): Both device and server present certificates for bidirectional authentication
- Embedded TLS libraries: mbedTLS (ARM), wolfSSL, BearSSL (minimal footprint)

## DTLS for UDP-Based Protocols (CoAP, LwM2M)
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
