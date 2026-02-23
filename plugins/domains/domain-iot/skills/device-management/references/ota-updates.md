# Firmware OTA Updates

## When to load
Load when designing or implementing over-the-air firmware update pipelines, rollback mechanisms, or staged campaign rollout strategies.

## A/B Partition Strategy
- Maintain two firmware slots (A and B) in flash memory
- Download new firmware to the inactive slot while the active slot keeps running
- Validate the downloaded image (checksum, signature) before marking it bootable
- Bootloader switches to the new slot on next reboot
- If the new firmware fails health checks, bootloader reverts to the previous slot

## Delta Updates
- Compute binary diffs between firmware versions using bsdiff or detools
- Delta patches are 5-20x smaller than full images, saving bandwidth and data costs
- Device applies the patch to reconstruct the full image, then validates its integrity
- Maintain a few recent full images server-side for devices that skip versions

## Rollback Mechanisms
- **Watchdog rollback**: If firmware does not confirm health within a timeout, the watchdog resets and bootloader loads the previous version
- **Application-level rollback**: Firmware runs self-tests on boot (connectivity, sensor reads, crypto); on failure, it flags itself as bad
- **Server-initiated rollback**: Fleet manager can push the previous version to specific devices

## Update Campaign Management
- Stage rollouts: canary (1%) then gradual expansion (10%, 50%, 100%)
- Define success criteria: device reports healthy after N minutes, error rate stays below threshold
- Automatic pause on failure rate exceeding the threshold
- Support scheduling update windows (maintenance hours, off-peak network times)
