# Population Health Management and Clinical Decision Support

## When to load
Building risk stratification models, identifying care gaps, designing disease registries, implementing CDS alerts, managing alert fatigue, or configuring evidence-based order sets.

## Risk Stratification

- Assign patients to risk tiers (low, rising, moderate, high, complex) based on clinical and utilization data
- Use validated risk models: HCC (Hierarchical Condition Categories), LACE index (readmission risk), Charlson Comorbidity Index
- Input data: diagnoses, medications, lab results, utilization history, demographics, social determinants
- Update risk scores monthly or upon significant clinical events
- Stratified lists drive care management workflows: high-risk patients get proactive outreach

## Care Gap Identification

- Compare patient records against evidence-based guidelines to identify missing preventive care
- Common care gaps: overdue screenings (mammography, colonoscopy, HbA1c), missing immunizations, uncontrolled chronic conditions
- Generate patient outreach lists with specific gap details for care coordinators
- Track gap closure rates as a quality improvement metric
- Integrate care gap alerts into provider workflows at the point of care

## Chronic Disease Management

- Build disease registries for diabetes, hypertension, heart failure, COPD, asthma
- Track key metrics per condition: HbA1c for diabetes, BP readings for hypertension, ejection fraction for heart failure
- Identify patients not meeting treatment targets for intervention
- Support care plan adherence monitoring (medication refills, follow-up visits, self-management goals)

## CDS Alert Types

| Type | Trigger | Example |
|------|---------|---------|
| **Drug-drug interaction** | Medication order entry | Alert for concurrent warfarin and aspirin |
| **Drug-allergy** | Medication order with allergy on file | Alert for penicillin order with documented allergy |
| **Duplicate order** | Same or similar order already active | Alert for duplicate lab order within 24 hours |
| **Dosing guidance** | Order with renal/hepatic impairment | Suggest dose adjustment for low eGFR |
| **Preventive care reminder** | Patient visit with overdue screening | Prompt for annual diabetic eye exam |
| **Diagnostic support** | Lab result outside critical range | Flag critical potassium level for immediate review |

## Alert Fatigue Management

- Track override rates per alert type; alerts overridden more than 90% of the time need redesign
- Implement tiered severity: informational (passive), warning (interruptive but dismissible), hard stop (requires action)
- Suppress duplicate alerts within clinically appropriate windows
- Allow department and specialty-specific alert configuration
- Regularly review and retire low-value alerts based on clinician feedback

## Order Sets

- Pre-built bundles of orders for common clinical scenarios (e.g., chest pain admission, post-surgical care)
- Include medications, labs, imaging, nursing orders, and consults
- Based on evidence-based guidelines and institutional protocols
- Track order set utilization and outcomes for continuous improvement
