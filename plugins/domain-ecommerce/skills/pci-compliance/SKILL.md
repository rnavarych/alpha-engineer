---
name: pci-compliance
description: |
  PCI DSS compliance for e-commerce: compliance levels (SAQ A, SAQ A-EP, SAQ D), cardholder
  data handling, tokenization (Stripe, Braintree tokens), secure payment forms (iframes,
  hosted fields), network segmentation, vulnerability scanning, penetration testing, and
  compliance audit preparation.
allowed-tools: Read, Grep, Glob, Bash
---

# PCI DSS Compliance

## Compliance Levels

### Self-Assessment Questionnaires (SAQ)
- **SAQ A**: Fully outsourced payment page (e.g., Stripe Checkout, PayPal hosted). Card data never touches your servers. Simplest compliance path; approximately 20 requirements.
- **SAQ A-EP**: Payment page on your domain but card data collected via JavaScript that sends directly to the gateway (e.g., Stripe Elements, Braintree Hosted Fields). Your page hosts the JavaScript but card data bypasses your server. Approximately 140 requirements.
- **SAQ D**: You directly handle, process, or store card data on your servers. Full PCI DSS assessment with all ~300 requirements. Avoid this unless absolutely necessary.

### Choosing the Right Level
- Prefer SAQ A (hosted payment page) for the simplest compliance burden.
- Use SAQ A-EP (JavaScript integration with hosted fields/iframes) for a custom checkout UX without handling card data.
- Only accept SAQ D if you have a specific business requirement to handle raw card numbers (rare).

## Cardholder Data Handling

### What You Must Never Do
- Never store the CVV/CVC/CVV2 after authorization, even if encrypted.
- Never log full card numbers (PAN) in application logs, error tracking, or analytics.
- Never transmit card data over unencrypted channels.
- Never store card data in cookies, local storage, or URL parameters.

### What You Can Store
- Truncated PAN (first 6 and last 4 digits) for display and customer identification.
- Tokenized references (gateway tokens) that map to the card on the provider's systems.
- Expiration date (if needed for display), but only alongside truncated PAN.

## Tokenization

### How Tokenization Works
- The payment gateway collects card details and returns a token (e.g., `pm_xxx` in Stripe, a payment method nonce in Braintree).
- Your server only handles the token, never the raw card number.
- Tokens are scoped to your merchant account and cannot be used by other merchants.

### Implementation
- Stripe: use `PaymentMethod` or `Token` objects. Attach to a `Customer` for reuse.
- Braintree: use `paymentMethodNonce` from the client SDK. Vault the nonce for recurring charges.
- Adyen: use `storedPaymentMethodId` after initial tokenization via the Components SDK.
- Always create tokens client-side (browser or mobile) and send only the token to your server.

## Secure Payment Forms

### Iframes (Stripe Elements, Braintree Hosted Fields)
- Card input fields render inside an iframe hosted by the payment provider.
- Your page's JavaScript cannot access the iframe contents (same-origin policy).
- Card data is sent directly from the iframe to the provider, never passing through your server.
- Customize the look and feel via provider APIs to match your site's design.

### Hosted Payment Pages
- Redirect the customer to a payment page hosted entirely by the provider (Stripe Checkout, PayPal).
- The customer enters card details on the provider's domain.
- After payment, the customer is redirected back to your site with a session/token reference.
- Lowest PCI scope; your servers have zero contact with card data.

## Network Segmentation

- Isolate payment processing systems in a separate network segment (VPC subnet, VLAN).
- Restrict inbound and outbound traffic to only what is necessary (gateway API endpoints, webhooks).
- Use firewalls and security groups to enforce segmentation.
- Place payment-related services behind a reverse proxy; do not expose them directly to the internet.
- Document your network topology for the PCI assessor.

## Vulnerability Scanning

### Internal Scans
- Run authenticated vulnerability scans on all systems in the cardholder data environment (CDE) quarterly.
- Remediate critical and high-severity findings before the next scan.

### External Scans (ASV)
- Engage an Approved Scanning Vendor (ASV) for quarterly external scans of public-facing systems.
- Achieve a passing scan (no vulnerabilities with CVSS >= 4.0 unresolved).
- Retain scan reports for at least one year.

### Continuous Monitoring
- Integrate SAST and DAST tools into CI/CD pipelines for ongoing code-level vulnerability detection.
- Monitor dependencies for known CVEs (Dependabot, Snyk, Trivy).

## Penetration Testing

- Conduct annual penetration tests on systems in and adjacent to the CDE.
- Test both application-layer and network-layer attack vectors.
- Engage a qualified third-party penetration testing firm.
- Remediate identified vulnerabilities and re-test to confirm fixes.
- Document findings, remediation, and re-test results for audit evidence.

## Compliance Audit Preparation

### Documentation
- Maintain an up-to-date data flow diagram showing where cardholder data enters, is processed, and exits.
- Document all third-party service providers that handle card data.
- Keep an inventory of all systems in the CDE with their roles and software versions.

### Policies and Procedures
- Information security policy covering access control, encryption, and incident response.
- Change management procedures for systems in the CDE.
- Employee security awareness training records.
- Incident response plan with specific procedures for a card data breach.

### Evidence Collection
- Collect firewall and access control configurations.
- Gather vulnerability scan and penetration test reports.
- Provide access logs showing who accessed CDE systems and when.
- Prepare encryption key management documentation.
