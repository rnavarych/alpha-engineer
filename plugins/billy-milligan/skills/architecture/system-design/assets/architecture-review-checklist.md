# Architecture Review Checklist

## System Overview
- [ ] Architecture pattern identified (monolith / modular monolith / microservices / serverless)
- [ ] Key components and their responsibilities documented
- [ ] Data flow diagram exists and is current
- [ ] Technology choices justified with decision records

## Scalability
- [ ] Expected traffic (RPM) identified and architecture matches thresholds
- [ ] Horizontal scaling strategy defined (stateless services, load balancing)
- [ ] Database scaling plan in place (read replicas, sharding, connection pooling)
- [ ] Caching strategy defined (L1/L2, TTL, invalidation)
- [ ] Rate limiting implemented at API gateway level

## Reliability
- [ ] Single points of failure identified and mitigated
- [ ] Health checks implemented (liveness + readiness)
- [ ] Graceful degradation strategy for dependency failures
- [ ] Circuit breakers on external service calls
- [ ] Retry policies with exponential backoff and jitter

## Data
- [ ] Data ownership per service/module clearly defined
- [ ] Consistency model chosen (strong vs eventual) and documented
- [ ] Backup and recovery strategy tested
- [ ] Data retention policies defined
- [ ] PII handling compliant with relevant regulations

## Security
- [ ] Authentication and authorization patterns defined
- [ ] Secrets management via vault/KMS (not env vars in code)
- [ ] Network boundaries and access controls in place
- [ ] OWASP Top 10 mitigations verified

## Observability
- [ ] Structured logging with correlation IDs
- [ ] Key metrics defined (RED method: Rate, Errors, Duration)
- [ ] Distributed tracing configured
- [ ] SLOs defined with error budget alerts
- [ ] Runbooks exist for critical failure modes

## Deployment
- [ ] CI/CD pipeline covers: lint → test → build → security scan → deploy
- [ ] Zero-downtime deployment strategy implemented
- [ ] Rollback procedure documented and tested
- [ ] Feature flags for risky changes
- [ ] Database migration strategy supports rollback
