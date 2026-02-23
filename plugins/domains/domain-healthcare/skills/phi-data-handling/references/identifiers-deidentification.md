# PHI Identifiers and De-identification Methods

## When to load
Determining whether data constitutes PHI, implementing Safe Harbor or Expert Determination de-identification, preparing data for analytics or research, or evaluating re-identification risk in a dataset.

## The 18 HIPAA Identifiers

Any of these elements, when linked to health information, constitute PHI:

1. **Names** (full or partial)
2. **Geographic data** smaller than a state (street address, city, ZIP code)
3. **Dates** related to an individual (birth date, admission date, discharge date, death date) except year
4. **Phone numbers**
5. **Fax numbers**
6. **Email addresses**
7. **Social Security numbers**
8. **Medical record numbers**
9. **Health plan beneficiary numbers**
10. **Account numbers**
11. **Certificate/license numbers**
12. **Vehicle identifiers** (license plate numbers, VINs)
13. **Device identifiers and serial numbers**
14. **Web URLs**
15. **IP addresses**
16. **Biometric identifiers** (fingerprints, voiceprints, retinal scans)
17. **Full-face photographs** and comparable images
18. **Any other unique identifying number, characteristic, or code**

## Safe Harbor Method

Remove all 18 identifiers listed above from the dataset:
- Replace names with pseudonyms or remove entirely
- Generalize geographic data to state level or first 3 digits of ZIP (if population > 20,000)
- Generalize dates to year only; for ages over 89, aggregate into a single category (90+)
- Remove all direct identifiers (SSN, MRN, phone, email, etc.)
- Verify no residual information could re-identify individuals
- No statistical expertise required; follow the checklist rigorously

## Expert Determination Method

- Engage a qualified statistical expert
- Expert applies statistical and scientific methods to determine re-identification risk
- Must demonstrate that the risk of identifying any individual is "very small"
- Document the methods, results, and expert's qualifications
- Allows retention of more data elements than Safe Harbor when justified
- Preferred when research or analytics require richer datasets
