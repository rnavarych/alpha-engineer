# Device Identity and Secure Boot Chain

## When to load
Load when designing device identity infrastructure (X.509, secure elements, TPM), implementing secure boot chains, or managing the device identity lifecycle from manufacturing to decommission.

## X.509 Certificates
- Issue per-device certificates from a dedicated IoT CA (not your web PKI CA)
- Use short-lived certificates (1-2 years) with automated renewal before expiry
- Include the device ID in the certificate Common Name or Subject Alternative Name
- Validate the full certificate chain on both device and server sides
- Maintain a Certificate Revocation List (CRL) or use OCSP for compromised devices

## Hardware Security Components

| Component | Capability | Examples |
|-----------|-----------|----------|
| **Secure Element** | Key storage, crypto operations, tamper resistance | Microchip ATECC608, NXP SE050 |
| **TPM 2.0** | Platform integrity, measured boot, key sealing | Infineon OPTIGA TPM, STMicro STSAFE |
| **ARM TrustZone** | Hardware-isolated secure world for key operations | Available on Cortex-A and Cortex-M33+ |

- Store private keys exclusively in hardware secure elements; never in firmware flash
- Use the secure element for TLS handshake operations so the private key never leaves hardware
- If no secure element is available, use flash encryption and secure boot to protect key material

## Device Identity Lifecycle
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
