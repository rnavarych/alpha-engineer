# HL7v2 Messaging

## When to load
Processing ADT, ORM, ORU, or other HL7v2 message types, implementing an interface engine channel, mapping HL7v2 fields to an internal data model, or troubleshooting message delivery and acknowledgment failures.

## Message Types

| Message | Trigger | Purpose |
|---------|---------|---------|
| **ADT** (A01-A60) | Admit, Discharge, Transfer | Patient movement and registration events |
| **ORM** (O01) | Order Message | New orders for labs, imaging, procedures |
| **ORU** (R01) | Observation Result | Lab results, radiology reports, transcriptions |
| **MDM** (T01-T11) | Medical Document Management | Clinical document notifications and content |
| **SIU** (S12-S26) | Scheduling | Appointment scheduling and updates |
| **DFT** (P03) | Detail Financial Transaction | Charge posting and billing events |
| **RDE** (O11) | Pharmacy Encoded Order | Medication orders to pharmacy systems |

## HL7v2 Message Structure

- Messages consist of segments (MSH, PID, PV1, OBR, OBX) separated by carriage returns
- Fields within segments separated by `|`, components by `^`, subcomponents by `&`
- MSH segment contains message type, sending/receiving facility, timestamp, and message control ID
- Implement acknowledgment (ACK) messages for reliable delivery

## HL7v2 Best Practices

- Validate inbound messages against expected message profiles
- Map HL7v2 fields to your internal data model with explicit transformation rules
- Handle character encoding (UTF-8) and escape sequences
- Implement dead letter queues for messages that fail processing
- Log all messages with correlation IDs for troubleshooting
