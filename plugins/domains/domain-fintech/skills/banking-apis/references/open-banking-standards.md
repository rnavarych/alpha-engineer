# Open Banking Standards

## When to load
Load when integrating with PSD2 APIs in Europe, UK Open Banking, FDX in North America, or any
regulatory-mandated banking API. Covers standards, endpoints, consent flows, and versioning.

## PSD2 APIs (Europe)

### Berlin Group NextGenPSD2
Most widely adopted in continental Europe.
- Account Information: `GET /v1/accounts`, `GET /v1/accounts/{id}/transactions`
- Payment Initiation: `POST /v1/payments/{payment-product}`
- Consent management: `POST /v1/consents` with access scope and validity period

### STET
French banking standard, similar scope to Berlin Group.

### Polish API (PolishAPI)
KIR-managed standard for Polish banks. Versioning: support multiple API versions during transition
periods.

## UK Open Banking

CMA-mandated standard for the CMA9 (nine largest UK banks).
- Account and Transaction API: `GET /accounts`, `GET /accounts/{id}/transactions`
- Payment Initiation API: `POST /domestic-payments`, `POST /international-payments`
- Confirmation of Funds API: `POST /funds-confirmations`
- Dynamic Client Registration for TPP onboarding
- Uses FAPI (Financial-grade API) security profile

## FDX (Financial Data Exchange) — North America

Successor to screen scraping for US/Canada financial data.
- Core API: accounts, transactions, statements, tax documents
- Consent management with granular data sharing permissions
- API certification program for data providers and recipients
- Transitioning from Plaid/Yodlee screen scraping to tokenized API access

## Account Information (AISP)

### Consent Management
- Granular consent: specify which accounts and data types to access
- Time-limited: consent expires after specified duration (max 90 days for PSD2)
- Revocable: customer can revoke consent at any time
- Consent receipts: provide customer with record of granted permissions
- Re-authentication: required when consent expires or for sensitive operations

### Data Categories
- Account details: account number, type, currency, status
- Balances: available, current, pending, credit line
- Transactions: date, amount, currency, merchant, category, status
- Beneficiaries: saved payee details
- Direct debits and standing orders
