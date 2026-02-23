# Risk Assessment, Mitigation Prioritization, and Security Architecture Review

## When to load
Load when rating threats using likelihood/impact matrices, prioritizing mitigations, defining acceptable risk tolerance, or conducting structured security architecture reviews.

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
