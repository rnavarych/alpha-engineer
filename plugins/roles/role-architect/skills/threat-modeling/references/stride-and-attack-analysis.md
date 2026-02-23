# STRIDE Methodology and Attack Analysis

## When to load
Load when applying the STRIDE framework to identify threats, building attack trees, identifying trust boundaries, or tracing sensitive data flows through a system.

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
- Mitigations: principle of least privilege for all access controls, field-level encryption for sensitive data (PII, financial data), response filtering, generic error messages in production, and data classification with access policies per classification level.

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
