# Security Hardening: WAF, SIEM, Supply Chain, Container, Compliance

## When to load
Load when hardening infrastructure, setting up WAF or SIEM, securing container workloads, implementing supply chain security, or ensuring compliance with security frameworks.

## Web Application Firewalls (WAF)
- **AWS WAF**: Managed rules, IP reputation lists, Bot Control, Fraud Control, custom rules with WCUs
- **Cloudflare WAF**: OWASP ruleset, bot management, rate limiting, custom rules, DDoS protection
- **ModSecurity**: Open-source, OWASP CRS, nginx/Apache/IIS integration, paranoia levels
- **Azure WAF**: Application Gateway WAF v2, Front Door WAF, managed rulesets
- **GCP Cloud Armor**: Adaptive protection, preconfigured WAF rules, reCAPTCHA integration

## SIEM and Security Monitoring
- **Splunk Enterprise Security**: Industry standard, SPL queries, UEBA, SOAR integration
- **Microsoft Sentinel**: Cloud-native SIEM/SOAR, Azure-native, ML analytics, Workbooks
- **Elastic SIEM**: ELK-based, detection rules, timeline investigation
- **Chronicle (Google SecOps)**: Cloud-scale security analytics, YARA-L rules, SOAR
- Integrate with MITRE ATT&CK framework for detection rule mapping

## Supply Chain Security

### Frameworks
- **SLSA (Supply-chain Levels for Software Artifacts)**: L1-L4 build integrity levels
- **SBOM**: Software Bill of Materials in SPDX or CycloneDX format
- **OpenSSF Scorecard**: Automated security health checks for OSS projects

### Tools
- **Sigstore / Cosign**: Keyless container image signing using OIDC identity
- **Rekor**: Append-only transparency log for supply chain artifacts
- **in-toto**: Software supply chain attestations and policies
- **Syft**: SBOM generation; **Grype**: Vulnerability scanning against generated SBOMs

## Container Security
- **Falco**: Runtime security, syscall monitoring, Kubernetes audit log, CNCF project
- **Trivy**: All-in-one scanner: images, IaC, SBOM, secrets, licenses
- **Snyk Container**: Registry integration, base image recommendations, fix PRs
- **Docker Scout**: Native Docker CLI, image analysis, remediation guidance
- **KubeArmor**: Runtime security policy using LSM (AppArmor/SELinux/BPF)
- **OPA / Gatekeeper**: Policy-as-code for Kubernetes admission control
- **Kyverno**: Kubernetes-native policy engine, validation, mutation, generation

## Security Headers
```
Strict-Transport-Security: max-age=63072000; includeSubDomains; preload
Content-Security-Policy: default-src 'self'; script-src 'self'; object-src 'none'; base-uri 'self'
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
Referrer-Policy: strict-origin-when-cross-origin
Permissions-Policy: camera=(), microphone=(), geolocation=(), payment=()
Cross-Origin-Opener-Policy: same-origin
Cross-Origin-Embedder-Policy: require-corp
```

## Input Validation
- Validate on server side (client-side is UX only)
- Allowlist over denylist approach; validate type, length, format, range, encoding
- Sanitize HTML with DOMPurify (client), bleach (Python), sanitize-html (Node)
- Parameterized queries / prepared statements for all database operations

## Compliance Frameworks

### Security Standards
- **SOC 2 Type II**: Trust service criteria: security, availability, processing integrity, confidentiality, privacy
- **ISO 27001:2022**: ISMS requirements, Annex A controls, audit and certification
- **NIST CSF 2.0**: Govern, Identify, Protect, Detect, Respond, Recover
- **CIS Benchmarks**: Hardening guides for OS, cloud, containers, applications

### Regulatory Frameworks
- **FedRAMP**: US Federal cloud security requirements, ATO process, continuous monitoring
- **DORA**: EU financial sector ICT risk management, incident reporting, TLPT
- **NIS2 Directive**: EU network and information security, expanded scope, stricter penalties
- **PCI DSS v4.0**: 12 requirements, SAQ types, penetration testing, network segmentation
- **AI Act (EU)**: Risk-based AI regulation, prohibited AI, high-risk systems, conformity assessment
