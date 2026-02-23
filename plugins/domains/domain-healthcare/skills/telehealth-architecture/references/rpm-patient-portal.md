# Remote Patient Monitoring and Patient Portal Design

## When to load
Integrating RPM devices into a care platform, designing a clinical alerting pipeline for monitored patients, building a patient portal, or implementing accessible UX for diverse patient populations.

## Remote Patient Monitoring (RPM) — Device Integration

- **Blood pressure monitors**: Withings, Omron (Bluetooth/WiFi connected)
- **Glucose monitors**: Dexcom CGM, Abbott FreeStyle Libre (continuous and spot-check)
- **Pulse oximeters**: Masimo, Nonin (Bluetooth connectivity)
- **Weight scales**: Withings Body+, BodyTrace (cellular-connected for elderly patients)
- **Activity trackers**: Fitbit, Apple Watch (HealthKit/Google Fit integration)

## Data Collection Pipeline

1. Device captures measurement and transmits via Bluetooth/WiFi/Cellular
2. Gateway app (mobile or hub device) receives and validates the reading
3. Data transmitted to cloud platform over TLS with patient identifier
4. Platform normalizes data (units, timestamps, device metadata)
5. Clinical rules engine evaluates readings against thresholds
6. Alerts generated for out-of-range values and routed to care team

## Clinical Alerting

- Define patient-specific thresholds (e.g., systolic BP > 160 mmHg)
- Escalation tiers: notification to care coordinator, then nurse, then physician
- Track alert acknowledgment and response time
- Reduce alert fatigue: suppress duplicate alerts within configurable windows
- Dashboard for care team showing all monitored patients with status indicators

## Patient Portal — Core Features

- **Appointment scheduling**: Online booking with provider availability, appointment type selection, and visit preparation instructions
- **Secure messaging**: HIPAA-compliant provider-patient messaging with read receipts and response time expectations
- **Lab results**: Display results with reference ranges, trending over time, and plain-language explanations
- **Medication management**: Active medication list, refill requests, pharmacy selection
- **Visit summaries**: After-visit summaries with care instructions and follow-up actions
- **Document upload**: Patient-submitted forms, insurance cards, ID verification photos

## UX Considerations

- Accessible design (WCAG 2.1 AA minimum) for patients with disabilities
- Multi-language support for diverse patient populations
- Mobile-first responsive design (majority of patients access via smartphone)
- Clear health literacy: present clinical information at a 6th-grade reading level
- Proxy access for caregivers managing family members' health
