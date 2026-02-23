# Network Segmentation, Vulnerability Scanning, Pen Testing, and Audit Prep

## When to load
Load when implementing network segmentation for payment systems, setting up vulnerability scanning, preparing for a PCI audit, or documenting the cardholder data environment (CDE).

## Network Segmentation
- Isolate payment processing systems in a separate network segment (VPC subnet, VLAN).
- Restrict inbound and outbound traffic to only what is necessary: gateway API endpoints and webhooks.
- Use firewalls and security groups to enforce segmentation rules.
- Place payment-related services behind a reverse proxy — do not expose directly to the internet.
- Document your network topology for the PCI assessor; keep it current.

## Vulnerability Scanning

### Internal Scans
- Run authenticated vulnerability scans on all systems in the cardholder data environment (CDE) quarterly.
- Remediate critical and high-severity findings before the next scan cycle.

### External Scans (ASV)
- Engage an Approved Scanning Vendor (ASV) for quarterly external scans of public-facing systems.
- Achieve a passing scan: no unresolved vulnerabilities with CVSS >= 4.0.
- Retain scan reports for at least one year.

### Continuous Monitoring
- Integrate SAST and DAST tools into CI/CD pipelines for ongoing code-level detection.
- Monitor dependencies for known CVEs: Dependabot, Snyk, Trivy.

## Penetration Testing
- Conduct annual penetration tests on systems in and adjacent to the CDE.
- Test both application-layer and network-layer attack vectors.
- Engage a qualified third-party penetration testing firm.
- Remediate identified vulnerabilities and re-test to confirm fixes.
- Document findings, remediation, and re-test results as audit evidence.

## Compliance Audit Preparation

### Documentation
- Maintain an up-to-date data flow diagram showing where cardholder data enters, is processed, and exits.
- Document all third-party service providers that handle card data.
- Keep an inventory of all CDE systems with roles and software versions.

### Policies and Procedures
- Information security policy covering access control, encryption, and incident response.
- Change management procedures for CDE systems.
- Employee security awareness training records.
- Incident response plan with specific procedures for a card data breach.

### Evidence Collection
- Firewall and access control configurations.
- Vulnerability scan and penetration test reports.
- Access logs showing who accessed CDE systems and when.
- Encryption key management documentation.
