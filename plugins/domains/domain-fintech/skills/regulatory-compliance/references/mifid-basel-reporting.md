# MiFID II, Basel III, and Regulatory Reporting Pipelines

## When to load
Load when implementing MiFID II best execution or transaction reporting obligations, calculating
Basel III capital ratios, or designing automated regulatory reporting pipelines.

## MiFID II (Markets in Financial Instruments Directive)

- **Best execution**: demonstrate best price/cost/speed for client orders
- **Transaction reporting**: report trades to regulators within T+1
- **Record keeping**: retain communications (phone, email, chat) for 5-7 years
- **Product governance**: target market assessment for financial products
- **Inducements**: disclose fees, commissions, and non-monetary benefits

## Basel III Capital Requirements

- Capital adequacy ratios: CET1 >= 4.5%, Tier 1 >= 6%, Total Capital >= 8%
- Liquidity Coverage Ratio (LCR): sufficient liquid assets for 30-day stress
- Net Stable Funding Ratio (NSFR): stable funding for 1-year horizon
- Leverage ratio: minimum 3% non-risk-weighted measure
- Data systems must support daily risk calculations and regulatory reporting

## Regulatory Reporting Pipelines

### Pipeline Architecture
```
Source Systems -> Extract -> Validate -> Transform -> Reconcile -> Submit -> Archive
```

### Pipeline Requirements
- Automated data quality checks at each stage with pass/fail gating
- Reconciliation between source data and report output
- Version-controlled transformation rules (auditors must see the logic)
- Submission audit trail: what was sent, when, to whom, acknowledgment received
- Resubmission workflow for corrections with regulatory impact assessment
