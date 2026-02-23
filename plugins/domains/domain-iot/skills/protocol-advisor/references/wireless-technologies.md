# Wireless Technology Selection

## When to load
Load when selecting a wireless communication technology for IoT devices, comparing BLE, Zigbee, Z-Wave, Wi-Fi, LoRaWAN, NB-IoT, and LTE-M based on range, power, and data rate requirements.

## Short Range (< 100m)

### Bluetooth Low Energy (BLE)
- Range: 10-100m, Data rate: 1-2 Mbps (BLE 5.0), Power: Very low
- Use cases: Wearables, proximity beacons, medical devices, asset tracking
- Mesh support via Bluetooth Mesh for building automation
- Best when: Devices pair with smartphones or local gateways, low data volume

### Zigbee (IEEE 802.15.4)
- Range: 10-100m, Data rate: 250 kbps, Power: Low
- Use cases: Home automation (lights, switches, sensors), industrial sensor networks
- Self-forming and self-healing mesh network with up to 65,000 nodes
- Best when: Dense mesh networks, home/building automation, Matter-compatible ecosystem

### Z-Wave
- Range: 30-100m, Data rate: 100 kbps, Power: Low
- Use cases: Home automation (locks, thermostats, security)
- Sub-GHz frequency (less interference than 2.4GHz), mesh with up to 232 nodes
- Best when: Home automation requiring reliable sub-GHz mesh, interoperability matters (Z-Wave Alliance certification)

## Medium Range (100m - 10km)

### Wi-Fi (802.11 b/g/n/ac/ax)
- Range: 50-100m indoor, Data rate: Up to 9.6 Gbps (Wi-Fi 6), Power: High
- Use cases: Cameras, smart speakers, appliances, any device near mains power
- Wi-Fi HaLow (802.11ah): Sub-GHz, lower power, longer range for IoT
- Best when: High bandwidth needed, mains-powered devices, existing Wi-Fi infrastructure

## Long Range (> 1km)

### LoRaWAN
- Range: 2-15km (urban/rural), Data rate: 0.3-50 kbps, Power: Very low
- Use cases: Smart agriculture, water metering, environmental monitoring, asset tracking
- Unlicensed spectrum (ISM bands), low infrastructure cost
- Best when: Long range, very low power, small data payloads (< 250 bytes), low cost per device

### NB-IoT (Narrowband IoT)
- Range: Cellular coverage, Data rate: ~250 kbps, Power: Low
- Use cases: Smart metering, connected health, urban infrastructure
- Licensed spectrum (deployed by carriers), better building penetration than LTE
- Best when: Carrier coverage available, moderate data needs, reliable delivery required

### LTE-M (Cat-M1)
- Range: Cellular coverage, Data rate: ~1 Mbps, Power: Moderate
- Use cases: Asset tracking with mobility, connected vehicles, wearables with voice
- Supports handover between cells (mobility), VoLTE support
- Best when: Mobile devices needing cellular handover, higher bandwidth than NB-IoT, voice capability needed
