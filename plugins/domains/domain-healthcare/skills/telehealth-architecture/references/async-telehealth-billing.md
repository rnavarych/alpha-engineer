# Asynchronous Telehealth and Billing Integration

## When to load
Implementing store-and-forward telehealth workflows, building provider review queues for asynchronous cases, handling telehealth CPT code billing, or navigating payer coverage and place-of-service requirements.

## Asynchronous Telehealth (Store-and-Forward)

- **Dermatology**: Patient uploads photos of skin condition with clinical history; dermatologist reviews and responds within 24-48 hours
- **Radiology**: Imaging uploaded to PACS; radiologist reviews and reports asynchronously
- **Pathology**: Digital slides transmitted for remote pathologist review
- **Ophthalmology**: Retinal images captured at primary care and forwarded to ophthalmologist

## Implementation

- Secure upload portal with image quality validation (resolution, focus, lighting)
- Structured questionnaire accompanying the media for clinical context
- Provider queue with priority and SLA tracking (urgent vs. routine)
- Structured response templates for consistent documentation
- Integration with EHR for seamless documentation in the patient chart

## Telehealth CPT Codes

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

## Billing Considerations

- Verify payer-specific telehealth coverage and reimbursement rates
- Track originating site and distant site for proper claims submission
- Document informed consent for telehealth visit in the patient record
- Apply correct Place of Service code (02 for telehealth, 10 for patient home)
- Monitor state-specific telehealth regulations (parity laws, licensure requirements)
