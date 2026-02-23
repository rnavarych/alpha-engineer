# Social Determinants of Health Data

## When to load
Collecting or modeling SDOH data, coding social needs with ICD-10 Z-codes or LOINC, integrating community resource referrals, or incorporating SDOH factors into risk stratification and care gap workflows.

## SDOH Data Categories

- **Economic stability**: Employment, income, food insecurity, housing instability
- **Education**: Literacy, language, educational attainment
- **Healthcare access**: Insurance coverage, transportation barriers, provider availability
- **Neighborhood**: Safety, environmental quality, broadband access
- **Social and community**: Social isolation, discrimination, incarceration history

## SDOH Data Collection

- Screen patients using validated tools: PRAPARE, AHC-HRSN (Accountable Health Communities)
- Code SDOH observations using ICD-10-CM Z-codes (Z55-Z65 range) and LOINC survey codes
- Store SDOH data as FHIR Observation resources linked to the patient
- Integrate SDOH data into risk models and care gap identification
- Connect patients to community resources through closed-loop referral platforms (e.g., Unite Us, Aunt Bertha/findhelp)
