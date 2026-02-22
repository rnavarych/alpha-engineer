---
name: threat-modeling
description: |
  Threat modeling expertise including STRIDE methodology, attack trees,
  trust boundary identification, data flow analysis, risk assessment,
  mitigation prioritization, and security architecture review.
allowed-tools: Read, Grep, Glob, Bash
---

# Threat Modeling

## STRIDE Methodology

Apply the STRIDE framework systematically to each component and data flow in the system:

### Spoofing (Authentication Threats)
- Can an attacker impersonate a legitimate user, service, or system component?
- Check for: weak authentication mechanisms, missing mutual TLS between services, hardcoded credentials, session tokens without expiration, and API keys transmitted in URLs.
- Mitigations: multi-factor authentication, short-lived JWT tokens with refresh rotation, mutual TLS for service-to-service communication, and API key management with automated rotation.

### Tampering (Integrity Threats)
- Can an attacker modify data in transit or at rest without detection?
- Check for: unencrypted communication channels, missing input validation, unsigned API responses, mutable audit logs, and SQL/NoSQL injection vectors.
- Mitigations: TLS for all data in transit, HMAC or digital signatures for sensitive payloads, parameterized queries, immutable append-only audit logs, and content integrity checks (checksums, SRI hashes).

### Repudiation (Accountability Threats)
- Can a user deny performing an action, and can you prove they did?
- Check for: missing audit trails, insufficient logging detail, unsigned transactions, and logs stored on the same system they monitor.
- Mitigations: comprehensive audit logging with timestamps, user identity, action, and affected resource. Store logs in a tamper-evident system (append-only, separate from application infrastructure). Digital signatures on critical transactions.

### Information Disclosure (Confidentiality Threats)
- Can an attacker access data they should not see?
- Check for: excessive API response data (returning full objects instead of projections), error messages leaking stack traces or database schemas, insecure direct object references (IDOR), unencrypted data at rest, and overly permissive access controls.
- Mitigations: principle of least privilege for all access controls, field-level encryption for sensitive data (PII, financial data), response filtering to return only requested fields, generic error messages in production, and data classification with access policies per classification level.

### Denial of Service (Availability Threats)
- Can an attacker degrade or disrupt the system's availability?
- Check for: endpoints without rate limiting, resource-intensive operations triggerable by unauthenticated users, unbounded queries (SELECT * without LIMIT), missing circuit breakers on external dependencies, and single points of failure.
- Mitigations: rate limiting and throttling per user/IP/API key, request size limits, query complexity limits (for GraphQL), circuit breakers with fallback responses, auto-scaling with maximum bounds, and DDoS protection (WAF, CDN-level filtering).

### Elevation of Privilege (Authorization Threats)
- Can an attacker gain permissions beyond what they are authorized for?
- Check for: missing authorization checks on API endpoints, role escalation vulnerabilities, insecure deserialization, path traversal, and command injection.
- Mitigations: enforce authorization at every layer (API gateway, application, database), use RBAC or ABAC with the principle of least privilege, validate all input and reject unexpected types, and run services with minimum required OS permissions.

## Attack Trees

- Model threats hierarchically: root node is the attacker's goal, child nodes are methods to achieve it.
- For each leaf node, assess: feasibility (skill required, tools needed, access required) and cost to the attacker.
- Focus defense on leaf nodes that are both feasible and high-impact.
- Example structure:
  - Goal: "Access customer PII"
    - Method 1: "Exploit SQL injection in search endpoint"
    - Method 2: "Compromise admin credentials via phishing"
    - Method 3: "Access unencrypted database backup in S3"
- Update attack trees when the system architecture changes or new attack vectors are disclosed.

## Trust Boundary Identification

- A trust boundary exists wherever data crosses between different levels of trust (e.g., user input to server, server to database, internal service to external API).
- Draw trust boundaries on the system architecture diagram. Common boundaries:
  - Internet to DMZ (external users to public-facing services)
  - DMZ to internal network (public services to internal services)
  - Application to database (application logic to data storage)
  - Service to service (between microservices with different data access levels)
  - Internal to third-party (your system to vendor APIs)
- Every data flow crossing a trust boundary must validate, sanitize, and authenticate.

## Data Flow Analysis

- Trace every type of sensitive data through the system: where it enters, how it transforms, where it is stored, and where it exits.
- Classify data by sensitivity: public, internal, confidential, restricted.
- For each data type, document: encryption requirements (in transit, at rest), access control requirements, retention period, and disposal method.
- Identify data aggregation risks: individually non-sensitive data that becomes sensitive when combined (e.g., browsing history + location + purchase history = personal profile).

## Risk Assessment

### Likelihood x Impact Matrix
- Rate each identified threat on two dimensions:
  - **Likelihood**: How probable is exploitation? Consider attacker motivation, skill required, and exposure surface. Scale: Low (1), Medium (2), High (3).
  - **Impact**: What is the damage if exploited? Consider data loss, financial loss, reputational damage, regulatory penalties, and operational disruption. Scale: Low (1), Medium (2), High (3).
- Risk score = Likelihood x Impact. Prioritize: High (6-9), Medium (3-4), Low (1-2).

### Risk Tolerance
- Define acceptable risk levels with stakeholders before the assessment. Not all risks need mitigation.
- Accept low risks with documentation. Mitigate medium and high risks. Transfer extreme risks via insurance or contracts.

## Mitigation Prioritization

- Address high-risk items first. Within the same risk level, prioritize by cost of mitigation (cheapest effective fix first).
- Quick wins: fixes that take less than a day and reduce risk significantly (e.g., enabling TLS, adding rate limiting, removing debug endpoints).
- Strategic mitigations: larger efforts that reduce risk across multiple threats (e.g., implementing a centralized authentication service, adopting a zero-trust network model).
- Track mitigations as tasks with owners and deadlines. Review completion in security review meetings.
- Residual risk: after mitigation, re-assess each threat. Document remaining risk and the rationale for accepting it.

## Security Architecture Review

- Conduct security architecture reviews at three points: initial design, before major releases, and after security incidents.
- Review checklist:
  - Authentication: How are users and services authenticated? Are credentials stored securely?
  - Authorization: How are permissions enforced? Is least privilege applied?
  - Data protection: Is sensitive data encrypted at rest and in transit? Are encryption keys managed securely?
  - Network security: Are services exposed only as needed? Are internal communications secured?
  - Logging and monitoring: Are security-relevant events logged? Are alerts configured for anomalous behavior?
  - Dependency security: Are third-party libraries scanned for vulnerabilities? Is there a patch management process?
  - Incident response: Is there a documented incident response plan? Has it been tested?
- Document findings in a security review report with severity ratings and remediation recommendations.
