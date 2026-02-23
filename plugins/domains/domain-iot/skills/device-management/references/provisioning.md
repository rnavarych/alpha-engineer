# Device Provisioning

## When to load
Load when implementing zero-touch provisioning, certificate-based device onboarding, or designing the first-boot registration flow for IoT devices.

## Zero-Touch Provisioning
- Device ships with a factory-installed bootstrap credential (X.509 certificate or symmetric key)
- On first boot the device contacts the provisioning service, authenticates, and receives its operational configuration
- Provisioning service assigns the device to the correct IoT hub, tenant, and policy group
- No manual per-device setup required; scales to millions of devices

## Certificate-Based Provisioning
- Generate per-device certificates from a trusted CA during manufacturing
- Store private keys in a secure element (ATECC608, SE050) or TPM when available
- Use certificate CN or SAN as the device identity
- Support certificate rotation before expiry without device recall

## Provisioning Flow
1. Device boots and loads bootstrap credentials from secure storage
2. Device connects to Device Provisioning Service (DPS) endpoint via mutual TLS
3. DPS validates certificate chain against registered CA
4. DPS assigns device to target IoT Hub based on allocation policy (hashed, geo, custom)
5. Device receives connection string and operational configuration
6. Device connects to assigned IoT Hub and begins normal operation

## Device Registry and Inventory
Maintain a server-side registry containing:
- **Identity**: Device ID, certificates, authentication credentials
- **Metadata**: Hardware revision, firmware version, manufacturing date, location
- **Tags**: Logical groupings (site, customer, product line, firmware channel)
- **Connection state**: Last connected timestamp, IP address, protocol version
- **Desired and reported configuration**: Effectively the device twin/shadow
