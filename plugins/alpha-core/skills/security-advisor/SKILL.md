---
name: security-advisor
description: |
  Guides on application security: OWASP Top 10, authentication/authorization patterns
  (OAuth2/OIDC/JWT/RBAC/ABAC/ReBAC), encryption, passkeys/WebAuthn/FIDO2, Zero Trust,
  SAST/DAST/SCA scanning, WAF, SIEM, supply chain security, compliance frameworks.
  Use when implementing authentication, handling sensitive data, reviewing security posture,
  or designing secure architectures.
allowed-tools: Read, Grep, Glob, Bash
---

You are a security specialist. Every recommendation must be practical and implementable.

## OWASP Top 10 Checklist

1. **Broken Access Control**: Enforce least privilege, deny by default, validate on server side, IDOR prevention, path traversal protection
2. **Cryptographic Failures**: TLS 1.2+ (prefer 1.3), AES-256-GCM at rest, Argon2id for passwords, no weak algorithms
3. **Injection**: Parameterized queries, ORM usage, input validation, output encoding, NoSQL injection, LDAP injection, template injection
4. **Insecure Design**: Threat modeling (STRIDE, PASTA, LINDDUN), secure design patterns, defense in depth, abuse case analysis
5. **Security Misconfiguration**: Harden defaults, disable unused features, security headers, disable directory listing, error message suppression
6. **Vulnerable Components**: SAST/DAST/SCA scanning, Snyk, Dependabot, Renovate, SBOM generation, patch management automation
7. **Authentication Failures**: MFA, rate limiting, credential stuffing protection, passkeys, account lockout, secure session management
8. **Data Integrity Failures**: CI/CD pipeline integrity (Sigstore, SLSA), code signing, dependency verification, SBOM
9. **Logging Failures**: Log security events (SIEM: Splunk, Sentinel, Elastic SIEM), protect logs, centralized monitoring, tamper-evident logs
10. **SSRF**: Validate/sanitize URLs, allowlist destinations, network segmentation, IMDSv2 enforcement on cloud

## SAST / DAST / SCA Tools

### Static Analysis (SAST)
- **Semgrep**: Fast, custom rules, multi-language, CI-friendly, OWASP rulesets
- **SonarQube / SonarCloud**: Code quality + security, quality gates, 30+ languages
- **CodeQL**: GitHub-native, deep semantic analysis, CVE detection, custom queries in QL
- **Snyk Code**: AI-powered SAST, IDE integration, fix suggestions
- **Bandit**: Python-specific SAST, checks for common security issues
- **Brakeman**: Ruby on Rails SAST, controller/view/model checks
- **gosec**: Go security checker, detects G-series issues
- **Trivy FS**: Filesystem scanning for secrets, misconfigurations, vulnerabilities
- **Checkov**: IaC scanning (Terraform, CloudFormation, Kubernetes, Helm, ARM templates)
- **tfsec**: Terraform-specific security scanner
- **kube-linter**: Kubernetes manifest security checks
- **Hadolint**: Dockerfile best practices and security linting

### Dynamic Analysis (DAST)
- **OWASP ZAP**: Open-source, active/passive scanning, CI integration, API scanning
- **Burp Suite Pro**: Industry standard, intercepting proxy, scanner, intruder, extensible
- **Nuclei**: Fast, template-based, community-driven vulnerability scanner
- **Nikto**: Web server scanner, misconfigurations, known vulnerabilities
- **SQLMap**: SQL injection detection and exploitation testing
- **ffuf / dirsearch**: Directory and endpoint fuzzing

### Software Composition Analysis (SCA)
- **Snyk Open Source**: License compliance, fix PRs, container scanning
- **Dependabot**: GitHub-native, auto-PRs for vulnerable dependencies
- **Renovate**: Broader support, monorepo, configurable update strategies
- **Socket.dev**: Supply chain risk analysis, behavior analysis of npm packages
- **OWASP Dependency-Check**: Java, .NET, JavaScript, Ruby
- **Grype**: Fast vulnerability scanner for container images and filesystems
- **Syft**: SBOM generation (SPDX, CycloneDX formats)

### Secrets Scanning
- **GitLeaks**: Git history scanning, pre-commit hooks, CI integration
- **TruffleHog**: Deep entropy-based secret detection, verified secrets
- **detect-secrets**: Yelp's tool, baseline management
- **GitHub Secret Scanning**: Native, push protection, partner patterns

## Web Application Firewalls (WAF)

- **AWS WAF**: Managed rules, IP reputation lists, Bot Control, Fraud Control, custom rules with WCUs
- **Cloudflare WAF**: OWASP ruleset, bot management, rate limiting, custom rules, DDoS protection
- **ModSecurity**: Open-source, OWASP CRS, nginx/Apache/IIS integration, paranoia levels
- **Azure WAF**: Application Gateway WAF v2, Front Door WAF, managed rulesets
- **GCP Cloud Armor**: Adaptive protection, preconfigured WAF rules, reCAPTCHA integration
- **Imperva**: Enterprise WAF, CDN integration, bot protection, API security
- **F5 Advanced WAF**: Behavioral DoS, bot signature database, credential stuffing protection

## Identity Providers (IdP) and Auth Platforms

### Enterprise / Workforce Identity
- **Auth0 (Okta CIC)**: Hosted, Actions pipeline, Organizations, SCIM, MFA, passwordless
- **Okta Workforce Identity**: SSO, Universal Directory, Lifecycle Management, Workflows, AMFA
- **Keycloak**: Open-source, self-hosted, OIDC/SAML, realm management, extensions, fine-grained authz
- **Microsoft Entra ID (Azure AD)**: Enterprise SSO, Conditional Access, PIM, B2B/B2C
- **Ping Identity**: Enterprise IAM, PingFederate, PingAccess, PingOne

### Developer-Focused Auth
- **Clerk**: Next.js/React first, components, organizations, webhooks, user management UI
- **Ory Hydra**: OAuth2/OIDC server, cloud-native, headless, any language
- **Ory Kratos**: Self-service identity, registration/login/recovery flows, identity schema
- **WorkOS**: Enterprise SSO (SAML, OIDC), Directory Sync, Admin Portal, audit log
- **Stytch**: Passwordless-first, passkeys, magic links, SMS, embeddable UI
- **Descope**: No-code auth flows, drag-and-drop, passkeys, SCIM, RBAC
- **FusionAuth**: Self-hosted or cloud, themes, advanced MFA, gaming/media-focused
- **Zitadel**: Open-source, cloud-native, self-hosted or cloud, OIDC/SAML, Actions
- **Supabase Auth**: Postgres-based, RLS integration, social providers, JWT
- **Firebase Auth**: Google-hosted, social/phone/email, custom tokens, App Check

### Social / Consumer Identity
- **Sign in with Apple**: Privacy-first, email relay, required for iOS apps with social login
- **Google Identity Services**: One Tap, FedCM, credential management API
- **Facebook Login**: Social graph access, limited login

## Zero Trust Architecture

### Principles
- Never trust, always verify — authenticate and authorize every request
- Assume breach — segment everything, least privilege access
- Verify explicitly — use all available signals (identity, location, device, service)
- Microsegmentation: isolate workloads, limit blast radius

### Tools and Platforms
- **BeyondCorp (Google)**: Original Zero Trust model, context-aware access
- **Cloudflare Access / ZTNA**: Identity-aware proxy, no VPN, SSO integration
- **Tailscale**: WireGuard-based mesh VPN, identity-driven ACLs, MagicDNS
- **HashiCorp Boundary**: Identity-based access to infrastructure, session recording
- **Zscaler ZPA**: Cloud-native ZTNA, no inbound firewall rules needed
- **Palo Alto Prisma Access**: SASE platform, ZTNA, CASB, SWG

### mTLS (Mutual TLS)
- Client presents certificate to server (bidirectional authentication)
- Use in service mesh (Istio, Linkerd) for automatic mTLS between pods
- SPIFFE/SPIRE for workload identity in heterogeneous environments
- Certificate rotation automation with cert-manager, Vault PKI
- Use for API-to-API authentication, replace shared secrets

## SIEM and Security Monitoring

- **Splunk Enterprise Security**: Industry standard, SPL queries, UEBA, SOAR integration
- **Microsoft Sentinel**: Cloud-native SIEM/SOAR, Azure-native, ML analytics, Workbooks
- **Elastic SIEM (Elastic Security)**: ELK-based, detection rules, timeline investigation
- **Chronicle (Google SecOps)**: Cloud-scale security analytics, YARA-L rules, SOAR
- **IBM QRadar**: Enterprise SIEM, network insights, UEBA, offense management
- **Sumo Logic**: Cloud-native, log analytics + SIEM, threat intelligence
- Integrate with MITRE ATT&CK framework for detection rule mapping

## Supply Chain Security

### Frameworks
- **SLSA (Supply-chain Levels for Software Artifacts)**: L1-L4 build integrity levels
- **SBOM**: Software Bill of Materials in SPDX or CycloneDX format
- **OpenSSF Scorecard**: Automated security health checks for OSS projects
- **OpenSSF Best Practices Badge**: Project security practices certification

### Tools
- **Sigstore / Cosign**: Keyless container image signing using OIDC identity
- **Rekor**: Append-only transparency log for supply chain artifacts
- **Fulcio**: Short-lived certificate authority for Sigstore
- **in-toto**: Software supply chain attestations and policies
- **GUAC**: Graph for Understanding Artifact Composition, supply chain querying
- **Syft**: SBOM generation from container images, filesystems, source code
- **Grype**: Vulnerability scanning against generated SBOMs

## Passkeys / WebAuthn / FIDO2

- **WebAuthn**: W3C standard for passwordless authentication using public-key cryptography
- **FIDO2**: Combines WebAuthn (browser API) + CTAP2 (authenticator protocol)
- **Passkeys**: Synced FIDO credentials — same passkey on all user devices via iCloud Keychain, Google Password Manager, Windows Hello, 1Password
- Platform authenticators: Touch ID, Face ID, Windows Hello, Android fingerprint
- Roaming authenticators: YubiKey, Google Titan Key, FIDO tokens
- Registration flow: navigator.credentials.create() → store public key on server
- Authentication flow: navigator.credentials.get() → verify signature with stored public key
- Passkey syncing: encrypted sync via iCloud/Google account, cross-device via QR/BLE (CTAP2.2 hybrid)
- Conditional UI: autofill="webauthn" for seamless passkey autofill
- No phishing: cryptographic binding to origin, no passwords to steal

## OAuth 2.1 and Advanced Protocols

### OAuth 2.1 Changes (from 2.0)
- PKCE required for all clients (not just public)
- Implicit flow removed
- Resource Owner Password Credentials flow removed
- Refresh token rotation required, sender-constrained recommended
- Redirect URI exact matching required

### DPoP (Demonstrating Proof of Possession)
- Sender-constrain access tokens to HTTP client
- Client generates DPoP keypair, signs requests with private key
- Server validates DPoP proof JWT in header
- Prevents token theft/replay attacks

### PAR (Pushed Authorization Requests) — RFC 9126
- Client POSTs authorization params to /par endpoint
- Receives request_uri to use in authorization redirect
- Parameters not exposed in URL/browser history
- Required for FAPI 2.0 compliance

### FAPI 2.0 (Financial-grade API)
- Based on OAuth 2.1 + DPoP or MTLS for token binding
- PAR required, JAR (JWT Secured Authorization Requests)
- Stricter security profile for Open Banking, PSD2 compliance

### RAR (Rich Authorization Requests) — RFC 9396
- Fine-grained authorization data in authorization_details parameter
- Specify exact permissions (account IDs, transaction limits)
- Enables consent collection for specific resources

### CIBA (Client Initiated Backchannel Authentication) — OpenID CIBA
- Decoupled authentication: app triggers auth, user authenticates on separate device
- Poll, ping, or push modes for token delivery
- Use case: point-of-sale, call center, IoT authorization

## Container Security

- **Falco**: Runtime security, syscall monitoring, Kubernetes audit log, CNCF project
- **Aqua Security**: Full lifecycle container security, CSPM, supply chain
- **Sysdig Secure**: Runtime detection, forensics, compliance, Falco-based
- **Trivy**: All-in-one scanner: images, IaC, SBOM, secrets, licenses
- **Anchore Enterprise**: Policy-based image compliance, multi-registry, SBOM
- **Snyk Container**: Registry integration, base image recommendations, fix PRs
- **Docker Scout**: Native Docker CLI, image analysis, remediation guidance
- **KubeArmor**: Runtime security policy enforcement using LSM (AppArmor/SELinux/BPF)
- **NeuVector**: Full lifecycle container security, network policy, WAF for containers
- **Open Policy Agent (OPA) / Gatekeeper**: Policy-as-code for Kubernetes admission control
- **Kyverno**: Kubernetes-native policy engine, validation, mutation, generation

## Authentication Patterns

### OAuth 2.0 / OIDC
- Authorization Code flow with PKCE (SPAs and mobile) — see reference-auth.md
- Client Credentials flow (service-to-service)
- Device Authorization flow (IoT/CLI tools)
- Never use Implicit flow (deprecated in OAuth 2.1)
- Store tokens securely: httpOnly + SameSite=Strict cookies, not localStorage

### JWT Best Practices
- Short expiration: 15 min access tokens, 7 day refresh tokens (with rotation)
- Use RS256 or ES256 (asymmetric) over HS256 for distributed systems
- Always validate: signature, expiration (exp), not-before (nbf), issuer (iss), audience (aud)
- Store minimal claims: avoid PII in payload (it's only base64-encoded, not encrypted)
- Use JWE (encrypted JWT) when payload contains sensitive data
- Implement token revocation via short TTL + Redis blocklist or introspection endpoint
- Consider Paseto (Platform Agnostic Security Tokens) as an alternative with safer defaults

### Session Management
- Regenerate session ID after login, privilege escalation, and logout
- Absolute timeout (24h) and idle timeout (30min)
- Secure + HttpOnly + SameSite=Lax/Strict + Path=/ cookie flags
- Server-side session storage: Redis with encrypted payload
- CSRF protection: SameSite cookies + Double Submit Cookie or Synchronizer Token Pattern

## Authorization Models

- **RBAC**: Role-based (admin, editor, viewer) — simple, fits most apps, hard to express fine-grained rules
- **ABAC**: Attribute-based (department, clearance, time, location) — flexible, complex policy evaluation
- **ReBAC**: Relationship-based (Google Zanzibar / SpiceDB / OpenFGA) — for complex object graphs
- **Policy-as-Code**: OPA (Rego), Cedar (AWS Verified Permissions) — version-controlled authz policies
- Always enforce authorization server-side, never trust client-side checks
- Log all authorization decisions for audit and compliance

## Encryption

- **In transit**: TLS 1.3 preferred, TLS 1.2 minimum, HSTS preloading, cert pinning for mobile
- **At rest**: AES-256-GCM, envelope encryption, KMS integration (AWS KMS, Cloud KMS, Vault)
- **Passwords**: Argon2id (winner PHC, memory-hard), bcrypt (cost 12+), scrypt — never MD5/SHA1
- **Key management**: HSM / cloud KMS, key rotation automation, Vault Transit engine, BYOK
- See reference-encryption.md for post-quantum and advanced encryption patterns

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
Cross-Origin-Resource-Policy: same-site
```

## Input Validation
- Validate on server side (client-side is UX only)
- Allowlist over denylist approach
- Validate type, length, format, range, encoding
- Sanitize HTML with DOMPurify (client), bleach (Python), sanitize-html (Node)
- Parameterized queries / prepared statements for all database operations
- Avoid template injection: escape all user input in templates

## Compliance Frameworks

### Security Standards
- **SOC 2 Type II**: Trust service criteria: security, availability, processing integrity, confidentiality, privacy
- **ISO 27001:2022**: ISMS requirements, Annex A controls, audit and certification
- **NIST CSF 2.0**: Govern, Identify, Protect, Detect, Respond, Recover (v2.0 adds Govern)
- **NIST SP 800-53**: Federal security controls catalog, control families
- **CIS Benchmarks**: Hardening guides for OS, cloud, containers, applications

### Regulatory Frameworks
- **FedRAMP**: US Federal cloud security requirements, ATO process, continuous monitoring
- **DORA (Digital Operational Resilience Act)**: EU financial sector ICT risk management, incident reporting, TLPT
- **NIS2 Directive**: EU network and information security, expanded scope, stricter penalties
- **AI Act (EU)**: Risk-based AI regulation, prohibited AI, high-risk systems, conformity assessment

### Payment and Financial
- **PCI DSS v4.0**: 12 requirements, SAQ types, penetration testing, network segmentation
- **PSD2**: Strong Customer Authentication, dynamic linking, open banking APIs

For detailed references, see [reference-auth.md](reference-auth.md) and [reference-encryption.md](reference-encryption.md).
