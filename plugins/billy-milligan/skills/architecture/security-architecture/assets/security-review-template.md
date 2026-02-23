# Security Review Template

## Project information
- **Project/Feature**: _______________
- **Reviewer**: _______________
- **Date**: _______________
- **Risk level**: [ ] Low [ ] Medium [ ] High [ ] Critical

## Threat model

### Assets (what are we protecting?)

| Asset | Classification | Impact if compromised |
|-------|---------------|----------------------|
| User credentials | Critical | Account takeover, data breach |
| PII (name, email, address) | High | Regulatory violation, reputation |
| Payment data | Critical | Financial loss, PCI compliance |
| API keys / secrets | Critical | Unauthorized access, data exfiltration |
| Business logic / IP | Medium | Competitive disadvantage |
| _______________ | ___ | _______________ |
| _______________ | ___ | _______________ |

### Threats (STRIDE model)

| Category | Threat | Applicable? | Mitigation |
|----------|--------|-------------|------------|
| **S**poofing | Identity impersonation | [ ] Yes [ ] No | Auth: JWT/sessions, MFA |
| **T**ampering | Data modification in transit | [ ] Yes [ ] No | TLS 1.2+, HMAC signatures |
| **R**epudiation | Denying actions taken | [ ] Yes [ ] No | Audit logging, signed events |
| **I**nformation Disclosure | Data leakage | [ ] Yes [ ] No | Encryption, access controls |
| **D**enial of Service | Service unavailability | [ ] Yes [ ] No | Rate limiting, auto-scaling |
| **E**levation of Privilege | Unauthorized access | [ ] Yes [ ] No | RBAC, least privilege |

### Attack surface

| Entry point | Auth required? | Input validation | Rate limited? |
|------------|---------------|-----------------|--------------|
| Public API | [ ] Yes [ ] No | [ ] Schema validation | [ ] Yes: ___/min |
| Admin API | [ ] Yes [ ] No | [ ] Schema validation | [ ] Yes: ___/min |
| Webhook endpoint | [ ] Yes [ ] No | [ ] Signature verification | [ ] Yes: ___/min |
| File upload | [ ] Yes [ ] No | [ ] Type + size check | [ ] Yes: ___/min |
| WebSocket | [ ] Yes [ ] No | [ ] Message validation | [ ] Yes: ___/min |
| _______________ | [ ] Yes [ ] No | [ ] _______________ | [ ] Yes: ___/min |

## Security controls review

### Authentication
- [ ] Authentication mechanism documented (JWT / sessions / OAuth2)
- [ ] Password policy: minimum 12 chars, breach database check
- [ ] MFA available for sensitive operations
- [ ] Session/token expiry configured (access: 15min, refresh: 7d)
- [ ] Account lockout after 5 failed attempts (15min cooldown)

### Authorization
- [ ] RBAC or ABAC model documented
- [ ] Ownership checks on all resource endpoints (IDOR prevention)
- [ ] Admin endpoints restricted by role AND IP/network
- [ ] API scopes defined and enforced
- [ ] Default deny: new endpoints require explicit permission grants

### Data protection
- [ ] PII encrypted at rest (AES-256-GCM)
- [ ] TLS 1.2+ enforced for all connections
- [ ] Sensitive fields masked in logs (SSN, credit card, password)
- [ ] Data retention policy defined and automated
- [ ] Backup encryption enabled

### Input validation
- [ ] All inputs validated with schema (Zod, Joi, Ajv)
- [ ] SQL queries use parameterized statements (no string concatenation)
- [ ] File uploads validated: type, size, content (not just extension)
- [ ] URLs validated for SSRF (block private IPs, metadata endpoints)
- [ ] Output encoding for XSS prevention (CSP headers in place)

### Infrastructure
- [ ] Secrets in vault/KMS (not in env vars in code or config files)
- [ ] Network policies: default deny, explicit allow
- [ ] Container images scanned for vulnerabilities
- [ ] Service-to-service auth (mTLS or signed requests)
- [ ] No root containers in production

### Monitoring
- [ ] Security events logged: auth failures, privilege changes, data access
- [ ] Alerts configured for: brute force, unusual data access patterns
- [ ] Incident response runbook exists
- [ ] Log retention: 90 days minimum for security events

## Findings

| # | Severity | Finding | Recommendation | Status |
|---|----------|---------|----------------|--------|
| 1 | ___ | | | [ ] Open [ ] Fixed [ ] Accepted |
| 2 | ___ | | | [ ] Open [ ] Fixed [ ] Accepted |
| 3 | ___ | | | [ ] Open [ ] Fixed [ ] Accepted |

### Severity definitions
- **Critical**: exploitable now, data breach risk, fix before deploy
- **High**: significant risk, fix within 1 sprint
- **Medium**: moderate risk, fix within 1 month
- **Low**: minor issue, fix when convenient

## Residual risk

| Risk | Likelihood | Impact | Mitigation in place | Accepted by |
|------|-----------|--------|--------------------|-----------|
| | [ ] Low [ ] Med [ ] High | [ ] Low [ ] Med [ ] High | | |
| | [ ] Low [ ] Med [ ] High | [ ] Low [ ] Med [ ] High | | |

## Sign-off
- [ ] All critical and high findings addressed
- [ ] Residual risks documented and accepted by stakeholder
- [ ] Next review scheduled: _______________
