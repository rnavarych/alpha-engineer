# Test Strategy: [Project Name]

**Date**: YYYY-MM-DD
**Author**: [Name]
**Status**: [Draft / Approved]

## Scope
- Features in scope: [list]
- Features out of scope: [list]

## Test Pyramid Distribution
| Level | Target % | Current % | Tools |
|-------|----------|-----------|-------|
| Unit | 70% | ___ | Jest/Vitest |
| Integration | 20% | ___ | Supertest/Testcontainers |
| E2E | 10% | ___ | Playwright |

## Coverage Targets
- [ ] Overall: ≥80% line coverage
- [ ] Critical paths: ≥90% branch coverage
- [ ] New code: 100% coverage required

## Test Data Strategy
- [ ] Factories defined for core entities
- [ ] Seed scripts for local development
- [ ] Test database isolation strategy: [per-worker schema / transactions]

## CI Integration
- [ ] Tests run on every PR
- [ ] Flaky test quarantine process defined
- [ ] Test splitting for parallel execution

## Risk Areas
| Area | Risk Level | Mitigation |
|------|-----------|------------|
| [Payment flow] | High | Integration + E2E + contract tests |
| [Auth] | High | Unit + security tests |
| [Search] | Medium | Integration + load tests |

## Sign-off
- [ ] Dev lead approved
- [ ] QA reviewed
