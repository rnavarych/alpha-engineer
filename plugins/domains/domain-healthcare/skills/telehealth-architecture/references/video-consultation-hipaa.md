# Video Consultation and HIPAA-Compliant Video

## When to load
Selecting a video platform for telehealth, implementing WebRTC for clinical video visits, configuring HIPAA-compliant session management, or handling patient identity verification before video encounters.

## Technology Options

| Platform | Strengths | HIPAA BAA | Best For |
|----------|-----------|-----------|----------|
| **WebRTC** (self-hosted) | Full control, no per-minute costs, customizable UI | N/A (self-managed) | Organizations wanting full ownership |
| **Twilio Video** | Robust API, HIPAA-eligible, scalable, TURN/STUN included | Available | Custom-built telehealth platforms |
| **Vonage (TokBox)** | Mature WebRTC platform, session-based model, recording | Available | Multi-party consultations |
| **Zoom Video SDK** | Familiar UX, embedding SDK, reliable infrastructure | Available | Quick integration with existing workflows |
| **Doxy.me** | Purpose-built for telehealth, browser-based, simple | Available | Clinics needing turnkey solution |

## WebRTC Implementation

- Use SRTP (Secure Real-Time Transport Protocol) for media encryption
- Deploy TURN servers for NAT traversal (coturn is open-source and widely used)
- Implement signaling server (WebSocket-based) for session negotiation
- Handle network quality adaptation: bitrate adjustment, resolution scaling, audio-only fallback
- Support screen sharing for reviewing lab results or imaging with patients
- Record sessions (with consent) using server-side recording for documentation

## Video Quality Considerations

- Minimum bandwidth: 300 kbps for acceptable video, 1.5 Mbps for HD
- Implement network quality indicators for both provider and patient
- Graceful degradation: reduce video quality before dropping the call
- Test on real-world networks: cellular, rural broadband, institutional WiFi

## HIPAA-Compliant Video Requirements

- **BAA with provider**: Obtain a signed BAA from the video platform vendor
- **End-to-end encryption**: Media streams encrypted from sender to receiver
- **Access controls**: Authenticated access for both providers and patients
- **Waiting room**: Virtual waiting room to prevent unauthorized participants
- **Session logging**: Log session metadata (participants, duration, timestamps) without recording content unless consented
- **No recording by default**: Disable cloud recording unless explicitly required and consented

## Patient Identity Verification

- Verify patient identity before each video session (name, DOB, last 4 of SSN or MRN)
- Use unique session links with time-limited tokens (expire within 1 hour)
- Prevent link sharing by binding sessions to authenticated users
