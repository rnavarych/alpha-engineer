---
name: telehealth-architecture
description: |
  Telehealth system architecture covering HIPAA-compliant video consultation, remote patient
  monitoring, patient portal design, asynchronous telehealth, and billing integration
  with telehealth-specific CPT codes.
allowed-tools: Read, Grep, Glob, Bash
---

# Telehealth Architecture

## Video Consultation

### Technology Options
| Platform | Strengths | HIPAA BAA | Best For |
|----------|-----------|-----------|----------|
| **WebRTC** (self-hosted) | Full control, no per-minute costs, customizable UI | N/A (self-managed) | Organizations wanting full ownership |
| **Twilio Video** | Robust API, HIPAA-eligible, scalable, TURN/STUN included | Available | Custom-built telehealth platforms |
| **Vonage (TokBox)** | Mature WebRTC platform, session-based model, recording | Available | Multi-party consultations |
| **Zoom Video SDK** | Familiar UX, embedding SDK, reliable infrastructure | Available | Quick integration with existing workflows |
| **Doxy.me** | Purpose-built for telehealth, browser-based, simple | Available | Clinics needing turnkey solution |

### WebRTC Implementation
- Use SRTP (Secure Real-Time Transport Protocol) for media encryption
- Deploy TURN servers for NAT traversal (coturn is open-source and widely used)
- Implement signaling server (WebSocket-based) for session negotiation
- Handle network quality adaptation: bitrate adjustment, resolution scaling, audio-only fallback
- Support screen sharing for reviewing lab results or imaging with patients
- Record sessions (with consent) using server-side recording for documentation

### Video Quality Considerations
- Minimum bandwidth: 300 kbps for acceptable video, 1.5 Mbps for HD
- Implement network quality indicators for both provider and patient
- Graceful degradation: reduce video quality before dropping the call
- Test on real-world networks: cellular, rural broadband, institutional WiFi

## HIPAA-Compliant Video

### Requirements
- **BAA with provider**: Obtain a signed BAA from the video platform vendor
- **End-to-end encryption**: Media streams encrypted from sender to receiver
- **Access controls**: Authenticated access for both providers and patients
- **Waiting room**: Virtual waiting room to prevent unauthorized participants
- **Session logging**: Log session metadata (participants, duration, timestamps) without recording content unless consented
- **No recording by default**: Disable cloud recording unless explicitly required and consented

### Patient Identity Verification
- Verify patient identity before each video session (name, DOB, last 4 of SSN or MRN)
- Use unique session links with time-limited tokens (expire within 1 hour)
- Prevent link sharing by binding sessions to authenticated users

## Remote Patient Monitoring (RPM)

### Device Integration
- **Blood pressure monitors**: Withings, Omron (Bluetooth/WiFi connected)
- **Glucose monitors**: Dexcom CGM, Abbott FreeStyle Libre (continuous and spot-check)
- **Pulse oximeters**: Masimo, Nonin (Bluetooth connectivity)
- **Weight scales**: Withings Body+, BodyTrace (cellular-connected for elderly patients)
- **Activity trackers**: Fitbit, Apple Watch (HealthKit/Google Fit integration)

### Data Collection Pipeline
1. Device captures measurement and transmits via Bluetooth/WiFi/Cellular
2. Gateway app (mobile or hub device) receives and validates the reading
3. Data transmitted to cloud platform over TLS with patient identifier
4. Platform normalizes data (units, timestamps, device metadata)
5. Clinical rules engine evaluates readings against thresholds
6. Alerts generated for out-of-range values and routed to care team

### Clinical Alerting
- Define patient-specific thresholds (e.g., systolic BP > 160 mmHg)
- Escalation tiers: notification to care coordinator, then nurse, then physician
- Track alert acknowledgment and response time
- Reduce alert fatigue: suppress duplicate alerts within configurable windows
- Dashboard for care team showing all monitored patients with status indicators

## Patient Portal Design

### Core Features
- **Appointment scheduling**: Online booking with provider availability, appointment type selection, and visit preparation instructions
- **Secure messaging**: HIPAA-compliant provider-patient messaging with read receipts and response time expectations
- **Lab results**: Display results with reference ranges, trending over time, and plain-language explanations
- **Medication management**: Active medication list, refill requests, pharmacy selection
- **Visit summaries**: After-visit summaries with care instructions and follow-up actions
- **Document upload**: Patient-submitted forms, insurance cards, ID verification photos

### UX Considerations
- Accessible design (WCAG 2.1 AA minimum) for patients with disabilities
- Multi-language support for diverse patient populations
- Mobile-first responsive design (majority of patients access via smartphone)
- Clear health literacy: present clinical information at a 6th-grade reading level
- Proxy access for caregivers managing family members' health

## Asynchronous Telehealth (Store-and-Forward)

- **Dermatology**: Patient uploads photos of skin condition with clinical history; dermatologist reviews and responds within 24-48 hours
- **Radiology**: Imaging uploaded to PACS; radiologist reviews and reports asynchronously
- **Pathology**: Digital slides transmitted for remote pathologist review
- **Ophthalmology**: Retinal images captured at primary care and forwarded to ophthalmologist

### Implementation
- Secure upload portal with image quality validation (resolution, focus, lighting)
- Structured questionnaire accompanying the media for clinical context
- Provider queue with priority and SLA tracking (urgent vs. routine)
- Structured response templates for consistent documentation
- Integration with EHR for seamless documentation in the patient chart

## Billing Integration

### Telehealth CPT Codes
| Code | Description | Typical Use |
|------|-------------|-------------|
| **99201-99215** | E/M office visit codes | Synchronous video visits (with modifier -95 or Place of Service 02) |
| **99421-99423** | Online digital E/M | Asynchronous patient-initiated communications (time-based) |
| **99453** | RPM device setup | Initial device setup and patient education |
| **99454** | RPM device supply | Monthly device supply with daily recordings |
| **99457** | RPM management (first 20 min) | Clinical staff interactive communication |
| **99458** | RPM management (additional 20 min) | Each additional 20 minutes of management |
| **G2010** | Store-and-forward (brief) | Remote evaluation of pre-recorded information |
| **G2012** | Virtual check-in | Brief provider communication via phone or video (5-10 min) |

### Billing Considerations
- Verify payer-specific telehealth coverage and reimbursement rates
- Track originating site and distant site for proper claims submission
- Document informed consent for telehealth visit in the patient record
- Apply correct Place of Service code (02 for telehealth, 10 for patient home)
- Monitor state-specific telehealth regulations (parity laws, licensure requirements)
